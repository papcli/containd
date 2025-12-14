module containd.util.div;

public class Optional(T)
{
    private T value;
    private const(bool) _isEmpty;
    
    private this(T value)
    {
        this.value = value;
        this._isEmpty = false;
    }
    
    private this()
    {
        this._isEmpty = true;
    }
    
    public static Optional!T of(R : T)(R value)
    {
        return new Optional!T(value);
    }
    
    public static Optional!T ofNullable(typeof(null) value)
    {
        return empty();
    }
    
    public static Optional!T ofNullable(R : T)(R value)
    {
        static if (is(R == typeof(null)))
        {
            return empty();
        }
        
        return of(value);
    }
    
    public static Optional!T empty()
    {
        return new Optional!T();
    }
    
    public bool isPresent()
    {
        return !_isEmpty;
    }
    
    public bool isEmpty()
    {
        return _isEmpty;
    }
    
    public T get()
    {
        if (isEmpty)
        {
            throw new Exception("No value present");
        }
        
        return value;
    }
    
    public void ifPresent(void delegate(T) consumer)
    {
        if (isEmpty)
        {
            return;
        }
        
        consumer(value);
    }
    
    public T orElse(R : T)(R other)
    {
        if (isEmpty)
        {
            return other;
        }
        
        return value;
    }
}