module dedit.ModuleInformation;

import gtk.Widget;
import gtk.TextBuffer;
import gtk.Menu;

import dedit.ModuleView;
import dedit.Buffer;
import dedit.BufferControlsInterface;

struct ModuleInformation
{
    string ModuleName;
    string[] SupportedExtensions;
    string[] SupportedMIMETypes;
    BufferControlsInterface createBufferControlsForBuffer(Buffer buff, string name);
}
