#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);

  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  // Naya: dusre instance se aaye deep link ko Dart tak bhejne ka channel
  deep_link_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "qistx.app/deeplink",
      &flutter::StandardMethodCodec::GetInstance());

  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                                     WPARAM const wparam,
                                     LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    if (message == WM_COPYDATA) {
      PCOPYDATASTRUCT pcds = reinterpret_cast<PCOPYDATASTRUCT>(lparam);
      if (pcds->dwData == 1 && pcds->lpData != nullptr) {
        ShowWindow(hwnd, SW_RESTORE);
        SetForegroundWindow(hwnd);

        // wchar_t command line ko UTF-8 string mein convert karein
        std::wstring wLink(reinterpret_cast<wchar_t*>(pcds->lpData));
        int size = WideCharToMultiByte(CP_UTF8, 0, wLink.c_str(), -1, nullptr, 0, nullptr, nullptr);
        std::string utf8Link(size > 0 ? size - 1 : 0, 0);
        WideCharToMultiByte(CP_UTF8, 0, wLink.c_str(), -1, utf8Link.data(), size, nullptr, nullptr);

        if (deep_link_channel_) {
          deep_link_channel_->InvokeMethod(
              "onDeepLink", std::make_unique<flutter::EncodableValue>(utf8Link));
        }
      }
    }

    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam, lparam);
    if (result) {
      return *result;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}