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
import dedit.Settings;

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
    string current_buffer_filename_rtr;

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
        buffers_view_list_store = new ListStore(cast(GType[])[
                GType.STRING, GType.STRING
                ]);
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

    void saveSettings()
    {
        if (project_name !in controller.window_settings)
        {
            controller.window_settings[project_name] = new WindowSettings;
        }
        WindowSettings x = controller.window_settings[project_name];

        window.getPosition(x.x, x.y);
        window.getSize(x.width, x.height);
        x.maximized = window.isMaximized();
        x.p1pos = main_paned.getPosition();
        x.p2pos = left_paned.getPosition();
        auto y = x.toJSONValue();
        // writeln("save\n", y.toJSON(true));
    }

    void loadSettings()
    {
        if (project_name !in controller.window_settings)
        {
            return;
        }
        WindowSettings x = controller.window_settings[project_name];

        /*{
            auto y = x.toJSONValue();
            writeln("load\n", y.toJSON(true));
        }*/

        window.move(x.x, x.y);
        /* window.setDefaultSize(x.width, x.height);*/
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
            controller.window_settings[project_name] = new WindowSettings;
        }
        WindowSettings x = controller.window_settings[project_name];

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

        if (current_view !is null)
        {
            auto st = current_view.getSettings();
            WindowSettings xx;
            if (project_name !in controller.window_settings)
            {
                controller.window_settings[project_name] = new WindowSettings;
            }
            xx = controller.window_settings[project_name];

            xx.window_buffer_view_settings[current_buffer_filename_rtr] = st;
        }

        if (current_view !is null)
        {
            current_view.close();
        }

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

        auto b = buffers[itr_name];

        current_buffer = b;
        current_buffer_filename_rtr = itr_name;
        current_view = b.createView();

        auto w = current_view.getWidget();

        setMainViewWidget(cast(Widget) w);

        // auto module_info = current_view.getModInfo();

        // writeln("module_info name ", module_info.moduleName);

        // main_menu.menu_special.setLabel(module_info.moduleName);
        // main_menu.menu_special.setSubmenu(current_view.getMainMenu().getWidget());

        // main_paned.checkResize();

        {
            if (project_name in controller.window_settings
                    && current_buffer_filename_rtr in controller
                    .window_settings[project_name].window_buffer_view_settings)
            {
                auto st = controller.window_settings[project_name]
                    .window_buffer_view_settings[current_buffer_filename_rtr];
                current_view.setSettings(st);
            }
        }

    }

    private void setMainViewWidget(Widget w)
    {
        if (w is null)
        {
            w = new Label(MAIN_VIEW_LABEL_TEXT);
        }

        auto c2 = main_paned.getChild2();
        if (c2 !is null)
        {
            c2.destroy();
        }

        main_paned.add2(w);
        w.showAll();

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

        setMainViewWidget(cast(Widget) null);
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
                writeln("adding ", k, " to buffer list");
                TreeIter new_iter = new TreeIter;
                buffers_view_list_store.append(new_iter);
                buffers_view_list_store.set(new_iter, [0], [k]);
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
                    writeln("removing ", filename_rtr, " from buffer list");
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
