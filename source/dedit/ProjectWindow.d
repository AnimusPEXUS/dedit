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

import gobject.Value;

import gtk.c.types;
import gdk.c.types;
import pango.c.types;

import dutils.path;
import dutils.gtkcollection.FileTreeView;

import dedit.ViewWindow;
import dedit.Controller;
import dedit.moduleinterface;
import dedit.builtinmodules;

// TODO: ensure window destroyed on close

// const MAIN_VIEW_LABEL_TEXT = "Open file and activate it's buffer";

class ProjectWindow
{

    string project;

    Controller controller;

    // AccelGroup accel_group;

    // EditorWindowMainMenu main_menu;

    Window window;

    // Box root_box;

    Paned vertical_paned;
    Paned project_info_paned;
    Paned project_bookmarks_paned;
    Paned project_open_views_paned;
    Paned todo_list_paned;
    Paned available_modes_paned;

    TreeView bookmarks_view;
    ScrolledWindow bookmarks_view_sw;
    ListStore bookmarks_view_list_store;

    TreeView openviews_view;
    ScrolledWindow openviews_view_sw;
    ListStore openviews_view_list_store;

    // TreeViewColumn fileNameTreeViewColumn;

    ScrolledWindow files_view_sw;

    FileTreeView filebrowser;

    this(Controller controller, string project)
    {
        this.controller = controller;

        window = new Window("dedit");
        window.addOnDelete(&onDeleteEvent);

        bookmarks_view = new TreeView();
        openviews_view = new TreeView();

        bookmarks_view_sw = new ScrolledWindow();
        openviews_view_sw = new ScrolledWindow();

        bookmarks_view_sw.add(bookmarks_view);
        openviews_view_sw.add(openviews_view);

        vertical_paned = new Paned(GtkOrientation.VERTICAL);
        project_info_paned = new Paned(GtkOrientation.HORIZONTAL);
        project_bookmarks_paned = new Paned(GtkOrientation.HORIZONTAL);
        project_open_views_paned = new Paned(GtkOrientation.HORIZONTAL);
        todo_list_paned = new Paned(GtkOrientation.HORIZONTAL);
        // available_modes_paned= new Paned(GtkOrientation.VERTICAL);

        project_info_paned.add1(new Label("project info"));
        project_bookmarks_paned.add1(bookmarks_view_sw);
        project_open_views_paned.add1(openviews_view_sw);
        todo_list_paned.add1(new Label("todo list"));

        vertical_paned.add1(project_info_paned);

        project_info_paned.add2(project_bookmarks_paned);
        project_bookmarks_paned.add2(project_open_views_paned);
        project_open_views_paned.add2(todo_list_paned);
        todo_list_paned.add2(new Label("modes"));

        window.add(vertical_paned);

        bookmarks_view_list_store = new ListStore(cast(GType[])[
                GType.STRING, GType.STRING
                ]);

        filebrowser = new FileTreeView();
        filebrowser.addOnRowActivated(&onFileListViewActivated);

        auto filebrowser_widget = filebrowser.getWidget();

        vertical_paned.add2(filebrowser_widget);

        vertical_paned.childSetProperty(vertical_paned.getChild1(), "resize", new Value(true));
        vertical_paned.childSetProperty(vertical_paned.getChild2(), "resize", new Value(false));

        project_info_paned.childSetProperty(project_info_paned.getChild1(),
                "resize", new Value(true));
        project_info_paned.childSetProperty(project_info_paned.getChild2(),
                "resize", new Value(true));

        project_bookmarks_paned.childSetProperty(project_bookmarks_paned.getChild1(),
                "resize", new Value(true));
        project_bookmarks_paned.childSetProperty(project_bookmarks_paned.getChild2(),
                "resize", new Value(true));

        project_open_views_paned.childSetProperty(project_open_views_paned.getChild1(),
                "resize", new Value(true));
        project_open_views_paned.childSetProperty(project_open_views_paned.getChild2(),
                "resize", new Value(true));

        todo_list_paned.childSetProperty(todo_list_paned.getChild1(), "resize", new Value(true));
        todo_list_paned.childSetProperty(todo_list_paned.getChild2(), "resize", new Value(true));

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
        filebrowser.setRootDirectory(res[0]);
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
        ret.paned1 = vertical_paned.getPosition();
        ret.paned2 = project_info_paned.getPosition();
        ret.paned3 = project_bookmarks_paned.getPosition();
        ret.paned4 = project_open_views_paned.getPosition();
        ret.paned5 = todo_list_paned.getPosition();
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
        vertical_paned.setPosition(settings.paned1);
        project_info_paned.setPosition(settings.paned2);
        project_bookmarks_paned.setPosition(settings.paned3);
        project_open_views_paned.setPosition(settings.paned4);
        todo_list_paned.setPosition(settings.paned5);
    }

    void onFileListViewActivated(TreePath tp, TreeViewColumn tvc, TreeView tv)
    {

        if (filebrowser.isDir(tp))
        {
            filebrowser.loadByTreePath(tp);
            filebrowser.expandByTreePath(tp);
        }
        else
        {
            auto filename = filebrowser.convertTreePathToFilePath(tp);
            this.controller.openNewView(this.project, filename, "");
        }
    }

}

class ProjectWindowSettings
{
    bool maximized;
    bool minimized;
    int x, y;
    int width, height;

    int paned1, paned2, paned3, paned4, paned5;

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

        ret.object["paned1"] = JSONValue(paned1);
        ret.object["paned2"] = JSONValue(paned2);
        ret.object["paned3"] = JSONValue(paned3);
        ret.object["paned4"] = JSONValue(paned4);
        ret.object["paned5"] = JSONValue(paned5);

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

        if ("paned1" in x.object)
        {
            paned1 = cast(int) x.object["paned1"].integer;
        }

        if ("paned2" in x.object)
        {
            paned2 = cast(int) x.object["paned2"].integer;
        }

        if ("paned3" in x.object)
        {
            paned3 = cast(int) x.object["paned3"].integer;
        }

        if ("paned4" in x.object)
        {
            paned4 = cast(int) x.object["paned4"].integer;
        }

        if ("paned5" in x.object)
        {
            paned5 = cast(int) x.object["paned5"].integer;
        }

        return true;
    }
}
