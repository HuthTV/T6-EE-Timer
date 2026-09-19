#include "std_include.hpp"
#include "overlay.hpp"
#include "menu_state.hpp"
#include "livesplit.hpp"
#include <imgui.h>

namespace overlay
{
    namespace
    {
        bool binding = false;
        bool held[256]{};
    }
    bool capturing_key() { return binding; }
    void cancel_key_capture() { binding = false; }
    void poll_key_capture()
    {
        if (!binding) return;
        for (int key = VK_BACK; key <= 0xFE; ++key)
        {
            const bool down = (GetAsyncKeyState(key) & 0x8000) != 0;
            if (down && !held[key])
            {
                if (key == VK_ESCAPE) { binding = false; return; }
                if (menu_state::valid_menu_key(key))
                {
                    auto prefs = menu_state::get_preferences();
                    prefs.key = key;
                    menu_state::set_preferences(prefs);
                    binding = false;
                    return;
                }
            }
            held[key] = down;
        }
    }
    void draw_panel(bool* open)
    {
        ImGui::SetNextWindowSize(ImVec2(540, 560), ImGuiCond_FirstUseEver);
        ImGui::SetNextWindowPos(ImVec2(35, 35), ImGuiCond_FirstUseEver);
        if (!ImGui::Begin("T6EE | LiveSplit settings", open, ImGuiWindowFlags_NoCollapse))
        { ImGui::End(); return; }
        ImGui::TextWrapped("Make sure T6EE.gsc script is loaded and LiveSplit TCP server is running.");
        ImGui::Separator();
        const auto current = menu_state::latest();
        if (current.map >= 0)
        {
            ImGui::Text("Map: %s", menu_state::maps[current.map].id);
            const auto& map = menu_state::maps[current.map];
            const char* split_name = current.index < map.count ? map.labels[current.index] : "Complete";
            ImGui::Text("Split: %d %s", current.index + 1, split_name);
        }
        else ImGui::TextDisabled("Waiting for map start...");
        ImGui::Spacing();
        static int selected = current.map >= 0 ? current.map : 0;
        auto prefs = menu_state::get_preferences();
        if (ImGui::BeginCombo("Map splits", prefs.super_mode ? "Super Easter Egg" : menu_state::maps[selected].title))
        {
            for (int i = 0; i < 5; ++i)
                if (ImGui::Selectable(menu_state::maps[i].title, !prefs.super_mode && selected == i))
                {
                    selected = i;
                    prefs.super_mode = false;
                    menu_state::set_preferences(prefs);
                }
            if (ImGui::Selectable("Super Easter Egg", prefs.super_mode))
            {
                prefs.super_mode = true;
                menu_state::set_preferences(prefs);
            }
            ImGui::EndCombo();
        }
        ImGui::BeginChild("split_choices", ImVec2(0, 225), ImGuiChildFlags_Borders);
        for (int m = 0; m < 5; ++m)
        {
            if (prefs.super_mode ? (m != 0 && m != 1 && m != 3) : m != selected) continue;
            ImGui::PushID(m);
            const auto& map = menu_state::maps[m];
            if (prefs.super_mode) ImGui::SeparatorText(map.title);
            auto& mask = prefs.super_mode ? prefs.super_masks[m] : prefs.masks[m];
            for (int i = 0; i < map.count; ++i)
            {
                if (!prefs.super_mode && m == 3 && i == 5) continue;
                ImGui::PushID(i);
                bool enabled = (mask & (1u << i)) != 0;
                if (ImGui::Checkbox(map.labels[i], &enabled))
                {
                    if (enabled) mask |= 1u << i;
                    else mask &= ~(1u << i);
                    menu_state::set_preferences(prefs);
                }
                ImGui::PopID();
            }
            ImGui::PopID();
        }
        ImGui::EndChild();
        ImGui::TextWrapped("Match your LiveSplit segments to the enabled choices.");
        char key_name[64]{};
        const UINT scan = MapVirtualKeyW(prefs.key, MAPVK_VK_TO_VSC_EX);
        const LONG key_bits = static_cast<LONG>((scan & 0xFF) << 16 | ((scan & 0xFF00) ? (1u << 24) : 0));
        if (!GetKeyNameTextA(key_bits, key_name, sizeof(key_name)))
            strcpy_s(key_name, "Unknown key");
        ImGui::TextUnformatted("Menu key");
        ImGui::SameLine();
        if (ImGui::Button(binding ? "Press a key... (Esc cancels)###menu_key" : (std::string(key_name) + " - click to change###menu_key").c_str()))
        {
            binding = true;
            for (int key = 0; key < 256; ++key) held[key] = (GetAsyncKeyState(key) & 0x8000) != 0;
        }
        ImGui::TextWrapped("%s", menu_state::save_status().c_str());
        ImGui::End();
    }
}
