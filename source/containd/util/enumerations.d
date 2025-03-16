module containd.util.enumerations;

import std.typecons : Nullable, nullable;

public Nullable!T valueToEnum(T, R)(R value)
{
    T[R] lookup;

    static foreach (member; __traits(allMembers, T))
    {
        lookup[cast(R) __traits(getMember, T, member)] = __traits(getMember, T, member);
    }

    if (value in lookup)
    {
        return (*(value in lookup)).nullable;
    }
    else
    {
        return Nullable!T.init;
    }
}
