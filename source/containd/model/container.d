module containd.model.container;

public struct Container
{
    public string id;
    public string name;
    public string image;
    public string[string] labels;
    public string status;
    public string health;
    public string[int] ports;

    public static Container fromDockerString(string s)
    {
        import std.conv : to;
        import std.algorithm : map;
        import std.typecons : tuple;
        import std.array : assocArray, split, array, replace;
        import stdx.data.json : parseJSONValue, JSONValue, opt, toJSONValue;

        JSONValue container = toJSONValue(s)[0];

        string[string] labels;
        if (opt(container["Config"]["Labels"]).exists) labels = container["Config"]["Labels"]
            .get!(JSONValue[string])
            .byKeyValue()
            .map!(label => tuple(label.key.to!string, label.value.to!string))
            .array
            .assocArray;

        string[int] ports;
        if (opt(container["NetworkSettings"]["Ports"]).exists) ports = container["NetworkSettings"]["Ports"]
            .get!(JSONValue[string])
            .byKeyValue()
            .map!(port => tuple(port.value.isNull ? 0 : port.value[0]["HostPort"].get!string.to!int, port.key.to!string)) //port.value[0]["HostPort"].get!string.to!int
            .array
            .assocArray;

        return Container(
            container["Id"].get!string,
            container["Name"].get!string.replace("/", ""),
            container["Config"]["Image"].get!string,
            labels,
            container["State"]["Status"].get!string,
            `container["State"]["Health"]["Status"].to!string`,
            ports
        );
    }
}

public class ContainerList
{
    //
}

public class ContainerException : Exception
{
    public this(string message)
    {
        super(message);
    }
}
