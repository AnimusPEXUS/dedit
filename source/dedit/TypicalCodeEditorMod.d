module dedit.TypicalCodeEditorMod;

import std.path;
import std.algorithm;
import std.stdio;
import std.json;
import std.process;
import std.range;
import std.regex;
import std.string;

import glib.Idle;

import gtk.Paned;
import gtk.Scrollbar;
import gtk.TextBuffer;
import gtk.TextView;
import gtk.TextTagTable;
import gtk.Menu;
import gtk.MenuItem;
import gtk.Widget;
import gtk.ScrolledWindow;
import gtk.c.types;

import pango.PgFontDescription;

import gsv.SourceView;
import gsv.SourceBuffer;
import gsv.SourceLanguageManager;
import gsv.c.types;

import dedit.moduleinterface;
import dedit.Controller;
import dedit.EditorWindow;
import dedit.OutlineTool;

import dutils.regex;

void outlineToolDataInsertMatchedLines(OutlineToolInputData* ret, string txt, Regex!char re, ulong[] lstarts)
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

        auto xx = new OutlineToolInputDataUnit(
                v,
                txt[start_index .. end_index].stripRight()
        );

        debug
        {
            writeln(" adding to ret.data : ", xx.line, " : ", xx.text);
        }

        ret.data ~= xx;
    }

}

class MainMenu : ModuleBufferMainMenu
{

    View view;
    Menu mm;

    private MenuItem mm_menu_format;
    private string buffer_id;

    this(View view, string buffer_id)
    {

        this.buffer_id = buffer_id;

        assert(view !is null);
        this.view = view;

        mm = new Menu();

        auto mm_menu_format = new MenuItem("Format");
        this.mm_menu_format = mm_menu_format;
        mm_menu_format.addOnActivate(&onMIFormatActivate);

        mm.append(mm_menu_format);

    }

    Menu getWidget()
    {
        return mm;
    }

    void installAccelerators(bool uninstall = false)
    {
        if (!uninstall)
        {
            mm_menu_format.addAccelerator(
                    "activate",
                    this.view.w.accel_group,
                    'f',
                    GdkModifierType.CONTROL_MASK | GdkModifierType.SHIFT_MASK,
                    GtkAccelFlags.VISIBLE
            );
        }
        else
        {
            this.mm_menu_format.removeAccelerator(
                    this.view.w.accel_group,
                    'f',
                    GdkModifierType.CONTROL_MASK | GdkModifierType.SHIFT_MASK
            );
        }
    }

    void uninstallAccelerators()
    {
        installAccelerators(true);
    }

    void onMIFormatActivate(MenuItem mi)
    {

        auto s = this.view.getSettings();
        this.view.b.format();
        this.view.setSettings(s);

    }

    void destroy()
    {
        // writeln("d : MainMenu : ModuleBufferMainMenu - destroy() is called");
        uninstallAccelerators();
        mm.destroy();
    }

}

class View : ModuleBufferView
{

    Controller c;
    EditorWindow w;
    Buffer b;

    Paned paned;

    SourceView sv;
    SourceBuffer sb;
    ScrolledWindow sw;

    bool close_already_called;

    ModuleBufferMainMenu mm;

    OutlineTool outlineTool;

    this(Buffer b)
    {
        this.c = b.c;
        this.w = b.w;
        this.b = b;

        paned = new Paned(GtkOrientation.HORIZONTAL);

        /* sb = new SourceBuffer(cast(GtkSourceBuffer*) null); */
        sv = new SourceView();
        b.tcem.options.applyLanguageSettingsToSourceView(sv);
        {
            auto fd = PgFontDescription.fromString(c.font);
            sv.overrideFont(fd);

        }
        auto sb = (cast(Buffer) b).getSourceBuffer();
        b.tcem.options.applyLanguageSettingsToSourceBuffer(sb);
        sv.setBuffer(sb);

        sw = new ScrolledWindow();
        sw.setOverlayScrolling(false);
        sw.setKineticScrolling(false);
        sw.setCaptureButtonPress(false);
        sw.add(sv);
        mm = new MainMenu(this, this.b.uri);

        OutlineToolOptions* oto = new OutlineToolOptions();
        oto.userWishesToGoToLine = &outlineToolUserWishesToGoToLine;
        oto.userWishesToRefreshData = &outlineToolUserWishesToRefreshData;

        outlineTool = new OutlineTool(oto);

        paned.add1(sw);
        paned.add2(outlineTool.getWidget());
    }

