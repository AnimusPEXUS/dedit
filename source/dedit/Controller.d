module dedit.Controller;

import std.json;
import std.file;
import std.path;
import std.stdio;
import std.typecons;

import gtk.Application;
import gio.Application;

import gtk.Widget;
import gtk.Window;
import gtk.ListStore;
import gtk.TreeIter;
import gobject.Value;

import dedit.ProjectWindow;
import dedit.ViewWindow;
import dedit.ProjectsWindow;
import dedit.FileController;
import dedit.moduleinterface;

import dedit.builtinmodules;
import dedit.builtintoolwidgets;

class Controller
{

    string settingsPath;

    string[string] project_paths;

    ProjectWindow[] project_windows;
    ViewWindow[] view_windows;

    FileController[] file_controllers;

    // TODO: leaving this for a future. for now, I'll will not implement buffer reusage.
    //       maybe in future..
    // ModuleDataBuffer[string] buffers;

    // ViewWindowSettings[string] window_settings;

    ProjectsWindow projects_window;
    JSONValue projects_window_settings;
    // string font;

    ListStore tool_widget_combobox_item_list;

    JSONValue settings;

    int main(string[] args)
    {
        settingsPath = expandTilde("~/.config/dedit/settings.json");

        tool_widget_combobox_item_list = new ListStore(cast(GType[])[
                GType.STRING, GType.STRING
                ]);

        {
            auto ti = new TreeIter;
            tool_widget_combobox_item_list.append(ti);
            tool_widget_combobox_item_list.setValue(ti, 0, new Value(""));
            tool_widget_combobox_item_list.setValue(ti, 1, new Value("(not selected)"));
        }

        foreach (i, v; builtinToolWidgets)
        {
            auto ti = new TreeIter;
            tool_widget_combobox_item_list.append(ti);
            tool_widget_combobox_item_list.setValue(ti, 0, new Value(v.name));
            tool_widget_combobox_item_list.setValue(ti, 1, new Value(v.displayName));
        }

        loadSettings();

        auto app = new gtk.Application.Application(null,
                gio.Application.GApplicationFlags.FLAGS_NONE);

        app.addOnActivate(delegate void(gio.Application.Application gioapp) {

            projects_window = new ProjectsWindow(this);

            /* auto w = createNewCleanWindow(); */

            auto widget = projects_window.getWindow();
            auto window = cast(Window) widget;

            window.showAll();

            app.addWindow(window);
        });

        return app.run(args);
    }

    Exception saveSettings()
    {

        string j = settings.toJSON(true);

        try
        {
            mkdir(dirName(settingsPath));
        }
        catch (Exception)
        {
            // NOTE: not an error
            return cast(Exception) null;
        }

        try
        {
            File of = File(settingsPath, "w");
            of.rawWrite(j);
        }
        catch (Exception e)
        {
            return e;
        }
        return cast(Exception) null;
    }

    Exception loadSettings()
    {
        try
        {
            if (isFile(settingsPath))
            {
                auto f = File(settingsPath);
                char[] buf;
                buf.length = f.size;
                string data = cast(string) f.rawRead(buf);

                settings = parseJSON(data);
                settings = sanitizeSettings(settings);
            }
        }
        catch (Exception e)
        {
            return e;
        }
        return cast(Exception) null;
    }

    JSONValue sanitizeSettings(JSONValue settings)
    {

        if (settings.type() != JSONType.object)
        {
            settings = JSONValue(cast(JSONValue[string]) null);
        }

        if ("font" !in settings)
        {
            settings["font"] = "Go Mono 10";
        }

        foreach (size_t index, v; [
                "projects", "projects_windows_settings", "view_windows_settings", "tool_window_settings"
            ])
        {
            if (v !in settings || settings[v].type() != JSONType.object)
            {
                settings[v] = JSONValue(cast(JSONValue[string]) null);
            }
        }

        // TODO: make garbage removal

        return settings;
    }

