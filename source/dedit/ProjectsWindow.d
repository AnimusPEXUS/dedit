module dedit.ProjectsWindow;

import std.stdio;
import std.path;
import std.json;

import dlangui;
import dlangui.dialogs.filedlg;
import dlangui.dialogs.dialog;

import dutils.string;
import dutils.dlanguiutils.StringGridWidgetWithTools;

import dedit.Controller;

/* import dedit.ViewWindow; */

class ProjectsWindow
{

    private
    {
        Window win;
        StringGridWidgetWithTools tv;
        EditLine entry_name;
        EditLine entry_path;
        Button btn_open;

        /* Button btn_open; */

        Controller controller;
    }

    this(Controller controller)
    {
        this.controller = controller;

        win = Platform.instance.createWindow("dedit :: project mgr", null);

        tv = new StringGridWidgetWithTools("GRID1");

        tv.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
        tv.rowSelect = true;
        tv.headerCols = 0;
        tv.fixedCols = 0;
        tv.fixedRows = 0;
        tv.cols = 2;
        tv.rows = 0;
        tv.setColTitle(0, "Project Name");
        tv.setColTitle(1, "Path (Directory)");
        tv.cellSelected = &onCellSelected;
        tv.cellActivated = &onCellActivated;

        auto box = new VerticalLayout();
        box.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
        win.mainWidget = box;

        auto l = new TextWidget("").text("Select or Add and Select Project");

        box.addChild(l);
        box.addChild(tv);

        auto hb = new HorizontalLayout();
        box.addChild(hb);

        auto btn_delete = new Button().text("Remove from List");
        btn_delete.click = &onClickedRemove;
        hb.addChild(btn_delete);

        entry_name = new EditLine("");
        hb.addChild(entry_name);

        entry_path = new EditLine("");
        entry_path.layoutWidth(FILL_PARENT);
        hb.addChild(entry_path);

        auto btn_browse = new Button().text("Browse..");
        btn_browse.click = &onClickedBrowse;
        hb.addChild(btn_browse);

        auto btn_add = new Button().text("Add / Set");
        btn_add.click = &onClickedAdd;
        hb.addChild(btn_add);

        btn_open = cast(Button)(new Button().text("Open Project.."));
        btn_open.click = &onClickedOpen;
        hb.addChild(btn_open);

        /* {
            foreach (string k, string v; controller.project_paths)
            {
                TreeIter ti = new TreeIter();
                tv_ls.append(ti);
                tv_ls.set(ti, [0, 1], [k, v]);
            }
        } */

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
            tv.rows = tv.rows + 1;
            tv.setCellText(0, tv.rows - 1, to!dstring(k));
            tv.setCellText(1, tv.rows - 1, to!dstring(v.str));
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

        /* win.getPosition(x.x, x.y); */
        /* x.width = win.width;
        x.height = win.height;
        /* win.getSize(x.width, x.height); */
        /* x.maximized = win.isMaximized(); */

        return x.toJSONValue();
    }

    void setSettings(JSONValue value)
    {

        auto x = new ProjectsWindowSettings(value);

        /* win.width = x.width;
        win.height = x.height; */

        /* win.move(x.x, x.y);
        win.resize(x.width, x.height);
        if (x.maximized)
        {
            win.maximize();
        }
        else
        {
            win.unmaximize();
        } */

    }

    /* void onWindowDestroy(Widget w)
    {
        writeln("ProjectsWindow destroy");
        controller.saveState();
    } */

    /* bool onDeleteEvent()
    {
        debug
        {
            writeln("ProjectsWindow delete");
        }
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
        else
        {
            writeln("No problems saving settings");
        }

        return false;
    } */

    bool onClickedBrowse(Widget btn)
    {

        auto d = new FileDialog(UIString.fromRaw("Select Project Directory"d), this.win, null, //
                FileDialogFlag.SelectDirectory
                | FileDialogFlag.EnableCreateDirectory | DialogFlag.Resizable);
        d.dialogResult = (delegate(Dialog dlg, const(Action) result) {
            writeln("dialog result received: ", result.id);
            if (result.id == ACTION_OPEN_DIRECTORY.id)
            {
                writeln("action == ACTION_OPEN_DIRECTORY");
                writeln("   filename:", d.filename);
                writeln("   path    :", d.path);

                entry_name.text = to!dstring(d.path.baseName());
                entry_path.text = to!dstring(d.path);
            }
            // d.close();
        });
        d.show();

        return true;
    }

    bool onClickedAdd(Widget btn)
    {
        for (int i = 0; i != tv.rows; i++)
        {
            if (tv.cellText(0, i) == entry_name.text)
            {
                tv.setCellText(1, i, entry_path.text);
                return true;
            }
        }

        auto name = entry_name.text;
        auto path = entry_path.text;

        auto t = tv.rows;
        tv.rows = tv.rows + 1;

        tv.setCellText(0, t, name);
        tv.setCellText(1, t, path);

        controller.project_paths[to!string(name)] = to!string(path);

        // controller.saveState();
        return true;
    }

    bool onClickedRemove(Widget btn)
    {
        // TODO: add checks

        auto n = entry_name.text;

        for (int i = tv.rows - 1; i != -1; i--)
        {
            if (tv.cellText(0, i) == n)
            {
                tv.removeRow(i);
            }
        }

        auto ns = to!string(n);

        if (ns in controller.project_paths)
        {
            controller.project_paths.remove(ns);
        }

        // controller.saveState();
        return true;
    }

    bool onClickedOpen(Widget btn)
    {
        auto name = entry_name.text;

        bool found = false;

        for (int i = 0; i != tv.rows; i++)
        {
            if (tv.cellText(0, i) == name)
            {
                found = true;
                break;
            }
        }

        if (!found)
        {
            // TODO: show message
            return true;
        }

        auto w = controller.createNewOrGetExistingProjectWindow(to!string(name));
        w.showAndPresent();
        return true;
    }

    void onCellSelected(GridWidgetBase source, int col, int row)
    {
        entry_name.text = tv.cellText(0, row);
        entry_path.text = tv.cellText(1, row);
    }

    /* void onSelectionChanged(TreeSelection ts)
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
    }*/

    void onCellActivated(GridWidgetBase source, int col, int row)
    {
        btn_open.click(btn_open);
    }

    /*
    void onRowActivated(TreePath tp, TreeViewColumn tvc, TreeView tv)
    {
        onSelectionChanged(tv.getSelection());
        onClickedOpen(null);
    } */

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
