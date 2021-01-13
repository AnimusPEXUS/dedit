module dedit.moduleinterface;

import gtk.Widget;
import gtk.TextBuffer;
import gtk.Menu;

import dedit.Controller;
import dedit.EditorWindow;

struct ModuleInformation
{
    string moduleName;
    string specialMenuName;
    string[] supportedExtensions;
    string[] supportedMIMETypes;
    ModuleDataBuffer function(Controller c, EditorWindow w, string uri) createDataBufferForURI;
    /* ModuleBufferView function(Controller c, EditorWindow w, ModuleDataBuffer b) createView; */
    /* Menu createMenuForBuffer(Buffer buff); */
}

interface ModuleBufferView
{
    Widget getWidget();
    void close();
}

interface ModuleDataBuffer
{
    ModuleBufferView createView(ModuleDataBuffer b = null, EditorWindow w = null, Controller c = null);
}
