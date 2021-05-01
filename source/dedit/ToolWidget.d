module dedit.ToolWidget;

import core.sync.mutex;

import std.typecons;
import std.json;

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

        tool_selection_cb.addOnChanged(delegate void(ComboBox cb) {
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
    }

    Box getWidget()
    {
        return main_box;
    }

    Exception unselectTool()
    {
        try
        {
            tool_selection_cb.setActiveId("");
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
            tool_selection_cb.setActiveId(name);
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
            ret = tool_selection_cb.getActiveId();
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
