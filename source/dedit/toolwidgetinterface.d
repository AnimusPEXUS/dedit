module dedit.toolwidgetinterface;

import gtk.Widget;

import dedit.Controller;

struct ToolWidgetInformation
{
    string name;
    string displayName;
    ToolWidgetInterface function(Controller c) createWidget;
}

interface ToolWidgetInterface
{
    ToolWidgetInformation* getToolWidgetInformation(); // TODO: ToolWidgetInformation must be unmodifiable
    void setProject(string name);
    Widget getWidget();
    Exception destroy();
}
