module dedit.EditorWindow;

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

import gobject.Value;

import gtk.c.types;
import gdk.c.types;
import pango.c.types;

import dutils.path;
import dutils.gtkcollection.FileTreeView;

import dedit.EditorWindowMainMenu;
import dedit.Controller;
import dedit.moduleinterface;
import dedit.builtinmodules;

// TODO: ensure window destroyed on close

const MAIN_VIEW_LABEL_TEXT = "Open file and activate it's buffer";

class EditorWindow
{

    string project_name;
    string project_path;

    Controller controller;

    ModuleDataBuffer[string] buffers;

    ModuleBufferView current_view;
    ModuleDataBuffer current_buffer;
    string current_buffer_filename_rtr; // TODO: maybe it is better to remove this property

    AccelGroup accel_group;

    EditorWindowMainMenu main_menu;

    Window window;

    Box root_box;

    Paned main_paned;
    Paned left_paned;

    Frame left_upper_frame;
    Frame left_lower_frame;

    Frame main_frame;
    Box main_view_box;

    TreeView buffers_view;
    ScrolledWindow buffers_view_sw;
    ListStore buffers_view_list_store;
    TreeViewColumn fileNameTreeViewColumn;

    TreeView files_view;
    ScrolledWindow files_view_sw;

    FileTreeView filebrowser;

    this(Controller controller, string project_name)
    {
        this.controller = controller;

        window = new Window("dedit");
        /* window.setGravity(Gravity.STATIC); */
        /* window.addOnDestroy(&windowOnDestroy); */
        window.addOnDelete(&onDeleteEvent);
        accel_group = new AccelGroup();
        window.addAccelGroup(accel_group);

        main_menu = new EditorWindowMainMenu(this);

        root_box = new Box(GtkOrientation.VERTICAL, 0);
        window.add(root_box);

        main_paned = new Paned(GtkOrientation.HORIZONTAL);
        left_paned = new Paned(GtkOrientation.VERTICAL);

        main_paned.add1(left_paned);
        main_paned.add2(new Label(MAIN_VIEW_LABEL_TEXT));

        root_box.packStart(main_menu.getWidget(), false, true, 0);
        root_box.packStart(main_paned, true, true, 0);

        // buffers
        buffers_view_list_store = new ListStore(
                cast(
                GType[])[
                GType.STRING,
                GType.STRING
                ]
        );
        buffers_view = new TreeView();
        buffers_view.setModel(buffers_view_list_store);
        setupBufferView(buffers_view);
        buffers_view.addOnRowActivated(&onBufferViewActivated);

        buffers_view_sw = new ScrolledWindow();
        buffers_view_sw.setOverlayScrolling(false);
        buffers_view_sw.add(buffers_view);

        filebrowser = new FileTreeView();
        filebrowser.addOnRowActivated(&onFileListViewActivated);

        left_paned.add1(buffers_view_sw);
        left_paned.add2(filebrowser.getWidget());

        setProject(project_name);
        loadSettings();
        unsetMainView();
    }

