#pragma once
#include <array>
#include <string>

namespace menu_state
{
    struct map_info { const char* id; const char* title; int count; const char* labels[9]; };
    inline constexpr map_info maps[] = {
        {"zm_transit", "Tranzit", 3, {"Jetgun / Power off", "Tower / Turbines", "EMP (Richtofen)"}},
        {"zm_highrise", "Die Rise", 2, {"Symbols", "High Maintenance"}},
        {"zm_prison", "Mob of the Dead", 9, {"Dryer", "Gondola 1", "Flight 1", "Gondola 2", "Flight 2", "Gondola 3", "Flight 3", "Codes", "Headphones"}},
        {"zm_buried", "Buried", 6, {"Boxhit", "Ghosts", "Cipher", "Time Travel", "Sharpshooter", "Mined Games"}},
        {"zm_tomb", "Origins", 9, {"No Man's Land", "Chests Filled", "Staff 1", "Staff 2", "Staff 3", "Staff 4", "Ascend from Darkness", "Rain Fire", "Freedom"}}
    };
    struct preferences
    {
        std::array<unsigned, 5> masks{511,511,511,511,511};
        std::array<unsigned, 5> super_masks{511,511,0,511,0};
        bool super_mode = false;
        int key = 0x78; // Use F9 because Plutonium uses F10
    };
    struct telemetry { int map = -1; int index = -1; };
    int map_index(const char* name);
    bool valid_menu_key(int key);
    bool valid(int map, int index, int milliseconds, bool split);
    bool accepts_map(int map);
    bool enabled(int map, int index);
    preferences get_preferences();
    void set_preferences(const preferences& value);
    void observe(int map, int index);
    telemetry latest();
    void initialize();
    void save_async();
    void shutdown();
    std::string save_status();
}
