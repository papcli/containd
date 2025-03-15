module containd.model.volume;

public struct Volume
{
    public string name;
    public string driver;
    public string mountpoint;
    public string scope_;
    public string[] labels;
    // Options, CreatedAt
}

public class VolumeList
{
    //
}
