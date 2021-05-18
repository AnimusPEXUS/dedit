module dedit.TypicalModuleFileControllerText;

import std.path;
import std.algorithm;
import std.stdio;
import std.json;
import std.process;
import std.range;
import std.regex;
import std.string;



import dedit.moduleinterface;
import dedit.Controller;
import dedit.FileController;
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

    // ret.data = [];
    // ret.data.length = 0;
    // assert(ret.data !is null);

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

struct TypicalModuleFileControllerTextSettings
{
    Controller controller;
    FileController file_controller;

    dedit.moduleinterface.ModuleInformation* module_information;
    void delegate(SourceView sv) applyLanguageSettingsToSourceView;
    void delegate(SourceBuffer sb) applyLanguageSettingsToSourceBuffer;
    string delegate(string txt) formatWholeBufferText;
    OutlineToolInputData* delegate(string txt) prepareDataForOutlineTool;
    string delegate(string txt) comment;
    string delegate(string txt) uncomment;

    ~this()
    {
        writeln("TypicalModuleFileControllerTextSettings destroyed");
    }
}

class TypicalModuleFileControllerText : ModuleFileController
{
    TypicalModuleFileControllerTextSettings* settings;

    Buffer buffer;
    View view;
    MainMenu mainmenu;

    this(TypicalModuleFileControllerTextSettings* settings)
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

    FileController getFileController()
    {
        return this.settings.file_controller;
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

    Exception loadData()
    {
        auto txt = this.settings.file_controller.getString();
        if (txt[1]!is null)
        {
            return txt[1];
        }
        this.buffer.buff.setText(txt[0]);
        return cast(Exception) null;
    }

    Exception saveData()
    {
        auto txt = this.buffer.buff.getText();
        auto res = this.settings.file_controller.setString(txt);
        if (res !is null)
        {
            return res;
        }
        return cast(Exception) null;
    }

    string getProject()
    {
        return this.settings.file_controller.settings.project;
    }

    string getFilename()
    {
        return this.settings.file_controller.settings.filename;
    }

    void setFilename(string filename)
    {
        this.settings.file_controller.settings.filename = filename;
        return;
    }

    void close()
    {
        // TODO: is this needed?
    }

}

class Buffer : ModuleControllerBuffer
{

    TypicalModuleFileControllerText tmfct;

    SourceBuffer buff;

    /* this(TypicalCodeEditorMod tcem, Controller c, ViewWindow w, string uri) */
    this(TypicalModuleFileControllerText tmfct)
    {

        this.tmfct = tmfct;
        /* this.uri = uri; */

        // TODO: better uri handling required
        /* this.c = c;
        this.w = w; */

        /* if (uri.startsWith("file://"))
        {
            uri = uri["file://".length .. $];
        }
        auto filename = uri;

        filename = absolutePath(filename);


        auto f = new std.stdio.File(filename);

        char[] buff;
        buff.length = f.size;

        if (f.size > 0)
        {
            f.rawRead(buff);
        }

        this.buff = new SourceBuffer(cast(TextTagTable) null);
        this.buff.setText(cast(string) buff.idup); */

        this.buff = new SourceBuffer(cast(TextTagTable) null);
        auto res = this.tmfct.settings.file_controller.getString();
        if (res[1]!is null)
        {
            throw res[1];
        }
        this.buff.setText(res[0]);
    }

    /* ref const dedit.moduleinterface.ModuleInformation getModInfo() {
    	return ModuleInformation;
    	} */

    TypicalModuleFileControllerText getModuleFileController()
    {
        return tmfct;
    }

    void close()
    {
        // buff.destroy();
        // buff = null;
    }

    SourceBuffer getSourceBuffer()
    {
        return buff;
    }

    /* void save(string uri)
    {
        if (uri.startsWith("file://"))
        {
            uri = uri["file://".length .. $];
        }
        auto filename = uri;

        string txt = buff.getText();

        toFile(txt, filename);
    } */

    void format()
    {
        ubyte[] bt = cast(ubyte[]) buff.getText();
        auto res = this.tmfct.settings.formatWholeBufferText(cast(string) bt);
        buff.setText(res.idup);
    }

}

class MainMenu : ModuleControllerMainMenu
{

    TypicalModuleFileControllerText tmfct;

    private Menu mm;
    private MenuItem mm_menu_format;

    this(TypicalModuleFileControllerText tmfct)
    {
        this.tmfct = tmfct;

        mm = new Menu();

        auto mm_menu_format = new MenuItem("Format");
        this.mm_menu_format = mm_menu_format;
        mm_menu_format.addOnActivate(&onMIFormatActivate);

        mm.append(mm_menu_format);
    }

    TypicalModuleFileControllerText getModuleFileController()
    {
        return tmfct;
    }

    Menu getWidget()
    {
        return mm;
    }

    /* void installAccelerators(bool uninstall = false) */
    void installAccelerators(AccelGroup ag, bool uninstall = false)
    {
        if (!uninstall)
        {
            mm_menu_format.addAccelerator("activate", ag, 'f',
                    GdkModifierType.CONTROL_MASK | GdkModifierType.SHIFT_MASK,
                    GtkAccelFlags.VISIBLE);
        }
        else
        {
            this.mm_menu_format.removeAccelerator(ag, 'f',
                    GdkModifierType.CONTROL_MASK | GdkModifierType.SHIFT_MASK);
        }
    }

