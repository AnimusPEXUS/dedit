module dedit.moduleinterface;

import std.json;

import dlangui;

import dedit.Controller;
import dedit.ViewWindow;

struct ModuleInformation
{
    string name;
    string menuName;
    string titleName;
    string[] supportedExtensions; // must start with point
    string[] supportedMIMETypes;
    ModuleController function(Controller c) createModuleController;
}

interface ModuleController
{
    ModuleInformation* getModInfo(); // TODO: ModuleInformation must be unmodifiable

    void setViewWindow(ViewWindow window);

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

    MainMenu getWidget();
    ActionPair[] getActionPairList();
}

interface ModuleControllerView
{
    ModuleController getModuleController();

    Widget getWidget();
    JSONValue getSettings();
    void setSettings(JSONValue value);
}
