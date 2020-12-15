module dedit.BufferControlsInterface;

import gtk.Menu;
import gtk.Widget;

import dedit.Buffer;

interface BufferControlsInterface {
    // TODO: may be use ref attributes for returned objects
    string getName();
    Buffer getBuffer();
    Widget getBufferView();
    Widget getMainMenu();
    Widget getViewMenu();
    /* void close(); // TODO: possibly this is not needed and object can be GCed */
};
