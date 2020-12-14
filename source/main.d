module dedit.main;

import gtk.Application;
import gio.Application;

import dedit.MainWindow;

int main(string[] args)
{

    auto app = new gtk.Application.Application(
        "dedit.wayround.i2p",
        gio.Application.GApplicationFlags.FLAGS_NONE
        );

    app.addOnActivate(delegate void(gio.Application.Application gioapp) {
        auto w = new MainWindow();
        app.addWindow(w);
        w.showAll();
    });

    return app.run(args);
}
