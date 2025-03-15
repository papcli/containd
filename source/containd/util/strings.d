module containd.util.strings;

public string clean(string s)
{
    import std.array : replace;
    import std.string : strip;

    return s.strip().replace("\n", "").replace("\r", "").replace("\"", "");
}
