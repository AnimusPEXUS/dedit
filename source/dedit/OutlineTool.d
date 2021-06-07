module dedit.OutlineTool;

import std.stdio;
import std.typecons;
import std.json;

import dlangui;

import dutils.dlanguiutils.StringGridWidgetWithTools;

import dedit.Controller;
import dedit.TypicalModuleControllerText;

struct OutlineToolInputDataUnit
{
    ulong line;
    // string type;
    string text;
}

struct OutlineToolInputData
{
    OutlineToolInputDataUnit*[] data;
}

/* struct OutlineToolOptions
{
    void delegate(int new_line_number) userWishesToGoToLine;
    void delegate() userWishesToRefreshData;
} */

class OutlineTool
{

    TypicalModuleControllerText tmct;

    VerticalLayout mainBox;

    this(TypicalModuleControllerText tmct)
    {

        mainBox = new VerticalLayout;

        auto tool_bar = new ToolBar;

        auto button_referesh = new ImageButton(new Action(0, "refresh", null));

        tool_bar.addChild(button_referesh);

        auto grid = new StringGridWidgetWithTools("GRID1");
        grid.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
        grid.rowSelect = true;
        grid.headerCols = 0;
        grid.fixedCols = 0;
        grid.fixedRows = 0;
        grid.cols = 2;
        grid.rows = 0;
        grid.setColTitle(0, "Line");
        grid.setColTitle(1, "Entity");
        /* grid.cellSelected = &onCellSelected; */
        /* grid.cellActivated = &onCellActivated; */

        mainBox.addChild(tool_bar);
        mainBox.addChild(grid);
        /* Box mainBox; */

        /* ScrolledWindow sw; */
        /* TreeView tw; */
        /* ListStore tw_ls; */

    }

    private void buttonRefreshClicked(Button b)
    {

    }

    void close()
    {

    }

    Widget getWidget()
    {
        return mainBox;
    }

    void setData(OutlineToolInputData* data)
    {

    }

    Tuple!(JSONValue, Exception) getSettings()
    {
        auto ret = JSONValue(cast(JSONValue[string]) null);

        return tuple(ret, cast(Exception) null);
    }

    Exception setSettings(JSONValue v)
    {
        return cast(Exception) null;
    }

}
