module dedit.ToolWidget;

import gtk.Box;
import gtk.ComboBox;
import gtk.CellRendererText;

import dedit.Controller;
import dedit.toolwidgetinterface;
import dedit.builtintoolwidgets;

class ToolWidget
{

    Controller controller;

    string project;

    Box main_box;
    Box tools_box;
    Box children_box;

    ComboBox tool_selection_cb;

    ToolWidgetInterface current_tool_widget;

    this(Controller controller)
    {
        this.controller = controller;

        main_box = new Box(GtkOrientation.VERTICAL, 0);
        tools_box = new Box(GtkOrientation.HORIZONTAL, 0);
        children_box = new Box(GtkOrientation.VERTICAL, 0);

        main_box.packStart(tools_box, false, true, 0);
        main_box.packStart(children_box, true, true, 0);

        tool_selection_cb = new ComboBox(controller.tool_widget_combobox_item_list, false);
        tool_selection_cb.setIdColumn(0);

        {
            auto cr = new CellRendererText();
            tool_selection_cb.packStart(cr, true);
            tool_selection_cb.addAttribute(cr, "text", 1);
        }

        tools_box.packStart(tool_selection_cb, false, false, 0);
    }

    Box getWidget()
    {
        return main_box;
    }

    Exception unselectTool()
    {
        if (current_tool_widget !is null)
        {
            current_tool_widget.destroy;
            current_tool_widget = null;
        }
        return cast(Exception) null;
    }

    Exception selectTool(string name)
    {
        unselectTool();
        auto tw = getToolWidgetInformation(name);
        auto w = tw.createWidget(controller);
        children_box.packStart(w.getWidget(), true, true, 0);
        current_tool_widget = w;
        current_tool_widget.setProject(project);
        return cast(Exception) null;
    }

    void setProject(string name)
    {
        project = name;
        if (current_tool_widget !is null)
        {
            current_tool_widget.setProject(name);
        }
    }

    Exception destroy()
    {
        unselectTool();
        main_box.destroy();
        return cast(Exception) null;
    }

}
