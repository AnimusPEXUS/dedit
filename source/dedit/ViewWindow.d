module dedit.ViewWindow;

import std.stdio;
import std.path;
import std.algorithm;
import std.json;
import std.uuid;



import dutils.path;
import dutils.gtkcollection.FileTreeView;

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

struct ViewWindowSettings
{
    Controller controller;
    string window_uuid;
    ViewWindowContentSetup* setup;

    ~this()
    {
        writeln("ViewWindowSettings destroyed");
    }
}

class ViewWindow
{

    ViewWindowSettings* settings;

    AccelGroup accel_group;

    ViewWindowMainMenu main_menu;

    Window window;

    Box root_box;
    Box view_box;

    Label view_module_project;
    Label view_module_filename;

    ModuleFileController current_module_file_controller;
    // ModuleDataBuffer    current_module_file_controller;

    bool keep_settings_on_window_close = false;

    this(ViewWindowSettings* settings)
    {
        this.settings = settings;

        bool apply_setup = settings.window_uuid == "" && settings.setup !is null;
        debug
        {
            writeln("apply_setup == ", apply_setup);
        }

        if (settings.window_uuid == "")
        {
            settings.window_uuid = randomUUID.toString();
        }

        window = new Window("dedit");
        /* window.setGravity(Gravity.STATIC); */
        /* window.addOnDestroy(&windowOnDestroy); */
        window.addOnDelete(&onDeleteEvent);

        accel_group = new AccelGroup();

        window.addAccelGroup(accel_group);

        main_menu = new ViewWindowMainMenu(this);

        root_box = new Box(GtkOrientation.VERTICAL, 0);
        window.add(root_box);

        view_box = new Box(GtkOrientation.VERTICAL, 0);

        auto menu_box = new Box(GtkOrientation.HORIZONTAL, 0);

        view_module_project = new Label("project");
        view_module_filename = new Label("filename");
        /* auto view_module_data_load = new Button("Load Data"); */
        /* auto view_module_data_save = new Button("Save Data"); */
        /* auto view_module_change_name = new Button("Change Name.."); */
        /* auto view_module_apply = new Button("Apply"); */

        auto view_module_grid = new Grid();
        view_module_grid.attach(new Label("project:"), 0, 0, 1, 1);
        view_module_grid.attach(view_module_project, 1, 0, 1, 1);
        view_module_grid.attach(new Label("file:"), 0, 1, 1, 1);
        view_module_grid.attach(view_module_filename, 1, 1, 1, 1);

        menu_box.packStart(main_menu.getWidget(), true, true, 0);
        menu_box.packStart(view_module_grid, false, true, 0);

        root_box.packStart(menu_box, false, true, 0);
        root_box.packStart(view_box, true, true, 0);

        if (apply_setup)
        {
            this.setSetup(settings.setup);
        }

        settings.controller.view_windows ~= this;

        loadSettings();
    }

    ~this()
    {
        writeln("ViewWindow destroyed");
    }

    bool onDeleteEvent(Event event, Widget w)
    {
        if (!keep_settings_on_window_close)
        {
            debug
            {
                writeln("removing settings for view window: ", settings.window_uuid);
            }
            settings.controller.delViewWindowSettings(settings.window_uuid);
        }
        else
        {
            saveSettings();
        }
        if (current_module_file_controller !is null)
        {
            // TODO: maybe is is better to call unsetSetup()
            current_module_file_controller.close();
            current_module_file_controller = null;
        }

        auto i = settings.controller.view_windows.length - settings.controller.view_windows.find(this)
            .length;
        settings.controller.view_windows = settings.controller.view_windows.remove(i);

        return false;
    }

