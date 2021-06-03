module dedit.ToolProjectFilesWidget;

import std.stdio;
import std.typecons;
import std.json;

import dlangui;

import dutils.dlanguicollection.FileTreeView;

import dedit.Controller;
import dedit.toolwidgetinterface;

const dedit.toolwidgetinterface.ToolWidgetInformation ToolProjectFilesWidgetInformation = {
    name: "projectfiles", displayName: "Files", createToolWidget: function ToolWidgetInterface(
            Controller c) {
        debug
        {
            writeln("ToolProjectFilesWidgetInformation createToolWidget()");
        }
        auto tpfw = new ToolProjectFilesWidget(c);
        /* return cast(dedit.toolwidgetinterface.ToolWidgetInformation)tpfw; */
        /* auto tpfwi = cast(dedit.toolwidgetinterface.ToolWidgetInterface)tpfw; */
        assert(tpfw !is null);
        return tpfw;
    }};

    class ToolProjectFilesWidget : ToolWidgetInterface
    {

        Controller controller;

        string project;

        VerticalLayout main_box;

        FileTreeView filebrowser;

        this(Controller controller)
        {
            this.controller = controller;

            main_box = new VerticalLayout();
            main_box.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);

            filebrowser = new FileTreeView();
            filebrowser.itemActivated = &itemActivated;
            auto w = filebrowser.getWidget();
            w.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
            main_box.addChild(w);
            /* filebrowser.addOnRowActivated(&onFileListViewActivated); */

            /* auto filebrowser_widget = filebrowser.getWidget(); */

            /* main_box.packStart(filebrowser_widget, true, true, 0); */
        }

        void itemActivated(TreeItem ti)
        {
            if (filebrowser.isDir(ti))
            {
                filebrowser.loadByTreeItem(ti);
                filebrowser.expandByTreeItem(ti);
            }
            else
            {
                auto filename = filebrowser.convertTreeItemToFilePath(ti);
                debug
                {
                    writeln("filebrowser.convertTreeItemToFilePath returned path ", filename);
                }
                // TODO: openNewViewOrExisting or openNewView?
                this.controller.openNewViewOrExisting(this.project, filename);
            }
        }

        ToolWidgetInformation* getToolWidgetInformation()
        {
            return cast(ToolWidgetInformation*)&ToolProjectFilesWidgetInformation;
        }

        Exception setProject(string name)
        {
            this.project = name;
            auto pth = controller.getProjectPath(name);
            if (pth[1]!is null)
            {
                return pth[1];
            }

            filebrowser.setRootDirectory(pth[0]);

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
        }

    }
