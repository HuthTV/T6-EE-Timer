#pragma once
namespace overlay
{
    bool startup();
    void shutdown();
    void draw_panel(bool* open);
    bool capturing_key();
    void poll_key_capture();
    void cancel_key_capture();
}
