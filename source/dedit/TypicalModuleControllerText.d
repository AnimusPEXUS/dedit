module dedit.TypicalModuleControllerText;

import std.path;
import std.algorithm;
import std.stdio;
import std.json;
import std.process;
import std.range;
import std.regex;
import std.string;

import dlangui;

import dedit.moduleinterface;
import dedit.Controller;
import dedit.ViewWindow;
import dedit.OutlineTool;

import dutils.regex;

void outlineToolDataInsertMatchedLines(OutlineToolInputData* ret, string txt,
        Regex!char re, ulong[] lstarts)
{

    auto positions = matchPositions(txt, re, lstarts);

    debug
    {
        writeln("positions");
        foreach (k, v; positions)
        {
            writeln("  ", k, " : ", v);
        }
    }

    foreach (k, v; positions)
    {
        ulong start_index = lstarts[v];
        ulong end_index = 0;

        if (v == lstarts.length)
        {
            end_index = txt.length;
        }
        else
        {
            end_index = lstarts[v + 1]; // TODO: substuct \n (or, maybe, all whitespaces)
        }

        auto xx = new OutlineToolInputDataUnit(v, txt[start_index .. end_index].stripRight());

        debug
        {
            writeln(" adding to ret.data : ", xx.line, " : ", xx.text);
        }

        ret.data ~= xx;
    }

}

struct TypicalModuleControllerTextSettings
{
    Controller controller;

    dedit.moduleinterface.ModuleInformation* module_information;
    void delegate(TypicalModuleControllerText tmct, SourceEdit sv) applyLanguageSettingsToSourceView;
    /* void delegate(SourceBuffer sb) applyLanguageSettingsToSourceBuffer; */
    string delegate(TypicalModuleControllerText tmct, string txt) formatWholeBufferText;
    OutlineToolInputData* delegate(string txt) prepareDataForOutlineTool;
    string delegate(TypicalModuleControllerText tmct, string txt) comment;
    string delegate(TypicalModuleControllerText tmct, string txt) uncomment;

    ~this()
    {
        writeln("TypicalModuleControllerTextSettings destroyed");
    }
}

class TypicalModuleControllerText : ModuleController
{
    TypicalModuleControllerTextSettings* settings;

    Buffer buffer;
    View view;
    MainMenu mainmenu;

    ViewWindow window;

    this(TypicalModuleControllerTextSettings* settings)
    {
        this.settings = settings;

        this.buffer = new Buffer(this);
        this.view = new View(this);
        this.mainmenu = new MainMenu(this);
    }

    ModuleInformation* getModInfo()
    {
        return this.settings.module_information; // TODO: ensure immutable
    }

    Controller getController()
    {
        return this.settings.controller;
    }

    void setViewWindow(ViewWindow window)
    {
        this.window = window;
    }

    ModuleControllerBuffer getBuffer()
    {
        return this.buffer;
    }

    ModuleControllerView getView()
    {
        return this.view;
    }

    ModuleControllerMainMenu getMainMenu()
    {
        return this.mainmenu;
    }

    Exception loadData(string project, string filename)
    {
        auto txt = this.settings.controller.getFileString(project, filename);
        if (txt[1]!is null)
        {
            return txt[1];
        }
        this.buffer.buff.text = to!dstring(txt[0]);
        return cast(Exception) null;
    }

    Exception saveData(string project, string filename)
    {
        auto txt = this.buffer.buff.text;
        auto res = this.settings.controller.setFileString(project, filename, to!string(txt));
        if (res !is null)
        {
            return res;
        }
        return cast(Exception) null;
    }

    void destroy()
    {
        // TODO: is this needed?
        this.settings = null;

        this.buffer = null;
        this.view = null;
        this.mainmenu = null;
    }

}

class Buffer : ModuleControllerBuffer
{

    TypicalModuleControllerText tmct;

    EditableContent buff;

    this(TypicalModuleControllerText tmct)
    {

        this.tmct = tmct;
        this.buff = new EditableContent(true);
    }

    TypicalModuleControllerText getModuleController()
    {
        return tmct;
    }

    EditableContent getSourceBuffer()
    {
        return buff;
    }

    Exception format()
    {
        try
        {
            ubyte[] bt = cast(ubyte[])(to!string(buff.text));
            auto res = this.tmct.settings.formatWholeBufferText(tmct, cast(string) bt);
            buff.text = to!dstring(res);
        }
        catch (Exception e)
        {
            return e;
        }
        return cast(Exception) null;
    }
}

class MainMenu : ModuleControllerMainMenu
{

    TypicalModuleControllerText tmct;

    dlangui.widgets.menu.MainMenu menuBar;
    MenuItem main_menu;

    MenuItem mm_menu_format;

    ActionPair[] action_pair_list;

