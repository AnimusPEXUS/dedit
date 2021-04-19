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

import dedit.ProjectWindow;
import dedit.ViewWindow;
import dedit.ProjectsWindow;
import dedit.FileController;
import dedit.builtinmodules;
import dedit.moduleinterface;

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

    JSONValue settings;

    int main(string[] args)
    {
        settingsPath = expandTilde("~/.config/dedit/settings.json");

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

    void saveSettings()
    {

        string j = settings.toJSON(true);

        try
        {
            mkdir(dirName(settingsPath));
        }
        catch (Exception)
        {
            return;
        }

        // TODO: display errors
        File of = File(settingsPath, "w");
        of.rawWrite(j);
    }

    void loadSettings()
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

        foreach (size_t index, v; ["projects", "projects_windows_settings"])
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
            project_windows ~= ret;
        }
        return ret;
    }

    void openNewView(string project, string filename, string uri)
    {
        ViewWindowContentSetup y = {
            view_module_auto: true, view_module_auto_mode: ViewModuleAutoMode.BY_EXTENSION,
            project: project, filename: filename, uri: uri,};

            ViewWindowSettings x = {controller: this, setup: &y
        };

        ViewWindowSettings* options = &x;

        auto w = new ViewWindow(options);

        w.show();
    }

    Tuple!(FileController, Exception) getOrCreateFileController(string project,
            string filename, string uri, bool create_if_absent = true,)
    {
        auto new_object = new FileController(this, project, filename, uri);

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
