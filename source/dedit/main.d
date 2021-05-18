module dedit.main;

import dlangui;

import dedit.Controller;

extern (C) int UIAppMain(string[] args) {
    auto editor_controller = new Controller();
    return editor_controller.main(args);
}
