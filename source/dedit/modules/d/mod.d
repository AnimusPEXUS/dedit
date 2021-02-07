module dedit.modules.d.mod;

import std.path;
import std.algorithm;
import std.stdio;
import std.json;
import std.process;
import std.range;

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

void applyLanguageSettingsToSourceView(SourceView sv)
{
    sv.setAutoIndent(true);
    /* sv.setDrawSpaces(DrawSpacesFlags.ALL); */
    sv.setHighlightCurrentLine(true);
    sv.setIndentOnTab(true);
    sv.setIndentWidth(4);
    sv.setInsertSpacesInsteadOfTabs(false);
    sv.setRightMarginPosition(80);
    sv.setShowRightMargin(true);
    sv.setTabWidth(4);
    sv.setShowLineMarks(true);
    sv.setShowLineNumbers(true);
    // sv.setSmartHomeEnd(GtkSourceSmartHomeEndType.ALWAYS);
}

void applyLanguageSettingsToSourceBuffer(SourceBuffer sb)
{
    sb.setLanguage(SourceLanguageManager.getDefault().getLanguage("d"));
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
            mm_menu_format.addAccelerator("activate", this.view.w.accel_group,
                    'f', GdkModifierType.CONTROL_MASK, GtkAccelFlags.VISIBLE);
        }
        else
        {
            this.mm_menu_format.removeAccelerator(this.view.w.accel_group, 'f',
                    GdkModifierType.CONTROL_MASK);
        }
    }

    void uninstallAccelerators()
    {
        installAccelerators(true);
    }

    void onMIFormatActivate(MenuItem mi)
    {

        // auto s = this.view.getSettings();
        this.view.format();
        // this.view.setSettings(s);

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
        applyLanguageSettingsToSourceView(sv);
        {
            auto fd = PgFontDescription.fromString(c.font);
            sv.overrideFont(fd);

        }
        auto sb = (cast(Buffer) b).getSourceBuffer();
        applyLanguageSettingsToSourceBuffer(sb);
        sv.setBuffer(sb);

        sw = new ScrolledWindow();
        sw.setOverlayScrolling(false);
        sw.setKineticScrolling(false);
        sw.setCaptureButtonPress(false);
        sw.add(sv);
        mm = new MainMenu(this, this.b.uri);

        OutlineToolOptions* oto = new OutlineToolOptions(&outlineToolUserWishesToGoToLine);

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

    ref const dedit.moduleinterface.ModuleInformation getModInfo()
    {
        return cast(dedit.moduleinterface.ModuleInformation) ModuleInformation;
    }

    ModuleDataBuffer getBuffer()
    {
        return b;
    }

    void outlineToolUserWishesToGoToLine(int new_line_number)
    {
    }

    void format()
    {

        import std.array;
        import dfmt.config : Config;
        import dfmt.formatter : format;
        import dfmt.editorconfig : OptionalBoolean;

        ubyte[] bt = cast(ubyte[]) this.b.buff.getText();

        Config config;
        config.initializeWithDefaults();
        config.dfmt_keep_line_breaks = OptionalBoolean.t;

        if (!config.isValid())
        {
            writeln("dfmt config error");
            return;
        }

        auto output = appender!string;

        immutable bool formatSuccess = format("stdin", bt, output, &config);

        if (!formatSuccess)
        {
            writeln("dfmt:format() returned error");
            return;
        }

        string x = cast(string) output[];

        auto s = this.getSettings();

        //buff.setText(x);
        new Idle(delegate bool() {
            this.b.buff.setText(x);
            this.setSettings(s);
            return false;
        });

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

    private string uri; // TODO: move this to EditorWindow

    this(Controller c, EditorWindow w, string uri)
    {

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
            writeln("scroll_position type ", v.object["scroll_position"].type);
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

const dedit.moduleinterface.ModuleInformation ModuleInformation = {
    moduleName: "D",
    supportedExtensions: [".d"],
    createDataBufferForURI: function ModuleDataBuffer(
            Controller c,
            EditorWindow w,
            string uri
    ) { return new Buffer(c, w, uri); }};
