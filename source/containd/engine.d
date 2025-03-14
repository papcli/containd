module containd.engine;

import containd.model;

package interface ContainerEngineAPI
{
    /++ Information Retrieval +/
    public Container[] getAllContainers();
    public string[] getAllContainerIds();
    public string[] getAllContainerNames();
    public Container getContainerById(string id);
    public Container getContainerByName(string name);
    /+
    public Image[] getAllImages();
    public Image getImageById(string id);

    public Network[] getAllNetworks();
    public Network getNetworkByName(string name);

    public Volume[] getAllVolumes();
    public Volume getVolumeByName(string name);

    /++ Container Management +/
    public bool runContainer(string image, string[] command /* TODO: More options */);
    public bool createContainer(string image, string[] command = null /* TODO: More options */);
    public bool startContainer(string id, bool attach = false, bool interactive = false);
    public bool stopContainer(string id, uint signal = 0, int timeout = 0);
    public bool killContainer(string id, uint signal = 0);
    public bool restartContainer(string id, uint signal = 0, int timeout = 0);
    public bool removeContainer(string id, bool force = false, bool removeVolumes = false);
    public bool renameContainer(string id, string name);
    public bool pauseContainer(string id);
    public bool unpauseContainer(string id);
    public bool copyFilesContainer(string id, string sourcePath, string destinationPath);
    public bool execContainerCommand(string id, string command, bool detach = false, bool privileged = false, bool interactive = false, string[string] env = null, string workdir = "", string user = ""); // TODO: multi-line
    public bool getContainerLogs(string id, ref string logs, int tail = 0, string since = "", string until = "");
    /++ Image Management +/

    /++ Network Management +/

    /++ Volume Management +/

    +/
}

public class ContainerServiceClient
{
    private ContainerEngineAPI engine;

    private this(ContainerEngineAPI engine)
    {
        this.engine = engine;
    }

    /++ Initialization +/
    public static ContainerServiceClient docker(string socket)
    {
        return new ContainerServiceClient(null);
    }

    public static ContainerServiceClient dockerFromEnv()
    {
        return new ContainerServiceClient(null);
    }

    public static ContainerServiceClient podman(string socket)
    {
        return new ContainerServiceClient(null);
    }

    public static ContainerServiceClient podmanFromEnv()
    {
        return new ContainerServiceClient(null);
    }

    /++ Information Retrieval +/
}
