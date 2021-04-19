module dedit.moduleinterface;

import std.json;

import gtk.Widget;
import gtk.TextBuffer;
import gtk.Menu;
import gtk.AccelGroup;

import dedit.Controller;
import dedit.FileController;
import dedit.ViewWindow;

struct ModuleInformation
{
    string moduleName;
    /* string specialMenuName; */
    string[] supportedExtensions; // must start with point
    string[] supportedMIMETypes;
    ModuleFileController function(Controller c, FileController file_controller) createModuleController;
}

interface ModuleFileController
{
    ModuleInformation* getModInfo(); // TODO: ModuleInformation must be unmodifiable

    Controller getController();
    FileController getFileController();

    ModuleControllerBuffer getBuffer();
    ModuleControllerMainMenu getMainMenu();
    ModuleControllerView getView();

    Exception loadData();
    Exception saveData();

    string getProject();
    string getFilename();
    void setFilename(string filename);

    void close();
}

interface ModuleControllerBuffer
{
    ModuleFileController getModuleFileController();
}

interface ModuleControllerMainMenu
{
    ModuleFileController getModuleFileController();

    // ref ModuleInformation getModInfo()  ;
    Menu getWidget();
    void installAccelerators(AccelGroup ag, bool uninstall = false);
    void uninstallAccelerators(AccelGroup ag);
}

interface ModuleControllerView
{
    ModuleFileController getModuleFileController();

    //ref const ModuleInformation getModInfo();
    Widget getWidget();
    JSONValue getSettings();
    void setSettings(JSONValue value);
}
