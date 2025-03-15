module containd.model.network;

public struct Network
{
    public string name;
    public string id;
    public string driver;
    public string scope_;
    public bool ipv6;
    // Internal, Ingress, Attachable, IPAM (Driver, Options, Config (Subnet, Gateway))
    
    // TODO: more info
}

public class NetworkList
{
    //
}