    Widget getWidget()
    {
        return paned;
    }

    ModuleBufferMainMenu getMainMenu()
    {
        return mm;
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

    void close()
    {
        if (close_already_called)
        {
            return;
        }
        close_already_called = true;

        mm.destroy();
        sv.destroy();
        outlineTool.destroy();
    }

    dedit.moduleinterface.ModuleInformation* getModInfo()
    {
        return b.tcem.options.module_information;
    }

    ModuleDataBuffer getBuffer()
    {
        return b;
    }

    void outlineToolUserWishesToGoToLine(int new_line_number)
    {
    }

    void outlineToolUserWishesToRefreshData()
    {
        OutlineToolInputData* delegate(string txt) tt;

        try
        {
            tt = this.b.tcem.options.prepareDataForOutlineTool;
        }
        catch (Exception e)
        {
            return;
        }

        if (tt is null)
        {
            return;
        }

        auto tt_res = tt(b.buff.getText());

        outlineTool.setData(tt_res);
    }

}

class Buffer : ModuleDataBuffer
{

    SourceBuffer buff;

    // TODO:
    // it is better to leave knowlage of filenames to EditorWindow itself
    /* string original_filename;
        string filename_rtr; // relative to project root */

    Controller c;
    EditorWindow w;
    TypicalCodeEditorMod tcem;

    private string uri; // TODO: move this to EditorWindow

    this(TypicalCodeEditorMod tcem, Controller c, EditorWindow w, string uri)
    {

        this.tcem = tcem;
        this.uri = uri;

        // TODO: better uri handling required
        this.c = c;
        this.w = w;

        if (uri.startsWith("file://"))
        {
            uri = uri["file://".length .. $];
        }
        auto filename = uri;

        filename = absolutePath(filename);
        /* this.filename = filename; */

        auto f = new std.stdio.File(filename);

        char[] buff;
        buff.length = f.size;

        if (f.size > 0)
        {
            f.rawRead(buff);
        }

        this.buff = new SourceBuffer(cast(TextTagTable) null);
        this.buff.setText(cast(string) buff.idup);
    }

    /* ref const dedit.moduleinterface.ModuleInformation getModInfo() {
    	return ModuleInformation;
    	} */

    void close()
    {
        // buff.destroy();
        // buff = null;
    }

    SourceBuffer getSourceBuffer()
    {
        return buff;
    }

    void save(string uri)
    {
        if (uri.startsWith("file://"))
        {
            uri = uri["file://".length .. $];
        }
        auto filename = uri;

        string txt = buff.getText();

        toFile(txt, filename);
    }

    ModuleBufferView createView()
    {
        return new View(this);
    }

    void format()
    {
        ubyte[] bt = cast(ubyte[]) buff.getText();
        auto res = this.tcem.options.formatWholeBufferText(cast(string) bt);
        buff.setText(res.idup);
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

struct TypicalCodeEditorModOptions
{
    dedit.moduleinterface.ModuleInformation* module_information;
    void delegate(SourceView sv) applyLanguageSettingsToSourceView;
    void delegate(SourceBuffer sb) applyLanguageSettingsToSourceBuffer;
    string delegate(string txt) formatWholeBufferText;
    OutlineToolInputData* delegate(string txt) prepareDataForOutlineTool;
    string delegate(string txt) comment;
    string delegate(string txt) uncomment;
}

class TypicalCodeEditorMod
{

    TypicalCodeEditorModOptions* options;

    this(TypicalCodeEditorModOptions* options)
    {
        this.options = options;
    }

    ModuleDataBuffer createDataBufferForURI(Controller c, EditorWindow w, string uri)
    {
        return new Buffer(this, c, w, uri);
    }

}
