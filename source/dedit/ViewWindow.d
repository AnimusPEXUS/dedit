module dedit.ViewWindow;

import std.stdio;
import std.path;
import std.algorithm;
import std.json;

import gtk.Window;
import gtk.Label;
import gtk.Box;
import gtk.TreeView;
import gtk.TreeIter;
import gtk.TreePath;
import gtk.Frame;
import gtk.ScrolledWindow;
import gtk.Paned;
import gtk.Widget;
import gtk.CellRendererText;
import gtk.TreeViewColumn;
import gtk.ListStore;
import gtk.TreeIter;
import gdk.Event;
import gtk.AccelGroup;
import gtk.MenuItem;
import gtk.Button;
import gtk.MessageDialog;

import gobject.Value;

import gtk.c.types;
import gdk.c.types;
import pango.c.types;

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
}

struct ViewWindowSettings
{
    Controller controller;
    ViewWindowContentSetup* setup;
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

    this(ViewWindowSettings* settings)
    {
        this.settings = settings;

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

        auto view_module_box = new Box(GtkOrientation.HORIZONTAL, 0);

        view_module_project = new Label("project");
        view_module_filename = new Label("filename");
        auto view_module_data_load = new Button("Load Data");
        auto view_module_data_save = new Button("Save Data");
        auto view_module_change_name = new Button("Change Name..");
        /* auto view_module_apply = new Button("Apply"); */

        view_module_box.packStart(view_module_project, false, true, 0);
        view_module_box.packStart(view_module_filename, false, true, 0);
        view_module_box.packStart(view_module_data_load, false, true, 0);
        view_module_box.packStart(view_module_data_save, false, true, 0);
        view_module_box.packStart(view_module_change_name, false, true, 0);

        menu_box.packStart(main_menu.getWidget(), true, true, 0);
        menu_box.packStart(view_module_box, false, true, 0);

        root_box.packStart(menu_box, false, true, 0);
        root_box.packStart(view_box, true, true, 0);

        if (settings.setup !is null)
        {
            this.setSetup(settings.setup);
        }
    }

    bool onDeleteEvent(Event event, Widget w)
    {
        // saveSettings();
        // controller.editorWindowIsClosed(project);
        return false;
    }

    Window getWidget()
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

    Exception setSetup(ViewWindowContentSetup* setup)
    {
        // load appropriate ModuleFileController and feed it to
        // setModuleFileController() function

        auto fc = this.settings.controller.getOrCreateFileController(setup.project,
                setup.filename, true,);
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

        this.main_menu.setSpecialMenuItem(mfc.getModInfo().moduleName, mm_widget);

        this.view_module_project.setText("project: " ~ mfc.getProject());
        this.view_module_filename.setText("filename: " ~ mfc.getFilename());

        this.current_module_file_controller = mfc;

        return null;
    }

}

/*
class ViewWindowSettings
{
    int x, y;
    int width, height;

    int padding_position;

    init(JSONValue v)
    {
        if (v.type() != JSONType.object)
        {
            return;
        }

        if ("x" in v)
        {
            x = cast(int) v["x"].integer();
        }

        if ("y" in v)
        {
            y = cast(int) v["y"].integer();
        }

        if ("width" in v)
        {
            width = cast(int) v["width"].integer();
        }

        if ("height" in v)
        {
            height = cast(int) v["height"].integer();
        }

        if ("padding_position" in v)
        {
            height = cast(int) v["height"].integer();
        }
    }
}
*/
