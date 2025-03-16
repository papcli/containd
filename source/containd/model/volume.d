module containd.model.volume;

import std.datetime : DateTime;

import containd.util;

/++
 + A struct representing a container volume.
 +/
public struct Volume
{
    /// The name of the volume.
    public string name;
    /// The driver of the volume.
    public string driver;
    /// The mountpoint of the volume.
    public string mountpoint;
    /// The scope of the volume.
    public string scope_;
    /// The labels of the volume.
    public string[string] labels;
    /// The creation date and time of the volume.
    public DateTime created;
    // Options

    /++
     + Creates a `Volume` object from a Docker JSON string.
     +/
    public static Volume fromDockerString(string s)
    {
        import std.conv : to;
        import std.algorithm : map, filter;
        import std.typecons : tuple;
        import std.array : assocArray, split, array, replace;
        import stdx.data.json : JSONValue, opt, toJSONValue;

        JSONValue volume = toJSONValue(s)[0];

        string[string] labels_;
        if (opt(volume["Labels"]).exists) labels_ = volume["Labels"]
            .get!(JSONValue[string])
            .byKeyValue()
            .map!(label => tuple(label.key.to!string, label.value.to!string))
            .array
            .assocArray;

        return Volume(
            volume.find("Name").orElse("noname"),
            volume.find("Driver").orElse("null"),
            volume.find("Mountpoint").orElse("nomountpoint"),
            volume.find("Scope").orElse("local"),
            labels_,
            DateTime.fromISOExtString(volume.find("CreatedAt").orElse("1970-01-01T00:00:00Z").split('.')[0])
        );
    }
}

/++
 + A class that represents a list of volumes.
 + The list is lazy-loaded, meaning that it will only fetch the volumes from the daemon when they are requested.
 + The list is also cached, meaning that it will only fetch the volumes once.
 + All volumes can be fetched with `#getAll()`.
 +/
public class VolumeList
{
    import containd : ContainerServiceClient;

    private
    {
        ContainerServiceClient client;
        Volume[] volumes;
    }

    public this(ContainerServiceClient client)
    {
        this.client = client;
        this.volumes = [];
    }

    int opApply(int delegate(Volume) dg)
    {
        foreach (volume; volumes)
        {
            if (dg(volume))
            {
                return 1;
            }
        }

        return 0;
    }

    /++
     + Fetches all the missing volumes from the daemon in parallel.
     + If the volume is already in the list, it will not be fetched again.
     + Returns all the volumes in the list.
     +/
    public Volume[] getAll()
    {
        import std.algorithm : filter, any, each;
        import std.array : array;
        import std.parallelism : parallel;
        
        string[] missingNames = client.engine.getAllVolumeNames()
            .filter!(name => !this.volumes.any!(volume => volume.name == name))
            .array;
            
        missingNames.parallel.each!(name => this.volumes ~= client.getVolumeByName(name));
        
        return this.volumes;
    }
    
    /++
     + Fetches the volume with the given name from the daemon.
     + If the volume is already in the list, it will not be fetched again.
     + Returns the volume.
     +/
    public Volume getByName(string name)
    {
        import std.algorithm : find;
        
        auto volumes = volumes.find!(volume => volume.name == name);
        Volume volume;
        if (volumes is null || volumes == [])
        {
            volume = client.getVolumeByName(name);
            this.volumes ~= volume;
        }
        
        return volume;
    }
}

/++
 + An exception that is thrown when something goes wrong with the volume.
 +/
public class VolumeException : Exception
{
    public this(string msg)
    {
        super(msg);
    }
}
