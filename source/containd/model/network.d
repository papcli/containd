module containd.model.network;

import std.datetime : DateTime;

import containd.util;

public struct Network
{
    public string name;
    public string id;
    public DateTime created;
    public NetworkScope scope_;
    public NetworkDriver driver;
    public bool ipv6;
    public string[string] labels;
    public string subnet;
    public string gateway;
    public string[string] auxiliaries;
    public bool internal;
    public bool ingress;
    public bool attachable;
    
    public string shortId() const @property
    in (id.length > 12)
    out (id; id.length == 12) => id[0..12];

    public static Network fromDockerString(string s)
    {
        import std.conv : to;
        import std.algorithm : map, filter;
        import std.typecons : tuple;
        import std.array : assocArray, split, array, replace;
        import stdx.data.json : JSONValue, opt, toJSONValue;

        JSONValue network = toJSONValue(s)[0];

        string[string] labels;
        if (opt(network["Labels"]).exists) labels = network["Labels"]
            .get!(JSONValue[string])
            .byKeyValue()
            .map!(label => tuple(label.key.to!string, label.value.to!string))
            .array
            .assocArray;
        
        // TODO: allow for multiple subnets, gateways and auxiliary (multiple configs), instead of using index 0
        string[string] auxiliaries;
        if (opt(network["IPAM"]["Config"][0]["AuxiliaryAddresses"]).exists) auxiliaries = network["IPAM"]["Config"][0]["AuxiliaryAddresses"]
            .get!(JSONValue[string])
            .byKeyValue()
            .map!(aux => tuple(aux.key.to!string, aux.value.to!string))
            .array
            .assocArray;

        return Network(
            network.tryGet("Name").getOr("noname"),
            network.tryGet("Id").getOr("noid"),
            DateTime.fromISOExtString(network.tryGet("Created").getOr("1970-01-01T00:00:00Z").split('.')[0]),
            network.tryGet("Scope").getOr("local").valueToEnum!NetworkScope.get,
            network.tryGet("Driver").getOr("null").valueToEnum!NetworkDriver.get,
            network.tryGet("EnableIPv6").getOr(false).to!bool,
            labels,
            network.tryGet("IPAM").tryGet("Config").tryGet(0).tryGet("Subnet").getOr(""),
            network.tryGet("IPAM").tryGet("Config").tryGet(0).tryGet("Gateway").getOr(""),
            auxiliaries,
            network.tryGet("Internal").getOr(false).to!bool,
            network.tryGet("Ingress").getOr(false).to!bool,
            network.tryGet("Attachable").getOr(false).to!bool
        );
    }
}

public enum NetworkScope : string
{
    LOCAL  = "local",
    GLOBAL = "global",
}

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

public class NetworkList
{
    //
}

public class NetworkException : Exception
{
    this(string message)
    {
        super(message);
    }
}
