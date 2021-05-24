module dedit.ToolWidget;

import core.sync.mutex;

import std.typecons;
import std.json;

import dlangui;

import dedit.Controller;
import dedit.toolwidgetinterface;
import dedit.builtintoolwidgets;

class ToolWidget
{

    Controller controller;

    string project;

    VerticalLayout main_box;

    HorizontalLayout tools_box;
    VerticalLayout children_box;

    ComboBox tool_selection_cb;

    ToolWidgetInterface current_tool_widget;

    this(Controller controller)
    {
        this.controller = controller;

        main_box = new VerticalLayout;
        tools_box = new HorizontalLayout;
        children_box = new VerticalLayout;

        main_box.addChild(tools_box);
        main_box.addChild(children_box);

        tools_box.layoutWidth(FILL_PARENT);
        children_box.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);

        /* main_box.packStart(tools_box, false, true, 0);
        main_box.packStart(children_box, true, true, 0); */

        tool_selection_cb = new ComboBox("", controller.tool_widget_combobox_item_list);
        tool_selection_cb.layoutWidth(FILL_PARENT);
        /* tool_selection_cb.setIdColumn(0); */

        /* {
            auto cr = new CellRendererText();
            tool_selection_cb.packStart(cr, true);
            tool_selection_cb.addAttribute(cr, "text", 1);
        } */

        tools_box.addChild(tool_selection_cb);
        /* tools_box.packStart(tool_selection_cb, false, false, 0); */

        /* tool_selection_cb.addOnChanged(delegate void(ComboBox cb) {
            auto id = cb.getActiveId();

            if (current_tool_widget !is null)
            {
                current_tool_widget.destroy;
                current_tool_widget = null;
            }

            if (id != "")
            {
                auto twi = getToolWidgetInformation(id);
                assert(twi !is null);
                auto tw = twi.createToolWidget(controller);
                assert(tw !is null);
                auto w = tw.getWidget();
                assert(w !is null);
                assert(children_box.children.length == 0);
                children_box.packStart(w, true, true, 0);
                w.showAll();
                current_tool_widget = tw;
                current_tool_widget.setProject(project);
            }
        });
        tool_selection_cb.setActiveId(""); */
    }

    Widget getWidget()
    {
        return main_box;
    }

    Exception unselectTool()
    {
        try
        {
            /* tool_selection_cb.setActiveId(""); */
        }
        catch (Exception e)
        {
            return e;
        }
        return cast(Exception) null;
    }

    Exception selectTool(string name)
    {

        try
        {
            /* tool_selection_cb.setActiveId(name); */
        }
        catch (Exception e)
        {
            return e;
        }

        return cast(Exception) null;
    }

    Tuple!(string, Exception) getTool()
    {
        string ret;
        try
        {
            /* ret = tool_selection_cb.getActiveId(); */
        }
        catch (Exception e)
        {
            return tuple("", e);
        }

        return tuple(ret, cast(Exception) null);
    }

    void setProject(string name)
    {
        project = name;
        if (current_tool_widget !is null)
        {
            current_tool_widget.setProject(name);
        }
    }

    string getProject()
    {
        return project;
    }

    Tuple!(JSONValue, Exception) getSettings()
    {
        return current_tool_widget.getSettings();
    }

    Exception setSettings(JSONValue v)
    {
        return current_tool_widget.setSettings(v);
    }

    Exception destroy()
    {
        unselectTool();
        main_box.destroy();
        return cast(Exception) null;
    }

}
