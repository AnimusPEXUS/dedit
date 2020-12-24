module dedit.Controller;

import std.json;
import std.file;
import std.path;

import gtk.Application;
import gio.Application;

import gtk.Widget;
import gtk.Window;



import dedit.MainWindow;
import dedit.Buffer;



class Controller {

    private {
        Buffer[] buffers;
        string[string] projects;

        string settingsPath;

        MainWindow[] windows;
    }

    void saveState() {
/*
        JSONValue v = JSONType.object;

        v.object["projects"] = this.projects;
        v.object["buffers"] = JSONValue([]);
        v.object["open_projects"] = JSONValue([]);


        string j= toJSON(v);

        mkdir(dirName(settingsPath));

        File of = new File(settingsPath,"w");

        of.rawWrite(j); */
    }

    void loadState() {

        /* if (isFile(settingsPath)) {
            auto f = new File(settingsPath);
            char[] buf;
            buf.length = f.size;
            string data = f.rawRead(buf);


            this.projects = v.object["projects"];
        } */
    }

    int main(string[] args) {

            settingsPath = expandTilde("~/.config/dedit/settings.json");

            auto app = new gtk.Application.Application(
                "dedit.wayround.i2p",
                gio.Application.GApplicationFlags.FLAGS_NONE
                );

            app.addOnActivate(
                    delegate void(gio.Application.Application gioapp) {

                        auto w = createNewCleanWindow();

                        auto widget = w.getWidget();
                        auto window = cast(Window) widget;

                        app.addWindow(window);
                    }
                );

            return app.run(args);
    }

    MainWindow createNewCleanWindow() {
        auto w = new MainWindow();

        auto widget = w.getWidget();
        auto window = cast(Window) widget;

        window.showAll();

        return w;
    }

    MainWindow createIfNotExistsAndReturnWindowForProject(string project_name) {
            return null;
    }



}
