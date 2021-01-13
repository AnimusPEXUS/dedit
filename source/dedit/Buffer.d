module dedit.Buffer;

import std.stdio;
import std.path;

import gtk.TextBuffer;
import gtk.TextTagTable;

class Buffer
{

    private
    {
        TextBuffer textBuffer;
        string filename;
    }

    this(string filename)
    {
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

    /* void close()
    {
        textBuffer.destroy();
    } */
}
