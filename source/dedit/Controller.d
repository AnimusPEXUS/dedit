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

class Controller
{

    string settingsPath;

    string[string] project_paths;

    ProjectWindow[] project_windows;
    ViewWindow[] view_windows;

    // TODO: leaving this for a future. for now, I'll will not implement buffer reusage.
    //       maybe in future..
    // ModuleDataBuffer[string] buffers;

    // ViewWindowSettings[string] window_settings;

    ProjectsWindow projects_window;
    JSONValue projects_window_settings;
    string font;

    JSONValue settings;

    int main(string[] args)
    {
        settingsPath = expandTilde("~/.config/dedit/settings.json");

        loadSettings();

        auto app = new gtk.Application.Application(
                null,
                gio.Application.GApplicationFlags.FLAGS_NONE
        );

        app.addOnActivate(
                delegate void(gio.Application.Application gioapp) {

            projects_window = new ProjectsWindow(this);

            /* auto w = createNewCleanWindow(); */

            auto widget = projects_window.getWindow();
            auto window = cast(Window) widget;

            window.showAll();

            app.addWindow(window);
        }
        );

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

    ProjectWindow createNewProjectWindow(string project_name)
    {
        return new ProjectWindow(this, project_name);
    }

    ProjectWindow createNewOrGetExistingProjectWindow(string project_name)
    {
        ProjectWindow ret;
        foreach (size_t index, w; project_windows)
        {
            if (w.project_name == project_name)
            {
                ret = w;
                break;
            }
        }
        if (ret is null)
        {
            ret = createNewProjectWindow(project_name);
            project_windows ~= ret;
        }
        return ret;
    }

    /*
    void editorWindowIsClosed(string project_name)
    {
        if (project_name in windows)
        {
            windows.remove(project_name);
        }
    }
    */


}
