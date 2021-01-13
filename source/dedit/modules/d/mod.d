module dedit.modules.d.mod;

import std.path;
import std.algorithm;

import gtk.TextBuffer;
import gtk.TextView;
import gtk.TextTagTable;
import gtk.Menu;
import gtk.Widget;

import gsv.SourceView;
import gsv.SourceBuffer;

import dedit.moduleinterface;
import dedit.Controller;
import dedit.EditorWindow;

class View : ModuleBufferView
{
    private
    {
        Controller c;
        EditorWindow w;
        ModuleDataBuffer b;

        SourceView sv;
        SourceBuffer sb;

        bool close_already_called;
    }

    this(Controller c, EditorWindow w, ModuleDataBuffer b)
    {
        this.c = c;
        this.w = w;
        this.b = b;

        /* sb = new SourceBuffer(cast(GtkSourceBuffer*) null); */
        sv = new SourceView(sb);
    }

    Widget getWidget()
    {
        return sv;
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
        TextBuffer textBuffer;
        string filename;
    }

    this(Controller c, EditorWindow w, string uri)
    {
        // TODO: better uri handling required

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

        textBuffer = new TextBuffer(cast(TextTagTable) null);
        textBuffer.setText(cast(string) buff.idup);
    }

    string getFileName()
    {
        return filename;
    }

    TextBuffer getTextBuffer()
    {
        return textBuffer;
    }

    ModuleBufferView createView(Controller c, EditorWindow w, ModuleDataBuffer b)
    {
        return new View(c, w, b);
    }

}

const dedit.moduleinterface.ModuleInformation ModuleInformation = {
    moduleName: "D", supportedExtensions: [".d"], createDataBufferForURI: function ModuleDataBuffer(
            Controller c, EditorWindow w, string uri) {
        return new Buffer(c, w, uri);
    },};
