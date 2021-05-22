module dedit.OutlineTool;

import std.stdio;

import dlangui;

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

struct OutlineToolOptions
{
    void delegate(int new_line_number) userWishesToGoToLine;
    void delegate() userWishesToRefreshData;
}

class OutlineTool
{

    OutlineToolOptions* options;

    VerticalLayout mainBox;
    /* Box mainBox; */

    /* ScrolledWindow sw; */
    /* TreeView tw; */
    /* ListStore tw_ls; */

    this(OutlineToolOptions* options)
    {

        this.options = options;

        mainBox = new VerticalLayout;
        /*
        sw = new ScrolledWindow();
        sw.setOverlayScrolling(false);

        tw = new TreeView();
        sw.add(tw);

        tw_ls = new ListStore(cast(GType[])[GType.UINT, GType.STRING]);

        mainBox = new Box(GtkOrientation.VERTICAL, 0);

        auto button_refresh = new Button("refresh");
        button_refresh.addOnClicked(&buttonRefreshClicked);

        mainBox.packStart(button_refresh, false, true, 0);
        mainBox.packStart(sw, true, true, 0);

        tw.setModel(tw_ls);

        setupTableColumns(tw); */
    }

    private void buttonRefreshClicked(Button b)
    {

        /* if (options.userWishesToRefreshData !is null)
        {
            debug
            {
                writeln("refresh button clicked");
            }
            options.userWishesToRefreshData();
        } */

    }

    /* private void setupTableColumns(TreeView tw)
    {
        /* {
            auto rend = new CellRendererText();
            // rend.setProperty("ellipsize", PangoEllipsizeMode.START);
            auto col = new TreeViewColumn("line", rend, "text", 0);
            // this.fileNameTreeViewColumn = col;
            // col.setResizable(true);
            tw.insertColumn(col, 0);
        }

        {
            auto rend = new CellRendererText();
            rend.setProperty("ellipsize", PangoEllipsizeMode.END);
            auto col = new TreeViewColumn("contents", rend, "text", 1);
            // col.setResizable(true);
            tw.insertColumn(col, 1);
        } * /
    } */

    void close()
    {
        /* mainBox.destroy(); */
    }

    Widget getWidget()
    {
        return mainBox;
    }

    void setData(OutlineToolInputData* data)
    {
        /* assert(data !is null);
        // assert(data.data !is null);

        foreach (size_t k, OutlineToolInputDataUnit* v; data.data)
        {
            bool found = false;

            TreeIter iter = new TreeIter;
            bool ok = tw_ls.getIterFirst(iter);

            while (ok)
            {
                Value val = tw_ls.getValue(iter, 0);
                auto line_num = val.getUint();

                val = tw_ls.getValue(iter, 1);
                auto line_text = val.getString();

                if (line_num == v.line && line_text == v.text)
                {
                    found = true;
                    break;
                }
                ok = tw_ls.iterNext(iter);
            }

            if (!found)
            {
                iter = new TreeIter;
                tw_ls.append(iter);
                tw_ls.setValue(iter, 0, v.line);
                tw_ls.setValue(iter, 1, v.text);
            }
        }

        {
            TreeIter iter = new TreeIter;
            bool ok = tw_ls.getIterFirst(iter);

            while (ok)
            {
                Value val = tw_ls.getValue(iter, 0);
                auto line_num = val.getUint();

                val = tw_ls.getValue(iter, 1);
                auto line_text = val.getString();

                bool found = false;

                foreach (size_t k, OutlineToolInputDataUnit* v; data.data)
                {
                    if (line_num == v.line && line_text == v.text)
                    {
                        found = true;
                        break;
                    }
                }

                if (!found)
                {
                    ok = tw_ls.remove(iter);
                }
                else
                {
                    ok = tw_ls.iterNext(iter);
                }

            }
        } */

    }

    string getSettings()
    {
        /*auto x = new OutlineToolSettings();
        x.scroll_position = (cast(Scrollbar)(sw.getVscrollbar())).getValue();
        auto y = x.toJSONValue();
        return y.toJSON();*/
        return "";
    }

    void setSettings(string value)
    {

        /*
        new Idle(delegate bool() {

            auto x = new OutlineToolSettings(value);
            (cast(Scrollbar)(sw.getVscrollbar())).setValue(x.scroll_position);

            return false;
        });*/

    }

}
