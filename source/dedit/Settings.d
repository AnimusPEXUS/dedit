module dedit.Settings;

import std.json;

class WindowSettings
{
    bool maximized;
    bool minimized;
    int x, y;
    int width, height;
    int p1pos, p2pos;
    int filename_column_width; // TODO: todo
    int buffer_view_filename_column_width;

    string[] window_buffers;
    string[string] window_buffer_view_settings;

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
        ret.object["buffer_view_filename_column_width"] = JSONValue(
                buffer_view_filename_column_width);
        ret.object["window_buffers"] = JSONValue(window_buffers);

        //auto window_buffer_view_settings_jv = JSONValue(cast(string[string]) null);

        ret.object["window_buffer_view_settings"] = JSONValue(window_buffer_view_settings);
        /*ret.object["window_buffer_view_settings"] = window_buffer_view_settings_jv;

        foreach (k, v; window_buffer_view_settings)
        {
            window_buffer_view_settings_jv.object[k] = v.toJSONValue();
        }*/

        return ret;
    }

    bool fromJSONValue(JSONValue x)
    {
        if (x.type != JSONType.object)
        {
            return false;
        }

        if ("maximized" in x.object)
        {
            maximized = x.object["maximized"].boolean;
        }

        if ("minimized" in x.object)
        {
            minimized = x.object["minimized"].boolean;
        }

        if ("x" in x.object)
        {
            this.x = cast(int) x.object["x"].integer;
        }

        if ("y" in x.object)
        {
            y = cast(int) x.object["y"].integer;
        }

        if ("width" in x.object)
        {
            width = cast(int) x.object["width"].integer;
        }

        if ("height" in x.object)
        {
            height = cast(int) x.object["height"].integer;
        }

        if ("p1pos" in x.object)
        {
            p1pos = cast(int) x.object["p1pos"].integer;
        }

        if ("p2pos" in x.object)
        {
            p2pos = cast(int) x.object["p2pos"].integer;
        }

        if ("buffer_view_filename_column_width" in x.object)
        {
            buffer_view_filename_column_width = cast(int) x
                .object["buffer_view_filename_column_width"].integer;
        }

        if ("window_buffers" in x.object)
        {
            // window_buffers.clear;

            window_buffers = window_buffers[];

            foreach (k, v; x.object["window_buffers"].array)
            {
                window_buffers ~= v.str;
            }
            // window_buffers = v.object["window_buffers"].array;

        }

        if ("window_buffer_view_settings" in x.object)
        {
            /*auto window_buffer_view_settings_jv = x.object["window_buffer_view_settings"];
            window_buffer_view_settings.clear;*/

            window_buffer_view_settings = cast(string[string])(
                    x.object["window_buffer_view_settings"].object);

            /*
            foreach (string k, v; window_buffer_view_settings_jv)
            {
                window_buffer_view_settings[k] = new WindowBufferSettings(v);
            }*/
        }

        return true;
    }
}
