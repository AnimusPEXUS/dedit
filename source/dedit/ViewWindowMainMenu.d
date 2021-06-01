module dedit.ViewWindowMainMenu;

import std.stdio;

import dlangui;
import dlangui.dialogs.msgbox;

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
            debug
            {
                writeln("onMenuItemClick (Re)Load");
            }
            if (view_window.current_module_controller is null)
            {
                return true;
            }
            auto res = view_window.current_module_controller.loadData(view_window.project, view_window.filename);
            if (res !is null)
            {
                view_window.window.showMessageBox(UIString.fromRaw("File Data Loading Error"),
                        UIString.fromRaw(res.msg));
                return true;
            }
            return true;
        };

        a = new Action(0, "Write"d);
        auto menu_file_menu_save = new MenuItem(a);
        menu_file_menu_save.menuItemClick = delegate bool(MenuItem item) {
            debug
            {
                writeln("onMenuItemClick Write");
            }
            if (view_window.current_module_controller is null)
            {
                return true;
            }
            auto res = view_window.current_module_controller.saveData(view_window.project, view_window.filename);
            if (res !is null)
            {
                view_window.window.showMessageBox(UIString.fromRaw("File Data Saving Error"),
                        UIString.fromRaw(res.msg));
                return true;
            }
            return true;
        };

        menu_file.add(menu_file_menu_reload);
        menu_file.add(menu_file_menu_save);

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
