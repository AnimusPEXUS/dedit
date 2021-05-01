module dedit.ProjectWindow;

import std.stdio;
import std.path;
import std.algorithm;
import std.json;
import std.typecons;

import gtk.Window;
import gtk.Label;
import gtk.Box;
import gtk.TreeView;
import gtk.TreeIter;
import gtk.TreePath;
import gtk.Frame;
import gtk.ScrolledWindow;
import gtk.Paned;
import gtk.Widget;
import gtk.CellRendererText;
import gtk.TreeViewColumn;
import gtk.ListStore;
import gtk.TreeIter;
import gdk.Event;
import gtk.AccelGroup;
import gtk.MenuItem;
import gtk.MessageDialog;
import gtk.Toolbar;
import gtk.ToolButton;
import gtk.SeparatorToolItem;

import gobject.Value;

import gtk.c.types;
import gdk.c.types;
import pango.c.types;

import dutils.path;

import dedit.ViewWindow;
import dedit.Controller;
import dedit.ToolWindow;
import dedit.moduleinterface;
import dedit.builtinmodules;

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

        window = new Window("dedit");
        window.addOnDelete(&onDeleteEvent);

        auto toolbar = new Toolbar();

        auto new_empty_toolwindow_tb = new ToolButton(null, "New Tool Window");
        new_empty_toolwindow_tb.addOnClicked(delegate void(ToolButton tb) {
            auto tw = new ToolWindow(controller, "");
            tw.show();
            tw.setProject(project);
        });

        auto new_projectinfo_toolwindow_tb = new ToolButton(null, "Info");

        auto new_projectfiles_toolwindow_tb = new ToolButton(null, "Files");
        auto new_views_toolwindow_tb = new ToolButton(null, "Views");
        auto new_bookmarks_toolwindow_tb = new ToolButton(null, "Bookmarks");
        auto new_todos_toolwindow_tb = new ToolButton(null, "ToDos");

        toolbar.insert(new_empty_toolwindow_tb);

        toolbar.insert(new SeparatorToolItem);
        toolbar.insert(new_projectinfo_toolwindow_tb);

        toolbar.insert(new SeparatorToolItem);
        toolbar.insert(new_projectfiles_toolwindow_tb);
        toolbar.insert(new_views_toolwindow_tb);
        toolbar.insert(new_bookmarks_toolwindow_tb);
        toolbar.insert(new_todos_toolwindow_tb);

        window.add(toolbar);

        setProject(project);
        {
            auto res = loadSettings();
            debug
            {
                if (res !is null)
                {
                    writeln("window settings load error:", res);
                }
            }
        }

        controller.project_windows ~= this;
    }

    bool onDeleteEvent(Event event, Widget w)
    {
        saveSettings();

        auto i = controller.project_windows.length - controller.project_windows.find(this).length;
        debug
        {
            writeln("this window index", i);
        }
        controller.project_windows = controller.project_windows.remove(i);

        return false;
    }

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
        window.setTitle(project ~ " :: (project window)");
        return null;
    }

    Widget getWidget()
    {
        return window;
    }

    void show()
    {
        window.showAll();
    }

    void present()
    {
        window.present();
    }

    void showAndPresent()
    {
        window.showAll();
        window.present();
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
        window.getPosition(ret.x, ret.y);
        window.getSize(ret.width, ret.height);
        ret.maximized = window.isMaximized();
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
        window.move(settings.x, settings.y);
        window.resize(settings.width, settings.height);
        if (settings.maximized)
        {
            window.maximize();
        }
        else
        {
            window.unmaximize();
        }
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
