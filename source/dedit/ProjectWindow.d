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

    string project_name;

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

    this(Controller controller, string project_name)
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

        bookmarks_view_list_store = new ListStore(
                cast(
                GType[])[
                GType.STRING,
                GType.STRING
                ]
        );

        filebrowser = new FileTreeView();
        filebrowser.addOnRowActivated(&onFileListViewActivated);

        setProject(project_name);
        loadSettings();
    }

    bool onDeleteEvent(Event event, Widget w)
    {
        saveSettings();
        return false;
    }

    Tuple!(string, Exception) getPath()
    {
        return controller.getProjectPath(project_name);
    }

    Exception setProject(string project_name)
    {
        this.project_name = project_name;
        auto res = getPath();
        if (res[1] !is null) {
            return res[1];
        }
        filebrowser.setRootDirectory(res[0]);
        window.setTitle(project_name);
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
        controller.setProjectWindowSettings(project_name, settings.toJSONValue());
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
        auto res = controller.getProjectWindowSettings(project_name);
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

    void onFileListViewActivated(TreePath tp, TreeViewColumn tvc, TreeView tv)
    {

        if (filebrowser.isDir(tp))
        {
            filebrowser.loadByTreePath(tp);
            filebrowser.expandByTreePath(tp);
        }
        else
        {
            auto cr = filebrowser.convertTreePathToFilePath(tp);
            openNewViewOrExisting(cr);
        }
    }

    void openNewViewOrExisting(string cr)
    {

        ViewWindowSetup y = {
            view_mode_auto: true,
            view_mode_auto_mode: ViewModeAutoMode.BY_EXTENSION,
            file_mode: ViewWindowMode.PROJECT_FILE,
            project: project_name,
            project_filename: cr
        };

        ViewWindowOptions x = {controller: controller,
        setup: &y};

        ViewWindowOptions* options = &x;

        auto w = new ViewWindow(options);

        w.show();
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
