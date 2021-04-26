module dedit.ToolWindow;

import gtk.Window;

import dedit.Controller;
import dedit.ToolWidget;

class ToolWindow
{

    Controller controller;

    Window window;

    ToolWidget tool_widget;

    this(Controller controller)
    {
        this.controller = controller;

        window = new Window("tool window");

        auto tool_widget = new ToolWidget(controller);

        window.add(tool_widget.getWidget());
    }

    void setProject(string name)
    {
        tool_widget.setProject(name);
    }

    void destroy()
    {
        tool_widget.destroy();
        window.destroy();
    }

    Window getWindow()
    {
        return window;
    }

    void show()
    {
        window.showAll();
    }

}
