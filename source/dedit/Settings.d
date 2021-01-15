module dedit.Settings;

import std.json;

class WindowSettings
{
    bool maximized;
    bool minimized;
    int x, y;
    int width, height;
    int p1pos, p2pos;

    this()
    {
    }

    this(JSONValue v)
    {
        fromJSONValue(v);
    }

    JSONValue toJSONValue()
    {
        JSONValue ret = JSONValue(cast(string[string]) null);
        ret.object["maximized"] = JSONValue(maximized);
        ret.object["minimized"] = JSONValue(minimized);
        ret.object["x"] = JSONValue(x);
        ret.object["y"] = JSONValue(y);
        ret.object["width"] = JSONValue(width);
        ret.object["height"] = JSONValue(height);
        ret.object["p1pos"] = JSONValue(p1pos);
        ret.object["p2pos"] = JSONValue(p2pos);
        return ret;
    }

    bool fromJSONValue(JSONValue v)
    {
        if (v.type != JSONType.object)
        {
            return false;
        }
        if ("maximized" in v.object)
        {
            maximized = v.object["maximized"].boolean;
        }
        if ("minimized" in v.object)
        {
            minimized = v.object["minimized"].boolean;
        }
        if ("x" in v.object)
        {
            x = cast(int) v.object["x"].integer;
        }
        if ("y" in v.object)
        {
            y = cast(int) v.object["y"].integer;
        }
        if ("width" in v.object)
        {
            width = cast(int) v.object["width"].integer;
        }
        if ("height" in v.object)
        {
            height = cast(int) v.object["height"].integer;
        }
        if ("p1pos" in v.object)
        {
            p1pos = cast(int) v.object["p1pos"].integer;
        }
        if ("p2pos" in v.object)
        {
            p2pos = cast(int) v.object["p2pos"].integer;
        }
        return true;
    }
}
