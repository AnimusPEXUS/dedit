module dedit.builtinmodules;

import std.typecons;
import std.algorithm;

import dedit.moduleinterface;

import dedit.modules.d.mod;
import dedit.modules.go.mod;

// import dedit.modules.python.mod;

static const dedit.moduleinterface.ModuleInformation[] builtinModules
    = [
        dedit.modules.d.mod.ModuleInformation,
        dedit.modules.go.mod.ModuleInformation,
        // dedit.modules.python.mod.ModuleInformation,
    ];

Tuple!(string[], Exception) determineModuleByFileExtension(string filename)
{
    string[] ret;
    try
    {

        loop0: foreach (size_t index, m; builtinModules)
        {
            foreach (size_t index2, ext; m.supportedExtensions)
            {
                if (filename.endsWith(ext))
                {
                    if (!ret.canFind(m.name))
                    {
                        ret ~= m.name;
                    }
                    continue loop0;
                }
            }
        }
    }
    catch (Exception e)
    {
        return tuple(cast(string[]) null, e);
    }

    return tuple(ret, cast(Exception) null);
}

dedit.moduleinterface.ModuleInformation* getModuleInformation(string name)
{
    foreach (size_t index, const ref m; builtinModules)
    {
        if (m.name == name)
        {
            return cast(dedit.moduleinterface.ModuleInformation*)&m;
        }
    }
    return null;
}

/* struct ModuleDeterminationSettings
{

}

Tuple!(string[], Exception) determineModule(ModuleDeterminationSettings* settings)
{
    string[] ret;
    return tuple(ret, cast(Exception) null);
} */
