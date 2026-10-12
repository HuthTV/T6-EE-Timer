#pragma once

// Release date, YYYY.MM.DD. Add .1, .2 for further releases on the same day.
// Versioned separately from timer.gsc; GSC checks builtinfunctionexists before every call.
#define T6EE_PLUGIN_VERSION "2026.10.12"

// GSC compatibility level returned by T6EE_Plugin_Api. GSC accepts the plugin only when this equals its PLUGIN_API.
// Bump when the functions GSC calls change; timer and plugin must then be released together.
#define T6EE_PLUGIN_API 1