    void uninstallAccelerators(AccelGroup ag)
    {
        installAccelerators(ag, true);
    }

    void onMIFormatActivate(MenuItem mi)
    {

        auto s = this.tmfct.getView().getSettings();
        (cast(Buffer)(this.tmfct.getBuffer())).format();
        this.tmfct.getView().setSettings(s);

    }

    /* void destroy()
    {
        // writeln("d : MainMenu : ModuleBufferMainMenu - destroy() is called");
        uninstallAccelerators();
        mm.destroy();
    } */

}

class View : ModuleControllerView
{

    TypicalModuleFileControllerText tmfct;

    Paned paned;

    SourceView sv;
    SourceBuffer sb;
    ScrolledWindow sw;

    bool close_already_called;

    OutlineTool outlineTool;

    this(TypicalModuleFileControllerText tmfct)
    {
        this.tmfct = tmfct;

        paned = new Paned(GtkOrientation.HORIZONTAL);

        /* sb = new SourceBuffer(cast(GtkSourceBuffer*) null); */
        sv = new SourceView();
        this.tmfct.settings.applyLanguageSettingsToSourceView(sv);
        {
            auto fd = PgFontDescription.fromString(
                    this.tmfct.settings.controller.settings["font"].str());
            sv.overrideFont(fd);
        }
        auto sb = (cast(Buffer)(this.tmfct.getBuffer())).getSourceBuffer();
        this.tmfct.settings.applyLanguageSettingsToSourceBuffer(sb);
        sv.setBuffer(sb);

        sw = new ScrolledWindow();
        sw.setOverlayScrolling(false);
        sw.setKineticScrolling(false);
        sw.setCaptureButtonPress(false);
        sw.add(sv);
        // mm = new MainMenu(this, this.b.uri);

        OutlineToolOptions* oto = new OutlineToolOptions();
        oto.userWishesToGoToLine = &outlineToolUserWishesToGoToLine;
        oto.userWishesToRefreshData = &outlineToolUserWishesToRefreshData;

        outlineTool = new OutlineTool(oto);
        auto outlinetool_widget = outlineTool.getWidget();

        paned.add1(sw);
        paned.add2(outlinetool_widget);

        paned.childSetProperty(paned.getChild1(), "resize", new Value(true));
        paned.childSetProperty(paned.getChild2(), "resize", new Value(false));
    }

    TypicalModuleFileControllerText getModuleFileController()
    {
        return tmfct;
    }

    Widget getWidget()
    {
        return paned;
    }

    JSONValue getSettings()
    {
        auto x = new ViewSettings();
        x.scroll_position = (cast(Scrollbar)(sw.getVscrollbar())).getValue();
        x.right_paned_position = paned.getPosition();
        return x.toJSONValue();
    }

    void setSettings(JSONValue value)
    {

        auto x = new ViewSettings(value);

        paned.setPosition(x.right_paned_position);

        new Idle(delegate bool() {

            (cast(Scrollbar)(sw.getVscrollbar())).setValue(x.scroll_position);

            return false;
        });
    }

    void outlineToolUserWishesToGoToLine(int new_line_number)
    {
    }

    void outlineToolUserWishesToRefreshData()
    {
        OutlineToolInputData* delegate(string txt) tt;

        try
        {
            tt = this.tmfct.settings.prepareDataForOutlineTool;
        }
        catch (Exception e)
        {
            return;
        }

        if (tt is null)
        {
            return;
        }

        auto tt_res = tt((cast(Buffer)(this.tmfct.getBuffer())).buff.getText());

        outlineTool.setData(tt_res);
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
        JSONValue ret = JSONValue(cast(string[string]) null);
        ret.object["cursor_line"] = JSONValue(cursor_line);
        ret.object["cursor_column"] = JSONValue(cursor_column);
        ret.object["scroll_position"] = JSONValue(scroll_position);
        ret.object["right_paned_position"] = JSONValue(right_paned_position);
        return ret;
    }

    bool fromJSONValue(JSONValue v)
    {
        if (v.type != JSONType.object)
        {
            return false;
        }

        if ("cursor_line" in v.object)
        {
            cursor_line = cast(int) v.object["cursor_line"].integer;
        }

        if ("cursor_column" in v.object)
        {
            cursor_column = cast(int) v.object["cursor_column"].integer;
        }

        if ("right_paned_position" in v.object)
        {
            right_paned_position = cast(int) v.object["right_paned_position"].integer;
        }

        if (right_paned_position < 300)
        {
            right_paned_position = 300;
        }

        if ("scroll_position" in v.object)
        {
            // writeln("scroll_position type ", v.object["scroll_position"].type);
            switch (v.object["scroll_position"].type)
            {
            default:
                break;
            case JSONType.integer:
                scroll_position = cast(double) v.object["scroll_position"].integer;
                break;
            case JSONType.float_:
                scroll_position = v.object["scroll_position"].floating;
                break;

            }

        }

        return true;
    }

}
