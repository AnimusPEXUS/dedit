module dedit.main;

import dedit.Controller;

int main(string[] args)
{
    auto editor_controller = new Controller();
    return editor_controller.main(args);
}
