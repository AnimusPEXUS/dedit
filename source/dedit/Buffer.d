module dedit.Buffer;

import std.stdio;

import gtk.TextBuffer;
import gtk.TextTagTable;

class Buffer
{

    private
    {
        TextBuffer textBuffer;
        string originalFileName;

    }

    this(string filename)
    {

        auto f = new std.stdio.File(filename);

        char[] buff;
        buff.length = f.size;

        f.rawRead(buff);

        textBuffer = new TextBuffer(cast(TextTagTable) null);
        textBuffer.setText(cast(string) buff.idup);
    };

    TextBuffer getTextBuffer()
    {
        return textBuffer;
    }

    void close()
    {
    };
}
