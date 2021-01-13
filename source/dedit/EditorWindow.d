module dedit.EditorWindow;

import std.stdio;
import std.path;

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

import gobject.Value;

import gtk.c.types;

import dutils.path;
import dutils.gtkcollection.FileTreeView;

import dedit.EditorWindowMainMenu;
import dedit.Controller;
import dedit.moduleinterface;
import dedit.builtinmodules;

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
        Paned secondary_paned;
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
        window.addOnDestroy(&windowOnDestroy);

        main_menu = new EditorWindowMainMenu(this);

        root_box = new Box(GtkOrientation.VERTICAL, 0);
        window.add(root_box);

        main_paned = new Paned(GtkOrientation.HORIZONTAL);
        left_paned = new Paned(GtkOrientation.VERTICAL);

        main_paned.add1(left_paned);
        main_paned.add2(new Label("todo 2"));

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

        /* {
        auto itr = new TreeIter();
        buffers_view_list_store.append( itr);
        buffers_view_list_store.set(itr, cast(int[]) [0,1], cast(string[]) [ "test1", "test2"]);
    } */

    }

    void windowOnDestroy(Widget w)
    {
        controller.editorWindowIsClosed(project_name);
    }

    private void setupBufferView(TreeView tw)
    {
        {
            auto rend = new CellRendererText();
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
        window.setTitle(project_name ~ " :: dedit");
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

    void onFileListViewActivated(TreePath tp, TreeViewColumn tvc, TreeView tv)
    {

        if (filebrowser.isDir(tp))
        {
            filebrowser.expandByTreePath(tp);
        }
        else
        {
            auto fp = dutils.path.join([
                    project_path, filebrowser.convertTreePathToFilePath(tp)
                    ]);
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
                    throw new Exception("nodule not found");
                }
            }
            auto b = mi.createDataBufferForURI(controller, this, "file://" ~ filename);
            buffers[filename] = b;
        }
        return buffers[filename];
    }

    void onBufferViewActivated(TreePath tp, TreeViewColumn tvc, TreeView tv)
    {
        if (current_view !is null)
        {
            current_view.close();
        }
    }

    void refreshBuffersView()
    {
        // add absent in view list
        foreach (string k, ModuleDataBuffer v; buffers)
        {
            bool found = false;

            TreeIter iter;
            bool ok = buffers_view_list_store.getIterFirst(iter);

            while (ok)
            {
                Value val = buffers_view_list_store.getValue(iter, 0);
                if (dutils.path.join(cast(string[])[
                            project_path, val.getString()
                        ]) == k)
                {
                    found = true;
                    break;
                }
                ok = buffers_view_list_store.iterNext(iter);
            }

            if (!found)
            {
                TreeIter new_iter = new TreeIter;
                buffers_view_list_store.append(new_iter);
                buffers_view_list_store.set(new_iter, [0], [k]);
            }
        }

        // remove from list actually absent items
        {
            TreeIter iter;
            bool ok = buffers_view_list_store.getIterFirst(iter);

            while (ok)
            {
                Value val = buffers_view_list_store.getValue(iter, 0);
                if (dutils.path.join(cast(string[])[
                            project_path, val.getString()
                        ]) !in buffers)
                {
                    ok = buffers_view_list_store.remove(iter);
                }
                else
                {
                    ok = buffers_view_list_store.iterNext(iter);
                }
            }
        }
    }

}
