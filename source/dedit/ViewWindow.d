module dedit.ViewWindow;

import std.stdio;
import std.path;
import std.algorithm;
import std.json;
import std.uuid;
import std.typecons;

import dlangui;

import dutils.path;
import dutils.dlanguicollection.FileTreeView;

import dedit.ViewWindowMainMenu;
import dedit.Controller;
import dedit.moduleinterface;
import dedit.builtinmodules;

const LABEL_TEXT_FILE_NOT_OPENED = "< file and mode not selected >";

/*
enum ViewModule
{
    PROJECT_FILE,
    PROJECT_URI,

    PROJECTLESS_FILE,
    PROJECTLESS_URI,
} */

enum ViewModuleAutoMode
{
    BY_EXTENSION,
    BY_MIME
}

struct ViewWindowContentSetup
{
    // select module automatically? if not - use view_mode_to_use value
    bool view_module_auto;

    // how to determine module in automatic mode
    ViewModuleAutoMode view_module_auto_mode;

    string view_module_to_use; // module name if automatic mode selection disabled

    // view opened as part of project or not
    // (this helps to rename project directory without closing editor windows)
    // ViewMode view_module;

    // set this, if PROJECT_* mode selected
    string project;

    // set this to file name relative to project directory
    string filename;

    // uri (TODO: not implemented yet)
    /* string uri; */

    ~this()
    {
        writeln("ViewWindowContentSetup destroyed");
    }
}

struct ActionPair
{
    Action action;
    bool delegate(const(Action) a) callback;
}

class ViewWindow
{
    Controller controller;

    private string _project;
    @property string project()
    {
        return _project;
    }

    @property project(string value)
    {
        _project = value;
        projectOrFilenameUpdated();
    }

    private string _filename;
    @property string filename()
    {
        return _filename;
    }

    @property filename(string value)
    {
        _filename = value;
        projectOrFilenameUpdated();
    }

    string window_uuid;

    /* AccelGroup accel_group; */

    Window window;

    ViewWindowMainMenu main_menu;
    MainMenu main_menu_widget;

    VerticalLayout root_box;
    VerticalLayout view_box;

    HorizontalLayout menu_box2;

    TextWidget view_module_project;
    TextWidget view_module_filename;

    CheckBox synchronous_window_rect;

    ModuleController current_module_controller;
    // ModuleDataBuffer    current_module_controller;

    bool keep_settings_on_window_close = false;

    bool close_called;

    bool window_is_active;

    ActionPair[] action_pair_list;
    ActionPair[] action_pair_list_special;

    this(Controller controller, string window_uuid, ViewWindowContentSetup* setup)
    {
        this.controller = controller;
        this.window_uuid = window_uuid;

        if (setup !is null)
        {
            this.project = setup.project;
            this.filename = setup.filename;
        }

        bool apply_setup = this.window_uuid == "" && setup !is null;
        bool load_settings = this.window_uuid != "" && !apply_setup;

        debug
        {
            writeln("apply_setup == ", apply_setup);
            writeln("load_settings == ", load_settings);
        }

        if (this.window_uuid == "")
        {
            this.window_uuid = randomUUID.toString();
        }

        window = Platform.instance.createWindow("dedit", null);
        window.windowStateChanged = &onWindowStateChange;
        window.windowActivityChanged = &onWindowActivityChange;
        window.onClose = &onClose;

        auto view_module_grid = new TableLayout();
        /* view_module_grid.fontSize = 9; */
        view_module_grid.colCount(2);

        synchronous_window_rect = new CheckBox;
        synchronous_window_rect.text = "SPVM"d;
        synchronous_window_rect.tooltipText = "Synchronize Project Views Movements"d;

        view_module_grid.addChild(new TextWidget().text("project:"d).fontSize(9));
        view_module_grid.addChild(view_module_project = new TextWidget());

        view_module_grid.addChild(new TextWidget().text("file:"d).fontSize(9));
        view_module_grid.addChild(view_module_filename = new TextWidget());

        view_module_project.fontSize(9);
        view_module_filename.fontSize(9);

        main_menu = new ViewWindowMainMenu(this);
        main_menu_widget = main_menu.getWidget();
        /* main_menu_widget.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT); */
        action_pair_list = main_menu.getActionPairList();

        menu_box2 = new HorizontalLayout;
        /* menu_box2.layoutWidth(FILL_PARENT); */

        /* menu_box2.addChild(); */

        auto menu_box = new HorizontalLayout;
        menu_box.layoutWidth(FILL_PARENT);

        menu_box.addChild(main_menu_widget);
        menu_box.addChild(menu_box2);
        auto x = new HSpacer;
        x.layoutWidth(FILL_PARENT);
        menu_box.addChild(x);
        menu_box.addChild(synchronous_window_rect);
        menu_box.addChild(view_module_grid);

        root_box = new VerticalLayout;
        root_box.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
        window.mainWidget = root_box;
        window.mainWidget.fontSize = 10;

        root_box.addChild(menu_box);
        root_box.addChild(view_box = new VerticalLayout);
        view_box.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);

