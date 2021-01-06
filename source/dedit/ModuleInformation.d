module dedit.ModuleInformation;

import gtk.Widget;
import gtk.TextBuffer;
import gtk.Menu;

import dedit.ModuleView;
import dedit.Buffer;

struct ModuleInformation
{
    string ModuleName;
    string[] SupportedExtensions;
    string[] SupportedMIMETypes;
    Widget createViewForBuffer(Buffer buff);
    Menu createMenuForBuffer(Buffer buff);
}
