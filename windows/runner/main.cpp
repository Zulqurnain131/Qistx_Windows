#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include <string>
#include <vector>

// Windows.h ko C++ STL headers ke baad include karna zaroori hai
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

// Windows Registry mein custom scheme (Deep Link) register karne ka helper
void RegisterWindowProtocol(const std::wstring& scheme, const std::wstring& appPath) {
    std::wstring keyPath = L"Software\\Classes\\" + scheme;
    HKEY hKey;
    
    if (RegCreateKeyExW(HKEY_CURRENT_USER, keyPath.c_str(), 0, NULL, REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &hKey, NULL) == ERROR_SUCCESS) {
        std::wstring openCmd = L"\"" + appPath + L"\" \"%1\"";
        HKEY hCmdKey;
        if (RegCreateKeyExW(hKey, L"shell\\open\\command", 0, NULL, REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &hCmdKey, NULL) == ERROR_SUCCESS) {
            DWORD dataSize = static_cast<DWORD>((openCmd.length() + 1) * sizeof(wchar_t));
            RegSetValueExW(hCmdKey, L"", 0, REG_SZ, reinterpret_cast<const BYTE*>(openCmd.c_str()), dataSize);
            RegCloseKey(hCmdKey);
        }
        wchar_t emptyStr[] = L"";
        RegSetValueExW(hKey, L"URL Protocol", 0, REG_SZ, reinterpret_cast<const BYTE*>(emptyStr), sizeof(wchar_t));
        RegCloseKey(hKey);
    }
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  
  // Single Instance Protection
 HWND hwndExisting = FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"qistx_app");

// Sirf handle milna kaafi nahi — check karo ke window abhi bhi valid hai
bool isValidWindow = (hwndExisting != NULL) && IsWindow(hwndExisting);
DWORD_PTR result = 0;   // <-- yahan bahar declare kiya, dono blocks ke liye common

if (isValidWindow) {
    // SendMessageTimeoutW use karo taake agar existing window hang/unresponsive
    // ho to naya process bhi atak (freeze) na jaye
    LRESULT pingResult = SendMessageTimeoutW(
        hwndExisting, WM_NULL, 0, 0,
        SMTO_ABORTIFHUNG | SMTO_BLOCK,
        1000,  // 1 second timeout
        &result
    );

    if (pingResult == 0) {
        // Window responsive nahi hai (hung/zombie) — ise invalid treat karo
        isValidWindow = false;
    }
}

if (isValidWindow) {
    ShowWindow(hwndExisting, SW_SHOWDEFAULT);

    // Agar minimized hai to restore karo
    if (IsIconic(hwndExisting)) {
        ShowWindow(hwndExisting, SW_RESTORE);
    }

    SetForegroundWindow(hwndExisting);

    if (command_line != nullptr && wcslen(command_line) > 0) {
        std::wstring cmdLine(command_line);

        size_t start = cmdLine.find_first_not_of(L" \t");
        size_t end = cmdLine.find_last_not_of(L" \t");
        if (start != std::wstring::npos) {
            cmdLine = cmdLine.substr(start, end - start + 1);
        } else {
            cmdLine.clear();
        }

        if (cmdLine.size() >= 2 && cmdLine.front() == L'"' && cmdLine.back() == L'"') {
            cmdLine = cmdLine.substr(1, cmdLine.size() - 2);
        }

        if (!cmdLine.empty()) {
            COPYDATASTRUCT cds;
            cds.dwData = 1;
            cds.cbData = static_cast<DWORD>((cmdLine.size() + 1) * sizeof(wchar_t));
            cds.lpData = const_cast<wchar_t*>(cmdLine.c_str());

            SendMessageTimeoutW(
                hwndExisting, WM_COPYDATA,
                reinterpret_cast<WPARAM>(hwndExisting),
                reinterpret_cast<LPARAM>(&cds),
                SMTO_ABORTIFHUNG | SMTO_BLOCK,
                1000,
                &result
            );
        }
    }

    return EXIT_SUCCESS;
}

// isValidWindow false hai — code neeche flow ho ga aur naya window create karega

// isValidWindow false hai (koi window nahi mili, ya mili but zombie/hung thi)
// — is case mein code neeche flow ho ga aur naya window create karega

  // Registry mein scheme setup
  wchar_t buffer[MAX_PATH];
  GetModuleFileNameW(NULL, buffer, MAX_PATH);
  std::wstring appPath(buffer);
  RegisterWindowProtocol(L"qistxapp", appPath);

  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");
  std::vector<std::string> command_line_arguments = GetCommandLineArguments();
  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"qistx_app", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);
  window.Show();
  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}