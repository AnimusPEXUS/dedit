module dedit.ProjectsWindow;

import std.stdio;
import std.path;
import std.json;

import gtk.Window;
import gtk.Widget;
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
import gdk.Event;

import gdk.c.types;

import dedit.Controller;
import dedit.ViewWindow;

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
        /* win.addOnDestroy(&onWindowDestroy); */
        win.addOnDelete(&onDeleteEvent);

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

        auto btn_open = new Button("Project View..");
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

        loadSettings();
    }

    void loadSettings()
    {
        if ("projects_window_settings" in controller.settings)
        {
            setSettings(controller.settings["projects_window_settings"]);
        }

        foreach (string k, JSONValue v; controller.settings["projects"])
        {
            auto iter = new TreeIter;
            tv_ls.append(iter);
            tv_ls.set(iter, [0, 1], [k, v.str()]);
        }
    }

    void saveSettings()
    {
        auto x = getSettings();
        controller.settings["projects_window_settings"] = x;
    }

    Window getWindow()
    {
        return win;
    }

    JSONValue getSettings()
    {
        auto x = new ProjectsWindowSettings();

        win.getPosition(x.x, x.y);
        win.getSize(x.width, x.height);
        x.maximized = win.isMaximized();

        return x.toJSONValue();
    }

    void setSettings(JSONValue value)
    {

        auto x = new ProjectsWindowSettings(value);

        win.move(x.x, x.y);
        win.resize(x.width, x.height);
        if (x.maximized)
        {
            win.maximize();
        }
        else
        {
            win.unmaximize();
        }

    }

    /* void onWindowDestroy(Widget w)
    {
        writeln("ProjectsWindow destroy");
        controller.saveState();
    } */

    bool onDeleteEvent(Event event, Widget w)
    {
        writeln("ProjectsWindow delete");
        foreach (i, c; controller.project_windows)
        {
            c.close();
        }
        controller.projects_window_settings = getSettings();
        auto res = controller.saveSettings();
        if (res !is null)
        {
            writeln("Error while saving settings:", res);
        }

        return false;
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

        // controller.saveState();
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

        // controller.saveState();
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

        auto w = controller.createNewOrGetExistingProjectWindow(name);
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

class ProjectsWindowSettings
{
    bool maximized;
    bool minimized;
    int x, y;
    int width, height;

    this()
    {
    }

    this(JSONValue v)
    {
        fromJSONValue(v);
    }

    JSONValue toJSONValue()
    {
        JSONValue ret = JSONValue(cast(JSONValue[string]) null);
        ret.object["maximized"] = JSONValue(maximized);
        ret.object["minimized"] = JSONValue(minimized);
        ret.object["x"] = JSONValue(x);
        ret.object["y"] = JSONValue(y);
        ret.object["width"] = JSONValue(width);
        ret.object["height"] = JSONValue(height);

        return ret;
    }

    bool fromJSONValue(JSONValue x)
    {
        if (x.type() != JSONType.object)
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

        return true;
    }
}
