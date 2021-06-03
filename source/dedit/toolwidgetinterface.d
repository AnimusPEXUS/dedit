module dedit.toolwidgetinterface;

import std.json;
import std.typecons;

import dlangui;

import dedit.Controller;

struct ToolWidgetInformation
{
    string name;
    string displayName;
    ToolWidgetInterface function(Controller c) createToolWidget;
}

interface ToolWidgetInterface
{
    ToolWidgetInformation* getToolWidgetInformation(); // TODO: ToolWidgetInformation must be unmodifiable
    Exception setProject(string name);
    string getProject();
    Widget getWidget();
    Tuple!(JSONValue, Exception) getSettings();
    Exception setSettings(JSONValue);
    void destroy(); // so widget could unbind it self from signals
}
