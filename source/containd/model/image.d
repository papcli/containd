module containd.model.image;

import std.algorithm : startsWith;
import std.datetime : DateTime;

import containd.util;

public struct Image
{
    public string id; // ID (maybe short form :12 or :19 with `sha256:` prefix?)
    public string[] tags;
    public string[string] labels;
    public DateTime created;
    public long size;
    public string architecture;
    public string os;

    public string shortId() const @property
    in (id.length > 12)
    out (id; id.length >= 12 && id.length <= 19) => id.startsWith("sha256:") ? id[0..19] : id[0..12];

    public static Image fromDockerString(string s)
    {
        import std.conv : to;
        import std.algorithm : map, filter;
        import std.typecons : tuple;
        import std.array : assocArray, split, array, replace;
        import stdx.data.json : JSONValue, opt, toJSONValue;

        JSONValue image = toJSONValue(s)[0];

        string[] tags;
        if (opt(image["RepoTags"]).exists) tags = image["RepoTags"]
            .get!(JSONValue[])
            .map!(tag => tag.get!string)
            .array;

        string[string] labels;
        if (opt(image["Config"]["Labels"]).exists) labels = image["Config"]["Labels"]
            .get!(JSONValue[string])
            .byKeyValue()
            .map!(label => tuple(label.key.to!string, label.value.to!string))
            .array
            .assocArray;

        return Image(
            image.tryGet("Id").getOr("noid"),
            tags,
            labels,
            DateTime.fromISOExtString(image.tryGet("Created").getOr("1970-01-01T00:00:00Z").split('.')[0]),
            image.tryGet("Size").getOr(0L).to!long,
            image.tryGet("Architecture").getOr(""),
            image.tryGet("Os").getOr("")
        );
    }
}

public class ImageList
{
    //
}

public class ImageException : Exception
{
    this(string message)
    {
        super(message);
    }
}
