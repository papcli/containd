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
	auto container = containers.getByName("homepage");
	writeln(container.networks);
	/*
	foreach (container; containers)
	{
	    writeln(container.name);
	}
	containers.getAll();
	containers.each!(c => writeln(c.name));

	auto service = new DockerService();
	//writeln(service.getImageById("").size);
	writeln(service.getNetworkByName("br0").auxiliaries);
	*/
	
	auto service = new DockerService();
	writeln(service.runContainer("hello-world", null, name: "hello-world", remove: true));
	
    auto x = Optional!int.of(5);
    writeln(x.isPresent);
    x.ifPresent(a => writeln(a));
    
    auto y = Optional!int.empty();
    writeln(y.isPresent);
    
    auto z = Optional!int.ofNullable(null);
    writeln(z.isPresent);
}
