module dedit.ProjectsWindow;

import std.stdio;
import std.path;

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
import gtk.Label;
import gtk.FileChooserDialog;


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
        box.setSpacing(5);
        box.setMarginTop(5);
        box.setMarginBottom(5);
        box.setMarginLeft(5);
        box.setMarginRight(5);
        win.add(box);

        box.packStart(
                new Label("Closing this window - will save the state, close all editor windows and exit application"),
false, true, 0
                );

                box.packStart(sw, true,true,0);

        auto hb = new Box(GtkOrientation.HORIZONTAL, 0);
        box.packStart(hb, false,true,0);
        hb.setSpacing(5);

        auto btn_delete = new Button("Remove from List");
        hb.packStart(btn_delete, false, true, 0);

        auto entry_name = new Entry();
        hb.packStart(entry_name, false, true, 0);

        auto entry_path = new Entry();
        hb.packStart(entry_path, true, true, 0);

        auto btn_browse = new Button("Browse..");
        hb.packStart(btn_browse, false, true, 0);
        btn_browse.addOnClicked(&onClickedBrowse);

        auto btn_add = new Button("Add / Set");
        hb.packStart(btn_add, false, true, 0);

        auto btn_open = new Button("Open Editor Window for Project..");
        hb.packStart(btn_open, false, true, 0);

    }

    Window getWindow() {
        return win;
    }

    void onClickedBrowse(Button btn) {
            auto d = new FileChooserDialog(
                "Select Project Directory",
                win,
                FileChooserAction.SELECT_FOLDER,
                ["Confirm", "Cancel"],
                cast(ResponseType[])[ResponseType.OK, ResponseType.CANCEL]
                );

                auto res= d.run();

                if (res == ResponseType.OK) {
                    auto filename = d.getFilename();
                    entry_name.setText(baseName(filename));
                    entry_path.setText(absolutePath(filename));
                }

                d.destroy();
    }

    /* void show() {
        win.showAll();
    } */
}
