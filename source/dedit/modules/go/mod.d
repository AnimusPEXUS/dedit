module dedit.modules.go.mod;

import std.path;
import std.algorithm;
import std.stdio;
import std.json;
import std.process;
import std.range;
import std.functional;
import std.regex;

import glib.Idle;

import gtk.Paned;
import gtk.Scrollbar;
import gtk.TextBuffer;
import gtk.TextView;
import gtk.TextTagTable;
import gtk.Menu;
import gtk.MenuItem;
import gtk.Widget;
import gtk.ScrolledWindow;
import gtk.c.types;

import pango.PgFontDescription;

import gsv.SourceView;
import gsv.SourceBuffer;
import gsv.SourceLanguageManager;
import gsv.c.types;

import dedit.moduleinterface;
import dedit.Controller;
import dedit.EditorWindow;
import dedit.OutlineTool;
import dedit.TypicalCodeEditorMod;

import dutils.regex;

void applyLanguageSettingsToSourceView(SourceView sv)
{
    sv.setAutoIndent(true);
    /* sv.setDrawSpaces(DrawSpacesFlags.ALL); */
    sv.setHighlightCurrentLine(true);
    sv.setIndentOnTab(true);
    sv.setIndentWidth(4);
    sv.setInsertSpacesInsteadOfTabs(false);
    sv.setRightMarginPosition(80);
    sv.setShowRightMargin(true);
    sv.setTabWidth(4);
    sv.setShowLineMarks(true);
    sv.setShowLineNumbers(true);
    // sv.setSmartHomeEnd(GtkSourceSmartHomeEndType.ALWAYS);
}

void applyLanguageSettingsToSourceBuffer(SourceBuffer sb)
{
    sb.setLanguage(SourceLanguageManager.getDefault().getLanguage("go"));
}

const SYMBOL_REGEXP = ctRegex!(`^[ \t]*(func|var|const|type|import) .*$`, "m");

// const SYMBOL2_REGEXP = ctRegex!(`^([ \t]*[a-zA-Z_][a-zA-Z0-9_\.]*?)[ \t]*\=.*$`);

string formatWholeBufferText(string txt)
{
    return txt;
}

OutlineToolInputData* prepareDataForOutlineTool(string txt)
{
    auto lstarts = lineStarts(txt);

    OutlineToolInputData* ret = new OutlineToolInputData();

    outlineToolDataInsertMatchedLines(ret, txt, SYMBOL_REGEXP, lstarts);

    return ret;
}

const dedit.moduleinterface.ModuleInformation ModuleInformation =
{
    moduleName: "Go",
    supportedExtensions: [".go"],
    createDataBufferForURI: function ModuleDataBuffer(
            Controller c,
            EditorWindow w,
            string uri
    ) {
        auto options = new TypicalCodeEditorModOptions();
        options.module_information = cast(
                dedit.moduleinterface.ModuleInformation*)&ModuleInformation;
        // options.module_information = cast(dedit.moduleinterface.ModuleInformation*)&ModuleInformation;
        options.applyLanguageSettingsToSourceView =
            toDelegate(&applyLanguageSettingsToSourceView);
        options.applyLanguageSettingsToSourceBuffer =
            toDelegate(
                    &applyLanguageSettingsToSourceBuffer);
        options.formatWholeBufferText = toDelegate(&formatWholeBufferText);
        options.prepareDataForOutlineTool = toDelegate(&prepareDataForOutlineTool);

        auto tem = new TypicalCodeEditorMod(options);
        return tem.createDataBufferForURI(c, w, uri);
    }};
