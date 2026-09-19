#include "std_include.hpp"
#include "overlay.hpp"
#include "menu_state.hpp"
#include <d3d11.h>
#include <dxgi.h>
#include <imgui.h>
#include <backends/imgui_impl_dx11.h>
#include <backends/imgui_impl_win32.h>
#include <MinHook.h>
#include <mutex>
#include <atomic>

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "d3dcompiler.lib")
#pragma comment(lib, "dwmapi.lib")

extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND, UINT, WPARAM, LPARAM);

namespace overlay
{
    namespace
    {
        using present_fn = HRESULT(__stdcall*)(IDXGISwapChain*, UINT, UINT);
        using resize_fn = HRESULT(__stdcall*)(IDXGISwapChain*, UINT, UINT, UINT, DXGI_FORMAT, UINT);
        present_fn original_present = nullptr;
        resize_fn original_resize = nullptr;
        void* present_address = nullptr;
        void* resize_address = nullptr;
        std::recursive_mutex mutex;
        std::atomic<bool> stopping{false};
        std::atomic<bool> input_active{false};
        std::atomic<bool> moving_window{false};
        bool visible = false;
        bool key_down = false;
        bool clip_saved = false;
        RECT previous_clip{};
        HWND window = nullptr;
        WNDPROC previous_proc = nullptr;
        IDXGISwapChain* chain = nullptr;
        ID3D11Device* device = nullptr;
        ID3D11DeviceContext* context = nullptr;
        ID3D11RenderTargetView* target = nullptr;
        ImGuiContext* gui = nullptr;
        float wheel = 0;

        template <class T> void release(T*& value) { if (value) { value->Release(); value = nullptr; } }

        LRESULT CALLBACK window_proc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam)
        {
            if (message == WM_ENTERSIZEMOVE) moving_window = true;
            if (message == WM_EXITSIZEMOVE) moving_window = false;
            const bool client_input = message == WM_INPUT || message == WM_CHAR ||
                (message >= WM_MOUSEFIRST && message <= WM_MOUSELAST) ||
                (message >= WM_KEYFIRST && message <= WM_KEYLAST) ||
                (message == WM_SETCURSOR && LOWORD(lparam) == HTCLIENT);
            // Keep input moving when the menu is closed or the window is dragged.
            if (!client_input || moving_window || !input_active.load(std::memory_order_acquire) || stopping)
                return previous_proc ? CallWindowProcW(previous_proc, hwnd, message, wparam, lparam)
                    : DefWindowProcW(hwnd, message, wparam, lparam);
            WNDPROC next;
            {
                // Skip the menu if it is busy, so the game keeps responding.
                std::unique_lock lock(mutex, std::try_to_lock);
                if (!lock.owns_lock())
                    return previous_proc ? CallWindowProcW(previous_proc, hwnd, message, wparam, lparam)
                        : DefWindowProcW(hwnd, message, wparam, lparam);
                next = previous_proc;
                if (!stopping && gui && visible)
                {
                    ImGuiContext* saved = ImGui::GetCurrentContext();
                    ImGui::SetCurrentContext(gui);
                    // Check the mouse each frame
                    if (message == WM_INPUT)
                    {
                        RAWINPUT raw{};
                        UINT size = sizeof(raw);
                        if (GetRawInputData(reinterpret_cast<HRAWINPUT>(lparam), RID_INPUT, &raw, &size, sizeof(RAWINPUTHEADER)) != static_cast<UINT>(-1) &&
                            raw.header.dwType == RIM_TYPEMOUSE && (raw.data.mouse.usButtonFlags & RI_MOUSE_WHEEL))
                            wheel += static_cast<SHORT>(raw.data.mouse.usButtonData) / static_cast<float>(WHEEL_DELTA);
                    }
                    else if (message == WM_MOUSEWHEEL)
                        wheel += GET_WHEEL_DELTA_WPARAM(wparam) / static_cast<float>(WHEEL_DELTA);
                    else if (!(message >= WM_MOUSEFIRST && message <= WM_MOUSELAST) && message != WM_MOUSELEAVE)
                        ImGui_ImplWin32_WndProcHandler(hwnd, message, wparam, lparam);
                    ImGui::SetCurrentContext(saved);
                    // Let Windows clean up this mouse input
                    if (message == WM_INPUT) return DefWindowProcW(hwnd, message, wparam, lparam);
                    if ((message >= WM_MOUSEFIRST && message <= WM_MOUSELAST) ||
                        (message >= WM_KEYFIRST && message <= WM_KEYLAST) || message == WM_SETCURSOR)
                        return message == WM_SETCURSOR ? TRUE : 0;
                }
            }
            return next ? CallWindowProcW(next, hwnd, message, wparam, lparam) : DefWindowProcW(hwnd, message, wparam, lparam);
        }

