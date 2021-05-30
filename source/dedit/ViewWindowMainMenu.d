module dedit.ViewWindowMainMenu;

import std.stdio;

import dlangui;

import dedit.ViewWindow;

const string SPECIAL_MENU_ITEM_LABEL = "[Special]";

class ViewWindowMainMenu
{

    MainMenu menuBar;

    ViewWindow view_window;

    MenuItem menu_special;

    this(ViewWindow view_window)
    {

        assert(view_window !is null);

        this.view_window = view_window;

        menuBar = new MainMenu();
        auto mainmenu = new MenuItem();

        Action a;

        a = new Action(0, "File"d);
        auto menu_file = new MenuItem(a);
        mainmenu.add(menu_file);
        menuBar.menuItems = mainmenu;

        a = new Action(0, "(Re)Load"d);
        auto menu_file_menu_reload = new MenuItem(a);
        menu_file_menu_reload.menuItemClick = delegate bool(MenuItem item) {
            writeln("onMenuItemClick");
            return true;
        };

        menu_file.add(menu_file_menu_reload);

    }

    MainMenu getWidget()
    {
        return menuBar;
    }

    void setSpecialMenuItem(string label, MenuItem newSubmenu)
    {

    }

    void removeSpecialMenuItem()
    {

    }
}
