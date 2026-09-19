#include "std_include.hpp"
#include "menu_state.hpp"
#include <mutex>
#include <thread>
#include <condition_variable>
#include <filesystem>
#include <cstring>

namespace menu_state
{
    namespace
    {
        std::mutex mutex;
        preferences prefs;
        telemetry current;
        std::wstring path;
        std::string status = "Changes apply to future split events.";
        std::thread saver;
        std::condition_variable wake;
        bool requested = false;
        bool stopping = false;

        void save_worker()
        {
            for (;;)
            {
                preferences copy;
                {
                    std::unique_lock lock(mutex);
                    wake.wait(lock, [] { return requested || stopping; });
                    if (!requested && stopping) return;
                    requested = false;
                    copy = prefs;
                }
                std::error_code error;
                std::filesystem::create_directories(std::filesystem::path(path).parent_path(), error);
                bool ok = !error && WritePrivateProfileStringW(L"menu", L"key", std::to_wstring(copy.key).c_str(), path.c_str());
                ok = WritePrivateProfileStringW(L"menu", L"super_mode", copy.super_mode ? L"1" : L"0", path.c_str()) && ok;
                for (int i = 0; i < 5; ++i)
                {
                    const std::string id = maps[i].id;
                    const std::wstring section(id.begin(), id.end());
                    ok = WritePrivateProfileStringW(section.c_str(), L"enabled_mask", std::to_wstring(copy.masks[i]).c_str(), path.c_str()) && ok;
                    ok = WritePrivateProfileStringW(section.c_str(), L"super_enabled_mask", std::to_wstring(copy.super_masks[i]).c_str(), path.c_str()) && ok;
                }
                std::lock_guard lock(mutex);
                status = ok ? "Saved to T6EE_Plugin.ini beside the DLL." : "Could not save settings; changes remain in memory.";
            }
        }
    }

    int map_index(const char* name)
    {
        if (name) for (int i = 0; i < 5; ++i) if (std::strcmp(name, maps[i].id) == 0) return i;
        return -1;
    }
    bool valid_menu_key(int key)
    {
        return key >= VK_BACK && key <= 0xFE && key != VK_ESCAPE &&
            key != VK_SHIFT && key != VK_CONTROL && key != VK_MENU &&
            key != VK_LSHIFT && key != VK_RSHIFT && key != VK_LCONTROL && key != VK_RCONTROL &&
            key != VK_LMENU && key != VK_RMENU && key != VK_LWIN && key != VK_RWIN;
    }
    bool valid(int map, int index, int milliseconds, bool split)
    {
        return map >= 0 && map < 5 && index >= 0 && milliseconds >= 0 &&
            index < maps[map].count + (split ? 0 : 1);
    }
    bool accepts_map(int map)
    {
        if (map < 0 || map >= 5) return false;
        std::lock_guard lock(mutex);
        return !prefs.super_mode || map == 0 || map == 1 || map == 3;
    }
    bool enabled(int map, int index)
    {
        if (!valid(map, index, 0, true)) return false;
        std::lock_guard lock(mutex);
        if (prefs.super_mode && map != 0 && map != 1 && map != 3) return false;
        if (!prefs.super_mode && map == 3 && index == 5) return false;
        return ((prefs.super_mode ? prefs.super_masks[map] : prefs.masks[map]) & (1u << index)) != 0;
    }
    preferences get_preferences() { std::lock_guard lock(mutex); return prefs; }
    void set_preferences(const preferences& value)
    {
        { std::lock_guard lock(mutex); prefs = value; }
        save_async(); // Save only when the user changes settings
    }
    void observe(int map, int index)
    {
        std::lock_guard lock(mutex);
        current = {map,index};
    }
    telemetry latest() { std::lock_guard lock(mutex); return current; }
    std::string save_status() { std::lock_guard lock(mutex); return status; }
    void initialize()
    {
        if (saver.joinable()) return;
        HMODULE module = nullptr;
        if (!GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
            reinterpret_cast<LPCWSTR>(&initialize), &module)) return;
        wchar_t filename[32768];
        const DWORD length = GetModuleFileNameW(module, filename, 32768);
        if (!length || length >= 32768) return;
        path = (std::filesystem::path(filename).parent_path() / L"T6EE_Plugin.ini").wstring();
        prefs = preferences{};
        requested = false;
        prefs.key = static_cast<int>(GetPrivateProfileIntW(L"menu", L"key", 0x78, path.c_str()));
        if (!valid_menu_key(prefs.key)) prefs.key = VK_F9;
        prefs.super_mode = GetPrivateProfileIntW(L"menu", L"super_mode", 0, path.c_str()) != 0;
        for (int i = 0; i < 5; ++i)
        {
            const std::string id = maps[i].id;
            const std::wstring section(id.begin(), id.end());
            prefs.masks[i] = GetPrivateProfileIntW(section.c_str(), L"enabled_mask", 511, path.c_str()) & 511u;
            prefs.super_masks[i] = GetPrivateProfileIntW(section.c_str(), L"super_enabled_mask", prefs.super_masks[i], path.c_str()) & 511u;
        }
        stopping = false;
        saver = std::thread(save_worker);
    }
    void save_async()
    {
        std::lock_guard lock(mutex);
        if (!saver.joinable()) { status = "Settings storage unavailable."; return; }
        requested = true;
        status = "Saving...";
        wake.notify_one();
    }
    void shutdown()
    {
        { std::lock_guard lock(mutex); stopping = true; }
        wake.notify_one();
        if (saver.joinable()) saver.join();
    }
}
