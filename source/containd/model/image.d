module containd.model.image;

public struct Image
{
    public string id; // ID (maybe short form :12 or :19 with `sha256:` prefix?)
    public string[] tags; // RepoTags
    public string[] labels; // Config.Labels
    
    // TODO: more info
    // Created (https://dlang.org/phobos/std_datetime.html -> `DateTime#fromISOExtString(string)`)
    // Size
    // Architecture
    // Os
}

public class ImageList
{
    //
}
