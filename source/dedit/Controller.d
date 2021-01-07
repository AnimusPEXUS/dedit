module dedit.Controller;

import std.json;
import std.file;
import std.path;

import gtk.Application;
import gio.Application;

import gtk.Widget;
import gtk.Window;

import dedit.EditorWindow;
import dedit.ProjectsWindow;
import dedit.Buffer;

class Controller
{

    private
    {
        Buffer[] buffers;
        /* string[string] projects; */

        string settingsPath;

        EditorWindow[string] windows;
    }

    public
    {
        string[string] project_paths;
    }

    void saveState()
    {

        JSONValue v = JSONType.object;

        v.object["projects"] = project_paths;
        /* v.object["buffers"] = JSONValue([]); */
        /* v.object["open_projects"] = JSONValue([]); */

        string j = toJSON(v);

        mkdir(dirName(settingsPath));

        File of = new File(settingsPath, "w");

        of.rawWrite(j);
    }

    void loadState()
    {

        if (isFile(settingsPath))
        {
            auto f = new File(settingsPath);
            char[] buf;
            buf.length = f.size;
            string data = f.rawRead(buf);

            this.projects = v.object["projects"];
        }
    }

    int main(string[] args)
    {

        settingsPath = expandTilde("~/.config/dedit/settings.json");

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
