module dedit.ProjectWindow;

import std.stdio;
import std.path;
import std.algorithm;
import std.json;
import std.typecons;

import dlangui;

import dutils.path;

/* import dedit.ViewWindow; */
import dedit.Controller;

/* import dedit.ToolWindow; */
/* import dedit.moduleinterface; */
/* import dedit.builtinmodules; */

// TODO: ensure window destroyed on close

// const MAIN_VIEW_LABEL_TEXT = "Open file and activate it's buffer";

class ProjectWindow
{
    string project;

    Controller controller;

    Window window;

    this(Controller controller, string project)
    {
        this.controller = controller;

        window = Platform.instance.createWindow("project window", null);

        auto l = new VerticalLayout();
        l.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);

        auto toolbar = new ToolBar();
        l.addChild(toolbar);

        auto a = new Button().text = "New Tool Window"d;
        a.click = delegate bool(Widget b) { writeln("clicked"); return true; };
        toolbar.addControl(a);

        a = new Button().text = "Info"d;
        a.click = delegate bool(Widget b) { writeln("clicked"); return true; };
        toolbar.addControl(a);

        a = new Button().text = "Files"d;
        a.click = delegate bool(Widget b) { writeln("clicked"); return true; };
        toolbar.addControl(a);

        a = new Button().text = "Views"d;
        a.click = delegate bool(Widget b) { writeln("clicked"); return true; };
        toolbar.addControl(a);

        a = new Button().text = "Bookmarks"d;
        a.click = delegate bool(Widget b) { writeln("clicked"); return true; };
        toolbar.addControl(a);

        a = new Button().text = "ToDos"d;
        a.click = delegate bool(Widget b) { writeln("clicked"); return true; };
        toolbar.addControl(a);

        window.mainWidget = l;

        setProject(project);

        controller.project_windows ~= this;

        /* {
            auto res = loadSettings();
            debug
            {
                if (res !is null)
                {
                    writeln("window settings load error:", res);
                }
            }

            debug
            {
                writeln("searching for saved ToolWindow settings");
            }
            foreach (size_t k, JSONValue v; controller.settings["tool_windows_settings"].array())
            {
                if (v["project"].str() == project && "tool_name" in v && "window_uuid" in v)
                {
                    writeln("found settings for tool window: ", v["window_uuid"].str());
                    auto tw = new ToolWindow(controller, v["window_uuid"].str());
                    tw.show();
                    tw.setProject(project);
                }
            }
        } */

    }

    /* bool onDeleteEvent(Event event, Widget w)
    {
        saveSettings();

        foreach (size_t k, ToolWindow v; controller.tool_windows)
        {
            if (v.getProject() == project)
            {
                v.keep_settings_on_window_close = true;
                v.getWindow().close();
            }
        }

        foreach (size_t k, ViewWindow v; controller.view_windows)
        {
            if (v.settings !is null && v.settings.setup && v.settings.setup.project == project)
            {
                v.keep_settings_on_window_close = true;
                v.getWindow().close();
            }
        }

        auto i = controller.project_windows.length - controller.project_windows.find(this).length;
        controller.project_windows = controller.project_windows.remove(i);

        return false;
    } */

    Tuple!(string, Exception) getPath()
    {
        return controller.getProjectPath(project);
    }

    Exception setProject(string project)
    {
        this.project = project;
        auto res = getPath();
        if (res[1]!is null)
        {
            return res[1];
        }
        /* filebrowser.setRootDirectory(res[0]); */
        window.windowCaption = to!dstring(project ~ " :: (project window)");
        return null;
    }

    Window getWindow()
    {
        return window;
    }

    void show()
    {
        window.show();
    }

    void present()
    {
        // TODO: todo
        /* window.present(); */
    }

    void showAndPresent()
    {
        window.show();
        /* window.present(); */
    }

    void close()
    {
        window.close();
    }

    void saveSettings()
    {
        auto settings = getSettings();
        controller.setProjectWindowSettings(project, settings.toJSONValue());
    }

    ProjectWindowSettings getSettings()
    {
        auto ret = new ProjectWindowSettings;
        /* window.getPosition(ret.x, ret.y);
        window.getSize(ret.width, ret.height);
        ret.maximized = window.isMaximized(); */
        return ret;
    }

    Exception loadSettings()
    {
        auto res = controller.getProjectWindowSettings(project);
        if (res[1]!is null)
        {
            return res[1];
        }

        auto settings = new ProjectWindowSettings(res[0]);
        setSettings(settings);
        return null;
    }

    void setSettings(ProjectWindowSettings settings)
    {
        /* window.move(settings.x, settings.y);
        window.resize(settings.width, settings.height);
        if (settings.maximized)
        {
            window.maximize();
        }
        else
        {
            window.unmaximize();
        } */
    }

}

class ProjectWindowSettings
{
    bool maximized;
    bool minimized;
    int x, y;
    int width, height;

    this()
    {
    }

    this(JSONValue v)
    {
        fromJSONValue(v);
    }

    JSONValue toJSONValue()
    {
        JSONValue ret = JSONValue(cast(JSONValue[string]) null);
        ret.object["maximized"] = JSONValue(maximized);
        ret.object["minimized"] = JSONValue(minimized);
        ret.object["x"] = JSONValue(x);
        ret.object["y"] = JSONValue(y);
        ret.object["width"] = JSONValue(width);
        ret.object["height"] = JSONValue(height);

        return ret;
    }

    bool fromJSONValue(JSONValue x)
    {
        if (x.type() != JSONType.object)
        {
            return false;
        }

        if ("maximized" in x.object)
        {
            maximized = x.object["maximized"].boolean;
        }

        if ("minimized" in x.object)
        {
            minimized = x.object["minimized"].boolean;
        }

        if ("x" in x.object)
        {
            this.x = cast(int) x.object["x"].integer;
        }

        if ("y" in x.object)
        {
            y = cast(int) x.object["y"].integer;
        }

        if ("width" in x.object)
        {
            width = cast(int) x.object["width"].integer;
        }

        if ("height" in x.object)
        {
            height = cast(int) x.object["height"].integer;
        }

        return true;
    }
}
