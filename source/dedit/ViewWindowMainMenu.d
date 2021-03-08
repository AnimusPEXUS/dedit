module dedit.ViewWindowMainMenu;

import std.stdio;

import gdk.Window;

import gtk.Window;
import gtk.MenuBar;
import gtk.Menu;
import gtk.MenuItem;
import gtk.c.types;

import dedit.ViewWindow;

const string SPECIAL_MENU_ITEM_LABEL = "[Special]";

class ViewWindowMainMenu
{

    MenuBar menuBar;

    ViewWindow view_window;

    MenuItem menu_special;

    this(ViewWindow view_window)
    {

        assert(view_window !is null);

        this.view_window = view_window;

        menuBar = new MenuBar();

        auto menu_file = new MenuItem("File");
        auto menu_edit = new MenuItem("Edit");
        menu_special = new MenuItem(SPECIAL_MENU_ITEM_LABEL);

        auto menu_file_menu = new Menu();
        menu_file.setSubmenu(menu_file_menu);

        /*
        auto menu_file_menu_save = new MenuItem("Save");
        menu_file_menu_save.addAccelerator("activate", view_window.accel_group,
                's', GdkModifierType.CONTROL_MASK, GtkAccelFlags.VISIBLE);
        menu_file_menu_save.addOnActivate(&view_window.onMISaveActivate);
        menu_file_menu.append(menu_file_menu_save);

        auto menu_file_menu_close = new MenuItem("Close");
        menu_file_menu_close.addAccelerator("activate", view_window.accel_group,
                'w', GdkModifierType.CONTROL_MASK, GtkAccelFlags.VISIBLE);
        menu_file_menu_close.addOnActivate(&view_window.onMICloseActivate);
        menu_file_menu.append(menu_file_menu_close);
        */

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
        if (newSubmenu !is null) {
        	menu_special.showAll();
        }
    }

    void removeSpecialMenuItem()
    {
        setSpecialMenuItem(SPECIAL_MENU_ITEM_LABEL, null);
    }
}