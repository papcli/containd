module containd.util.terminal;

static immutable DOCKER_COMMAND = ["docker", "-H=192.168.50.107:2375"];
static immutable PODMAN_COMMAND = ["podman"];

/++
 + The `CommandResult` struct contains the status code of the command, the output of the command, and the error message if the command failed.
 +/
public struct CommandResult
{
    public int status;
    public string output;
    public string error;
}

/++
 + The `execCmd` function takes an array of strings as input, which represents the command to be executed.
 + It returns a `CommandResult` struct, which contains the status code of the command, the output of the command, and the error message if the command failed.
 +/
public CommandResult execCmd(string[] cmd)
{
    import std.process : pipeProcess, wait;
    import std.array : join;

    auto p = pipeProcess(cmd);
    scope(exit) wait(p.pid);

    string output = p.stdout.byLineCopy().join("\n");
    string error = p.stderr.byLineCopy().join("\n");
    int status = wait(p.pid);

    return CommandResult(status, output, error);
}

public CommandResult execDockerCmd(string[] cmd)
{
    return execCmd(DOCKER_COMMAND ~ cmd);
}

public CommandResult execPodmanCmd(string[] cmd)
{
    return execCmd(PODMAN_COMMAND ~ cmd);
}
