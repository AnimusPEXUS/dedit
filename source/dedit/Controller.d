module dedit.Controller;

import std.json;
import std.file;
import std.path;
import std.stdio;

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
        font = "Go Mono 10";

        settingsPath = expandTilde("~/.config/dedit/settings.json");

        loadSettings();

        auto app = new gtk.Application.Application("dedit.wayround.i2p",
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
        }
    }
    
    string getProjectPath(string name) 
    {
        if (settings.type() != JSONType.object) 
        {
            throw new Exception("dedit saved settings have invalid structure");
        }
        
        if ("projects" !in settings) 
        {
            throw new Exception("don't have saved projects");
        }
        
        if (name !in settings["projects"])
        {
            throw new Exception("don't know named project's path");
        }
        
        return settings["projects"]["name"].str();
    }

    /*
    EditorWindow createNewEditorWindow(string project_name)
    {
        auto w = new EditorWindow(this, project_name);
        return w;
    }

    EditorWindow createNewOrGetExistingEditorWindow(string project_name)
    {
        EditorWindow ret;
        if (project_name !in windows)
        {
            ret = createNewEditorWindow(project_name);
            windows[project_name] = ret;
        }
        ret = windows[project_name];
        return ret;
    }
    */

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
