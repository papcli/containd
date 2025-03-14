module containd.util.ver;

import std.process : execute;

public struct DockerVersion
{
    public int major;
    public int minor;
    public int patch;
    public string build;

    public string toString() const
    {
        import std.format : format;

        return format("%d.%d.%d %s", major, minor, patch, build);
    }

    public static DockerVersion fromString(string s)
    {
        import std.array : split;
        import std.string : strip;
        import std.conv : to;

        auto parts = s.split(",");
        assert(parts.length == 2);

        auto semver = parts[0].split(" ")[$ - 1].split(".");
        return DockerVersion(
            semver[0].to!int,
            semver[1].to!int,
            semver[2].to!int,
            parts[1].split(" ")[$ - 1].strip
        );
    }
}

public bool isDockerInstalled()
{
    auto result = execute(["docker", "--version"]);
    return result.status == 0;
}

public DockerVersion getDockerVersion()
{
    if (!isDockerInstalled)
    {
        return DockerVersion(0, 0, 0, "");
    }

    auto result = execute(["docker", "--version"]);
    assert(result.status == 0);

    return DockerVersion.fromString(result.output);
}

public bool isPodmanInstalled()
{
    auto result = execute(["podman", "--version"]);
    return result.status == 0;
}
