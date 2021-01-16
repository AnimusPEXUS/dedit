module dedit.EditorWindowMainMenu;

import std.stdio;

import gdk.Window;

import gtk.Window;
import gtk.MenuBar;
import gtk.Menu;
import gtk.MenuItem;
import gtk.c.types;

import dedit.EditorWindow;

class EditorWindowMainMenu
{
    private
    {

        MenuBar menuBar;

        EditorWindow main_window;

        MenuItem menu_special;
    }

    this(EditorWindow main_window)
    {

        assert(main_window !is null);

        this.main_window = main_window;

        menuBar = new MenuBar();

        auto menu_file = new MenuItem("File");
        auto menu_edit = new MenuItem("Edit");
        auto menu_special = new MenuItem("[Special]");
        menu_special = menu_special;

        auto menu_file_menu = new Menu();
        menu_file.setSubmenu(menu_file_menu);
        auto menu_file_menu_save = new MenuItem("Save");
        menu_file_menu_save.addAccelerator("activate", main_window.accel_group,
                's', GdkModifierType.CONTROL_MASK, GtkAccelFlags.VISIBLE);
        menu_file_menu_save.addOnActivate(&main_window.onMISaveActivate);
        menu_file_menu.append(menu_file_menu_save);

        menuBar.append(menu_file);
        menuBar.append(menu_edit);
        menuBar.append(menu_special);

    }

    MenuBar getWidget()
    {
        return menuBar;
    }

    void setSpecialMenuItem(string label, Menu newSubmenu)
    {
        menu_special.setLabel(label);
        menu_special.setSubmenu(newSubmenu);
    }
}
