module dedit.EditorWindowMainMenu;

import std.stdio;

import gdk.Window;

import gtk.Window;
import gtk.MenuBar;
import gtk.Menu;
import gtk.MenuItem;

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

        menuBar.append(menu_file);
        menuBar.append(menu_edit);
        menuBar.append(menu_special);

    }

    MenuBar getWidget()
    {
        return menuBar;
    };

    void setSpecialMenuItem(string label, Menu newSubmenu)
    {
        menu_special.setLabel(label);
        menu_special.setSubmenu(newSubmenu);
    };
}
