module dedit.ViewWindow;

import std.stdio;
import std.path;
import std.algorithm;
import std.json;
import std.uuid;

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

class ViewWindow
{
    Controller controller;

    string project;
    string filename;
    string window_uuid;

    /* AccelGroup accel_group; */

    ViewWindowMainMenu main_menu;

    Window window;

    VerticalLayout root_box;
    VerticalLayout view_box;

    TextWidget view_module_project;
    TextWidget view_module_filename;

    ModuleFileController current_module_file_controller;
    // ModuleDataBuffer    current_module_file_controller;

    bool keep_settings_on_window_close = false;

    bool close_called;

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
        window.onClose = &onClose;

        auto view_module_grid = new TableLayout();
        view_module_grid.colCount(2);

        view_module_grid.addChild(new TextWidget().text = "project:"d);
        view_module_grid.addChild(view_module_project = new TextWidget);

        view_module_grid.addChild(new TextWidget().text = "file:"d);
        view_module_grid.addChild(view_module_filename = new TextWidget);

        main_menu = new ViewWindowMainMenu(this);

        auto menu_box = new HorizontalLayout;
        menu_box.layoutWidth(FILL_PARENT);
        menu_box.addChild({
            auto w = main_menu.getWidget();
            w.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
            return w;
        }());
        menu_box.addChild(view_module_grid);

        root_box = new VerticalLayout;
        window.mainWidget = root_box;

        root_box.addChild(menu_box);
        root_box.addChild(view_box = new VerticalLayout);

        if (apply_setup)
        {
            setSetup(setup);
        }

        if (load_settings)
        {
            loadSettings();
        }

        controller.view_windows ~= this;

    }

    ~this()
    {
        writeln("ViewWindow destroyed");
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
            if (current_module_file_controller !is null)
            {
                // TODO: maybe is is better to call unsetSetup()
                current_module_file_controller.destroy();
                current_module_file_controller = null;
            }

            auto i = controller.view_windows.length - controller.view_windows.find(this).length;
            controller.view_windows = controller.view_windows.remove(i);
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

                if ("view_setup" in x && !x["view_setup"].isNull)
                {
                    debug
                    {
                        writeln("loading view_setup for window ", window_uuid);
                    }
                    auto y = x["view_setup"];

                    auto setup_o = new ViewWindowContentSetup;
                    setup_o.view_module_auto = false;
                    setup_o.project = project;
                    setup_o.filename = "filename" in y ? y["filename"].str() : "";
                    setup_o.view_module_to_use = "view_module_to_use" in y
                        ? y["view_module_to_use"].str() : "";

                    setSetup(setup_o);

                    if ("view_setup_settings" in y && current_module_file_controller !is null)
                    {
                        current_module_file_controller.getView()
                            .setSettings(y["view_setup_settings"]);
                    }
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

        auto view_setup = JSONValue(cast(JSONValue[string]) null);

        if (current_module_file_controller !is null)
        {
            auto info = current_module_file_controller.getModInfo();
            view_setup["view_module_to_use"] = info.name;
            view_setup["filename"] = current_module_file_controller.getFileController()
                .settings.filename;
            view_setup["view_setup_settings"] = current_module_file_controller.getView()
                .getSettings();
        }

        val["view_setup"] = view_setup;
        val["window_uuid"] = window_uuid;
        val["project"] = project;

        //val["view_module_setup"] = js_setup;

        /* int x, y, w, h; */

        auto rect = window.windowRect;

        val["x"] = JSONValue(rect.left);
        val["y"] = JSONValue(rect.top);
        val["w"] = JSONValue(rect.right);
        val["h"] = JSONValue(rect.bottom);

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
        // simply calling unsetModuleFileController(), but maybe something more
        // should be done
        unsetModuleFileController();
    }

    Exception setSetup(ViewWindowContentSetup* setup)
    {
        debug
        {
            writeln("setSetup for ", window_uuid, " is called");
        }
        // load appropriate ModuleFileController and feed it to
        // setModuleFileController() function

        // NOTE: setSetup should not be able to change project. setProject have to be used for this
        /* setup.project = settings.setup.project; */
        if (project != setup.project)
        {
            return new Exception("provided setup have invalid project name");
        }

        debug
        {
            writeln("requesting FileController. project ", setup.project,
                    "filename ", setup.filename);
        }

        auto fc = controller.getOrCreateFileController(setup.project, setup.filename, true);
        if (fc[1]!is null)
        {
            return fc[1];
        }

        auto mfc = controller.createModuleFileController(fc[0]);
        if (mfc[1]!is null)
        {
            return mfc[1];
        }

        auto smfc = setModuleFileController(mfc[0]);
        if (smfc !is null)
        {
            return smfc;
        }

        /* this.setup = setup; */

        return cast(Exception) null;
    }

    void cleanupModuleFileController()
    {
        if (current_module_file_controller !is null)
        {
            auto mm = current_module_file_controller.getMainMenu();

            /* mm.uninstallAccelerators(this.accel_group); */

            main_menu.removeSpecialMenuItem();
            current_module_file_controller.destroy();
            current_module_file_controller = null;
        }
        view_box.removeAllChildren();
    }

    void unsetModuleFileController()
    {
        cleanupModuleFileController();

        view_box.addChild(new TextWidget().text = to!dstring(LABEL_TEXT_FILE_NOT_OPENED));
    }

    Exception setModuleFileController(ModuleFileController mfc)
    {
        assert(mfc !is null);

        cleanupModuleFileController();

        /* dedit.moduleinterface.ModuleInformation* moduleinfo; */

        auto view_res = mfc.getView();

        auto mm_res = mfc.getMainMenu();

        auto view_widget = view_res.getWidget();

        auto mm_widget = mm_res.getWidget();

        view_box.addChild(view_widget);
        /* view_box.packStart(view_widget, true, true, 0); */

        this.main_menu.setSpecialMenuItem(mfc.getModInfo().name, mm_widget);

        this.view_module_project.text = to!dstring(mfc.getProject());
        this.view_module_filename.text = to!dstring(mfc.getFilename());

        this.current_module_file_controller = mfc;

        return null;
    }

    void onMIReloadActivate(MenuItem mi)
    {
        if (this.current_module_file_controller !is null)
        {
            auto res = this.current_module_file_controller.loadData();
        }
        return;
    }

    void onMISaveActivate(MenuItem mi)
    {
        if (this.current_module_file_controller !is null)
        {
            auto res = this.current_module_file_controller.saveData();
        }
        return;
    }

    void onMIRenameActivate(MenuItem mi)
    {
        return;
    }

    void onMICloseActivate(MenuItem mi)
    {
        return;
    }

}