    Tuple!(string, Exception) getProjectPath(string name)
    {
        string ret;
        try
        {
            ret = settings["projects"][name].str();
        }
        catch (Exception e)
        {
            return tuple("", e);
        }
        return tuple(ret, cast(Exception) null);
    }

    Tuple!(JSONValue, Exception) getProjectWindowSettings(string name)
    {
        JSONValue ret;
        try
        {
            ret = settings["projects_windows_settings"][name];
        }
        catch (Exception e)
        {
            return tuple(JSONValue(null), e);
        }
        return tuple(ret, cast(Exception) null);
    }

    void setProjectWindowSettings(string name, JSONValue value)
    {
        settings = sanitizeSettings(settings);
        debug
        {
            writeln("saving settings for project window:", name);
            writeln("  settings:", value);
        }
        settings["projects_windows_settings"][name] = value;
        return;
    }

    ProjectWindow createNewProjectWindow(string project)
    {
        return new ProjectWindow(this, project);
    }

    ProjectWindow createNewOrGetExistingProjectWindow(string project)
    {
        ProjectWindow ret;
        foreach (size_t index, w; project_windows)
        {
            if (w.project == project)
            {
                ret = w;
                break;
            }
        }
        if (ret is null)
        {
            ret = createNewProjectWindow(project);
        }
        return ret;
    }

    Exception setToolWindowSettings(JSONValue value) {
        return cast(Exception) null;
    }

    Tuple!(JSONValue, Exception) getToolWindowSettings(string window_uuid) {
        return tuple(cast(JSONValue) null, cast(Exception) null);
    }

    Exception delToolWindowSettings(string window_uuid) {
        return cast(Exception) null;
    }

    void openNewView(string project, string filename, string uri)
    {
        ViewWindowContentSetup y = {
            view_module_auto: true, view_module_auto_mode: ViewModuleAutoMode.BY_EXTENSION,
            project: project, filename: filename};

            ViewWindowSettings x = {controller: this, setup: &y
        };

        ViewWindowSettings* options = &x;

        auto w = new ViewWindow(options);

        w.show();
    }

    Tuple!(FileController, Exception) getOrCreateFileController(string project,
            string filename, bool create_if_absent = true,)
    {
        auto new_object = new FileController(this, project, filename);

        auto res = new_object.getFilename();
        if (res[1]!is null)
        {
            return tuple(cast(FileController) null, res[1]);
        }

        FileController ret;

        foreach (k, FileController v; file_controllers)
        {
            auto res2 = v.getFilename();
            if (res2[1]!is null)
            {
                // ignorring faulty object
                continue;
            }

            if (res2[0] == res[0])
            {
                ret = v;
                break;
            }
        }

        if (ret is null && create_if_absent)
        {
            ret = new_object;
            file_controllers ~= new_object;
        }

        return tuple(ret, cast(Exception) null);
    }

    Tuple!(ModuleFileController, Exception) createModuleFileController(
            FileController file_controller)
    {
        assert(file_controller !is null);

        auto m = determineModuleByFileExtension(file_controller.settings.filename);
        if (m[1]!is null)
        {
            return tuple(cast(ModuleFileController) null, m[1]);
        }

        if (m[0].length == 0)
        {
            return tuple(cast(ModuleFileController) null,
                    new Exception("couldn't determine module for file"));
        }

        auto minfo = getModuleInformation(m[0][0]); // TODO: todo

        if (minfo is null)
        {
            return tuple(cast(ModuleFileController) null,
                    new Exception("couldn't get module information"));
        }

        auto ret = minfo.createModuleController(this, file_controller);

        return tuple(ret, cast(Exception) null);
    }
    /*
      void openNewViewOrExisting(string cr)
     {

         ViewWindowContentSetup* y = {
             view_module_auto: true,
            view_mode_auto_mode: ViewModuleAutoMode.BY_EXTENSION,
            file_mode: ViewWindowMode.PROJECT_FILE,
            project: project,
            filename: cr
        };

        ViewWindowSettings x = {controller: controller,
        setup: &y};

        ViewWindowSettings* options = &x;

        auto w = new ViewWindow(options);

        w.show();
    }
    */

}
