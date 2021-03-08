module dedit.ProjectWindow;

import std.stdio;
import std.path;
import std.algorithm;
import std.json;

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

    string getPath()
    {
        return controller.getProjectPath(project_name);
    }

    /*
    private void setupBufferView(TreeView tw)
    {
        {
            auto rend = new CellRendererText();
            rend.setProperty("ellipsize", PangoEllipsizeMode.START);
            auto col = new TreeViewColumn("File Name", rend, "text", 0);
            this.fileNameTreeViewColumn = col;
            col.setResizable(true);
            tw.insertColumn(col, 0);
        }

        {
            auto rend = new CellRendererText();
            auto col = new TreeViewColumn("Changed?", rend, "text", 1);
            col.setResizable(true);
            tw.insertColumn(col, 1);
        }
    }*/

    void setProject(string project_name)
    {
        this.project_name = project_name;
        filebrowser.setRootDirectory(getPath());
        // window.setTitle(project_name ~ " :: dedit, The code editor");
        window.setTitle(project_name);
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
        show();
        present();
    }

    void close()
    {
        window.close();
    }

    void saveSettings()
    {
        /*
        if (project_name !in controller.window_settings)
        {
            controller.window_settings[project_name] = new EditorWindowSettings;
        }
        EditorWindowSettings x = controller.window_settings[project_name];

        window.getPosition(x.x, x.y);
        window.getSize(x.width, x.height);
        x.maximized = window.isMaximized();
        x.p1pos = main_paned.getPosition();
        x.p2pos = left_paned.getPosition();
        x.buffer_view_filename_column_width = fileNameTreeViewColumn.getWidth();
        auto y = x.toJSONValue();
        */
        // writeln("save\n", y.toJSON(true));
    }

    void loadSettings()
    {
        /*
        if (project_name !in controller.window_settings)
        {
            return;
        }
        EditorWindowSettings x = controller.window_settings[project_name];

        window.move(x.x, x.y);
        window.resize(x.width, x.height);
        if (x.maximized)
        {
            window.maximize();
        }
        else
        {
            window.unmaximize();
        }
        main_paned.setPosition(x.p1pos);
        left_paned.setPosition(x.p2pos);

        fileNameTreeViewColumn.setFixedWidth(x.buffer_view_filename_column_width);

        //if (project_name in )
        foreach (size_t k, v; x.window_buffers)
        {
            ensureBufferForFile(dutils.path.join([project_path, v]), "");
        }
        refreshBuffersView();
        */
    }

    void saveBufferSettings()
    {
        /*
        if (project_name !in controller.window_settings)
        {
            controller.window_settings[project_name] = new EditorWindowSettings;
        }
        EditorWindowSettings x = controller.window_settings[project_name];

        x.window_buffers = buffers.keys().dup;
        */
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
