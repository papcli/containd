module containd.service.docker;

import std.algorithm : map;
import std.array : split, array;

import containd.engine;
import containd.model;
import containd.util;

import std.stdio : writeln, writefln;

public class DockerService : ContainerEngineAPI
{
    private string socket;

    public this(string socket = "unix:///var/run/docker.sock")
    {
        this.socket = socket;
    }

    /++ Information Retrieval +/
    public Container[] getAllContainers()
    {
        auto containers = execDockerCmd(["ps", "-a", "--format", "\"{{.ID}}\""]);
        if (containers.status != 0)
        {
            throw new ContainerException("Something went wrong");
        }

        return containers.output.split('\n')
            .map!(id => getContainerById(id.clean))
            .array;
    }

    public string[] getAllContainerIds()
    {
        auto containers = execDockerCmd(["ps", "-a", "--format", "\"{{.ID}}\""]);
        if (containers.status != 0)
        {
            throw new ContainerException("Something went wrong");
        }

        return containers.output.split('\n')
            .map!(id => id.clean)
            .array;
    }

    public string[] getAllContainerNames()
    {
        auto containers = execDockerCmd(["ps", "-a", "--format", "\"{{.Names}}\""]);
        if (containers.status != 0)
        {
            throw new ContainerException("Something went wrong");
        }

        return containers.output.split('\n')
            .map!(name => name.clean)
            .array;
    }

    public Container getContainerById(string id)
    {
        auto result = execDockerCmd(["container", "inspect", id]);
        if (result.status != 0)
        {
            throw new ContainerException("No container with the ID '" ~ id ~ "' was found");
        }

        return Container.fromDockerString(result.output);
    }

    public Container getContainerByName(string name)
    {
        auto result = execDockerCmd(["container", "inspect", name]);
        if (result.status != 0)
        {
            throw new ContainerException("No container with the name '" ~ name ~ "' was found");
        }

        return Container.fromDockerString(result.output);
    }

    public Image[] getAllImages()
    {
        auto images = execDockerCmd(["image", "ls", "-a", "--format", "\"{{.ID}}\""]);
        if (images.status != 0)
        {
            throw new ImageException("Something went wrong");
        }

        return images.output.split('\n')
            .map!(id => getImageById(id.clean))
            .array;
    }

    public Image getImageById(string id)
    {
        auto result = execDockerCmd(["image", "inspect", id]);
        if (result.status != 0)
        {
            throw new ImageException("No image with the ID '" ~ id ~ "' was found");
        }

        return Image.fromDockerString(result.output);
    }

    public Network[] getAllNetworks()
    {
        auto networks = execDockerCmd(["network", "ls", "--format", "\"{{.ID}}\""]);
        if (networks.status != 0)
        {
            throw new NetworkException("Something went wrong");
        }

        return networks.output.split('\n')
            .map!(id => getNetworkById(id.clean))
            .array;
    }

    public Network getNetworkById(string id)
    {
        auto result = execDockerCmd(["network", "inspect", id]);
        if (result.status != 0)
        {
            throw new NetworkException("No network with the ID '" ~ id ~ "' was found");
        }

        return Network.fromDockerString(result.output);
    }

    public Network getNetworkByName(string name)
    {
        auto result = execDockerCmd(["network", "inspect", name]);
        if (result.status != 0)
        {
            throw new NetworkException("No network with the name '" ~ name ~ "' was found");
        }

        return Network.fromDockerString(result.output);
    }

    public Volume[] getAllVolumes()
    {
        auto volumes = execDockerCmd(["volume", "ls", "--format", "\"{{.Name}}\""]);
        if (volumes.status != 0)
        {
            throw new VolumeException("Something went wrong");
        }

        return volumes.output.split('\n')
            .map!(name => getVolumeByName(name.clean))
            .array;
    }
    
    public Volume getVolumeByName(string name)
    {
        auto result = execDockerCmd(["volume", "inspect", name]);
        if (result.status != 0)
        {
            throw new VolumeException("No volume with the name '" ~ name ~ "' was found");
        }

        return Volume.fromDockerString(result.output);
    }
}
