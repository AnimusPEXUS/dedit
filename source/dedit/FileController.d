module dedit.FileController;

import std.typecons;
import std.path;

import dutils.path;

import dedit.Controller;

struct FileControllerSettings
{
    Controller controller;

    string project;
    string filename;
    string uri;
}

class FileController
{

    FileControllerSettings* settings;

    this(Controller controller, string project, string filename, string uri)
    {
        auto settings = new FileControllerSettings;
        settings.controller = controller;
        settings.project = project;
        settings.filename = filename;
        settings.uri = uri;
        this.settings = settings;
    }

    this(FileControllerSettings* settings)
    {
        this.settings = settings;
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
        return tuple("", cast(Exception) null);
    }

    Exception setString(string text)
    {
        return cast(Exception) null;
    }

    Tuple!(ubyte[], Exception) getBytes()
    {
        return tuple(cast(ubyte[])[], cast(Exception) null);
    }

    Exception setBytes(ubyte[] data)
    {
        return cast(Exception) null;
    }

    void addFileChangedOnDiskListener(void delegate() cb)
    {

    }

    void removeFileChangedOnDiskListener(void delegate() cb)
    {

    }
}
