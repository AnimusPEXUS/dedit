module dedit.main;

import dlangui;

mixin APP_ENTRY_POINT;

import std.stdio;

import dedit.Controller;

extern (C) int UIAppMain(string[] args)
{
    writeln("hello!");
    auto editor_controller = new Controller();
    return editor_controller.main(args);
}

/* int main() { return 0;} */
