module dedit.modules.d.mod;

import gtk.TextView;
import gtk.Menu;

import dedit.ModuleView;
import dedit.ModuleInformation;
import dedit.Buffer;

static const dedit.ModuleInformation.ModuleInformation ModuleInformation = {
    ModuleName: "D", SupportedExtensions: ["d"],/* createViewForBuffer: &createViewForBuffer  */

};