        /* root_box.keyToAction = delegate Action(Widget source, uint keyCode, uint flags) {
            return main_menu_widget.findKeyAction(keyCode, flags);
        }; */

        root_box.keyEvent = delegate bool(Widget source, KeyEvent event) {
            return triggerKeyEventBinding(event);
        };

        if (apply_setup)
        {
            auto err = setSetup(setup);
            if (err !is null)
            {
                window.showMessageBox(UIString.fromRaw("Couldn't apply this setup"),
                        UIString.fromRaw(err.msg));
            }
        }

        if (load_settings)
        {
            auto err = loadSettings();
            if (err !is null)
            {
                window.showMessageBox(UIString.fromRaw("Couldn't load settings"),
                        UIString.fromRaw(err.msg));
            }
        }

        /* updateTitle(); */

        controller.view_windows.add(this);
        window.update(true);
    }

    ~this()
    {
        writeln("ViewWindow destroyed");
    }

    bool haveKeyEventBinding(KeyEvent event)
    {
        return findKeyEventBinding(event)[0];
    }

    Tuple!(bool, Action, bool delegate(Action a)) findKeyEventBinding(KeyEvent event)
    {

        Action cb_a;
        bool delegate(Action a) cb;

        foreach (ActionPair ap; action_pair_list)
        {
            if (ap.action.checkAccelerator(event.keyCode, event.flags))
            {
                cb = ap.callback;
                cb_a = ap.action;
                break;
            }
        }

        if (cb is null && action_pair_list_special !is null)
        {
            foreach (ActionPair ap; action_pair_list_special)
            {
                if (ap.action.checkAccelerator(event.keyCode, event.flags))
                {
                    cb = ap.callback;
                    cb_a = ap.action;
                    break;
                }
            }
        }

        if (cb is null)
        {
            return tuple(false, cast(Action) null, cast(bool delegate(Action a)) null);
        }

        return tuple(true, cb_a, cb);
    }

    bool triggerKeyEventBinding(KeyEvent event)
    {
        /* if (source != root_box)
        {
            writeln("source != root_box");
        } */

        if (event.action != KeyAction.KeyUp)
        {
            return true;
        }

        writeln("key ", event.keyCode, " ", event.flags);

        auto res = findKeyEventBinding(event);

        if (res[0] == false)
        {
            return true;
        }

        return res[2](res[1]);
    }

    private void projectOrFilenameUpdated()
    {
        if (window !is null)
        {
            window.windowCaption = to!dstring(filename ~ " (" ~ project ~ ")");
            view_module_project.text = to!dstring(project);
            view_module_filename.text = to!dstring(filename);
        }
    }

    bool onWindowActivityChange(Window win, bool isActive)
    {
        window_is_active = isActive;
        return true;
    }

    bool onWindowStateChange(Window window, WindowState winState, Rect rect)
    {
        if (!window_is_active)
        {
            return true;
        }

        if (!synchronous_window_rect.checked)
        {
            return true;
        }

        controller.view_windows.listItems(delegate bool(ViewWindow win) {
            if (win.window == window || win.project != project
                || !win.synchronous_window_rect.checked)
            {
                return true;
            }

            win.window.moveAndResizeWindow(rect);

            return true;
        });
        return true;
    }

    void onClose()
    {
        if (!close_called)
        {
            close_called = true;

            debug
            {
                writeln("onClose() - View");
            }
            if (!keep_settings_on_window_close)
            {
                debug
                {
                    writeln("removing settings for view window: ", this.window_uuid);
                }
                controller.delViewWindowSettings(this.window_uuid);
            }
            else
            {
                saveSettings();
            }

            if (current_module_controller !is null)
            {
                // TODO: maybe is is better to call unsetSetup()
                current_module_controller.destroy();
                current_module_controller = null;
            }

            controller.view_windows.remove(this);
        }
    }

    Exception loadSettings()
    {
        debug
        {
            writeln("loading settings for view window: ", window_uuid);
        }

        auto set0 = controller.getViewWindowSettings(window_uuid);

        if (set0[1]!is null)
        {
            debug
            {
                writeln("error loading view window settings ", window_uuid);
            }
        }
        else
        {
            auto x = set0[0];
            if (!x.isNull)
            {
                // auto window_uuid = x["window_uuid"].str;

                if ("x" in x && "y" in x && "w" in x && "h" in x)
                {
                    auto rect = Rect();
                    rect.top = cast(int)(x["y"].integer());
                    rect.left = cast(int)(x["x"].integer());
                    rect.bottom = cast(int)(x["h"].integer());
                    rect.right = cast(int)(x["w"].integer());

                    window.moveAndResizeWindow(rect);
                }

                this.project = x["project"].str;
                this.filename = x["filename"].str;

                if ("synchronous_window_rect" in x)
                {
                    synchronous_window_rect.checked = x["synchronous_window_rect"].boolean;
                }

                debug
                {
                    writeln("loading view_setup for window ", window_uuid);
                }
                /* auto y = x["view_setup"]; */

                auto setup_o = new ViewWindowContentSetup;
                setup_o.view_module_auto = false;
                setup_o.project = project;
                setup_o.filename = filename;
                setup_o.view_module_to_use = "view_module_to_use" in x
                    ? x["view_module_to_use"].str() : "";

                auto err = setSetup(setup_o);
                if (err !is null)
                {
                    return err;
                }

                if ("view_setup_settings" in x && current_module_controller !is null)
                {
                    current_module_controller.getView().setSettings(x["view_setup_settings"]);
                }
            }
        }
        return cast(Exception) null;
    }

    Exception saveSettings()
    {
        debug
        {
            writeln("saving settings for view window: ", window_uuid);
        }

        JSONValue val = JSONValue();

        //auto js_setup = cast(JSONValue) getSetup();

        /* auto view_setup = JSONValue(cast(JSONValue[string]) null); */

        /* val["view_setup"] = view_setup; */
        val["window_uuid"] = window_uuid;
        val["project"] = project;
        val["filename"] = filename;
        /* val["view_module_to_use"] = current_module_controller is null ? "" : current_module_controller.getModInfo().name; */

        if (current_module_controller !is null)
        {
            auto info = current_module_controller.getModInfo();
            val["view_module_to_use"] = info.name;
            val["view_setup_settings"] = current_module_controller.getView().getSettings();
        }

        //val["view_module_setup"] = js_setup;

        /* int x, y, w, h; */

        auto rect = window.windowRect;

        val["x"] = JSONValue(rect.left);
        val["y"] = JSONValue(rect.top);
        val["w"] = JSONValue(rect.right);
        val["h"] = JSONValue(rect.bottom);

        val["synchronous_window_rect"] = synchronous_window_rect.checked;

        debug
        {
            writeln("saveSettings() window_uuid", window_uuid);
        }

        auto res = controller.setViewWindowSettings(val);
        if (res !is null)
        {
            writeln("error saving view window settings:", res);
        }

        return cast(Exception) null;
    }

    Window getWindow()
    {
        return window;
    }

    void show()
    {
        window.show();
    }

    void present()
    {
        /* window.present(); */
    }

    void showAndPresent()
    {
        show();
        present();
    }

    void close()
    {
        window.close();
    }

    void unsetSetup()
    {
        // simply calling unsetModuleController(), but maybe something more
        // should be done
        unsetModuleController();
    }

    Exception setSetup(ViewWindowContentSetup* setup)
    {
        debug
        {
            writeln("setSetup for ", window_uuid, " is called");
        }
        // load appropriate ModuleController and feed it to
        // setModuleController() function

        // NOTE: setSetup should not be able to change project. setProject have to be used for this
        /* setup.project = settings.setup.project; */
        // TODO: may be this should be allowed;
        if (project != setup.project)
        {
            return new Exception("provided setup have invalid project name");
        }

        debug
        {
            writeln("requesting FileController. project ", setup.project,
                    "filename ", setup.filename);
        }

        auto mc = controller.createModuleController(setup.project, setup.filename);
        if (mc[1]!is null)
        {
            return mc[1];
        }

        auto module_controller = mc[0];

        module_controller.setViewWindow(this);

        auto res = module_controller.loadData(setup.project, setup.filename);
        if (res !is null)
        {
            window.showMessageBox(UIString.fromRaw("Couldn't load file contents"),
                    UIString.fromRaw(res.msg));
            // NOTE: this should not return with error
        }

        auto smc = setModuleController(module_controller);
        if (smc !is null)
        {
            return smc;
        }

        this.filename = setup.filename;

        return cast(Exception) null;
    }

    void cleanupModuleController()
    {
        if (current_module_controller !is null)
        {
            current_module_controller.destroy();
            current_module_controller = null;
        }
        menu_box2.removeAllChildren();
        action_pair_list_special = [];
        view_box.removeAllChildren();
    }

    void unsetModuleController()
    {
        cleanupModuleController();

        view_box.addChild(new TextWidget().text = to!dstring(LABEL_TEXT_FILE_NOT_OPENED));
    }

    Exception setModuleController(ModuleController mc)
    {
        assert(mc !is null);

        cleanupModuleController();

        /* dedit.moduleinterface.ModuleInformation* moduleinfo; */

        auto view_res = mc.getView();

        auto mm_res = mc.getMainMenu();

        auto view_widget = view_res.getWidget();

        auto mm_widget = mm_res.getWidget();

        view_box.addChild(view_widget);
        /* view_box.packStart(view_widget, true, true, 0); */

        menu_box2.addChild(mm_widget);

        action_pair_list_special = mm_res.getActionPairList();

        this.current_module_controller = mc;

        return null;
    }

    void activateWindow()
    {
        controller.view_windows.listItems(delegate bool(ViewWindow w) {
            w.window_is_active = w == this;
            return true;
        });
        window.activateWindow();
    }
}
