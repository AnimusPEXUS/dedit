module dedit.modules.go.mod;

import std.path;
import std.algorithm;
import std.stdio;
import std.json;
import std.process;
import std.range;
import std.functional;
import core.thread.osthread;

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
    sv.useSpacesForTabs = false;
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



    auto p1 = std.process.pipe();
    auto p2 = std.process.pipe();

    auto gofmt = spawnProcess(["gofmt"], p1.readEnd, p2.writeEnd);
    scope (exit)
        wait(gofmt);

    p1.writeEnd.rawWrite(txt);
    p1.writeEnd.close();

    string ret;

    while (true)
    {
        char[] x2;
        x2.length = 1024;
        auto x = p2.readEnd.rawRead(x2);
        ret ~= x;
        if (x.length < 1024)
            break;
    }

    return ret;
}

const dedit.moduleinterface.ModuleInformation ModuleInformation = {
    name: "Go", supportedExtensions: [".go"], /* ModuleFileController function(Controller c, FileController file_controller) createModuleController; */
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
