module dedit.ControllerViewWindowMGR;

import std.algorithm;

import dedit.ViewWindow;

alias ChangeListener = void delegate(bool is_add, ViewWindow win);

class ControllerViewWindowMGR
{
    private ViewWindow[] list;
    private ChangeListener[] cl;

    bool isIn(string project, string filename)
    {
        return get(project, filename) !is null;
    }

    ViewWindow get(string project, string filename)
    {
        for (size_t i = 0; i != list.length; i++)
        {
            auto x = list[i];
            if (x.project == project && x.filename == filename)
            {
                return x;
            }
        }
        return null;
    }

    bool isIn(ViewWindow vw)
    {
        return isIn(vw.project, vw.filename);
    }

    void add(ViewWindow vw)
    {
        for (size_t i = 0; i != list.length; i++)
        {
            if (list[i] == vw)
            {
                return;
            }
        }
        list ~= vw;

        emit(true, vw);
    }

    void remove(string project, string filename)
    {
        for (size_t i = list.length - 1; i != -1; i = i - 1)
        {
            auto x = list[i];
            if (x.project == project && x.filename == filename)
            {
                list = list.remove(i);
                emit(false, x);
            }
        }
    }

    void remove(ViewWindow vw)
    {
        for (size_t i = list.length - 1; i != -1; i = i - 1)
        {
            if (list[i] == vw)
            {
                list = list.remove(i);
            }
        }

        emit(false, vw);
    }

    void emit(bool is_add, ViewWindow win)
    {
        for (size_t i = 0; i != cl.length; i++)
        {
            cl[i](is_add, win);
        }
    }

    void listItems(void delegate(ViewWindow win) l)
    {
        foreach (size_t i, ref ViewWindow w; list)
        {
            l(w);
        }
    }

    void addChangeListener(ChangeListener l)
    {
        cl ~= l;
    }

    void removeChangeListener(ChangeListener l)
    {
        for (size_t i = cl.length - 1; i != -1; i = i - 1)
        {
            if (cl[i] == l)
            {
                cl = cl.remove(i);
            }
        }
    }
}
