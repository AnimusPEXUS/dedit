module dedit.modules.d.mod;

import gtk.TextView;
import gtk.Menu;

import dedit.ModuleView;
import dedit.ModuleInformation;
import dedit.Buffer;
import dedit.BufferControlsInterface;

class DLangBufferControls : BufferControlsInterface {
    private {
        Buffer buff;
        string name;

        TextView tw;
        Menu mainMenu;
        Menu viewMenu;
    };

    this(Buffer buff, string name) {
            assert(buff !is null);
            assert(name != "");

            this.buff = buff;
            this.name = name;

            tw = new TextView();
            tw.setBuffer(buff.getTextBuffer());

            mainMenu = new Menu();
            viewMenu = new Menu();
    };

    string getName() {
        return name;
    };

    Buffer getBuffer() {
        return buff;
    };

    TextView getBufferView() {
        return tw;
    };

    Menu getMainMenu()    {
        return mainMenu;
    }    ;

    Menu getViewMenu(){
        return viewMenu;
    }    ;

}

BufferControlsInterface createBufferControlsForBuffer(Buffer buff, string name) {
    auto ret = new DLangBufferControls(buff, name);
    return ret;
}

static const dedit.ModuleInformation.ModuleInformation ModuleInformation = {
    ModuleName: "D",
    SupportedExtensions: ["d"],
    /* createViewForBuffer: &createViewForBuffer  */
};
