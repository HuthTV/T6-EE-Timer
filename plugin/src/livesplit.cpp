#include "std_include.hpp"
#include <winsock2.h>
#include <ws2tcpip.h>
#include "livesplit.hpp"
#include "menu_state.hpp"
#include <condition_variable>
#include <deque>
#include <vector>


#include <mutex>

#include <thread>
#include <atomic>


#pragma comment(lib, "Ws2_32.lib")

namespace livesplit
{
    namespace
    {
        enum class event { time, split, reset, restore };
        struct sample { int map = -1; int index = 0; int milliseconds = 0; event kind = event::time; bool enabled = false; };
        std::mutex mutex;
        std::condition_variable wake;
        std::deque<sample> pending;
        std::thread worker;
        bool stopping = false;
        bool overflow = false;
        std::atomic<bool> report_failure = false;
        bool failure_reported = false;
        plutonium::sdk::iinterface* sdk = nullptr;
        unsigned short port = 16834;
        void push(sample value)
        {
            std::lock_guard lock(mutex);
            if (stopping) return;
            // Coalesce clock samples; preserve lifecycle and split events in order.
            if (value.kind == event::time && !pending.empty() && pending.back().kind == event::time)
                pending.back() = value;
            else if (pending.size() < 128) pending.push_back(value);
            else { overflow = true; report_failure = true; }
            wake.notify_one();
        }

        void enqueue(int map, int index, int milliseconds, bool split)
        {
            if (!menu_state::valid(map, index, milliseconds, split)) return;
            menu_state::observe(map, index);
            push({map, index, milliseconds, split ? event::split : event::time});
        }

        SOCKET connect_local()
        {
            SOCKET socket = ::socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
            if (socket == INVALID_SOCKET) return socket;
            u_long nonblocking = 1;
            ioctlsocket(socket, FIONBIO, &nonblocking);
            sockaddr_in address{};
            address.sin_family = AF_INET;
            address.sin_port = htons(port);
            address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
            const int result = connect(socket, reinterpret_cast<sockaddr*>(&address), sizeof(address));
            if (result == SOCKET_ERROR && WSAGetLastError() != WSAEWOULDBLOCK)
            { closesocket(socket); return INVALID_SOCKET; }
            fd_set writable;
            FD_ZERO(&writable);
            FD_SET(socket, &writable);
            timeval timeout{0, 200000};
            int error = 0;
            int length = sizeof(error);
            if (select(0, nullptr, &writable, nullptr, &timeout) <= 0 ||
                getsockopt(socket, SOL_SOCKET, SO_ERROR, reinterpret_cast<char*>(&error), &length) != 0 || error)
            { closesocket(socket); return INVALID_SOCKET; }
            nonblocking = 0;
            ioctlsocket(socket, FIONBIO, &nonblocking);
            DWORD send_timeout = 200;
            setsockopt(socket, SOL_SOCKET, SO_SNDTIMEO, reinterpret_cast<char*>(&send_timeout), sizeof(send_timeout));
            BOOL no_delay = TRUE;
            setsockopt(socket, IPPROTO_TCP, TCP_NODELAY, reinterpret_cast<char*>(&no_delay), sizeof(no_delay));
            return socket;
        }

        bool send_all(SOCKET socket, const std::string& commands)
        {
            size_t offset = 0;
            while (offset < commands.size())
            {
                const int sent = send(socket, commands.data() + offset, static_cast<int>(commands.size() - offset), 0);
                if (sent <= 0) return false;
                offset += sent;
            }
            return true;
        }

        std::string game_time(int milliseconds)
        {
            // Always use a dot for decimal seconds.
            const auto fraction = std::to_string(1000 + milliseconds % 1000).substr(1);
            return "setgametime " + std::to_string(milliseconds / 1000) + "." + fraction + "\n";
        }

        void run()
        {
            SOCKET socket = INVALID_SOCKET;
            bool synchronized = false, started_output = false, have_time = false;
            int elapsed = 0;
            std::vector<int> history;
            auto disconnect = [&] {
                if (socket != INVALID_SOCKET) closesocket(socket);
                socket = INVALID_SOCKET;
                synchronized = false;
            };
            ULONGLONG retry_at = 0;
            for (;;)
            {
                sample value;
                {
                    std::unique_lock lock(mutex);
                    if (!synchronized && have_time)
                        wake.wait_for(lock, std::chrono::seconds(1), [] { return stopping || !pending.empty() || overflow; });
                    else wake.wait(lock, [] { return stopping || !pending.empty() || overflow; });
                    if (stopping && pending.empty()) break;
                    if (overflow)
                    {
                        have_time = false;
                        pending.clear();
                        overflow = false;
                        history.clear();
                        continue;
                    }
                    if (pending.empty()) value.kind = event::restore;
                    else { value = pending.front(); pending.pop_front(); }
                }
                if (value.kind == event::reset)
                {
                    elapsed = 0;
                    history.clear();
                    have_time = true;
                    synchronized = false;
                    started_output = false;
                }
                else if (value.kind != event::restore)
                {
                    // GSC supplies the complete cumulative time. Never add a native offset.
                    elapsed = value.milliseconds;
                    have_time = true;
                    if (value.kind == event::split)
                    {
                        value.enabled = menu_state::enabled(value.map, value.index);
                        if (value.enabled) history.push_back(elapsed);
                    }
                }
                // Rebuild from known split history after a reset or uncertain TCP send.
                // Reset before replay makes a partially delivered split safe to recover.
                if (socket == INVALID_SOCKET && GetTickCount64() >= retry_at)
                {
                    socket = connect_local();
                    retry_at = GetTickCount64() + 1000;
                    if (socket == INVALID_SOCKET) report_failure = true;
                }
                if (socket == INVALID_SOCKET) continue;
                std::string commands;
                if (!synchronized)
                {
                    commands = "reset\npausegametime\nsetgametime 0.000\n";
                    if (elapsed > 0 || !history.empty()) commands += "start\npausegametime\n";
                    for (int time : history) commands += game_time(time) + "split\n";
                    commands += game_time(elapsed);
                }
                else
                {
                    // A fresh map begin with zero time leaves LiveSplit in NotRunning.
                    if (elapsed > 0 && !started_output) commands += "start\npausegametime\n";
                    commands += game_time(elapsed);
                    if (value.enabled) commands += "split\n";
                }
                if (!send_all(socket, commands)) { disconnect(); report_failure = true; }
                else { synchronized = true; started_output = elapsed > 0 || !history.empty(); }
            }
            disconnect();
        }
    }
    void startup(plutonium::sdk::iinterface* api)
    {
        sdk = api;
        report_failure = false;
        failure_reported = false;
        WSADATA data{};
        if (WSAStartup(MAKEWORD(2, 2), &data) != 0) return;
        stopping = false;
        worker = std::thread(run);


        sdk->logging()->info("bridge ready; endpoint 127.0.0.1:16834");
    }

    void set_time(int map, int index, int milliseconds) { enqueue(map, index, milliseconds, false); }
    void split(int map, int index, int milliseconds) { enqueue(map, index, milliseconds, true); }
    void reset(int map)
    {
        if (menu_state::accepts_map(map)) push({map, 0, 0, event::reset});
    }

    void poll_status()
    {
        if (report_failure.exchange(false) && !failure_reported)
        {
            failure_reported = true;
            sdk->logging()->info("Unable to connect to LiveSplit, start LiveSplit TCP server.");
        }
    }

    void shutdown()
    {
        if (!worker.joinable()) return;
        { std::lock_guard lock(mutex); stopping = true; }
        wake.notify_one();
        worker.join();
        WSACleanup();
    }
}
