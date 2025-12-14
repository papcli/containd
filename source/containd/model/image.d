module containd.model.image;

import std.algorithm : startsWith;
import std.datetime : DateTime;

import containd.util;

/++
 + A struct that represents a container image.
 +/
public struct Image
{
    /// The id of the image.
    public string id;
    /// The tags of the image.
    public string[] tags;
    /// The labels of the image.
    public string[string] labels;
    /// The creation date and time of the image.
    public DateTime created;
    /// The size of the image.
    public long size;
    /// The architecture of the image.
    public string architecture;
    /// The operating system of the image.
    public string os;

    /// The id of the image in short form (12 or 19 characters including `sha256:`).
    public string shortId() const @property
    in (id.length > 12)
    out (id; id.length >= 12 && id.length <= 19) => id.startsWith("sha256:") ? id[0..19] : id[0..12];

    /// Compares the id of the image with the given id.
    public bool cmpId(string id) const => this.id == id || this.shortId == id;

    /++
     + Creates an `Image` object from a Docker JSON string.
     +/
    public static Image fromDockerString(string s)
    {
        import std.conv : to;
        import std.algorithm : map, filter;
        import std.typecons : tuple;
        import std.array : assocArray, split, array, replace;
        import stdx.data.json : JSONValue, opt, toJSONValue;

        JSONValue image = toJSONValue(s)[0];

        string[] tags_;
        if (opt(image["RepoTags"]).exists) tags_ = image["RepoTags"]
            .get!(JSONValue[])
            .map!(tag => tag.get!string)
            .array;

        string[string] labels_;
        if (opt(image["Config"]["Labels"]).exists) labels_ = image["Config"]["Labels"]
            .get!(JSONValue[string])
            .byKeyValue()
            .map!(label => tuple(label.key, label.value.to!string))
            .array
            .assocArray;

        return Image(
            image.find("Id").orElse("noid"),
            tags_,
            labels_,
            DateTime.fromISOExtString(image.find("Created").orElse("1970-01-01T00:00:00Z").split('.')[0]),
            image.find("Size").orElse(0L).to!long,
            image.find("Architecture").orElse(""),
            image.find("Os").orElse("")
        );
    }
}

/++
 + A class that represents a list of images.
 + The list is lazy-loaded, meaning that it will only fetch the images from the daemon when they are requested.
 + The list is also cached, meaning that it will only fetch the images once.
 + All images can be fetched with `#getAll()`.
 +/
public class ImageList
{
    import containd : ContainerServiceClient;

    private
    {
        ContainerServiceClient client;
        Image[] images;
    }

    public this(ContainerServiceClient client)
    {
        this.client = client;
        this.images = [];
    }

    int opApply(int delegate(Image) dg)
    {
        foreach (image; images)
        {
            if (dg(image))
            {
                return 1;
            }
        }

        return 0;
    }

    /++
     + Fetches all the missing images from the daemon in parallel.
     + If the image is already in the list, it will not be fetched again.
     + Returns all the images in the list.
     +/
    public Image[] getAll()
    {
        import std.algorithm : filter, any, each;
        import std.array : array;
        import std.parallelism : parallel;

        string[] missingIds = client.engine.getAllImageIds()
            .filter!(id => !this.images.any!(image => image.shortId == id))
            .array;

        missingIds.parallel.each!(id => this.images ~= client.engine.getImageById(id));

        return this.images;
    }

    /++
     + Fetches the image with the given id from the daemon.
     + If the image is already in the list, it will not be fetched again.
     + Returns the image.
     +/
    public Image getById(string id)
    {
        import std.algorithm : find;

        auto images = images.find!(image => image.cmpId(id));
        Image image;
        if (images is null || images == [])
        {
            image = client.engine.getImageById(id);
            this.images ~= image;
        }

        return image;
    }
}

/++
 + An exception that is thrown when something goes wrong with the image.
 +/
public class ImageException : Exception
{
    public this(string message)
    {
        super(message);
    }
}
