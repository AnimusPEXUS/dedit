module dedit.Controller;

import std.json;
import std.file;
import std.path;
import std.stdio;

import gtk.Application;
import gio.Application;

import gtk.Widget;
import gtk.Window;

import dedit.EditorWindow;
import dedit.ProjectsWindow;
import dedit.Settings;

class Controller
{

    private
    {
        string settingsPath;

        EditorWindow[string] windows;
    }

    public
    {
        string[string] project_paths;
        WindowSettings[string] window_settings;
        string font;
    }

    int main(string[] args)
    {
        font = "Go Mono 10";

        settingsPath = expandTilde("~/.config/dedit/settings.json");

        loadState();

        auto app = new gtk.Application.Application("dedit.wayround.i2p",
                gio.Application.GApplicationFlags.FLAGS_NONE);

        app.addOnActivate(delegate void(gio.Application.Application gioapp) {

            auto w = new ProjectsWindow(this);

            /* auto w = createNewCleanWindow(); */

            auto widget = w.getWindow();
            auto window = cast(Window) widget;

            window.showAll();

            app.addWindow(window);
        });

        return app.run(args);
    }

    void saveState()
    {

        string[string] root;

        JSONValue x = JSONValue(root);

        x["font"] = JSONValue(font);

        x["projects"] = JSONValue(project_paths);

        {
            JSONValue windowsettingsarray = JSONValue(cast(string[string]) null);
            foreach (k, v; window_settings)
            {
                windowsettingsarray[k] = v.toJSONValue();
            }
            x["window_settings"] = windowsettingsarray;
        }

        string j = x.toJSON(true);

        try
        {
            mkdir(dirName(settingsPath));
        }
        catch (Exception)
        {
            // do nothing
        }

        File of = File(settingsPath, "w");

        of.rawWrite(j);
    }

    void loadState()
    {
        if (isFile(settingsPath))
        {

            auto f = File(settingsPath);
            char[] buf;
            buf.length = f.size;
            string data = cast(string) f.rawRead(buf);

            JSONValue x = parseJSON(data);

            if ("font" in x)
            {
                font = x.object["font"].str;
            }

            if ("projects" in x)
            {
                this.project_paths = cast(string[string]) x["projects"].object;
            }

            if ("window_settings" in x)
            {
                window_settings.clear;
                foreach (string k, v; x["window_settings"])
                {
                    window_settings[k] = new WindowSettings(v);
                }
            }

        }
    }

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

    void editorWindowIsClosed(string project_name)
    {
        if (project_name in windows)
        {
            windows.remove(project_name);
        }
    }

}
