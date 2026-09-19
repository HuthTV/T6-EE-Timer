#include "std_include.hpp"

#include <plutonium_sdk.hpp>

#include <cstring>
#include "livesplit.hpp"
#include "menu_state.hpp"
#include "overlay.hpp"

using namespace plutonium::sdk::interfaces;

namespace
{
    plutonium::sdk::iinterface* plutonium_interface = nullptr;

    // Read GSC values from game memory; checked against the installed T6 ZM
    int read_message(char* map, int* index, int* value)
    {
        static const unsigned char get_int_code[] = {
            0x53,0x8B,0x5C,0x24,0x0C,0x56,0x8B,0x74,0x24,0x0C,0x57,0x8B,0xFE,
            0x69,0xFF,0xA8,0x42,0x00,0x00,0x3B,0x9F,0xEC,0xA8,0xDE,0x02,
            0x73,0x4C,0x8B,0x87,0xE0,0xA8,0xDE,0x02,0x8D,0x0C,0xDD,0,0,0,0,
            0x2B,0xC1,0x83,0x38,0x07,0x75,0x07,0x8B,0x40,0x04,0x5F,0x5E,0x5B,0xC3
        };
        __try
        {
            if (std::memcmp(reinterpret_cast<const void*>(0x49A060), get_int_code, sizeof(get_int_code))) return 1;
            if (*reinterpret_cast<const unsigned int*>(0x2DEA8EC) != (map ? (index ? 3u : 1u) : 0u)) return 2;
            if (!map) return 0;
            const auto top = *reinterpret_cast<const int* const*>(0x2DEA8E0);
            if (!top || top[0] != 2 || (index && (top[-2] != 7 || top[-4] != 7))) return 3;
            // text for this GSC string ID
            static const unsigned char string_code[] = {
                0x8B,0x44,0x24,0x04,0x85,0xC0,0x74,0x0E,0x8B,0x0D,0xA4,0x2D,0xBF,0x02,
                0x8D,0x04,0x40,0x8D,0x44,0xC1,0x04,0xC3
            };
            if (std::memcmp(reinterpret_cast<const void*>(0x532230), string_code, sizeof(string_code))) return 1;
            const auto token = static_cast<unsigned>(top[1]);
            if (!token || token > 0xFFFFFFu) return 3;
            const auto table = *reinterpret_cast<const char* const*>(0x2BF2DA4);
            if (!table) return 3;
            const char* name = table + token * 24u + 4;
            int i = 0;
            for (; i < 31 && name[i]; ++i) map[i] = name[i];
            if (name[i]) return 3;
            map[i] = 0;
            if (index) *index = top[-1];
            if (value) *value = top[-3];
            return 0;
        }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            return 1;
        }
    }

    void send_time(bool split)
    {
        int milliseconds = 0;
        char map[32]{};
        int index = -1;
        const int result = read_message(map, &index, &milliseconds);
        const int map_id = menu_state::map_index(map);
        if (result || !menu_state::valid(map_id, index, milliseconds, split))
        {
            plutonium_interface->logging()->info(result == 1
                ? "[T6EE args] refused: T6 ZM binding mismatch or inaccessible VM"
                : "[T6EE args] rejected: expected supported map, zero-based index and nonnegative milliseconds");
            return;
        }
        if (split) livesplit::split(map_id, index, milliseconds);
        else livesplit::set_time(map_id, index, milliseconds);
    }

    void set_game_time() { send_time(false); }
    void split_game_time() { send_time(true); }
    void reset_livesplit()
    {
        char map[32]{};
        if (read_message(map, nullptr, nullptr) == 0 && menu_state::map_index(map) >= 0)
            livesplit::reset(menu_state::map_index(map));
        else plutonium_interface->logging()->info("[T6EE TCP] reset refused: binding mismatch or unexpected arguments");
    }

}

class plugin_impl final : public plutonium::sdk::plugin
{
public:
    const char* plugin_name() override
    {
        return "T6EE Plugin";
    }

    bool is_game_supported(const plutonium::sdk::game game) override
    {
        return game == plutonium::sdk::game::t6;
    }

    void on_startup(plutonium::sdk::iinterface* interface_ptr,
        [[maybe_unused]] const plutonium::sdk::game game) override
    {
        plutonium_interface = interface_ptr;
        menu_state::initialize();
        livesplit::startup(interface_ptr);
        const bool menu_ready = overlay::startup();
        plutonium_interface->logging()->info(menu_ready
            ? "overlay hooks installed; F9 default"
            : "overlay unavailable; timer remains active");
        plutonium_interface->gsc()->register_function("T6EE_Plugin_SetGameTime", set_game_time);
        plutonium_interface->gsc()->register_function("T6EE_Plugin_Split", split_game_time);
        plutonium_interface->gsc()->register_function("T6EE_Plugin_Reset", reset_livesplit);
        plutonium_interface->scheduler()->on_frame(livesplit::poll_status, scheduler::thread::game);
    }

    void on_shutdown() override
    {
        overlay::shutdown();
        livesplit::shutdown();
        menu_state::shutdown();
    }
};

std::unique_ptr<plutonium::sdk::plugin> plugin;

PLUTONIUM_API plutonium::sdk::plugin* on_initialize()
{
    return (plugin = std::make_unique<plugin_impl>()).get();
}

BOOL APIENTRY DllMain(HMODULE, DWORD, LPVOID)
{
    return TRUE;
}
