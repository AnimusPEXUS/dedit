module dedit.OutlineTool;

import gtk.Box;
import gtk.ScrolledWindow;
import gtk.Scrollbar;
import gtk.TreeView;
import gtk.TreeIter;
import gtk.ListStore;
import gtk.Widget;

import gobject.Value;

struct OutlineToolInputDataUnit
{
    uint line;
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
}

class OutlineTool
{
    Box mainBox;

    ScrolledWindow sw;
    TreeView tw;
    ListStore tw_ls;

    this(OutlineToolOptions* options)
    {
        sw = new ScrolledWindow();
        sw.setOverlayScrolling(false);

        tw = new TreeView();
        sw.add(tw);

        tw_ls = new ListStore(cast(GType[])[GType.UINT, GType.STRING]);

        mainBox = new Box(GtkOrientation.VERTICAL, 0);
        mainBox.packStart(sw, true, true, 0);

        tw.setModel(tw_ls);
    }

    void destroy()
    {
        mainBox.destroy();
    }

    Widget getWidget()
    {
        return mainBox;
    }

    void setData(OutlineToolInputData* data)
    {
        assert(data !is null);
        assert(data.data !is null);

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
        }

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