module dedit.modules.d.mod;

import gtk.TextView;
import gtk.Menu;
import gtk.Widget;

import gsv.SourceView;
import gsv.SourceBuffer;

import dedit.moduleinterface;
import dedit.Buffer;
import dedit.Controller;
import dedit.EditorWindow;

class View : ModuleBufferView
{
    private
    {
        Controller c;
        EditorWindow w;
        Buffer b;

        SourceView sv;
        SourceBuffer sb;

        bool close_already_called;
    }

    this(Controller c, EditorWindow w, Buffer b)
    {
        this.c = c;
        this.w = w;
        this.b = b;

        sb = new SourceBuffer(cast(GtkSourceBuffer*) null);
        sv = new SourceView(sb);
    }

    Widget getWidget()
    {
        return sv;
    }

    void close()
    {
        if (close_already_called)
        {
            return;
        }
        close_already_called = true;

        sv.destroy();
        sb.destroy();
    }
}

View createViewForBuffer(Controller c, EditorWindow w, Buffer b)
{
    return new View(c, w, b);
}

const dedit.moduleinterface.ModuleInformation ModuleInformation = {
    ModuleName: "D", SupportedExtensions: ["d"], createViewForBuffer: cast(
            ModuleBufferView function(Controller c, EditorWindow w, Buffer b))&createViewForBuffer
};