    private Exception loadSettings()
    {
        debug
        {
            writeln("loading settings for view window: ", settings.window_uuid);
        }

        auto set0 = settings.controller.getViewWindowSettings(settings.window_uuid);

        if (set0[1]!is null)
        {
            debug
            {
                writeln("error loading view window settings ", settings.window_uuid);
            }
        }
        else
        {
            auto x = set0[0];
            if (!x.isNull)
            {
                auto window_uuid = x["window_uuid"].str;
                /*{
                    UUID x3;
                    try
                    {
                        x3 = parseUUID(window_uuid);
                    }
                    catch (Exception)
                    {
                        return new Exception("invalid config format");
                    }
                    window_uuid = x3.toString();
                } */

                if ("x" in x && "y" in x)
                {
                    window.move(cast(int)(x["x"].integer()), cast(int)(x["y"].integer()));
                }
                if ("w" in x && "h" in x)
                {
                    window.resize(cast(int)(x["w"].integer()), cast(int)(x["h"].integer()));
                }

                if ("view_setup" in x && !x["view_setup"].isNull)
                {
                    debug
                    {
                        writeln("loading view_setup for window ", window_uuid);
                    }
                    auto y = x["view_setup"];
                    ViewWindowContentSetup setup_o = {
                        view_module_auto: false, project: settings.setup.project, filename: "filename" in y
                            ? y["filename"].str() : "", view_module_to_use: "view_module_to_use" in y ? y["view_module_to_use"]
                            .str() : "",
                    };
                    setSetup(&setup_o);

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

    private Exception saveSettings()
    {
        debug
        {
            writeln("saving settings for view window: ", settings.window_uuid);
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
        val["window_uuid"] = settings.window_uuid;
        val["project"] = settings.setup !is null ? settings.setup.project : "";

        //val["view_module_setup"] = js_setup;

        int x, y, w, h;

        window.getPosition(x, y);
        window.getSize(w, h);

        val["x"] = JSONValue(x);
        val["y"] = JSONValue(y);
        val["w"] = JSONValue(w);
        val["h"] = JSONValue(h);

        debug
        {
            writeln("saveSettings() window_uuid", val["window_uuid"].str());
        }

        auto res = settings.controller.setViewWindowSettings(val);
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
        window.showAll();
    }

    void present()
    {
        window.present();
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

    /* Exception setSetup(JSONValue setup)
    {
        auto setup_o = new ViewWindowContentSetup{
            // NOTE: setSetup should not be able to change project. setProject have to be used for this
            // project:  this.setup.project,
            filename: "filename" in setup ? setup["filename"].str() : "",
            view_module_to_use: "view_module_to_use" in setup ? setup["view_module_to_use"].str() : "",
        };


    } */

    Exception setSetup(ViewWindowContentSetup* setup)
    {
        debug
        {
            writeln("setSetup for ", settings.window_uuid, " is called");
        }
        // load appropriate ModuleFileController and feed it to
        // setModuleFileController() function

        // NOTE: setSetup should not be able to change project. setProject have to be used for this
        setup.project = settings.setup.project;

        debug
        {
            writeln("requesting FileController. project ", setup.project,
                    "filename ", setup.filename);
        }

        auto fc = this.settings.controller.getOrCreateFileController(setup.project,
                setup.filename, true);
        if (fc[1]!is null)
        {
            return fc[1];
        }

        auto mfc = this.settings.controller.createModuleFileController(fc[0]);
        if (mfc[1]!is null)
        {
            return mfc[1];
        }

        auto smfc = this.setModuleFileController(mfc[0]);
        if (smfc !is null)
        {
            return smfc;
        }

        /* this.setup = setup; */

        return cast(Exception) null;
    }

    ViewWindowContentSetup* getSetup()
    {
        return settings.setup;
    }

    void unsetModuleFileController()
    {

        if (current_module_file_controller is null)
        {
            return;
        }

        // save view config

        // current_module_file_controller = null;

        if (current_module_file_controller !is null)
        {
            auto mm = current_module_file_controller.getMainMenu();

            mm.uninstallAccelerators(this.accel_group);

            main_menu.removeSpecialMenuItem();
            current_module_file_controller.close();
            current_module_file_controller = null;
        }

        while (view_box.children.length != 0)
        {
            auto x = view_box.children[0];
            x.destroy();
        }

        auto x = new Label(LABEL_TEXT_FILE_NOT_OPENED);
        view_box.packStart(x, true, true, 0);
        view_box.showAll();
    }

    Exception setModuleFileController(ModuleFileController mfc)
    {

        unsetModuleFileController();

        if (mfc is null)
        {
            return new Exception("programming error");
        }

        /* dedit.moduleinterface.ModuleInformation* moduleinfo; */

        auto view_res = mfc.getView();

        auto mm_res = mfc.getMainMenu();

        auto view_widget = view_res.getWidget();

        auto mm_widget = mm_res.getWidget();

        view_box.packStart(view_widget, true, true, 0);

        this.main_menu.setSpecialMenuItem(mfc.getModInfo().name, mm_widget);

        this.view_module_project.setText(mfc.getProject());
        this.view_module_filename.setText(mfc.getFilename());

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
