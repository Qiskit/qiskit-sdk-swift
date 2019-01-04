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

import CWebkitGtk_Linux

func window_widget() -> UnsafeMutablePointer<GtkWidget> {
    let widget = gtk_window_new(GTK_WINDOW_TOPLEVEL)!

    let window = UnsafeMutablePointer<GtkWindow>(OpaquePointer(widget))
    let window_width = gint(800)
    let window_height = gint(700)
    gtk_window_set_default_size(window, window_width, window_height)

    return widget
}

func notebook_widget() -> UnsafeMutablePointer<GtkWidget> {
    return gtk_notebook_new()
}

func scrolled_window_widget() -> UnsafeMutablePointer<GtkWidget> {
    return gtk_scrolled_window_new(nil, nil)!
}

func add_widget(_ widget: UnsafeMutablePointer<GtkWidget>, to container: UnsafeMutablePointer<GtkWidget>) {
    let internalContainer = UnsafeMutablePointer<GtkContainer>(OpaquePointer(container))

    gtk_container_add(internalContainer, widget)
}

func label_widget(text: String) -> UnsafeMutablePointer<GtkWidget> {
    return gtk_label_new (text)
}

func insert_page(_ widget: UnsafeMutablePointer<GtkWidget>, in container: UnsafeMutablePointer<GtkWidget>, position: Int, title: String) {
    let notebook = UnsafeMutablePointer<GtkNotebook>(OpaquePointer(container))
    let label = label_widget(text: title)

    let scrolledWindow = scrolled_window_widget()
    add_widget(widget, to: scrolledWindow)

    gtk_notebook_insert_page(notebook, scrolledWindow, label, gint(position))
}
