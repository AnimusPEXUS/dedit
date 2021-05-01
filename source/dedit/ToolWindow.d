module dedit.ToolWindow;

import std.uuid;
import std.json;

import gtk.Window;
import gtk.Widget;

import gdk.Event;

import dedit.Controller;
import dedit.ToolWidget;

class ToolWindow
{

    Controller controller;
    string window_uuid;

    Window window;

    ToolWidget tool_widget;

    // will delete window settings if window closed by hand and not by closing
    // dedit 'projects mgr window' or project's main window.
    bool keep_settings_on_window_close = false;

    this(Controller controller, string window_uuid)
    {
        this.controller = controller;

        if (window_uuid == "")
        {
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
        if (!keep_settings_on_window_close)
        {

        }
        tool_widget.destroy();
        return false;
    }

    void setProject(string name)
    {
        tool_widget.setProject(name);
    }

    private Exception loadSettings()
    {
        auto set0 = controller.getToolWindowSettings(window_uuid);

        if (!set0[0].isNull())
        {
            auto x = set0[0];
            auto x2 = x["window_uuid"].str();
            {
                UUID x3;
                try
                {
                    x3 = parseUUID(x2);
                }
                catch (Exception)
                {
                    return new Exception("invalid config format");
                }
                x2 = x3.toString();
            }
            if ("tool_name" in x)
            {
                tool_widget.selectTool(x["tool_name"].str());
                if ("tool_settings" in x)
                {
                    // TODO: detect error
                    tool_widget.setSettings(x["tool_settings"]);
                }
            }
        }
        return cast(Exception) null;
    }

    private Exception saveSettings()
    {
        JSONValue val = JSONValue();
        auto r = tool_widget.getTool();
        if (r[1]!is null)
        {
            return r[1];
        }
        val["tool_name"] = r[0];
        return cast(Exception) null;
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
