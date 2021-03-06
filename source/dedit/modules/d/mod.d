module dedit.modules.d.mod;

import std.path;
import std.algorithm;
import std.stdio;
import std.json;
import std.process;
import std.range;
import std.functional;

import dlangui;

import dedit.moduleinterface;
import dedit.Controller;
import dedit.ViewWindow;
import dedit.OutlineTool;
import dedit.TypicalModuleControllerText;

void applyLanguageSettingsToSourceView(TypicalModuleControllerText tmfct, SourceEdit sv)
{
    // TODO: this should be redesigned
    tmfct.settings.controller.setFontOnSourceEdit(sv);
    sv.smartIndents = true;
    sv.tabSize = 4;
    sv.useSpacesForTabs = true;
    sv.wantTabs = true;
    /* sv.setAutoIndent(true); */
    /* sv.setDrawSpaces(DrawSpacesFlags.ALL); */
    /* sv.setHighlightCurrentLine(true);
    sv.setIndentOnTab(true);
    sv.setIndentWidth(4);
    sv.setInsertSpacesInsteadOfTabs(true);
    sv.setRightMarginPosition(80);
    sv.setShowRightMargin(true);
    sv.setTabWidth(4);
    sv.setShowLineMarks(true);
    sv.setShowLineNumbers(true); */
    // sv.setSmartHomeEnd(GtkSourceSmartHomeEndType.ALWAYS);
}

/* void applyLanguageSettingsToSourceBuffer(SourceBuffer sb)
{
    /* sb.setLanguage(SourceLanguageManager.getDefault().getLanguage("d")); * /
} */

string formatWholeBufferText(TypicalModuleControllerText tmfct, string txt)
{
    import std.array;
    import dfmt.config : Config;
    import dfmt.formatter : format;
    import dfmt.editorconfig : OptionalBoolean;

    ubyte[] bt = cast(ubyte[]) txt;

    Config config;
    config.initializeWithDefaults();
    config.dfmt_keep_line_breaks = OptionalBoolean.t;

    if (!config.isValid())
    {
        string msg = "dfmt config error";
        writeln(msg);
        throw new Exception(msg);
        // return "";
    }

    auto output = appender!string;

    immutable bool formatSuccess = format("stdin", bt, output, &config);

    if (!formatSuccess)
    {
        string msg = "dfmt:format() returned error";
        writeln(msg);
        throw new Exception(msg);
        // return "";
    }

    string x = cast(string) output[];

    //buff.setText(x);
    /* new Idle(delegate bool() {
            this.setSettings(s);
            return false;
        }); */

    string ret = x.idup;

    return ret;

}

const dedit.moduleinterface.ModuleInformation ModuleInformation = {
    name: "D", supportedExtensions: [".d"], /* ModuleFileController function(Controller c, FileController file_controller) createModuleController; */
    createModuleController: function ModuleController(Controller controller) {
        auto settings = new TypicalModuleControllerTextSettings;
        settings.controller = controller;
        settings.module_information = cast(
                dedit.moduleinterface.ModuleInformation*)&ModuleInformation;
        settings.applyLanguageSettingsToSourceView = toDelegate(&applyLanguageSettingsToSourceView);
        /* settings.applyLanguageSettingsToSourceBuffer = toDelegate(
                &applyLanguageSettingsToSourceBuffer); */
        /* settings.formatWholeBufferText = toDelegate(&formatWholeBufferText); */
        settings.formatWholeBufferText = toDelegate(&formatWholeBufferText);

        auto ret = new TypicalModuleControllerText(settings);
        return ret;
    }};
