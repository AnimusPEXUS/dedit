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


import gtk.c.types;

import dedit.EditorWindowMainMenu;
import dedit.Buffer;

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

        TreeView files_view;
        ScrolledWindow files_view_sw;

        Buffer[] buffers;

        }

    this()
    {
        window = new Window ("code editor");

        main_menu= new EditorWindowMainMenu(this);

        root_box = new Box(GtkOrientation.VERTICAL, 0);
        window.add(root_box);

        main_paned = new Paned(GtkOrientation.HORIZONTAL);
        left_paned = new Paned(GtkOrientation.VERTICAL);

        left_upper_frame = new Frame(cast(string) null);
        left_lower_frame = new Frame(cast(string) null);
        main_frame = new Frame(cast(string) null);

        main_paned.add1(left_paned);
        main_paned.add2(new Label("todo 2"));

        left_paned.add1(left_upper_frame);
        left_paned.add2(new Label("todo"));

        root_box.packStart(main_menu.getWidget(), false, true, 0);
        root_box.packStart(main_paned, true, true, 0);

        buffers_view = new TreeView();
        setupBufferView(buffers_view);
        /* buffers_view_sw = new ScrolledWindow();
        buffers_view_sw.add(buffers_view); */
        left_upper_frame.add(buffers_view);

    }

    private void setupBufferView(TreeView tw) {
        {
            auto rend = new CellRendererText();
            auto col = new TreeViewColumn("File Base Name",rend, "text",0);
            tw.insertColumn(col,0);
        }

        {
            auto rend = new CellRendererText();
            auto col = new TreeViewColumn("Changed?",rend, "text",0);
            tw.insertColumn(col,1);
        }

    }

    Widget getWidget() {
        return window;
    };

}
