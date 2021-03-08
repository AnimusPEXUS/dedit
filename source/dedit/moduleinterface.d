module dedit.moduleinterface;

import std.json;

import gtk.Widget;
import gtk.TextBuffer;
import gtk.Menu;

import dedit.Controller;
import dedit.ViewWindow;

struct ModuleInformation
{
    string moduleName;
    string specialMenuName;
    string[] supportedExtensions;
    string[] supportedMIMETypes;
    ModuleDataBuffer function(Controller c, ViewWindow w, string uri) createDataBufferForURI;
    /* void function(ModuleDataBuffer b, string uri) saveBufferToURI; */
    /* ModuleBufferView function(Controller c, EditorWindow w, ModuleDataBuffer b) createView; */
    /* Menu createMenuForBuffer(Buffer buff); */
}

interface ModuleBufferMainMenu
{
    // ref ModuleInformation getModInfo()  ;
    Menu getWidget();
    void installAccelerators(bool uninstall=false);
    void uninstallAccelerators();
}

interface ModuleBufferView
{
    //ref const ModuleInformation getModInfo();    
    ModuleInformation* getModInfo(); // TODO: ModuleInformation must be unmodifiable
    Widget getWidget();
    ModuleBufferMainMenu getMainMenu(); // each view must have own main menu attached to language mode
    ModuleDataBuffer getBuffer();
    JSONValue getSettings();
    void setSettings(JSONValue value);
    void close();
}

interface ModuleDataBuffer
{
    // ref const ModuleInformation getModInfo();
    ModuleBufferView createView();
    void save(string uri);
    void close();
}
