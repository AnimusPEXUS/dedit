module dedit.ToolWidget;

import core.sync.mutex;

import std.stdio;
import std.typecons;
import std.json;

import dlangui;

import dedit.Controller;
import dedit.ToolWindow;

import dedit.toolwidgetinterface;
import dedit.builtintoolwidgets;

class ToolWidget
{

    Controller controller;
    ToolWindow tool_window;

    private string _project;
    @property string project()
    {
        return _project;
    };
    @property void project(string value)
    {
        _project = value;
        updateToolWindowTitle();
    };

    VerticalLayout main_box;

    HorizontalLayout tools_box;
    VerticalLayout children_box;

    ComboBox tool_selection_cb;

    ToolWidgetInterface current_tool_widget;

    this(Controller controller, ToolWindow tool_window)
    {
        this.controller = controller;
        this.tool_window = tool_window;

        main_box = new VerticalLayout;
        tools_box = new HorizontalLayout;
        children_box = new VerticalLayout;

        main_box.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);

        main_box.addChild(tools_box);
        main_box.addChild(children_box);

        tools_box.layoutWidth(FILL_PARENT);
        children_box.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);

        tool_selection_cb = new ComboBox("", controller.tool_widget_combobox_item_list_titles);
        tool_selection_cb.layoutWidth(FILL_PARENT);

        tools_box.addChild(tool_selection_cb);

        tool_selection_cb.itemClick = delegate bool(Widget wi, int index) {
            auto id = controller.tool_widget_combobox_item_list[index];

            writeln("itemSelected " ~ to!string(index) ~ ":" ~ id);
            selectTool(id);
            return true;
        };

        selectTool("");
        main_box.invalidate();
    }

    Widget getWidget()
    {
        return main_box;
    }

    void updateToolWindowTitle()
    {
        tool_window.window.windowCaption = to!dstring((current_tool_widget is null
                ? "Empty Tool Window" : current_tool_widget.getToolWidgetInformation()
                .displayName) ~ " (project: " ~ project ~ ")");
    }

    Exception unselectTool()
    {
        return selectTool("");
    }

    Exception selectTool(string name)
    {

        writeln("selectTool: " ~ name);

        if (current_tool_widget !is null)
        {
            current_tool_widget.destroy();
            current_tool_widget = null;
            children_box.removeAllChildren();
        }

        if (children_box.childCount == 0)
        {
            children_box.addChild(new TextWidget().text("Select Tool"d)
                    .layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT));
        }

        if (name != "")
        {
            auto twi = getToolWidgetInformation(name);
            assert(twi !is null);
            auto tw = twi.createToolWidget(controller);
            assert(tw !is null);
            auto w = tw.getWidget();
            assert(w !is null);
            // assert(children_box.childCount == 0);
            /* children_box.packStart(w, true, true, 0); */
            children_box.removeAllChildren();
            children_box.addChild(w);
            w.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
            /* w.showAll(); */
            current_tool_widget = tw;
            current_tool_widget.setProject(project);
        }

        foreach (size_t i, string v; controller.tool_widget_combobox_item_list)
        {
            if (v == name)
            {
                tool_selection_cb.selectedItemIndex = cast(int) i;
                break;
            }
        }

        updateToolWindowTitle();

        return cast(Exception) null;
    }

    Tuple!(string, Exception) getTool()
    {
        string ret = current_tool_widget is null ? "" : current_tool_widget.getToolWidgetInformation()
            .name;

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
