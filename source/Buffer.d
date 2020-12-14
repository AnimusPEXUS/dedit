module dedit.Buffer;

import std.stdio;

import gtk.TextBuffer;
import gtk.TextTagTable;

class Buffer {

    private TextBuffer textBuffer;
    private string originalFileName;

    public this(string filename) {

          auto f = new std.stdio.File(filename);

          char[] buff;
          buff.length = f.size;

          f.rawRead(buff);

          textBuffer = new TextBuffer(cast(TextTagTable)null);
          textBuffer.setText(cast(string)buff.idup);
    };

    gtk.Menu.Menu getMenuWidget() {
        return null;
    };

    gtk.Widget.Widget getMainWidget() {
        return null;
    };

        void close() {};
}
