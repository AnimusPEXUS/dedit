module dedit.ToolWindow;

import std.uuid;

import gtk.Window;
import gtk.Widget;

import gdk.Event;

import dedit.Controller;
import dedit.ToolWidget;

class ToolWindow
{

    Controller controller;
    string window_uuid

    Window window;

    ToolWidget tool_widget;

    // will delete window settings if window closed by hand and not by closing
    // dedit 'projects mgr window' or project's main window.
    bool keep_settings_on_window_close=false;

    this(Controller controller, string window_uuid)
    {
        this.controller = controller;

        if (window_uuid == "") {
            window_uuid = randomUUID.toString();
        }
        this.window_uuid = window_uuid;

        window = new Window("tool window");
        window.addOnDelete(&onDeleteEvent);

        tool_widget = new ToolWidget(controller);

        window.add(tool_widget.getWidget());
    }

    bool onDeleteEvent(Event event, Widget w)
    {
        if (!keep_settings_on_window_close) {

        }
        tool_widget.destroy();
        return false;
    }


    void setProject(string name)
    {
        tool_widget.setProject(name);
    }

    void destroy()
    {
        window.close();
    }

    Window getWindow()
    {
        return window;
    }

    void show()
    {
        window.showAll();
    }

}
