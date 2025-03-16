module containd.model.container;

import containd.util;

/++
 + A struct that represents a container.
 +/
public struct Container
{
    /// The id of the container.
    public string id;
    /// The name of the container.
    public string name;
    /// The image of the container.
    public string image;
    /// The labels of the container.
    public string[string] labels;
    /// The status of the container.
    public string status;
    /// The health of the container.
    public string health;
    /// The ports of the container.
    public string[int] ports;
    /// The networks of the container.
    public string[] networks;
    /// The environment variables of the container.
    public string[string] environment;
    /// The mounts of the container.
    public ContainerMount[] mounts;

    /// The id of the container in short form (12 characters).
    public string shortId() const @property
    in (id.length > 12)
    out (id; id.length == 12) => id[0..12];

    /// Compares the id of the container with the given id.
    public bool cmpId(string id) const => this.id == id || this.shortId == id;

    /++
     + Creates a `Container` object from a Docker JSON string.
     +/
    public static Container fromDockerString(string s)
    {
        import std.conv : to;
        import std.algorithm : map, filter;
        import std.typecons : tuple;
        import std.array : assocArray, split, array, replace;
        import stdx.data.json : JSONValue, opt, toJSONValue, toJSON;

        JSONValue container = toJSONValue(s)[0];

        string[string] labels_;
        if (opt(container["Config"]["Labels"]).exists) labels_ = container["Config"]["Labels"]
            .get!(JSONValue[string])
            .byKeyValue()
            .map!(label => tuple(label.key.to!string, label.value.to!string))
            .array
            .assocArray;

        string[int] ports_;
        if (opt(container["NetworkSettings"]["Ports"]).exists) ports_ = container["NetworkSettings"]["Ports"]
            .get!(JSONValue[string])
            .byKeyValue()
            .filter!(port => !port.value.isNull)
            .map!(port => tuple(port.value.find(0).find("HostPort").orElse("0").to!int, port.key.to!string))
            .array
            .assocArray;
            
        string[] networks_;
        if (opt(container["NetworkSettings"]["Networks"]).exists) networks_ = container["NetworkSettings"]["Networks"]
            .get!(JSONValue[string])
            .byKeyValue()
            .map!(network => network.key.to!string)
            .array;
            
        string[string] environment_;
        if (opt(container["Config"]["Env"]).exists) environment_ = container["Config"]["Env"]
            .get!(JSONValue[])
            .map!(env => env.get!string.split("="))
            .map!(env => tuple(env[0], env[1]))
            .array
            .assocArray;
            
        ContainerMount[] mounts_;
        if (opt(container["Mounts"]).exists) mounts_ = container["Mounts"]
            .get!(JSONValue[])
            .map!(mount => ContainerMount.fromJSON(mount))
            .array;

        return Container(
            container.find("Id").orElse("noid"),
            container.find("Name").orElse("noname").replace("/", ""),
            container.find("Config").find("Image").orElse("noimage"),
            labels_,
            container.find("State").find("Status").orElse("unknown"),
            container.find("State").find("Health").find("Status").orElse("unknown"),
            ports_,
            networks_,
            environment_,
            mounts_
        );
    }
}

/++
 + A struct that represents a container mount.
 +/
struct ContainerMount
{
    /// The container source of the mount.
    public string source;
    /// The local destination of the mount.
    public string destination;
    /// The mode of the mount.
    public string mode;
    /// The type of the mount.
    public string type;
    
    import stdx.data.json : JSONValue;
    
    /++
     + Creates a `ContainerMount` object from a Docker JSON object.
     +/
    public static ContainerMount fromJSON(JSONValue mount)
    {   
        return ContainerMount(
            mount.find("Source").orElse(""),
            mount.find("Destination").orElse(""),
            mount.find("Mode").orElse(""),
            mount.find("Type").orElse("")
        );
    }
}

/++
 + A class that represents a list of containers.
 + The list is lazy-loaded, meaning that it will only fetch the containers from the daemon when they are requested.
 + The list is also cached, meaning that it will only fetch the containers once.
 + All containers can be fetched with `#getAll()`.
 +/
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
        this.containers = [];
    }

    int opApply(int delegate(Container) dg)
    {
        foreach (container; containers)
        {
            if (dg(container)) return 1;
        }

        return 0;
    }

    /++
     + Fetches all the missing containers from the daemon in parallel.
     + If the container is already in the list, it will not be fetched again.
     + Returns all the containers in the list.
     +/
    public Container[] getAll()
    {
        import std.algorithm : filter, any, each;
        import std.array : array;
        import std.parallelism : parallel;

        string[] missingIds = client.engine.getAllContainerIds()
            .filter!(id => !this.containers.any!(c => c.shortId == id))
            .array;

        missingIds.parallel.each!(id => this.containers ~= client.getContainerById(id));

        return this.containers;
    }

    /++
     + Fetches the container with the given id from the daemon.
     + If the container is already in the list, it will not be fetched again.
     + Returns the container.
     +/
    public Container getById(string id)
    {
        import std.algorithm : find;

        auto containers = containers.find!(c => c.cmpId(id));
        Container container;
        if (containers is null || containers == [])
        {
            container = client.getContainerById(id);
            this.containers ~= container;
        }

        return container;
    }

    /++
     + Fetches the container with the given name from the daemon.
     + If the container is already in the list, it will not be fetched again.
     + Returns the container.
     +/
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

/++
 + An exception that is thrown when something goes wrong with the container.
 +/
public class ContainerException : Exception
{
    public this(string message)
    {
        super(message);
    }
}
