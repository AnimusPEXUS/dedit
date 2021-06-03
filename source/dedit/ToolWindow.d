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

    bool close_called;

    this(Controller controller, string window_uuid, string project)
    {
        this.controller = controller;

        if (window_uuid == "")
        {
            window_uuid = randomUUID.toString();
        }
        this.window_uuid = window_uuid;

        window = Platform.instance.createWindow("tool window"d, null);
        window.onClose = &onClose;
        /* window.addOnDelete(&onDeleteEvent); */

        tool_widget = new ToolWidget(controller, this);
        tool_widget.setProject(project);

        window.mainWidget = tool_widget.getWidget();
        // window.mainWidget.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);

        controller.tool_windows ~= this;

        loadSettings();
        // window.update(true);
        window.invalidate();
    }

    void onClose()
    {
        if (!close_called)
        {
            close_called = true;

            debug
            {
                writeln("onClose() - Tool");
            }
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

            foreach_reverse (size_t i, ref ToolWindow w; controller.tool_windows)
            {
                if (w == this)
                {
                    controller.tool_windows = controller.tool_windows[0 .. i]
                        ~ controller.tool_windows[i + 1 .. $];
                }
            }

            /* auto i = controller.tool_windows.length - controller.tool_windows.find(this).length;
            controller.tool_windows = controller.tool_windows.remove(i); */
        }
    }

    void setProject(string name)
    {
        tool_widget.setProject(name);
    }

    string getProject()
    {
        return tool_widget.getProject();
    }

    Exception loadSettings()
    {
        debug
        {
            writeln("loading settings for tool window: ", window_uuid);
        }

        auto res = controller.getToolWindowSettings(window_uuid);

        if (!res[0].isNull())
        {
            auto x = res[0];
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

            if ("x" in x && "y" in x && "w" in x && "h" in x)
            {
                auto rect = Rect();
                rect.top = cast(int)(x["y"].integer());
                rect.left = cast(int)(x["x"].integer());
                rect.bottom = cast(int)(x["h"].integer());
                rect.right = cast(int)(x["w"].integer());

                window.moveAndResizeWindow(rect);
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

    Exception saveSettings()
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

        /* int x, y, w, h; */

        auto rect = window.windowRect;

        val["x"] = JSONValue(rect.left);
        val["y"] = JSONValue(rect.top);
        val["w"] = JSONValue(rect.right);
        val["h"] = JSONValue(rect.bottom);

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

    void close()
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
