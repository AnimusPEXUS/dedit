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

class EditorWindow
{

    private
    {
        Controller controller;

        string project_name;
        string project_path;

        ModuleDataBuffer[string] buffers;

        ModuleBufferView current_view;
    }

    private
    {
        Window window;

        EditorWindowMainMenu main_menu;

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
    }

    this(Controller controller, string project_name)
    {
        this.controller = controller;

        window = new Window("dedit");
        /* window.setGravity(Gravity.STATIC); */
        /* window.addOnDestroy(&windowOnDestroy); */
        window.addOnDelete(&onDeleteEvent);

        main_menu = new EditorWindowMainMenu(this);

        root_box = new Box(GtkOrientation.VERTICAL, 0);
        window.add(root_box);

        main_paned = new Paned(GtkOrientation.HORIZONTAL);
        left_paned = new Paned(GtkOrientation.VERTICAL);

        main_paned.add1(left_paned);
        main_paned.add2(new Label("Open some file and activate it's buffer"));

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
        buffers_view_sw.add(buffers_view);

        filebrowser = new FileTreeView();
        filebrowser.addOnRowActivated(&onFileListViewActivated);

        left_paned.add1(buffers_view_sw);
        left_paned.add2(filebrowser.getWidget());

        setProject(project_name);
        loadSettings();

        /* {
        auto itr = new TreeIter();
        buffers_view_list_store.append( itr);
        buffers_view_list_store.set(itr, cast(int[]) [0,1], cast(string[]) [ "test1", "test2"]);
    } */

    }

    /* void windowOnDestroy(Widget w)
    {
        /* writeln("EditorWindow destroy"); */ /*
        saveSettings();
        controller.editorWindowIsClosed(project_name);
    } */

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
        writeln("save\n", y.toJSON(true));
    }

    void loadSettings()
    {
        if (project_name !in controller.window_settings)
        {
            return;
        }
        WindowSettings x = controller.window_settings[project_name];

        {
            auto y = x.toJSONValue();
            writeln("load\n", y.toJSON(true));
        }

        window.move(x.x, x.y);
        window.setDefaultSize(x.width, x.height);
        /* window.resize(x.width, x.height); */
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
            writeln("ensureBufferForFile", fp);
            ensureBufferForFile(fp, "");
            refreshBuffersView();
        }

    }

    ModuleDataBuffer ensureBufferForFile(string filename, string module_to_use)
    {
        filename = absolutePath(filename);
        if (filename !in buffers)
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
                string ext = extension(filename);
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
            string uri = "file://" ~ filename;
            auto b = mi.createDataBufferForURI(controller, this, uri);
            buffers[filename] = b;
            writeln("added new buffer");
        }
        return buffers[filename];
    }

    void onBufferViewActivated(TreePath tp, TreeViewColumn tvc, TreeView tv)
    {
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

        writeln("setting up view");

        current_view = b.createView();

        auto w = current_view.getWidget();

        auto c2 = main_paned.getChild2();
        if (c2 !is null)
        {
            c2.destroy();
        }
        main_paned.add2(w);
        w.showAll();

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
                string target = val.getString();
                if (target == k)
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
                string target = val.getString();
                if (target !in buffers)
                {
                    writeln("removing ", target, " from buffer list");
                    ok = buffers_view_list_store.remove(iter);
                }
                else
                {
                    ok = buffers_view_list_store.iterNext(iter);
                }
            }
        }

        writeln("buffers:");
        foreach (k, v; buffers)
        {
            writeln("   ", k);
        }
    }

}
