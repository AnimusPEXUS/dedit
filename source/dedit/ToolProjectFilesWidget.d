module dedit.ToolProjectFilesWidget;

import gtk.TreePath;
import gtk.TreeViewColumn;
import gtk.TreeView;

import dutils.gtkcollection.FileTreeView;

import dedit.Controller;
import dedit.toolwidgetinterface;

const dedit.toolwidgetinterface.ToolWidgetInformation ToolProjectFilesWidgetInformation = {
    name: "projectfiles", displayName: "Project Files", createWidget: function dedit
        .toolwidgetinterface.ToolWidgetInterface(Controller c) {
        auto tpfw = new ToolProjectFilesWidget(c);
        /* return cast(dedit.toolwidgetinterface.ToolWidgetInformation)tpfw; */
        /* auto tpfwi = cast(dedit.toolwidgetinterface.ToolWidgetInterface)tpfw; */
        return cast(dedit.toolwidgetinterface.ToolWidgetInterface) tpfw;
    }};

    class ToolProjectFilesWidget
    {

        Controller controller;

        string project;

        FileTreeView filebrowser;

        this(Controller controller)
        {
            this.controller = controller;
        }

        void onFileListViewActivated(TreePath tp, TreeViewColumn tvc, TreeView tv)
        {

            if (filebrowser.isDir(tp))
            {
                filebrowser.loadByTreePath(tp);
                filebrowser.expandByTreePath(tp);
            }
            else
            {
                auto filename = filebrowser.convertTreePathToFilePath(tp);
                this.controller.openNewView(this.project, filename, "");
            }
        }

        ToolWidgetInformation* getToolWidgetInformation()
        {
            return cast(ToolWidgetInformation*)&ToolProjectFilesWidgetInformation;
        }

        void setProject(string name)
        {
            this.project = name;
            // TODO: more to do
        }

        Exception destroy()
        {
            return cast(Exception) null;
        }

    }

    /* filebrowser = new FileTreeView();
filebrowser.addOnRowActivated(&onFileListViewActivated); */

    //         auto filebrowser_widget = filebrowser.getWidget();
