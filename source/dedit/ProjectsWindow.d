module dedit.ProjectsWindow;

import gtk.Window;
import gtk.TreeView;
import gtk.CellRendererText;
import gtk.TreeViewColumn;
import gtk.ListStore;
import gtk.ScrolledWindow;
import gtk.Button;
import gtk.ButtonBox;
import gtk.Box;
import gtk.Entry;


import dedit.Controller;

class ProjectsWindow {

    private {
        Window win;
        TreeView tw;
        ListStore tw_ls;

        Controller controller;

    }

    this(Controller controller) {
        this.controller=controller;

        win = new Window("dedit :: project mgr");

        tw_ls = new  ListStore(cast(GType[])[GType.STRING,GType.STRING]);

        tw = new TreeView();
        tw.setModel(tw_ls);
        {
            {
                auto rend = new CellRendererText();
                auto col = new TreeViewColumn("Project Name", rend, "text",0);
                col.setResizable(true);
                tw.appendColumn(col);
            }

            {
                auto rend = new CellRendererText();
                auto col = new TreeViewColumn("Path (Directory)",rend, "text",1);
                col.setResizable(true);
                tw.appendColumn(col);
            }
        }

        auto sw = new ScrolledWindow();
        sw.add(tw);

        auto box = new Box(GtkOrientation.VERTICAL, 0);
        box.packStart(sw, true,true,0);
        box.setSpacing(5);
        win.add(box);

        auto hb = new Box(GtkOrientation.HORIZONTAL, 0);
        box.packStart(hb, false,true,0);
        hb.setSpacing(5);

        auto entry_name = new Entry();
        hb.packStart(entry_name, false, true, 0);

        auto entry_path = new Entry();
        hb.packStart(entry_path, true, true, 0);

        auto btn_delete = new Button("Remove from List");
        hb.packStart(btn_delete, false, true, 0);

        auto btn_add = new Button("Add");
        hb.packStart(btn_add, false, true, 0);

        auto btn_browse = new Button("Browse..");
        hb.packStart(btn_browse, false, true, 0);

        auto bb = new ButtonBox(GtkOrientation.HORIZONTAL);
        box.packStart(bb, false,true,0);



    }

    Window getWindow() {
        return win;
    }

    /* void show() {
        win.showAll();
    } */
}
