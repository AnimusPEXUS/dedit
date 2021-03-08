module dedit.builtinmodules;

import dedit.moduleinterface;

import dedit.modules.d.mod;
// import dedit.modules.go.mod;
// import dedit.modules.python.mod;

static const dedit.moduleinterface.ModuleInformation[] builtinModules
    = [
        dedit.modules.d.mod.ModuleInformation,
         // dedit.modules.go.mod.ModuleInformation,
         // dedit.modules.python.mod.ModuleInformation,
    ];
