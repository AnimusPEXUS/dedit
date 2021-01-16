module dedit.modules.d.mod;

import std.path;
import std.algorithm;
import std.stdio;
import std.json;

import gtk.Scrollbar;
import gtk.TextBuffer;
import gtk.TextView;
import gtk.TextTagTable;
import gtk.Menu;
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

class View : ModuleBufferView
{
    private
    {
        Controller c;
        EditorWindow w;
        ModuleDataBuffer b;

        SourceView sv;
        SourceBuffer sb;
        ScrolledWindow sw;

        bool close_already_called;
    }

    this(Controller c, EditorWindow w, ModuleDataBuffer b)
    {
        this.c = c;
        this.w = w;
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
    }

    Widget getWidget()
    {
        writeln("returning buffer widget");
        return sw;
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
        auto x = new BufferViewSettings(value);
        writeln("x.scroll_position (setting to) ", x.scroll_position);
        (cast(Scrollbar)(sw.getVscrollbar())).setValue(x.scroll_position);
    }

    void close()
    {
        if (close_already_called)
        {
            return;
        }
        close_already_called = true;

        sv.destroy();
        sb.destroy();
    }
}

class Buffer : ModuleDataBuffer
{

    private
    {
        SourceBuffer buff;

        // it is better to leave knowlage of filenames to EditorWindow itself
        /* string original_filename;
        string filename_rtr; // relative to project root */

        Controller c;
        EditorWindow w;
    }

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

    /* string getFileName()
    {
        return filename;
    } */

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

    ModuleBufferView createView(ModuleDataBuffer b = null, EditorWindow w = null, Controller c = null)
    {
        if (c is null)
        {
            c = this.c;
        }

        if (w is null)
        {
            w = this.w;
        }

        if (b is null)
        {
            b = this;
        }

        return new View(c, w, b);
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