        void cleanup()
        {
            input_active.store(false, std::memory_order_release);
            if (window && previous_proc && reinterpret_cast<WNDPROC>(GetWindowLongPtrW(window, GWLP_WNDPROC)) == window_proc)
                SetWindowLongPtrW(window, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(previous_proc));
            if (gui)
            {
                ImGui::SetCurrentContext(gui);
                ImGui_ImplDX11_Shutdown();
                ImGui_ImplWin32_Shutdown();
                ImGui::DestroyContext(gui);
                gui = nullptr;
            }
            release(target); release(context); release(device); release(chain);
            window = nullptr;
            visible = false;
        }

        bool attach(IDXGISwapChain* candidate)
        {
            DXGI_SWAP_CHAIN_DESC desc{};
            if (FAILED(candidate->GetDesc(&desc)) || !IsWindowVisible(desc.OutputWindow)) return false;
            DWORD process = 0;
            GetWindowThreadProcessId(desc.OutputWindow, &process);
            if (process != GetCurrentProcessId()) return false;
            if (FAILED(candidate->GetDevice(__uuidof(ID3D11Device), reinterpret_cast<void**>(&device)))) return false;
            device->GetImmediateContext(&context);
            window = desc.OutputWindow;
            chain = candidate;
            chain->AddRef();
            gui = ImGui::CreateContext();
            ImGui::GetIO().IniFilename = nullptr; // Turn off automatic menu settings files
            ImGui::GetIO().LogFilename = nullptr;
            ImGui::GetIO().ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
            ImGui::StyleColorsDark();
            if (!ImGui_ImplWin32_Init(window)) { ImGui::DestroyContext(gui); gui = nullptr; cleanup(); return false; }
            if (!ImGui_ImplDX11_Init(device, context))
            { ImGui_ImplWin32_Shutdown(); ImGui::DestroyContext(gui); gui = nullptr; cleanup(); return false; }
            SetLastError(0);
            previous_proc = reinterpret_cast<WNDPROC>(GetWindowLongPtrW(window, GWLP_WNDPROC));
            previous_proc = reinterpret_cast<WNDPROC>(SetWindowLongPtrW(window, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(window_proc)));
            if (!previous_proc) { cleanup(); return false; }
            return true;
        }

