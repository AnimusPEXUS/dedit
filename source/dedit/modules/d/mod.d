module dedit.modules.d.mod;

import std.path;
import std.algorithm;
import std.stdio;
import std.json;
import std.process;
import std.range;

import glib.Idle;
import gtk.Scrollbar;
import gtk.TextBuffer;
import gtk.TextView;
import gtk.TextTagTable;
import gtk.Menu;
import gtk.MenuItem;
import gtk.Widget;
import gtk.ScrolledWindow;

import pango.PgFontDescription;

import gsv.SourceView;
import gsv.SourceBuffer;
import gsv.SourceLanguageManager;
import gsv.c.types;

import dedit.moduleinterface;
import dedit.Controller;
import dedit.EditorWindow;

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
    sv.setSmartHomeEnd(GtkSourceSmartHomeEndType.ALWAYS);
}

void applyLanguageSettingsToSourceBuffer(SourceBuffer sb)
{
    sb.setLanguage(SourceLanguageManager.getDefault().getLanguage("d"));
}

class MainMenu : ModuleBufferMainMenu
{

    View view;
    Menu mm;

    this(View view)
    {

        this.view = view;

        mm = new Menu();

        auto mm_menu_format = new MenuItem("Format");
        mm_menu_format.addAccelerator("activate", this.view.w.accel_group, 'f',
                GdkModifierType.CONTROL_MASK, GtkAccelFlags.VISIBLE);
        mm_menu_format.addOnActivate(&onMIFormatActivate);
        mm.append(mm_menu_format);

    }

    Menu getWidget()
    {
        return mm;
    }

    void onMIFormatActivate(MenuItem mi)
    {
        this.view.b.format();
    }

    /* ref dedit.moduleinterface.ModuleInformation getModInfo() {
    	return ModuleInformation;
    	} */

    ~this()
    {
        writeln("d : MainMenu : ModuleBufferMainMenu - is being destroyed");
    }

    void destroy()
    {
        writeln("d : MainMenu : ModuleBufferMainMenu - destroy() is called");
        mm.destroy();
    }

}

class View : ModuleBufferView
{

    Controller c;
    EditorWindow w;
    Buffer b;

    SourceView sv;
    SourceBuffer sb;
    ScrolledWindow sw;

    bool close_already_called;

    ModuleBufferMainMenu mm;

    this(Buffer b)
    {
        this.c = b.c;
        this.w = b.w;
        this.b = b;

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
        sw.add(sv);
        mm = new MainMenu(this);
    }

    Widget getWidget()
    {
        writeln("returning buffer widget");
        return sw;
    }

    ModuleBufferMainMenu getMainMenu()
    {
        return mm;
    }

    string getSettings()
    {
        auto x = new BufferViewSettings();
        x.scroll_position = (cast(Scrollbar)(sw.getVscrollbar())).getValue();
        writeln("x.scroll_position ", x.scroll_position);
        auto y = x.toJSONValue();
        return y.toJSON();
    }

    void setSettings(string value)
    {
        // TODO: 'values' variable have type of void - I don't know what this variable is - I should get to gnow.

        new Idle(delegate bool() {
            auto x = new BufferViewSettings(value);
            writeln("x.scroll_position (setting to) ", x.scroll_position);
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
        sb.destroy();
    }

    ref const dedit.moduleinterface.ModuleInformation getModInfo()
    {
        return cast(dedit.moduleinterface.ModuleInformation) ModuleInformation;
    }

}

class Buffer : ModuleDataBuffer
{

    SourceBuffer buff;

    // it is better to leave knowlage of filenames to EditorWindow itself
    /* string original_filename;
        string filename_rtr; // relative to project root */

    Controller c;
    EditorWindow w;

    this(Controller c, EditorWindow w, string uri)
    {
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

        f.rawRead(buff);

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

        import std.array;
        import dfmt.config : Config;
        import dfmt.formatter : format;

        ubyte[] bt = cast(ubyte[]) buff.getText();

        // p1.write(bt);

        /*auto p = spawnProcess(["dfmt"], p1.readEnd(), p2.writeEnd());
        auto wec = wait(p);

        if (wec == 0)
        {
            buff.setText(bt);
        }*/

        Config config;
        config.initializeWithDefaults();

        /*if (explicitConfigDir != "")
            {
                config.merge(explicitConfig, buildPath(explicitConfigDir, "dummy.d"));
            }
            else
            {
                Config fileConfig = getConfigFor!Config(getcwd());
                fileConfig.pattern = "*.d";
                config.merge(fileConfig, cwdDummyPath);
            }
            config.merge(optConfig, cwdDummyPath);*/

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

        writeln("dfmt out:", x);

        buff.setText(x);

    }

}

class BufferViewSettings
{
    int cursor_line, cursor_column;
    double scroll_position;

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
    moduleName: "D", supportedExtensions: [".d"], createDataBufferForURI: function ModuleDataBuffer(
            Controller c, EditorWindow w, string uri) {
        return new Buffer(c, w, uri);
    }};
