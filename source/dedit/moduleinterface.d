module dedit.moduleinterface;

import gtk.Widget;
import gtk.TextBuffer;
import gtk.Menu;

import dedit.Buffer;
import dedit.Controller;
import dedit.EditorWindow;

struct ModuleInformation
{
    string ModuleName;
    string[] SupportedExtensions;
    string[] SupportedMIMETypes;
    ModuleBufferView function(Controller c, EditorWindow w, Buffer b) createViewForBuffer;
    Menu createMenuForBuffer(Buffer buff);
}

interface ModuleBufferView
{
    Widget getWidget();
    void close();
}
