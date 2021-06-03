module dedit.ToolProjectViewsWidget;

import std.stdio;
import std.typecons;
import std.json;

import dlangui;

import dutils.dlanguicollection.FileTreeView;

import dedit.Controller;
import dedit.ViewWindow;

import dedit.toolwidgetinterface;

const dedit.toolwidgetinterface.ToolWidgetInformation ToolProjectViewsWidgetInformation = {
    name: "projectviews", displayName: "Views", createToolWidget: function ToolWidgetInterface(
            Controller c) {
        debug
        {
            writeln("ToolProjectFilesWidgetInformation createToolWidget()");
        }
        auto tpfw = new ToolProjectViewsWidget(c);
        /* return cast(dedit.toolwidgetinterface.ToolWidgetInformation)tpfw; */
        /* auto tpfwi = cast(dedit.toolwidgetinterface.ToolWidgetInterface)tpfw; */
        assert(tpfw !is null);
        return tpfw;
    }};

    class ToolProjectViewsWidget : ToolWidgetInterface
    {

        Controller controller;

        string project;

        VerticalLayout main_box;

        StringListWidget list;
        StringListAdapter list_adapter;

        this(Controller controller)
        {
            this.controller = controller;

            main_box = new VerticalLayout();
            main_box.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);

            list = new StringListWidget();
            list.itemClick = &itemClick;
            list.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
            main_box.addChild(list);

            list_adapter = new StringListAdapter;
            list.ownAdapter = list_adapter;

            controller.view_windows.addChangeListener(&onViewListChange);
        }

        void onViewListChange(bool is_add, ViewWindow win)
        {
            if (win.project != project)
            {
                return;
            }

            auto win_filename = to!dstring(win.filename);

            if (is_add)
            {

                for (size_t i = 0; i != list_adapter.items.length; i++)
                {
                    if (list_adapter.items[i] == win_filename)
                    {
                        return;
                    }
                }
                list_adapter.add(win_filename);
            }
            else
            {
                for (size_t i = list_adapter.items.length - 1; i != -1; i = i - 1)
                {
                    if (list_adapter.items[i] == win_filename)
                    {
                        list_adapter.remove(cast(int) i);
                    }
                }
            }
        }

        void reLoadList()
        {
            dstring[] complete_list;
            controller.view_windows.listItems(delegate void(ViewWindow w) {
                if (w.project == project)
                {
                    complete_list ~= to!dstring(w.filename);
                }
            });
            debug
            {
                writeln("complete_list:");
                foreach (dstring d; complete_list)
                {
                    writeln(d);
                }
            }
            foreach (size_t i, dstring w; complete_list)
            {
                auto found = false;
                for (size_t j = 0; j != list_adapter.items.length; j++)
                {
                    if (w == list_adapter.items[j])
                    {
                        found = true;
                        break;
                    }
                }
                if (!found)
                {
                    list_adapter.add(w);
                }
            }

            for (size_t i = list_adapter.items.length - 1; i != -1; i = i - 1)
            {
                auto found = false;
                foreach (dstring w; complete_list)
                {
                    if (w == list_adapter.items[i])
                    {
                        found = true;
                        break;
                    }
                }
                if (!found)
                {
                    list_adapter.remove(cast(int) i);
                }
            }
        }

        bool itemClick(Widget source, int itemIndex)
        {
            debug
            {
                writeln("itemClick");
            }
            return true;
        }

        ToolWidgetInformation* getToolWidgetInformation()
        {
            return cast(ToolWidgetInformation*)&ToolProjectViewsWidgetInformation;
        }

        Exception setProject(string name)
        {
            this.project = name;

            reLoadList();

            return cast(Exception) null;
        }

        string getProject()
        {
            return project;
        }

        Widget getWidget()
        {
            return main_box;
        }

        Tuple!(JSONValue, Exception) getSettings()
        {
            auto ret = JSONValue(cast(JSONValue[string]) null);
            ret["project"] = project;
            return tuple(ret, cast(Exception) null);
        }

        Exception setSettings(JSONValue v)
        {
            if ("project" in v)
            {
                setProject(v["project"].str());
            }
            return cast(Exception) null;
        }

        void destroy()
        {
            controller.view_windows.removeChangeListener(&onViewListChange);
            list_adapter = null;
            list.destroy();
            list = null;
        }

    }
