module dedit.main;

import gtk.Application;
import gio.Application;

import gtk.Widget;
import gtk.Window;


import dedit.MainWindow;

int main(string[] args)
{

    auto app = new gtk.Application.Application(
        "dedit.wayround.i2p",
        gio.Application.GApplicationFlags.FLAGS_NONE
        );

    app.addOnActivate(delegate void(gio.Application.Application gioapp) {
        auto w = new MainWindow();

        auto widget = w.getWidget();
        auto window = cast(Window) widget;

        app.addWindow(window);
        window.showAll();
    });

    return app.run(args);
}
