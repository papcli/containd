module containd.model.volume;

import std.datetime : DateTime;

import containd.util;

public struct Volume
{
    public string name;
    public string driver;
    public string mountpoint;
    public string scope_;
    public string[string] labels;
    public DateTime created;
    // Options

    public static Volume fromDockerString(string s)
    {
        import std.conv : to;
        import std.algorithm : map, filter;
        import std.typecons : tuple;
        import std.array : assocArray, split, array, replace;
        import stdx.data.json : JSONValue, opt, toJSONValue;

        JSONValue volume = toJSONValue(s)[0];

        string[string] labels;
        if (opt(volume["Labels"]).exists) labels = volume["Labels"]
            .get!(JSONValue[string])
            .byKeyValue()
            .map!(label => tuple(label.key.to!string, label.value.to!string))
            .array
            .assocArray;

        return Volume(
            volume.tryGet("Name").getOr("noname"),
            volume.tryGet("Driver").getOr("null"),
            volume.tryGet("Mountpoint").getOr("nomountpoint"),
            volume.tryGet("Scope").getOr("local"),
            labels,
            DateTime.fromISOExtString(volume.tryGet("CreatedAt").getOr("1970-01-01T00:00:00Z").split('.')[0])
        );
    }
}

public class VolumeList
{
    //
}

public class VolumeException : Exception
{
    public this(string msg)
    {
        super(msg);
    }
}
