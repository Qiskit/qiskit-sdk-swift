// Copyright 2018 IBM RESEARCH. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// =============================================================================

#if os(Linux)

import CWebkitGtk_Linux

// MARK: - Main body

struct LinuxWebViewFactory {

    // MARK: - Public class methods

    static func makeWebView(html: String) -> VisualizationTypes.View {
        let widget = webkit_web_view_new()!
        enableWebGL(in: widget)
        loadHtml(html, in: widget)

        return widget
    }
}

// MARK: - Private body

private extension LinuxWebViewFactory {

    // MARK: - Constants

    enum Constants {
        static let webviewSettingsEnableWebGL = "enable-webgl"
    }

    // MARK: - Private class methods

    static func enableWebGL(in widget: VisualizationTypes.View) {
        let webview = UnsafeMutablePointer<WebKitWebView>(OpaquePointer(widget))
        let webviewSettings = webkit_web_view_get_settings(webview)
        let objectSettings = UnsafeMutablePointer<GObject>(OpaquePointer(webviewSettings))

        var value = valueTrue()
        g_object_set_property(objectSettings, Constants.webviewSettingsEnableWebGL, &value)
    }

    static func valueTrue() -> GValue {
        var value = GValue()
        let type = GType(5 << G_TYPE_FUNDAMENTAL_SHIFT) // G_TYPE_BOOLEAN
        g_value_init(&value, type)
        g_value_set_boolean (&value, 1) // TRUE

        return value
    }

    static func loadHtml(_ html: String, in widget: VisualizationTypes.View) {
        let webview = UnsafeMutablePointer<WebKitWebView>(OpaquePointer(widget))

        webkit_web_view_load_html_string(webview, html, nil)
    }
}

#endif
