@echo off
setlocal
for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "T6EE_VS=%%i"
if not defined T6EE_VS (
    echo Install Visual Studio Build Tools with Desktop development with C++.
    exit /b 1
)
call "%T6EE_VS%\Common7\Tools\VsDevCmd.bat" -arch=x86 -host_arch=x64
if errorlevel 1 exit /b 1
pushd "%~dp0"
if not exist build mkdir build
cd build
cl /nologo /c /O2 /MT /W3 /DNDEBUG /DWIN32 /D_WINDOWS /I../vendor/minhook-1.3.4/include ../vendor/minhook-1.3.4/src/buffer.c ../vendor/minhook-1.3.4/src/hook.c ../vendor/minhook-1.3.4/src/trampoline.c ../vendor/minhook-1.3.4/src/hde/hde32.c
if errorlevel 1 goto failed
cl /nologo /c /std:c++17 /EHsc /O2 /MT /W3 /DNDEBUG /DWIN32 /D_WINDOWS /I../vendor/imgui-1.91.9b ../vendor/imgui-1.91.9b/imgui.cpp ../vendor/imgui-1.91.9b/imgui_draw.cpp ../vendor/imgui-1.91.9b/imgui_tables.cpp ../vendor/imgui-1.91.9b/imgui_widgets.cpp ../vendor/imgui-1.91.9b/backends/imgui_impl_win32.cpp ../vendor/imgui-1.91.9b/backends/imgui_impl_dx11.cpp
if errorlevel 1 goto failed
cl /nologo /c /std:c++17 /EHsc /O2 /MT /W4 /WX /DNDEBUG /DWIN32 /D_WINDOWS /I../vendor/plutonium-sdk /I../vendor/imgui-1.91.9b /I../vendor/minhook-1.3.4/include ../src/dllmain.cpp ../src/livesplit.cpp ../src/menu_state.cpp ../src/overlay.cpp ../src/overlay_panel.cpp
if errorlevel 1 goto failed
rem Keep the tested fixed base; refuse address collisions instead of relocating.
link /nologo /DLL /MACHINE:X86 /DYNAMICBASE:NO /BASE:0x60000000 /FIXED /INCREMENTAL:NO /Brepro /OUT:T6EE_Plugin.dll dllmain.obj livesplit.obj menu_state.obj overlay.obj overlay_panel.obj imgui.obj imgui_draw.obj imgui_tables.obj imgui_widgets.obj imgui_impl_win32.obj imgui_impl_dx11.obj buffer.obj hook.obj trampoline.obj hde32.obj user32.lib gdi32.lib
if errorlevel 1 goto failed
echo Built plugin\build\T6EE_Plugin.dll
popd
exit /b 0
:failed
popd
exit /b 1
