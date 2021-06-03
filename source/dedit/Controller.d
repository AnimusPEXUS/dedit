module dedit.Controller;

import std.json;
import std.file;
import std.path;
import std.stdio;
import std.typecons;
import std.uuid;
import std.algorithm;

import dlangui;

import dutils.path;

import dedit.ControllerViewWindowMGR;

import dedit.ProjectWindow;

import dedit.ViewWindow;
import dedit.ToolWindow;
import dedit.ProjectsWindow;

import dedit.moduleinterface;

import dedit.builtinmodules;
import dedit.builtintoolwidgets;

const VIEW_WINDOWS_SETTINGS_STR = "view_windows_settings";

/* struct EditorPreferences {
    string fontFamily = "Go Mono";
    FontFamily fontFamily = FontFamily.
    int fontSize;
} */

class Controller
{

    string settingsPath;

    string[string] project_paths;

    ProjectWindow[] project_windows;
    ToolWindow[] tool_windows;

    ControllerViewWindowMGR view_windows;

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

    /* bool view_window_state_change_propagation_already_entered; */

    this()
    {
        view_windows = new ControllerViewWindowMGR;

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

    void setFontOnSourceEdit(SourceEdit se)
    {
        se.fontFace("Go Mono");
        se.fontFamily(FontFamily.MonoSpace);
        se.fontSize(10);
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
                VIEW_WINDOWS_SETTINGS_STR, "tool_windows_settings"
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
        foreach (size_t index, ref w; project_windows)
        {
            if (w.project == project)
            {
                return w;
            }
        }
        return createNewProjectWindow(project);
    }

    Exception setViewWindowSettings(JSONValue value)
    {
        return setProjectSubwindowSettings(VIEW_WINDOWS_SETTINGS_STR, value);
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
                writeln("couldn't find existing settings in " ~ subwindow_settings_type ~ " for window ",
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
        return getProjectSubwindowSettings(VIEW_WINDOWS_SETTINGS_STR, window_uuid);
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
        return delProjectSubwindowSettings(VIEW_WINDOWS_SETTINGS_STR, window_uuid);
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

    Tuple!(ModuleController, Exception) createModuleController(string project, string filename)
    {

        auto res = calculateRealFilenameByProjectAndFilename(project, filename);
        if (res[1]!is null)
        {
            return tuple(cast(ModuleController) null, res[1]);
        }

        auto valid_filename = res[0];

        auto m = determineModuleByFileExtension(valid_filename);
        if (m[1]!is null)
        {
            return tuple(cast(ModuleController) null, m[1]);
        }

        if (m[0].length == 0)
        {
            return tuple(cast(ModuleController) null,
                    new Exception("couldn't determine module for file"));
        }

        auto minfo = getModuleInformation(m[0][0]); // TODO: todo

        if (minfo is null)
        {
            return tuple(cast(ModuleController) null,
                    new Exception("couldn't get module information"));
        }

        auto ret = minfo.createModuleController(this);

        return tuple(ret, cast(Exception) null);
    }

    ViewWindow openNewView(string project, string filename)
    {
        auto y = new ViewWindowContentSetup;

        y.view_module_auto = true;
        y.view_module_auto_mode = ViewModuleAutoMode.BY_EXTENSION;
        y.project = project;
        y.filename = filename;

        auto w = new ViewWindow(this, "", y);

        w.show();
        w.present();
        return w;
    }

    ViewWindow openNewViewOrExisting(string project, string filename)
    {
        if (view_windows.isIn(project, filename))
        {
            return view_windows.get(project, filename);
        }

        return openNewView(project, filename);
    }

    Exception close()
    {
        if (!close_called)
        {
            close_called = true;

            foreach (i, ref c; tool_windows)
            {
                c.keep_settings_on_window_close = true;
                c.saveSettings();
                c.close();
            }

            view_windows.listItems(delegate void(ViewWindow w) {
                w.keep_settings_on_window_close = true;
                w.saveSettings();
                w.close();
            });

            foreach (i, ref c; project_windows)
            {
                /* c.keep_settings_on_window_close = true; */
                c.saveSettings();
                c.close();
            }

            projects_window.saveSettings();
            projects_window.close();

            saveSettings();
        }
        return cast(Exception) null;
    }

    Exception checkFilenameIsAllowedToBeOutsideOfProject(string project, string filename)
    {
        if (project != "")
        {
            auto pp = getProjectPath(project);
            if (pp[1]!is null)
            {
                return pp[1];
            }
            if (!dutils.path.join([pp[0], filename]).absolutePath().startsWith(pp[0] ~ "/"))
            {
                return new Exception("supplied filename is outside project's path");
            }
        }
        return cast(Exception) null;
    }

    Tuple!(string, Exception) calculateRealFilenameByProjectAndFilename(string project,
            string filename)
    {
        auto res = checkFilenameIsAllowedToBeOutsideOfProject(project, filename);
        if (res !is null)
        {
            return tuple("", res);
        }

        string ret;
        if (project == "")
        {
            if (!filename.startsWith("/"))
            {
                ret = dutils.path.join(cast(string[])[getcwd(), filename]).absolutePath();
            }
            else
            {
                ret = dutils.path.join(cast(string[])[filename]).absolutePath();
            }
        }
        else
        {
            auto pp = getProjectPath(project);
            if (pp[1]!is null)
            {
                return tuple("", pp[1]);
            }

            ret = dutils.path.join([pp[0], filename]);
        }
        return tuple(ret, cast(Exception) null);
    }

    Tuple!(string, Exception) getFileString(string project, string filename)
    {

        auto chars = getFileChars(project, filename);
        if (chars[1]!is null)
        {
            return tuple("", chars[1]);
        }

        return tuple(cast(string) chars[0], cast(Exception) null);
    }

    Exception setFileString(string project, string filename, string text)
    {
        auto res = setFileChars(project, filename, cast(char[]) text);
        if (res !is null)
        {
            return res;
        }
        return cast(Exception) null;
    }

    Tuple!(char[], Exception) getFileChars(string project, string filename)
    {

        auto res = calculateRealFilenameByProjectAndFilename(project, filename);
        if (res[1]!is null)
        {
            return tuple(cast(char[]) null, res[1]);
        }

        auto valid_filename = res[0];

        debug
        {
            writeln("getChars");
            writeln("  project        :", project);
            writeln("  filename       :", filename);
            writeln("  valid_filename :", valid_filename);
        }
        auto f = new std.stdio.File(valid_filename);

        char[] buff;
        buff.length = f.size;

        if (f.size > 0)
        {
            f.rawRead(buff);
        }

        return tuple(buff, cast(Exception) null);
    }

    Exception setFileChars(string project, string filename, char[] data)
    {
        auto res = calculateRealFilenameByProjectAndFilename(project, filename);
        if (res[1]!is null)
        {
            return res[1];
        }

        auto valid_filename = res[0];

        try
        {
            toFile(data, valid_filename);
        }
        catch (Exception e)
        {
            return e;
        }

        return cast(Exception) null;
    }

}
