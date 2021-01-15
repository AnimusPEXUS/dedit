module dedit.modules.d.mod;

import std.path;
import std.algorithm;
import std.stdio;

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
        sw.add(sv);
    }

    Widget getWidget()
    {
        writeln("returning buffer widget");
        return sw;
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
        string filename;

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
        this.filename = filename;

        auto f = new std.stdio.File(filename);

        char[] buff;
        buff.length = f.size;

        f.rawRead(buff);

        this.buff = new SourceBuffer(cast(TextTagTable) null);
        this.buff.setText(cast(string) buff.idup);
    }

    string getFileName()
    {
        return filename;
    }

    SourceBuffer getSourceBuffer()
    {
        return buff;
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

const dedit.moduleinterface.ModuleInformation ModuleInformation = {
    moduleName: "D", supportedExtensions: [".d"], createDataBufferForURI: function ModuleDataBuffer(
            Controller c, EditorWindow w, string uri) {
        return new Buffer(c, w, uri);
    },};
