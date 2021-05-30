module dedit.FileController;

import std.algorithm;
import std.typecons;
import std.path;
import std.file;
import std.stdio;

import dutils.path;

import dedit.Controller;

// NOTE: no URI support for now
struct FileControllerSettings
{
    Controller controller;

    string project;
    string filename;
}

class FileController
{

    FileControllerSettings* settings;

    this(Controller controller, string project, string filename)
    {
        auto settings = new FileControllerSettings;
        settings.controller = controller;
        settings.project = project;
        settings.filename = filename;
        this.settings = settings;
        checkSettings();
    }

    this(FileControllerSettings* settings)
    {
        this.settings = settings;
        checkSettings();
    }

    private void checkSettings()
    {
        if (settings.project == "")
        {
            if (!settings.filename.startsWith("/"))
            {
                settings.filename = dutils.path.join(cast(string[])[
                        getcwd(), settings.filename
                        ]).absolutePath();
            }
        }
        else
        {
            if (settings.filename.startsWith("/"))
            {
                auto pp = this.settings.controller.getProjectPath(this.settings.project);
                if (pp[1]!is null)
                {
                    throw pp[1];
                }
                if (!dutils.path.join([pp[0], settings.filename])
                        .absolutePath().startsWith(pp[0] ~ "/"))
                {
                    throw new Exception("supplied filename is outside project's path");
                }
            }
        }
    }

    Tuple!(string, Exception) getFilename()
    {
        try
        {
            if (settings.project == "")
            {
                return tuple(settings.filename, cast(Exception) null);
            }
            else
            {
                auto pp = settings.controller.getProjectPath(settings.project);
                if (pp[1]!is null)
                {
                    return tuple("", pp[1]);
                }

                return tuple(dutils.path.join(cast(string[])[
                            pp[0], settings.filename
                        ]), cast(Exception) null);
            }
        }
        catch (Exception e)
        {
            return tuple("", e);
        }
    }

    Tuple!(string, Exception) getString()
    {
        auto chars = getChars();
        if (chars[1]!is null)
        {
            return tuple("", chars[1]);
        }
        auto ret = cast(string) chars[0];
        /* debug
        {
            writeln("getString result", ret);
        } */
        return tuple(ret, cast(Exception) null);
    }

    Exception setString(string text)
    {
        auto res = setChars(cast(char[]) text);
        if (res !is null)
        {
            return res;
        }
        return cast(Exception) null;
    }

    Tuple!(char[], Exception) getChars()
    {

        auto filename = this.getFilename();
        if (filename[1]!is null)
        {
            return tuple(cast(char[])[], filename[1]);
        }

        debug
        {
            writeln("getChars");
            writeln("  project:", settings.project);
            writeln("  filename:", settings.filename);
            writeln("  filename2:", filename[0]);
        }
        auto f = new std.stdio.File(filename[0]);

        char[] buff;
        buff.length = f.size;

        if (f.size > 0)
        {
            f.rawRead(buff);
        }

        return tuple(buff, cast(Exception) null);
    }

    Exception setChars(char[] data)
    {
        try
        {
            toFile(data, this.settings.filename);
        }
        catch (Exception e)
        {
            return e;
        }

        return cast(Exception) null;
    }

    void addFileChangedOnDiskListener(void delegate() cb)
    {

    }

    void removeFileChangedOnDiskListener(void delegate() cb)
    {

    }
}
