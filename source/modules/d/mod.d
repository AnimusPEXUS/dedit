module dedit.modules.d.mod;

import dedit.ModuleView;
import dedit.ModuleInformation;
import dedit.Buffer;

dedit.ModuleView.ModuleView createViewForBuffer(Buffer buff) {
    return null;
    }

static const dedit.ModuleInformation.ModuleInformation ModuleInformation = {
    ModuleName: "D",
    SupportedExtensions: ["d"],
    /* createViewForBuffer: &createViewForBuffer  */
};
