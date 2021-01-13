module dedit.ProjectsWindow;

import std.stdio;
import std.path;

import gtk.Window;
import gtk.TreeModelIF;
import gtk.ListStore;
import gtk.TreeView;
import gtk.TreeViewColumn;
import gtk.TreeIter;
import gtk.TreePath;
import gtk.TreeSelection;
import gtk.CellRendererText;
import gtk.ScrolledWindow;
import gtk.Button;
import gtk.ButtonBox;
import gtk.Box;
import gtk.Entry;
import gtk.Label;
import gtk.FileChooserDialog;

import dedit.Controller;
import dedit.EditorWindow;

class ProjectsWindow
{

    private
    {
        Window win;
        TreeView tv;
        ListStore tv_ls;
        Entry entry_name;
        Entry entry_path;

        /* Button btn_open; */

        Controller controller;

    }

    this(Controller controller)
    {
        this.controller = controller;

        win = new Window("dedit :: project mgr");

        tv_ls = new ListStore(cast(GType[])[GType.STRING, GType.STRING]);

        tv = new TreeView();
        tv.setModel(tv_ls);
        {
            auto sel = tv.getSelection();
            sel.addOnChanged(&onSelectionChanged);
        }
        {
            {
                auto rend = new CellRendererText();
                auto col = new TreeViewColumn("Project Name", rend, "text", 0);
                col.setResizable(true);
                tv.appendColumn(col);
            }

            {
                auto rend = new CellRendererText();
                auto col = new TreeViewColumn("Path (Directory)", rend, "text", 1);
                col.setResizable(true);
                tv.appendColumn(col);
            }
        }
        tv.addOnRowActivated(&onRowActivated);

        auto sw = new ScrolledWindow();
        sw.add(tv);

        auto box = new Box(GtkOrientation.VERTICAL, 0);
        box.setSpacing(5);
        box.setMarginTop(5);
        box.setMarginBottom(5);
        box.setMarginLeft(5);
        box.setMarginRight(5);
        win.add(box);

        box.packStart(new Label(
                "Closing this window - will save the state, close all editor windows and exit application"),
                false, true, 0);

        box.packStart(sw, true, true, 0);

        auto hb = new Box(GtkOrientation.HORIZONTAL, 0);
        box.packStart(hb, false, true, 0);
        hb.setSpacing(5);

        auto btn_delete = new Button("Remove from List");
        hb.packStart(btn_delete, false, true, 0);
        btn_delete.addOnClicked(&onClickedRemove);

        entry_name = new Entry();
        hb.packStart(entry_name, false, true, 0);

        entry_path = new Entry();
        hb.packStart(entry_path, true, true, 0);

        auto btn_browse = new Button("Browse..");
        hb.packStart(btn_browse, false, true, 0);
        btn_browse.addOnClicked(&onClickedBrowse);

        auto btn_add = new Button("Add / Set");
        hb.packStart(btn_add, false, true, 0);
        btn_add.addOnClicked(&onClickedAdd);

        auto btn_open = new Button("Open Editor Window for Project..");
        hb.packStart(btn_open, false, true, 0);
        btn_open.addOnClicked(&onClickedOpen);

        {
            foreach (string k, string v; controller.project_paths)
            {
                TreeIter ti = new TreeIter();
                tv_ls.append(ti);
                tv_ls.set(ti, [0, 1], [k, v]);
            }
        }

    }

    Window getWindow()
    {
        return win;
    }

    void onClickedBrowse(Button btn)
    {
        auto d = new FileChooserDialog("Select Project Directory", win, FileChooserAction.SELECT_FOLDER, [
                "Confirm", "Cancel"
                ], cast(ResponseType[])[ResponseType.OK, ResponseType.CANCEL]);

        auto res = d.run();

        if (res == ResponseType.OK)
        {
            auto filename = d.getFilename();
            entry_name.setText(baseName(filename));
            entry_path.setText(absolutePath(filename));
        }

        d.destroy();
    }

    void onClickedAdd(Button btn)
    {
        // TODO: add checks
        string name = entry_name.getText();
        string path = entry_path.getText();
        auto iter = new TreeIter();
        tv_ls.append(iter);
        tv_ls.set(iter, [0, 1], [name, path]);

        controller.project_paths[name] = path;

        controller.saveState();
    }

    void onClickedRemove(Button btn)
    {
        // TODO: add checks
        string name = entry_name.getText();

        {
            auto m = tv.getModel();
            TreeIter chi;
            bool res = m.iterChildren(chi, null);
            while (res)
            {

                auto v = m.getValue(chi, 0, null);
                if (v.getString() == name)
                {
                    tv_ls.remove(chi);
                    break;
                }
                res = m.iterNext(chi);
            }
        }

        if (name in controller.project_paths)
        {
            controller.project_paths.remove(name);
        }

        controller.saveState();
    }

    void onClickedOpen(Button btn)
    {
        string name = entry_name.getText();
        auto m = tv.getModel();
        bool found = false;

        {
            TreeIter chi;
            bool res = m.iterChildren(chi, null);
            while (res)
            {

                auto v = m.getValue(chi, 0, null);
                if (v.getString() == name)
                {
                    found = true;
                    break;
                }
                res = m.iterNext(chi);
            }
        }
        if (!found)
        {
            // TODO: show message
            return;
        }
        auto w = controller.createNewOrGetExistingEditorWindow(name);
        w.showAndPresent();
    }

    void onSelectionChanged(TreeSelection ts)
    {

        TreeModelIF tm;
        TreeIter ti;
        bool res = ts.getSelected(tm, ti);
        if (res)
        {
            auto tv0 = tm.getValue(ti, 0, null);
            auto tv1 = tm.getValue(ti, 1, null);

            entry_name.setText(tv0.getString());
            entry_path.setText(tv1.getString());
        }
    }

    void onRowActivated(TreePath tp, TreeViewColumn tvc, TreeView tv)
    {
        onSelectionChanged(tv.getSelection());
        onClickedOpen(null);
    }

}
