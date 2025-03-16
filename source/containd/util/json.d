module containd.util.json;

import std.typecons : Nullable;

import stdx.data.json : JSONValue, opt;

/++
 + Try to get a value from a JSON object or return a fallback value.
 +/
public T orElse(T)(JSONValue value, T fallback)
{
    if (value.isNull)
    {
        return fallback;
    }

    return value.get!T;
}

/++
 + Try to get a value from a JSON object or return a fallback value.
 +/
public T orElse(T)(Nullable!JSONValue value, T fallback)
{
    if (value.isNull || value.get.isNull)
    {
        return fallback;
    }

    return value.get.get!T;
}

/++
 + Try to get a child object from a JSON object or return null.
 +/
public Nullable!JSONValue find(JSONValue value, string child)
{
    import core.exception : RangeError;

    if (value.isNull)
    {
        return Nullable!JSONValue.init;
    }

    try return Nullable!JSONValue(value[child]);
    catch (RangeError e) return Nullable!JSONValue.init;
}

/++
 + Try to get a child object from a JSON object or return null.
 +/
public Nullable!JSONValue find(Nullable!JSONValue value, string child)
{
    import core.exception : RangeError;

    if (value.isNull || value.get.isNull)
    {
        return Nullable!JSONValue.init;
    }

    try return Nullable!JSONValue(value.get[child]);
    catch (RangeError e) return Nullable!JSONValue.init;
}

/++
 + Try to get a child object from a JSON object or return null.
 +/
public Nullable!JSONValue find(JSONValue value, int index)
{
    import core.exception : RangeError;

    if (value.isNull)
    {
        return Nullable!JSONValue.init;
    }

    try return Nullable!JSONValue(value[index]);
    catch (RangeError e) return Nullable!JSONValue.init;
}

/++
 + Try to get a child object from a JSON object or return null.
 +/
public Nullable!JSONValue find(Nullable!JSONValue value, int index)
{
    import core.exception : RangeError;

    if (value.isNull || value.get.isNull)
    {
        return Nullable!JSONValue.init;
    }

    try return Nullable!JSONValue(value.get[index]);
    catch (RangeError e) return Nullable!JSONValue.init;
}