    bool onDeleteEvent(Event event, Widget w)
    {
        saveSettings();
        controller.editorWindowIsClosed(project_name);
        return false;
    }

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
    }

    void setProject(string project_name)
    {
        this.project_name = project_name;
        project_path = controller.project_paths[project_name];
        filebrowser.setRootDirectory(project_path);
        window.setTitle(project_name ~ " :: dedit, The code editor");
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
        // writeln("save\n", y.toJSON(true));
    }

    void loadSettings()
    {
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
    }

    void saveBufferSettings()
    {
        if (project_name !in controller.window_settings)
        {
            controller.window_settings[project_name] = new EditorWindowSettings;
        }
        EditorWindowSettings x = controller.window_settings[project_name];

        x.window_buffers = buffers.keys().dup;
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
            auto fp = dutils.path.join([project_path, cr]);
            ensureBufferForFile(fp, "");
            refreshBuffersView();
            saveBufferSettings();
        }

    }

    ModuleDataBuffer ensureBufferForFile(string filename, string module_to_use)
    {
        filename = absolutePath(filename);
        string filename_rtr = relativePath(filename, project_path);
        if (filename_rtr !in buffers)
        {
            ModuleInformation mi;
            if (module_to_use != "")
            {
                foreach (i, mii; builtinModules)
                {
                    if (mii.moduleName == module_to_use)
                    {
                        mi = cast(ModuleInformation) mii;
                        break;
                    }
                }
                if (mi is cast(ModuleInformation) null)
                {
                    throw new Exception("module not found");
                }
            }
            else
            {
                string ext = extension(filename_rtr);
                foreach (i, mii; builtinModules)
                {
                    if (mii.supportedExtensions.canFind(ext))
                    {
                        mi = cast(ModuleInformation) mii;
                        break;
                    }
                }
                if (mi is cast(ModuleInformation) null)
                {
                    throw new Exception("extension not supported");
                }
            }
            string uri = "file://" ~ dutils.path.join([
                    project_path, filename_rtr
                    ]);
            auto b = mi.createDataBufferForURI(controller, this, uri);
            buffers[filename_rtr] = b;
            // writeln("added new buffer");
        }

        return buffers[filename_rtr];
    }

    void onBufferViewActivated(TreePath tp, TreeViewColumn tvc, TreeView tv)
    {
        TreeIter itr = new TreeIter;
        auto ok = buffers_view_list_store.getIter(itr, tp);
        if (!ok)
        {
            return;
        }

        string itr_name = buffers_view_list_store.getValue(itr, 0).getString();

        if (itr_name !in buffers)
        {
            return;
        }

        changeActivateBufferView(itr_name);

    }

    void changeActivateBufferView(string name)
    {
        if (name !in buffers)
        {
            return;
        }

        auto b = buffers[name];
        auto new_view = b.createView();

        saveCurrentViewSettings();
        current_buffer_filename_rtr = name;
        setMainView(new_view);
        restoreCurrentViewSettings();
    }

    private void saveCurrentViewSettings()
    {
        if (current_view is null)
        {
            return;
        }

        auto st = current_view.getSettings();
        EditorWindowSettings xx;
        if (project_name !in controller.window_settings)
        {
            controller.window_settings[project_name] = new EditorWindowSettings;
        }

        xx = controller.window_settings[project_name];

        if (xx.window_view_settings.type() != JSONType.object)
        {
            xx.window_view_settings = JSONValue(cast(string[string]) null);
        }

        xx.window_view_settings[current_buffer_filename_rtr] = st;

    }

    private void restoreCurrentViewSettings()
    {
        if (controller is null)
        {
            return;
        }

        if (controller.window_settings is null)
        {
            return;
        }

        if (controller is null)
        {
            return;
        }

        if (project_name !in controller.window_settings)
        {
            return;
        }

        if (controller.window_settings[project_name].window_view_settings.type() != JSONType.object)
        {
            return;
        }

        if (
            current_buffer_filename_rtr !in controller
                .window_settings[project_name].window_view_settings)
        {
            return;
        }

        // restore view config
        auto st = controller.window_settings[project_name]
            .window_view_settings[current_buffer_filename_rtr];
        current_view.setSettings(st);

    }

    private void unsetMainView()
    {

        if (current_view is null)
        {
            return;
        }

        // save view config 

        current_buffer = null;

        auto mm = current_view.getMainMenu();

        mm.uninstallAccelerators();

        main_menu.removeSpecialMenuItem();

        if (current_view !is null)
        {
            current_view.close();
            current_view = null;
        }

        auto c2 = main_paned.getChild2();
        if (c2 !is null)
        {
            c2.destroy();
        }

        auto w = new Label(MAIN_VIEW_LABEL_TEXT);
        main_paned.add2(w);
        w.showAll();
    }

    private void setMainView(ModuleBufferView assumed_new_current_view)
    {

        unsetMainView();

        if (assumed_new_current_view is null)
        {
            return;
        }

        auto assumed_new_current_buffer = assumed_new_current_view.getBuffer();
        assert(assumed_new_current_buffer !is null);

        auto c2 = main_paned.getChild2();
        if (c2 !is null)
        {
            c2.destroy();
        }

        auto w = assumed_new_current_view.getWidget();
        assert(w !is null);

        main_paned.add2(w);
        w.showAll();

        auto module_info = assumed_new_current_view.getModInfo();

        // writeln("module_info name ", module_info.moduleName);

        auto mm = assumed_new_current_view.getMainMenu();

        main_menu.setSpecialMenuItem(module_info.moduleName, mm.getWidget());

        mm.installAccelerators();

        current_buffer = assumed_new_current_buffer;
        current_view = assumed_new_current_view;

    }

    void onMISaveActivate(MenuItem mi)
    {
        current_buffer.save("file://" ~ dutils.path.join([
                    project_path, current_buffer_filename_rtr
                ]));
    }

    void onMICloseActivate(MenuItem mi)
    {
        // auto x = current_buffer;
        // current_buffer.close();
        current_buffer = null;
        buffers.remove(current_buffer_filename_rtr);
        current_view = null;
        refreshBuffersView();

        setMainView(cast(ModuleBufferView) null);
    }

    void refreshBuffersView()
    {
        // add absent in view list
        foreach (string k, ModuleDataBuffer v; buffers)
        {
            bool found = false;

            TreeIter iter = new TreeIter;
            bool ok = buffers_view_list_store.getIterFirst(iter);

            while (ok)
            {
                Value val = buffers_view_list_store.getValue(iter, 0);
                auto filename_rtr = val.getString();
                /* auto filename = dutils.path.join([project_path, filename_rtr]); */
                if (filename_rtr == k)
                {
                    found = true;
                    break;
                }
                ok = buffers_view_list_store.iterNext(iter);
            }

            if (!found)
            {
                // writeln("adding ", k, " to buffer list");
                iter = new TreeIter;
                buffers_view_list_store.append(iter);
                buffers_view_list_store.set(iter, [0], [k]);
            }
        }

        // remove from list actually absent items
        {
            TreeIter iter = new TreeIter;
            bool ok = buffers_view_list_store.getIterFirst(iter);

            while (ok)
            {
                Value val = buffers_view_list_store.getValue(iter, 0);
                string filename_rtr = val.getString();
                if (filename_rtr !in buffers)
                {
                    // writeln("removing ", filename_rtr, " from buffer list");
                    ok = buffers_view_list_store.remove(iter);
                }
                else
                {
                    ok = buffers_view_list_store.iterNext(iter);
                }
            }
        }

        /*writeln("buffers:");
        foreach (k, v; buffers)
        {
            writeln("   ", k);
        }*/
    }

}

