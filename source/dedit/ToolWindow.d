module dedit.ToolWindow;

import std.stdio;
import std.uuid;
import std.json;
import std.algorithm;

import dlangui;

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

        window = Platform.instance.createWindow("tool window"d, null);
        /* window.addOnDelete(&onDeleteEvent); */

        tool_widget = new ToolWidget(controller);

        window.mainWidget = tool_widget.getWidget();

        controller.tool_windows ~= this;

        loadSettings();
    }

    bool onDeleteEvent(Event event, Widget w)
    {

        if (!keep_settings_on_window_close)
        {
            debug
            {
                writeln("removing settings for tool window: ", window_uuid);
            }
            controller.delToolWindowSettings(window_uuid);
        }
        else
        {
            saveSettings();
        }
        if (tool_widget !is null)
        {
            tool_widget.destroy();
        }

        auto i = controller.tool_windows.length - controller.tool_windows.find(this).length;
        controller.tool_windows = controller.tool_windows.remove(i);

        return false;
    }

    void setProject(string name)
    {
        tool_widget.setProject(name);
    }

    string getProject()
    {
        return tool_widget.getProject();
    }

    private Exception loadSettings()
    {
        debug
        {
            writeln("loading settings for tool window: ", window_uuid);
        }

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

            if ("x" in x && "y" in x)
            {
                /* window.move(cast(int)(x["x"].integer()), cast(int)(x["y"].integer())); */
            }
            if ("w" in x && "h" in x)
            {
                /* window.resize(cast(int)(x["w"].integer()), cast(int)(x["h"].integer())); */
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
        debug
        {
            writeln("saving settings for tool window: ", window_uuid);
        }

        JSONValue val = JSONValue();
        auto r = tool_widget.getTool();
        if (r[1]!is null)
        {
            return r[1];
        }
        val["window_uuid"] = window_uuid;
        val["tool_name"] = r[0];
        val["project"] = tool_widget.project;

        int x, y, w, h;

        /* window.getPosition(x, y); */
        /* window.getSize(w, h); */

        val["x"] = JSONValue(x);
        val["y"] = JSONValue(y);
        val["w"] = JSONValue(w);
        val["h"] = JSONValue(h);

        debug
        {
            writeln("saveSettings() window_uuid", val["window_uuid"].str());
        }

        auto res = controller.setToolWindowSettings(val);
        if (res !is null)
        {
            writeln("error saving tool window settings:", res);
        }

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
        window.show();
    }

}
