module dedit.builtintoolwidgets;

import dedit.toolwidgetinterface;

import dedit.ToolProjectFilesWidget;

/* import dedit.ToolProjectFilesWidgetInformation; */

static const dedit.toolwidgetinterface.ToolWidgetInformation[] builtinToolWidgets
    = [dedit.ToolProjectFilesWidget.ToolProjectFilesWidgetInformation,];

dedit.toolwidgetinterface.ToolWidgetInformation* getToolWidgetInformation(string name)
{
    foreach (size_t index, const ref m; builtinToolWidgets)
    {
        if (m.name == name)
        {
            return cast(dedit.toolwidgetinterface.ToolWidgetInformation*)&m;
        }
    }
    return null;
}
