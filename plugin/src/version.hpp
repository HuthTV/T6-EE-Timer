#pragma once

// Release date, YYYY.MM.DD. Add .1, .2 for further releases on the same day.
// Versioned separately from timer.gsc; GSC checks builtinfunctionexists before every call.
#define T6EE_PLUGIN_VERSION "2026.10.12"

// GSC compatibility level returned by T6EE_Plugin_Api. GSC accepts the plugin when this is >= its PLUGIN_API.
// Bump only when adding functions GSC relies on. Never change an existing function's arguments.
#define T6EE_PLUGIN_API 1
