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

    public string[] getAllImageIds()
    {
        auto images = execDockerCmd(["image", "ls", "-a", "--format", "\"{{.ID}}\""]);
        if (images.status != 0)
        {
            throw new ImageException("Something went wrong");
        }

        return images.output.split('\n')
            .map!(id => id.clean)
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

    public string[] getAllNetworkIds()
    {
        auto networks = execDockerCmd(["network", "ls", "--format", "\"{{.ID}}\""]);
        if (networks.status != 0)
        {
            throw new NetworkException("Something went wrong");
        }

        return networks.output.split('\n')
            .map!(id => id.clean)
            .array;
    }

    public string[] getAllNetworkNames()
    {
        auto networks = execDockerCmd(["network", "ls", "--format", "\"{{.Name}}\""]);
        if (networks.status != 0)
        {
            throw new NetworkException("Something went wrong");
        }

        return networks.output.split('\n')
            .map!(name => name.clean)
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

    public string[] getAllVolumeNames()
    {
        auto volumes = execDockerCmd(["volume", "ls", "--format", "\"{{.Name}}\""]);
        if (volumes.status != 0)
        {
            throw new VolumeException("Something went wrong");
        }

        return volumes.output.split('\n')
            .map!(name => name.clean)
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

    /++ Container Management +/
    public bool runContainer(string image, string[] command, string name = "", string network = "", string[string] volumes = null,
        string[string] env = null, string envFile = "", string[string] labels = null, string labelFile = "", string hostname = "",
        bool privileged = false, bool remove = false, bool detach = false, string dns = "", string user = "", string restart = "")
    {
        string[] cmd = ["container", "run"];
        if (name != "")
        {
            cmd ~= "--name " ~ name;
        }
        if (network != "")
        {
            cmd ~= "--network " ~ network;
        }
        if (volumes !is null)
        {
            foreach (volume; volumes)
            {
                cmd ~= "--volume " ~ volume[0] ~ ":" ~ volume[1];
            }
        }
        if (env !is null)
        {
            foreach (envVar; env.byKeyValue)
            {
                if (envVar.value != "")
                {
                    cmd ~= "--env " ~ envVar.key ~ "=" ~ envVar.value;
                }
                else
                {
                    cmd ~= "--env " ~ envVar.key;
                }
            }
        }
        if (envFile != "")
        {
            cmd ~= "--env-file " ~ envFile;
        }
        if (labels !is null)
        {
            foreach (label; labels.byKeyValue)
            {
                if (label.value != "")
                {
                    cmd ~= "--label " ~ label.key ~ "=" ~ label.value;
                }
                else
                {
                    cmd ~= "--label " ~ label.key;
                }
            }
        }
        if (labelFile != "")
        {
            cmd ~= "--label-file " ~ labelFile;
        }
        if (hostname != "")
        {
            cmd ~= "--hostname " ~ hostname;
        }
        if (privileged)
        {
            cmd ~= "--privileged";
        }
        if (remove)
        {
            cmd ~= "--rm";
        }
        if (detach)
        {
            cmd ~= "--detach";
        }
        if (dns != "")
        {
            cmd ~= "--dns " ~ dns;
        }
        if (user != "")
        {
            cmd ~= "--user " ~ user;
        }
        if (restart != "")
        {
            cmd ~= "--restart " ~ restart;
        }

        cmd ~= image;
        if (command !is null)
        {
            cmd ~= command;
        }

        writeln(cmd);
        auto result = execDockerCmd(cmd);
        return result.status == 0;
    }
}
