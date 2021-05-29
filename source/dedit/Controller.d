module dedit.Controller;

import std.json;
import std.file;
import std.path;
import std.stdio;
import std.typecons;
import std.uuid;

import dlangui;

import dedit.ProjectWindow;

import dedit.ViewWindow;
import dedit.ToolWindow;
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
    ToolWindow[] tool_windows;

    FileController[] file_controllers;

    // TODO: leaving this for a future. for now, I'll will not implement buffer reusage.
    //       maybe in future..
    // ModuleDataBuffer[string] buffers;

    // ViewWindowSettings[string] window_settings;

    ProjectsWindow projects_window;
    /* JSONValue projects_window_settings; */
    // string font;

    // TODO: move this toto builtintoolwidgets.d as mixins
    string[] tool_widget_combobox_item_list;
    string[] tool_widget_combobox_item_list_titles;

    JSONValue settings;

    bool close_called;

    this()
    {
        tool_widget_combobox_item_list ~= "";
        tool_widget_combobox_item_list_titles ~= "";
        foreach (i, v; builtinToolWidgets)
        {
            tool_widget_combobox_item_list ~= v.name;
            tool_widget_combobox_item_list_titles ~= v.displayName;
            /* auto ti = new TreeIter;
            tool_widget_combobox_item_list.append(ti);
            tool_widget_combobox_item_list.setValue(ti, 0, new Value(v.name));
            tool_widget_combobox_item_list.setValue(ti, 1, new Value(v.displayName)); */
        }
    }

    int main(string[] args)
    {
        settingsPath = expandTilde("~/.config/dedit/settings.json");

        /* tool_widget_combobox_item_list = new ListStore(cast(GType[])[
                GType.STRING, GType.STRING
                ]);

        {
            auto ti = new TreeIter;
            tool_widget_combobox_item_list.append(ti);
            tool_widget_combobox_item_list.setValue(ti, 0, new Value(""));
            tool_widget_combobox_item_list.setValue(ti, 1, new Value("(not selected)"));
        }*/

        loadSettings();

        projects_window = new ProjectsWindow(this);

        auto window = projects_window.getWindow();

        window.show();

        return Platform.instance.enterMessageLoop();
    }

    Exception saveSettings()
    {

        string j = settings.toJSON(true);

        writeln(j);

        try
        {
            mkdir(dirName(settingsPath));
        }
        catch (Exception)
        {
            // NOTE: not an error
            /* return cast(Exception) null; */
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

        foreach (size_t index, v; ["projects", "project_window_settings"])
        {
            if (v !in settings || settings[v].type() != JSONType.object)
            {
                settings[v] = JSONValue(cast(JSONValue[string]) null);
            }
        }

        foreach (size_t index, v; [
                "view_windows_settings", "tool_windows_settings"
            ])
        {
            if (v !in settings || settings[v].type() != JSONType.array)
            {
                settings[v] = JSONValue(cast(JSONValue[]) null);
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
        return getWindowSettings("project_window_settings", name);
    }

    Tuple!(JSONValue, Exception) getWindowSettings(string window_settings_type, string name)
    {
        JSONValue ret;
        try
        {
            ret = settings[window_settings_type][name];
        }
        catch (Exception e)
        {
            return tuple(JSONValue(null), e);
        }
        return tuple(ret, cast(Exception) null);
    }

    void setProjectWindowSettings(string name, JSONValue value)
    {
        return setWindowSettings("project_window_settings", name, value);
    }

    void setWindowSettings(string window_settings_type, string name, JSONValue value)
    {
        settings = sanitizeSettings(settings);
        debug
        {
            writeln("saving settings for ", window_settings_type, " window:", name);
            writeln("  settings:", value);
        }
        settings[window_settings_type][name] = value;
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

    Exception setViewWindowSettings(JSONValue value)
    {
        return setProjectSubwindowSettings("view_windows_settings", value);
    }

    Exception setToolWindowSettings(JSONValue value)
    {
        return setProjectSubwindowSettings("tool_windows_settings", value);
    }

    Exception setProjectSubwindowSettings(string subwindow_settings_type, JSONValue value)
    {
        if ("window_uuid" !in value)
        {
            return new Exception("no 'window_uuid' in supplied value");
        }

        string window_uuid = value["window_uuid"].str();

        debug
        {
            writeln("setProjectSubwindowSettings window_uuid 1 ", window_uuid);
        }

        try
        {
            parseUUID(window_uuid.dup);
        }
        catch (Exception)
        {
            return new Exception("invalid 'window_uuid' in supplied value");
        }

        debug
        {
            writeln("setProjectSubwindowSettings window_uuid 2 ", window_uuid);
        }

        bool set = true;
        bool found = false;

        auto x = settings[subwindow_settings_type];
        scope (success)
            settings[subwindow_settings_type] = x;

        foreach_reverse (size_t k, JSONValue v; x.array())
        {
            if (v["window_uuid"].str() == window_uuid)
            {
                found = true;
                if (set)
                {
                    debug
                    {
                        writeln("updating existing ", window_uuid, " in x");
                    }
                    x[k] = value;
                    set = false;
                }
                else
                {
                    debug
                    {
                        writeln("removing excess ", window_uuid, " from x");
                    }
                    auto y = x.array();
                    x = y[0 .. k] ~ y[k + 1 .. $];
                }
            }
        }

        debug
        {
            if (!found)
            {
                writeln("couldn't find existing settings in tool_windows_settings for window ",
                        window_uuid);
            }
        }

        if (!found)
        {
            x.array() ~= value;
        }

        debug
        {
            writeln("x length", x.array().length);
        }

        return cast(Exception) null;
    }

    Tuple!(JSONValue, Exception) getViewWindowSettings(string window_uuid)
    {
        return getProjectSubwindowSettings("view_windows_settings", window_uuid);
    }

    Tuple!(JSONValue, Exception) getToolWindowSettings(string window_uuid)
    {
        return getProjectSubwindowSettings("tool_windows_settings", window_uuid);
    }

    Tuple!(JSONValue, Exception) getProjectSubwindowSettings(
            string subwindow_settings_type, string window_uuid)
    {

        auto x = settings[subwindow_settings_type];
        scope (success)
            settings[subwindow_settings_type] = x;

        foreach (size_t k, JSONValue v; x.array())
        {
            if (v["window_uuid"].str() == window_uuid)
            {
                return tuple(v, cast(Exception) null);
            }
        }
        return tuple(cast(JSONValue) null, cast(Exception) null);
    }

    Exception delViewWindowSettings(string window_uuid)
    {
        return delProjectSubwindowSettings("view_windows_settings", window_uuid);
    }

    Exception delToolWindowSettings(string window_uuid)
    {
        return delProjectSubwindowSettings("tool_windows_settings", window_uuid);
    }

    Exception delProjectSubwindowSettings(string subwindow_settings_type, string window_uuid)
    {

        auto x = settings[subwindow_settings_type];
        scope (success)
            settings[subwindow_settings_type] = x;

        foreach_reverse (size_t k, JSONValue v; x.array())
        {
            if (v["window_uuid"].str() == window_uuid)
            {
                auto y = x.array();
                x = y[0 .. k] ~ y[k + 1 .. $];
            }
        }
        return cast(Exception) null;
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

    ViewWindow openNewView(string project, string filename)
    {
        auto y = new ViewWindowContentSetup;

        y.view_module_auto = true;
        y.view_module_auto_mode = ViewModuleAutoMode.BY_EXTENSION;
        y.project = project;
        y.filename = filename;

        auto options = new ViewWindowSettings;
        options.controller = this;
        options.setup = y;

        auto w = new ViewWindow(options);

        w.show();
        w.present();
        return w;
    }

    ViewWindow openNewViewOrExisting(string project, string filename)
    {
        foreach (size_t i, ref ViewWindow v; view_windows)
        {
            if (v.settings.setup.project == project && v.settings.setup.filename == filename)
            {
                v.show();
                v.present();
                return v;
            }
        }

        return openNewView(project, filename);
    }

    Exception close()
    {
        if (!close_called)
        {

            foreach (i, c; project_windows)
            {
                c.saveSettings();
                c.close();
            }

            foreach (i, c; tool_windows)
            {
                c.saveSettings();
                c.close();
            }

            foreach (i, c; view_windows)
            {
                c.saveSettings();
                c.close();
            }

            projects_window.saveSettings();
            projects_window.close();

            saveSettings();
        }
        return cast(Exception) null;
    }

}
