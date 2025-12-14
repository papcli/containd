module containd.model.network;

import std.datetime : DateTime;

import containd.util;

/++
 + A struct that represents a network.
 +/
public struct Network
{
    /// The name of the network.
    public string name;
    /// The id of the network.
    public string id;
    /// The creation date and time of the network.
    public DateTime created;
    /// The scope of the network.
    public NetworkScope scope_;
    /// The driver of the network.
    public NetworkDriver driver;
    /// Whether IPv6 is enabled for the network.
    public bool ipv6;
    /// The labels of the network.
    public string[string] labels;
    /// The subnet of the network.
    public string subnet;
    /// The gateway of the network.
    public string gateway;
    /// The auxiliary addresses of the network.
    public string[string] auxiliaries;
    /// Whether the network is internal.
    public bool internal;
    /// Whether the network is an ingress network.
    public bool ingress;
    /// Whether the network is attachable.
    public bool attachable;

    /// The id of the network in short form (12 characters).
    public string shortId() const @property
    in (id.length > 12)
    out (id; id.length == 12) => id[0..12];

    /// Compares the id of the network with the given id.
    public bool cmpId(string id) const => this.id == id || this.shortId == id;

    /++
     + Creates a `Network` object from a Docker JSON string.
     +/
    public static Network fromDockerString(string s)
    {
        import std.conv : to;
        import std.algorithm : map, filter;
        import std.typecons : tuple;
        import std.array : assocArray, split, array, replace;
        import stdx.data.json : JSONValue, opt, toJSONValue;

        JSONValue network = toJSONValue(s)[0];

        string[string] labels_;
        if (opt(network["Labels"]).exists) labels_ = network["Labels"]
            .get!(JSONValue[string])
            .byKeyValue()
            .map!(label => tuple(label.key, label.value.get!string))
            .array
            .assocArray;

        // TODO: allow for multiple subnets, gateways and auxiliary (multiple configs), instead of using index 0
        string[string] auxiliaries_;
        if (opt(network["IPAM"]["Config"][0]["AuxiliaryAddresses"]).exists) auxiliaries_ = network["IPAM"]["Config"][0]["AuxiliaryAddresses"]
            .get!(JSONValue[string])
            .byKeyValue()
            .map!(aux => tuple(aux.key, aux.value.get!string))
            .array
            .assocArray;

        return Network(
            network.find("Name").orElse("noname"),
            network.find("Id").orElse("noid"),
            DateTime.fromISOExtString(network.find("Created").orElse("1970-01-01T00:00:00Z").split('.')[0]),
            network.find("Scope").orElse("local").valueToEnum!NetworkScope.get,
            network.find("Driver").orElse("null").valueToEnum!NetworkDriver.get,
            network.find("EnableIPv6").orElse(false).to!bool,
            labels_,
            network.find("IPAM").find("Config").find(0).find("Subnet").orElse(""),
            network.find("IPAM").find("Config").find(0).find("Gateway").orElse(""),
            auxiliaries_,
            network.find("Internal").orElse(false).to!bool,
            network.find("Ingress").orElse(false).to!bool,
            network.find("Attachable").orElse(false).to!bool
        );
    }
}

/// Should this be removed and just use string instead?
public enum NetworkScope : string
{
    LOCAL  = "local",
    GLOBAL = "global",
}

/// Should this be removed and just use string instead?
public enum NetworkDriver : string
{
    BRIDGE  = "bridge",
    HOST    = "host",
    NONE    = "none",
    OVERLAY = "overlay",
    IPVLAN  = "ipvlan",
    MACVLAN = "macvlan",
    null_   = "null",
}

/++
 + A class that represents a list of networks.
 + The list is lazy-loaded, meaning that it will only fetch the networks from the daemon when they are requested.
 + The list is also cached, meaning that it will only fetch the networks once.
 + All networks can be fetched with `#getAll()`.
 +/
public class NetworkList
{
    import containd : ContainerServiceClient;

    private
    {
        ContainerServiceClient client;
        Network[] networks;
    }

    public this(ContainerServiceClient client)
    {
        this.client = client;
        this.networks = [];
    }

    int opApply(int delegate(Network) dg)
    {
        foreach (network; networks)
        {
            if (dg(network))
            {
                return 1;
            }
        }

        return 0;
    }

    /++
     + Fetches all the missing networks from the daemon in parallel.
     + If the network is already in the list, it will not be fetched again.
     + Returns all the networks in the list.
     +/
    public Network[] getAll()
    {
        import std.algorithm : filter, any, each;
        import std.array : array;
        import std.parallelism : parallel;

        string[] missingIds = client.engine.getAllNetworkIds()
            .filter!(id => !this.networks.any!(network => network.shortId == id))
            .array;

        missingIds.parallel.each!(id => this.networks ~= client.engine.getNetworkById(id));

        return this.networks;
    }

    /++
     + Fetches the network with the given id from the daemon.
     + If the network is already in the list, it will not be fetched again.
     + Returns the network.
     +/
    public Network getById(string id)
    {
        import std.algorithm : find;

        auto networks = networks.find!(network => network.cmpId(id));
        Network network;
        if (networks is null || networks == [])
        {
            network = client.engine.getNetworkById(id);
            this.networks ~= network;
        }

        return network;
    }

    /++
     + Fetches the network with the given name from the daemon.
     + If the network is already in the list, it will not be fetched again.
     + Returns the network.
     +/
    public Network getByName(string name)
    {
        import std.algorithm : find;

        auto networks = networks.find!(network => network.name == name);
        Network network;
        if (networks is null || networks == [])
        {
            network = client.engine.getNetworkByName(name);
            this.networks ~= network;
        }

        return network;
    }
}

/++
 + An exception that is thrown when something goes wrong with the network.
 +/
public class NetworkException : Exception
{
    public this(string message)
    {
        super(message);
    }
}
