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

enum ViewMode
{
    PROJECT_FILE,
    PROJECT_URI,

    PROJECTLESS_FILE,
    PROJECTLESS_URI,
}

enum ViewModeAutoMode
{
    BY_EXTENSION,
    BY_MIME
}

struct ViewWindowSetup
{
    // select mode automatically? if not - use view_mode_to_use value
    bool view_mode_auto;

    // how to determine module in automatic mode
    ViewModeAutoMode view_mode_auto_mode;

    string view_mode_to_use; // mode name if automatic mode selection disabled

    // view opened as part of project or not 
    // (this helps to rename project directory without closing editor windows)
    ViewMode view_mode;

    // set this, if PROJECT_* mode selected
    string project;

    // set this to file name relative to project directory
    string project_filename;

    // if not a project file - set full file path (and name)
    string full_filename;

    // uri (TODO: not implemented yet)
    string uri;
}

struct ViewWindowOptions
{
    Controller controller;
    ViewWindowSetup* setup;
}

class ViewWindow
{

    ViewWindowOptions* options;

    AccelGroup accel_group;

    ViewWindowMainMenu main_menu;

    Window window;

    Box root_box;
    Box main_view_box;

    ModuleBufferView current_view;
    // ModuleDataBuffer    current_buffer; // NOTE: current_view.getBuffer() should be used

    this(ViewWindowOptions* options)
    {
        this.options = options;

        window = new Window("dedit");
        /* window.setGravity(Gravity.STATIC); */
        /* window.addOnDestroy(&windowOnDestroy); */
        window.addOnDelete(&onDeleteEvent);

        accel_group = new AccelGroup();

        window.addAccelGroup(accel_group);

        main_menu = new ViewWindowMainMenu(this);

        root_box = new Box(GtkOrientation.VERTICAL, 0);
        window.add(root_box);

        main_view_box = new Box(GtkOrientation.VERTICAL, 0);

        root_box.packStart(main_menu.getWidget(), false, true, 0);
        root_box.packStart(main_view_box, true, true, 0);

        // loadSettings();
        // unsetMainView();
        
    }

    bool onDeleteEvent(Event event, Widget w)
    {
        // saveSettings();
        // controller.editorWindowIsClosed(project_name);
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

    void unsetView()
    {

        if (current_view is null)
        {
            return;
        }

        // save view config 

        // current_buffer = null;

        if (current_view !is null)
        {
            auto mm = current_view.getMainMenu();

            mm.uninstallAccelerators();

            main_menu.removeSpecialMenuItem();
            current_view.close();
            current_view = null;
        }

        while (main_view_box.children.length != 0)
        {
            auto x = main_view_box.children[0];
            x.destroy();
        }

        auto x = new Label(LABEL_TEXT_FILE_NOT_OPENED);
        main_view_box.packStart(x, true, true, 0);
        main_view_box.showAll();
    }

    Exception setView(ViewWindowSetup* setup)
    {

        unsetView();

        if (setup is null)
        {
            return new Exception("programming error");
        }

        dedit.moduleinterface.ModuleInformation* moduleinfo;

        switch (setup.view_mode)
        {
        default:
            return new Exception("mode not supported");
        case ViewMode.PROJECT_FILE:
            auto res = determineModuleByFileExtension(setup.project_filename);
            if (res[1] !is null) {
                return res[1];
            }            
            break;
        case ViewMode.PROJECTLESS_FILE:
            auto res = determineModuleByFileExtension(setup.full_filename);
            if (res[1] !is null) {
                return res[1];
            }            
            break;
        }
        
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
