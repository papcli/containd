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
        // Perhaps we should do this lazily and only initialize the containers when they are actually accessed
        // ^^ Perhaps this should be done using the ContainerList class. But not in here. This should be done in the `ContainerServiceClient`
    
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

    /*
    public Image[] getAllImages();
    public Image getImageById(string id);

    public Network[] getAllNetworks();
    public Network getNetworkByName(string name);

    public Volume[] getAllVolumes();
    public Volume getVolumeByName(string name);
    */
}