        void render(IDXGISwapChain* candidate)
        {
            std::lock_guard lock(mutex);
            if (stopping || moving_window) return;
            ImGuiContext* saved = ImGui::GetCurrentContext();
            if (!chain && !attach(candidate)) { ImGui::SetCurrentContext(saved); return; }
            if (candidate != chain) return;
            const bool focused = GetForegroundWindow() == window;
            const bool was_binding = capturing_key();
            if (focused && visible) poll_key_capture();
            const bool pressed = (GetAsyncKeyState(menu_state::get_preferences().key) & 0x8000) != 0;
            if (focused && pressed && !key_down && !was_binding)
            {
                visible = !visible;
                if (visible) clip_saved = GetClipCursor(&previous_clip) != FALSE;
            }
            key_down = pressed;
            if (!focused) visible = false;
            input_active.store(visible, std::memory_order_release);
            if (!visible && !clip_saved)
            {
                ImGui::SetCurrentContext(saved);
                return;
            }
            ImGui::SetCurrentContext(gui);
            if (visible)
            {
                // Free the cursor without pausing the game
                ClipCursor(nullptr);
                if (!target)
                {
                    ID3D11Texture2D* buffer = nullptr;
                    if (SUCCEEDED(chain->GetBuffer(0, __uuidof(ID3D11Texture2D), reinterpret_cast<void**>(&buffer))))
                    { device->CreateRenderTargetView(buffer, nullptr, &target); buffer->Release(); }
                }
                if (target)
                {
                    ImGui_ImplDX11_NewFrame();
                    ImGui_ImplWin32_NewFrame();
                    auto& io = ImGui::GetIO();
                    POINT cursor{};
                    if (GetCursorPos(&cursor) && ScreenToClient(window, &cursor))
                        io.AddMousePosEvent(static_cast<float>(cursor.x), static_cast<float>(cursor.y));
                    const int buttons[] = { VK_LBUTTON, VK_RBUTTON, VK_MBUTTON, VK_XBUTTON1, VK_XBUTTON2 };
                    for (int button = 0; button < 5; ++button)
                        io.AddMouseButtonEvent(button, (GetAsyncKeyState(buttons[button]) & 0x8000) != 0);
                    if (wheel != 0) { io.AddMouseWheelEvent(0, wheel); wheel = 0; }
                    io.MouseDrawCursor = true;
                    ImGui::NewFrame();
                    draw_panel(&visible);
                    input_active.store(visible, std::memory_order_release);
                    ImGui::Render();
                    ID3D11RenderTargetView* old_targets[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT]{};
                    ID3D11DepthStencilView* old_depth = nullptr;
                    context->OMGetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, old_targets, &old_depth);
                    context->OMSetRenderTargets(1, &target, nullptr);
                    ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());
                    context->OMSetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, old_targets, old_depth);
                    for (auto& old : old_targets) release(old);
                    release(old_depth);
                }
            }
            if (!visible && clip_saved)
            {
                cancel_key_capture();
                ImGui::GetIO().ClearInputMouse();
                wheel = 0;
                if (focused) ClipCursor(&previous_clip);
                clip_saved = false;
            }
            ImGui::SetCurrentContext(saved);
        }

        HRESULT __stdcall present(IDXGISwapChain* candidate, UINT interval, UINT flags)
        {
            if (!(flags & DXGI_PRESENT_TEST)) render(candidate);
            return original_present(candidate, interval, flags);
        }

        HRESULT __stdcall resize(IDXGISwapChain* candidate, UINT count, UINT width, UINT height, DXGI_FORMAT format, UINT flags)
        {
            { std::lock_guard lock(mutex); if (candidate == chain) release(target); }
            return original_resize(candidate, count, width, height, format, flags);
        }
    }

    bool startup()
    {
        // Use a temporary graphics device to find the drawing functions.
        const HINSTANCE module = GetModuleHandleW(nullptr);
        WNDCLASSW wc{};
        wc.hInstance = module;
        wc.lpfnWndProc = DefWindowProcW;
        wc.lpszClassName = L"T6EE_DXGI_Probe";
        if (!RegisterClassW(&wc)) return false;
        HWND probe = CreateWindowW(wc.lpszClassName, L"", WS_OVERLAPPED, 0,0,2,2,nullptr,nullptr,module,nullptr);
        if (!probe) { UnregisterClassW(wc.lpszClassName,module); return false; }
        DXGI_SWAP_CHAIN_DESC desc{};
        desc.BufferCount = 1;
        desc.BufferDesc.Width = 2;
        desc.BufferDesc.Height = 2;
        desc.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
        desc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
        desc.OutputWindow = probe;
        desc.SampleDesc.Count = 1;
        desc.Windowed = TRUE;
        IDXGISwapChain* test_chain = nullptr;
        ID3D11Device* test_device = nullptr;
        const HRESULT result = D3D11CreateDeviceAndSwapChain(nullptr,D3D_DRIVER_TYPE_HARDWARE,nullptr,0,nullptr,0,D3D11_SDK_VERSION,
            &desc,&test_chain,&test_device,nullptr,nullptr);
        bool ok = false;
        if (SUCCEEDED(result))
        {
            void** table = *reinterpret_cast<void***>(test_chain);
            present_address = table[8];
            resize_address = table[13];
            if (MH_Initialize() == MH_OK)
            {
                ok = MH_CreateHook(present_address, reinterpret_cast<void*>(present), reinterpret_cast<void**>(&original_present)) == MH_OK &&
                    MH_CreateHook(resize_address, reinterpret_cast<void*>(resize), reinterpret_cast<void**>(&original_resize)) == MH_OK;
                if (ok)
                {
                    MH_QueueEnableHook(present_address);
                    MH_QueueEnableHook(resize_address);
                    ok = MH_ApplyQueued() == MH_OK;
                }
                if (!ok) MH_Uninitialize();
            }
        }
        release(test_chain); release(test_device);
        DestroyWindow(probe);
        UnregisterClassW(wc.lpszClassName,module);
        return ok;
    }

    void shutdown()
    {
        stopping = true;
        if (present_address) MH_DisableHook(present_address);
        if (resize_address) MH_DisableHook(resize_address);
        std::lock_guard lock(mutex);
        cleanup();
        // Keep hooks in memory until exit
    }
}
