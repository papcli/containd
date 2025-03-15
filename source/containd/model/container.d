module containd.model.container;

import containd.util;

public struct Container
{
    public string id;
    public string name;
    public string image;
    public string[string] labels;
    public string status;
    public string health;
    public string[int] ports;
    
    public string shortId() const @property
    in (id.length > 12)
    out (id; id.length == 12) => id[0..12];

    public static Container fromDockerString(string s)
    {
        import std.conv : to;
        import std.algorithm : map, filter;
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
            .filter!(port => !port.value.isNull)
            .map!(port => tuple(port.value.tryGet(0).tryGet("HostPort").getOr("0").to!int, port.key.to!string))
            .array
            .assocArray;

        return Container(
            container.tryGet("Id").getOr("noid"),
            container.tryGet("Name").getOr("noname").replace("/", ""),
            container.tryGet("Config").tryGet("Image").getOr("noimage"),
            labels,
            container.tryGet("State").tryGet("Status").getOr("unknown"),
            container.tryGet("State").tryGet("Health").tryGet("Status").getOr("unknown"),
            ports
        );
    }
}

public class ContainerList
{
    import containd : ContainerServiceClient;

    private
    {
        ContainerServiceClient client;
        Container[] containers;
    }

    public this(ContainerServiceClient client)
    {
        this.client = client;
        containers = [];
    }

    int opApply(int delegate(Container) dg)
    {
        foreach (container; containers)
        {
            if (dg(container)) return 1;
        }
        return 0;
    }

    public Container[] getAll()
    {
        import std.algorithm : filter, any, each;
        import std.array : array;
        import std.stdio : writefln;

        string[] missingIds = client.engine.getAllContainerIds()
            .filter!(id => !this.containers.any!(c => c.shortId == id))
            .array;

        missingIds.each!(id => this.containers ~= client.getContainerById(id));

        return this.containers;
    }

    public Container getById(string id)
    {
        import std.algorithm : find;

        auto containers = containers.find!(c => c.id == id);
        Container container;
        if (containers is null || containers == [])
        {
            container = client.getContainerById(id);
            this.containers ~= container;
        }

        return container;
    }

    public Container getByName(string name)
    {
        import std.algorithm : find;

        auto containers = containers.find!(c => c.name == name);
        Container container;
        if (containers is null || containers == [])
        {
            container = client.getContainerByName(name);
            this.containers ~= container;
        }

        return container;
    }
}

public class ContainerException : Exception
{
    public this(string message)
    {
        super(message);
    }
}