class EditorWindowSettings
{
    bool maximized;
    bool minimized;
    int x, y;
    int width, height;
    int p1pos, p2pos;
    // int filename_column_width; // TODO: todo
    int buffer_view_filename_column_width;

    string[] window_buffers;
    JSONValue window_view_settings;

    this()
    {
    }

    this(JSONValue v)
    {
        fromJSONValue(v);
    }

    JSONValue toJSONValue()
    {
        JSONValue ret = JSONValue(cast(string[string]) null);
        ret.object["maximized"] = JSONValue(maximized);
        ret.object["minimized"] = JSONValue(minimized);
        ret.object["x"] = JSONValue(x);
        ret.object["y"] = JSONValue(y);
        ret.object["width"] = JSONValue(width);
        ret.object["height"] = JSONValue(height);
        ret.object["p1pos"] = JSONValue(p1pos);
        ret.object["p2pos"] = JSONValue(p2pos);
        ret.object["buffer_view_filename_column_width"] = JSONValue(
                buffer_view_filename_column_width);
        ret.object["window_buffers"] = JSONValue(window_buffers);

        ret["window_view_settings"] = window_view_settings;

        if (ret["window_view_settings"].type() != JSONType.object)
        {
            ret["window_view_settings"] = JSONValue(cast(string[string]) null);
        }

        return ret;
    }

    bool fromJSONValue(JSONValue x)
    {
        if (x.type != JSONType.object)
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

        if ("p1pos" in x.object)
        {
            p1pos = cast(int) x.object["p1pos"].integer;
        }

        if ("p2pos" in x.object)
        {
            p2pos = cast(int) x.object["p2pos"].integer;
        }

        if ("buffer_view_filename_column_width" in x.object)
        {
            buffer_view_filename_column_width = cast(int) x
                .object["buffer_view_filename_column_width"].integer;
        }

        if ("window_buffers" in x.object)
        {
            // window_buffers.clear;

            window_buffers = window_buffers[];

            foreach (k, v; x.object["window_buffers"].array)
            {
                window_buffers ~= v.str;
            }
            // window_buffers = v.object["window_buffers"].array;

        }

        if ("window_view_settings" in x.object)
        {

            if (x["window_view_settings"].type() != JSONType.object)
            {
                x["window_view_settings"] = JSONValue(cast(string[string]) null);
            }

            window_view_settings = x["window_view_settings"];

        }

        return true;
    }
}
