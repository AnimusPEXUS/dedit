module dedit.ViewWindowMainMenu;

import std.stdio;

import dlangui;
import dlangui.dialogs.msgbox;

import dedit.ViewWindow;

const string SPECIAL_MENU_ITEM_LABEL = "[Special]";

class ViewWindowMainMenu
{

    MainMenu menuBar;
    MenuItem main_menu;
    MenuItem menu_special;

    ViewWindow view_window;

    ActionPair[] action_pair_list;

    this(ViewWindow view_window)
    {

        assert(view_window !is null);

        this.view_window = view_window;

        menuBar = new MainMenu();
        main_menu = new MenuItem();

        auto menu_file = new MenuItem(new Action(0, "File"d));
        main_menu.add(menu_file);

        ActionPair ap;

        ap = ActionPair(new Action(0, "(Re)Load"d, "document-open",
                KeyCode.KEY_O, KeyFlag.Control), delegate bool(const(Action) a) {
            debug
            {
                writeln("onMenuItemClick (Re)Load");
            }
            if (view_window.current_module_controller is null)
            {
                return true;
            }
            auto res = view_window.current_module_controller.loadData(view_window.project,
                view_window.filename);
            if (res !is null)
            {
                view_window.window.showMessageBox(UIString.fromRaw("File Data Loading Error"),
                    UIString.fromRaw(res.msg));
                return true;
            }
            return true;
        });

        action_pair_list ~= ap;

        auto menu_file_menu_reload = new MenuItem(ap.action);
        menu_file_menu_reload.menuItemAction = ap.callback;

        ap = ActionPair(new Action(0, "Write"d, "document-save", KeyCode.KEY_S,
                KeyFlag.Control), delegate bool(const(Action) a) {
            debug
            {
                writeln("onMenuItemClick Write");
            }
            if (view_window.current_module_controller is null)
            {
                return true;
            }
            auto res = view_window.current_module_controller.saveData(view_window.project,
                view_window.filename);
            if (res !is null)
            {
                view_window.window.showMessageBox(UIString.fromRaw("File Data Saving Error"),
                    UIString.fromRaw(res.msg));
                return true;
            }
            return true;
        });
        action_pair_list ~= ap;

        auto menu_file_menu_save = new MenuItem(ap.action);
        menu_file_menu_save.menuItemAction = ap.callback;

        menu_file.add(menu_file_menu_reload);
        menu_file.add(menu_file_menu_save);
        /* menuBar.menuItems = null;
        menuBar.ownAdapter = null; */
        menuBar.menuItems = main_menu;

    }

    MainMenu getWidget()
    {
        return menuBar;
    }

    ActionPair[] getActionPairList()
    {
        return action_pair_list;
    }

    void setSpecialMenuItem(MenuItem newSubmenu)
    {
        main_menu.add(newSubmenu);
        menu_special = newSubmenu;

        /* menuBar.menuItems = null;
        menuBar.ownAdapter = null; */
        /* writeln("main_menu: ", main_menu);
        menuBar.menuItems = main_menu; */
    }

    void removeSpecialMenuItem()
    {
        auto x = menu_special;
        menu_special = null;
        if (x !is null)
        {
            /* x.destroy(); */
            x = null;
        }
        /* menuBar.menuItems = null;
        menuBar.ownAdapter = null; */
        /* menuBar.menuItems = main_menu; */
    }
}
