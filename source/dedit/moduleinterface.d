module dedit.moduleinterface;

import std.json;

import dlangui;

import dedit.Controller;
import dedit.ViewWindow;

struct ModuleInformation
{
    string name;
    string[] supportedExtensions; // must start with point
    string[] supportedMIMETypes;
    ModuleController function(Controller c) createModuleController;
}

interface ModuleController
{
    ModuleInformation* getModInfo(); // TODO: ModuleInformation must be unmodifiable

    Controller getController();

    ModuleControllerBuffer getBuffer();
    ModuleControllerMainMenu getMainMenu();
    ModuleControllerView getView();

    Exception loadData(string project, string filename);
    Exception saveData(string project, string filename);

    void destroy();
}

interface ModuleControllerBuffer
{
    ModuleController getModuleController();
}

interface ModuleControllerMainMenu
{
    ModuleController getModuleController();

    // ref ModuleInformation getModInfo()  ;
    MenuItem getWidget();
    /* void installAccelerators(AccelGroup ag, bool uninstall = false);
    void uninstallAccelerators(AccelGroup ag); */
}

interface ModuleControllerView
{
    ModuleController getModuleController();

    //ref const ModuleInformation getModInfo();
    Widget getWidget();
    JSONValue getSettings();
    void setSettings(JSONValue value);
}
