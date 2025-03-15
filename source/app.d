import std.stdio;

import containd;

import std.algorithm : each;

void main()
{
	//writeln(getDockerVersion.toString);
	//writeln(execDockerCmd(["docker", "--version"]).output);

	//auto service = new DockerService();
	//writeln(service.getAllContainerNames);
	//writeln(service.getAllContainers()[0].name);
	//service.getAllContainers().each!(c => writeln(c.name, " ", c.ports, " ", c.health, " ", c.status, " ", c.image));

	auto client = ContainerServiceClient.dockerFromEnv();
	auto containers = client.getAllContainers();
	containers.getByName("containerName");
	foreach (container; containers)
	{
	    writeln(container.name);
	}
	containers.getAll();
	containers.each!(c => writeln(c.name));
}
