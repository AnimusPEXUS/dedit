module dedit.modules.d.mod;

import std.path;
import std.algorithm;
import std.stdio;
import std.json;
import std.process;
import std.range;
import std.functional;

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
import dedit.ViewWindow;
import dedit.OutlineTool;
import dedit.TypicalCodeEditorMod;

void applyLanguageSettingsToSourceView(SourceView sv)
{
    sv.setAutoIndent(true);
    /* sv.setDrawSpaces(DrawSpacesFlags.ALL); */
    sv.setHighlightCurrentLine(true);
    sv.setIndentOnTab(true);
    sv.setIndentWidth(4);
    sv.setInsertSpacesInsteadOfTabs(true);
    sv.setRightMarginPosition(80);
    sv.setShowRightMargin(true);
    sv.setTabWidth(4);
    sv.setShowLineMarks(true);
    sv.setShowLineNumbers(true);
    // sv.setSmartHomeEnd(GtkSourceSmartHomeEndType.ALWAYS);
}

void applyLanguageSettingsToSourceBuffer(SourceBuffer sb)
{
    sb.setLanguage(SourceLanguageManager.getDefault().getLanguage("d"));
}

string formatWholeBufferText(string txt)
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

const dedit.moduleinterface.ModuleInformation ModuleInformation =
{
    moduleName: "D",
    supportedExtensions: [".d"],
    createDataBufferForURI: function ModuleDataBuffer(
            Controller c,
            ViewWindow w,
            string uri
    ) {
        auto options = new TypicalCodeEditorModOptions();
        options.module_information = cast(
                dedit.moduleinterface.ModuleInformation*)&ModuleInformation;
        // options.module_information = cast(dedit.moduleinterface.ModuleInformation*)&ModuleInformation;
        options.applyLanguageSettingsToSourceView = toDelegate(&applyLanguageSettingsToSourceView);
        options.applyLanguageSettingsToSourceBuffer = toDelegate(
                &applyLanguageSettingsToSourceBuffer);
        options.formatWholeBufferText = toDelegate(&formatWholeBufferText);

        auto tem = new TypicalCodeEditorMod(options);
        return tem.createDataBufferForURI(c, w, uri);
    }};