    this(TypicalModuleControllerText tmct)
    {
        this.tmct = tmct;

        menuBar = new dlangui.widgets.menu.MainMenu;

        main_menu = new MenuItem();

        auto menu_dlang = new MenuItem(new Action(0, to!dstring(tmct.getModInfo().name)));
        main_menu.add(menu_dlang);

        ActionPair ap;

        ap = ActionPair(new Action(0, "Format"d, null, KeyCode.KEY_F,
                KeyFlag.Control | KeyFlag.Alt), delegate bool(const(Action) a) {
            debug
            {
                writeln("onMenuItemClick Format");
            }

            auto err = (cast(Buffer)(tmct.getBuffer())).format();
            if (err !is null)
            {
                tmct.window.window.showMessageBox(UIString.fromRaw("Error formatting text"),
                    UIString.fromRaw(err.msg));
                return true;
            }
            return true;
        });

        action_pair_list ~= ap;

        mm_menu_format = new MenuItem(ap.action);
        mm_menu_format.menuItemAction = ap.callback;

        menu_dlang.add(mm_menu_format);

        menuBar.menuItems = main_menu;
    }

    TypicalModuleControllerText getModuleController()
    {
        return tmct;
    }

    dlangui.widgets.menu.MainMenu getWidget()
    {
        return menuBar;
    }

    ActionPair[] getActionPairList()
    {
        return action_pair_list;
    }
}

class View : ModuleControllerView
{

    TypicalModuleControllerText tmct;

    /* Paned paned; */

    HorizontalLayout layout;

    SourceEdit sv;
    EditableContent sb;
    /* ScrolledWindow sw; */

    bool close_already_called;

    /* OutlineTool outlineTool; */

    this(TypicalModuleControllerText tmct)
    {
        this.tmct = tmct;

        layout = new HorizontalLayout;
        layout.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);

        auto outline = new OutlineTool(tmct);

        sv = new SourceEdit();
        sv.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
        sv.keyEvent = delegate bool(Widget source, KeyEvent event) {

            if (tmct.window.haveKeyEventBinding(event))
            {
                /* writeln("tmct.window.haveKeyEventBinding(event) == true"); */
                tmct.window.triggerKeyEventBinding(event);
                return true;
            }

            return false;
        };
        layout.addChild(sv);
        if (tmct.settings.applyLanguageSettingsToSourceView !is null)
        {
            tmct.settings.applyLanguageSettingsToSourceView(tmct, sv);
        }
        /* {
            auto fd = PgFontDescription.fromString(
                    this.tmct.settings.controller.settings["font"].str());
            sv.overrideFont(fd);
        } */
        auto sb = (cast(Buffer)(this.tmct.getBuffer())).getSourceBuffer();
        /* this.tmct.settings.applyLanguageSettingsToSourceBuffer(sb); */
        sv.content = sb;

        auto resizer = new ResizerWidget;
        layout.addChild(resizer);
        auto ow = outline.getWidget();
        ow.layoutHeight(FILL_PARENT);
        layout.addChild(ow);
    }

    TypicalModuleControllerText getModuleController()
    {
        return tmct;
    }

    Widget getWidget()
    {
        return layout;
    }

    JSONValue getSettings()
    {
        auto x = new ViewSettings();
        return x.toJSONValue();
    }

    void setSettings(JSONValue value)
    {

        /* auto x = new ViewSettings(value); */
    }

    void outlineToolUserWishesToGoToLine(int new_line_number)
    {
    }

    void outlineToolUserWishesToRefreshData()
    {
        OutlineToolInputData* delegate(string txt) tt;
        try
        {
            tt = this.tmct.settings.prepareDataForOutlineTool;
        }
        catch (Exception e)
        {
            return;
        }

        if (tt is null)
        {
            return;
        }

        /* auto tt_res = tt((cast(Buffer)(this.tmct.getBuffer())).buff.getText()); */

        /* outlineTool.setData(tt_res); */
    }

}

class ViewSettings
{
    int cursor_line, cursor_column; // TODO:
    double scroll_position;
    int right_paned_position;

    this()
    {
    }

    this(JSONValue v)
    {
        fromJSONValue(v);
    }

    this(string v)
    {
        fromJSONValue(parseJSON(v));
    }

    JSONValue toJSONValue()
    {
        /* JSONValue ret = JSONValue(cast(JSONValue[string]) null); */
        JSONValue ret = JSONValue(); /* ret["cursor_line"] = JSONValue(cursor_line);
        ret["cursor_column"] = JSONValue(cursor_column);
        ret["scroll_position"] = JSONValue(scroll_position);
        ret["right_paned_position"] = JSONValue(right_paned_position); */
        return ret;
    }

    bool fromJSONValue(JSONValue v)
    {
        /* if (v.type != JSONType.object)
        {
            return false;
        }

        if ("cursor_line" in v)
        {
            cursor_line = cast(int) v["cursor_line"].integer;
        }

        if ("cursor_column" in v.)
        {
            cursor_column = cast(int) v["cursor_column"].integer;
        }

        if ("right_paned_position" in v)
        {
            right_paned_position = cast(int) v["right_paned_position"].integer;
        }

        if (right_paned_position < 300)
        {
            right_paned_position = 300;
        }

        if ("scroll_position" in v)
        {
            // writeln("scroll_position type ", v.object["scroll_position"].type);
            switch (v["scroll_position"].type)
            {
            default:
                break;
            case JSONType.integer:
                scroll_position = cast(double) v["scroll_position"].integer;
                break;
            case JSONType.float_:
                scroll_position = v["scroll_position"].floating;
                break;

            }

        } */

        return true;
    }

}
