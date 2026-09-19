#pragma once
#include <plutonium_sdk.hpp>

namespace livesplit
{
    void startup(plutonium::sdk::iinterface* api);
    void shutdown();
    void set_time(int map, int index, int milliseconds);
    void split(int map, int index, int milliseconds);
    void reset(int map);
    void poll_status();
}
