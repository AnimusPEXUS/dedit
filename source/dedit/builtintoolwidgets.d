module dedit.builtintoolwidgets;

import dedit.toolwidgetinterface;

import dedit.ToolProjectFilesWidget;
import dedit.ToolProjectViewsWidget;

/* import dedit.ToolProjectFilesWidgetInformation; */

static const dedit.toolwidgetinterface.ToolWidgetInformation[] builtinToolWidgets
    = [
        dedit.ToolProjectFilesWidget.ToolProjectFilesWidgetInformation,
        dedit.ToolProjectViewsWidget.ToolProjectViewsWidgetInformation
    ];

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
