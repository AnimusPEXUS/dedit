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
    /* void function(ModuleDataBuffer b, string uri) saveBufferToURI; */
    /* ModuleBufferView function(Controller c, EditorWindow w, ModuleDataBuffer b) createView; */
    /* Menu createMenuForBuffer(Buffer buff); */
}

interface ModuleBufferMainMenu
{
    // ref ModuleInformation getModInfo()  ;
    Menu getWidget();
}

interface ModuleBufferView
{
    ref const ModuleInformation getModInfo();
    Widget getWidget();
    ModuleBufferMainMenu getMainMenu(); // each view must have own main menu attached to language mode
    string getSettings();
    void setSettings(string value);
    void close();
}

interface ModuleDataBuffer
{
    // ref const ModuleInformation getModInfo();
    ModuleBufferView createView();
    void save(string uri);
    void close();
}
