module dedit.MainWindow;

import gtk.Window;
import gtk.Label;
import gtk.Box;
import gtk.TreeView;
import gtk.Frame;
import gtk.ScrolledWindow;
import gtk.Paned;
import gtk.Widget;


import gtk.c.types;

import dedit.MainWindowMainMenu;

class MainWindow
{

    private {

        Window window;

    MainWindowMainMenu main_menu;

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
}

    this()
    {
        window = new Window ("code editor");

        main_menu= new MainWindowMainMenu(this);

        root_box = new Box(GtkOrientation.VERTICAL, 0);
        window.add(root_box);

        main_paned = new Paned(GtkOrientation.HORIZONTAL);
        secondary_paned = new Paned(GtkOrientation.HORIZONTAL);
        left_paned = new Paned(GtkOrientation.VERTICAL);

        left_upper_frame = new Frame(cast(string) null);
        left_lower_frame = new Frame(cast(string) null);
        main_frame = new Frame(cast(string) null);

        main_paned.add1(left_paned);
        main_paned.add2(secondary_paned);

        secondary_paned.add1(main_frame);

        left_paned.add1(left_upper_frame);
        left_paned.add2(left_lower_frame);

        root_box.packStart(main_paned, true, true, 0);

    }

    Widget getWidget() {
        return window;
    };

}
