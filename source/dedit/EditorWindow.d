module dedit.EditorWindow;

import std.stdio;

import gtk.Window;
import gtk.Label;
import gtk.Box;
import gtk.TreeView;
import gtk.Frame;
import gtk.ScrolledWindow;
import gtk.Paned;
import gtk.Widget;
import gtk.CellRendererText;
import gtk.TreeViewColumn;
import gtk.ListStore;
import gtk.TreeIter;

import gtk.c.types;

import dedit.EditorWindowMainMenu;
import dedit.Buffer;

import dutils.gtkcollection.FileTreeView;

class EditorWindow
{

    private {

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

        Buffer[] buffers;

        FileTreeView filebrowser;

        }

    this()
    {
        window = new Window ("Editor Window");

        main_menu= new EditorWindowMainMenu(this);

        root_box = new Box(GtkOrientation.VERTICAL, 0);
        window.add(root_box);

        main_paned = new Paned(GtkOrientation.HORIZONTAL);
        left_paned = new Paned(GtkOrientation.VERTICAL);


        main_paned.add1(left_paned);
        main_paned.add2(new Label("todo 2"));

        root_box.packStart(main_menu.getWidget(), false, true, 0);
        root_box.packStart(main_paned, true, true, 0);

        // buffers
        buffers_view_list_store = new ListStore(cast(GType[])[GType.STRING,GType.STRING]);
        buffers_view = new TreeView();
        buffers_view.setModel(buffers_view_list_store);
        setupBufferView(buffers_view);
        buffers_view_sw = new ScrolledWindow();
        buffers_view_sw.add(buffers_view);

        filebrowser = new FileTreeView();

        left_paned.add1(buffers_view_sw);
        left_paned.add2(filebrowser.getWidget());

        /* {
        auto itr = new TreeIter();
        buffers_view_list_store.append( itr);
        buffers_view_list_store.set(itr, cast(int[]) [0,1], cast(string[]) [ "test1", "test2"]);
    } */



    }

    private void setupBufferView(TreeView tw) {
        {
            auto rend = new CellRendererText();
            auto col = new TreeViewColumn("File Base Name",rend, "text",0);
            col.setResizable(true);
            tw.insertColumn(col,0);
        }

        {
            auto rend = new CellRendererText();
            auto col = new TreeViewColumn("Changed?",rend, "text",1);
            col.setResizable(true);
            tw.insertColumn(col,1);
        }

    }

    Widget getWidget() {
        return window;
    };

}
