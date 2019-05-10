struct betterGen(Input, ResEl, alias step)
{
    Input input;

    ResEl front;
    bool empty = false;
    bool nothingAvailable = true;

    this(Input input)
    {
        this.input = input;
        popFront();
    }

    void popFront()
    {
        nothingAvailable = true;
        while (!empty && nothingAvailable)
            this = step(this);
    }

    typeof(this) stop()
    {
        auto r = this;
        r.empty = true;
        return r;
    }

    typeof(this) val(ResEl v)
    {
        auto r = this;
        r.front = v;
        r.nothingAvailable = false;
        return r;
    }

    typeof(this) nothing() @property
    {
        auto r = this;
        r.nothingAvailable = true;
        return r;
    }

    typeof(this) apply(alias f)()
    {
        auto r = this;
        f(r);
        return r;
    }
}

auto modify(alias f, T)(T t)
{
    f(t);
    return t;
}

auto popInput(S)(S s)
{
    import std.range : popFront;
    s.input.popFront();
    return s;
}

auto filter(alias foo, R)(R r)
{
    import std.range : ElementType;
    import std.range : empty, popFront, front;

    return r.betterGen!(R, ElementType!R,
    (s) { with (s)
    {
        if (input.empty)
            return stop;
        auto inFront = input.front;
        if (foo(inFront))
            return val(inFront)
                .popInput();
        return nothing
            .popInput;
    }});
}

unittest
{
    import std.algorithm : equal;
    int[] empty;
    assert([1,2,3,4].filter!(x => x == 2).equal([2]));
    assert(empty.filter!(x => x == 2).equal(empty));
}

@nogc unittest
{
    import std.algorithm : equal;
    import std.range : iota, only;

    int[] empty;
    assert(iota(4).filter!(x => x == 2).equal(only(2)));
    assert(empty.filter!(x => x == 2).equal(empty));
}

auto map(alias foo, R)(R r)
{
    import std.range : ElementType, front, empty;

    return r.betterGen!(R, typeof(foo(ElementType!R.init)),
    (s) { with (s)
    {
        if (input.empty)
            return stop;
        return val(foo(input.front))
            .popInput;
    }});
}

unittest
{
    import std.algorithm : equal;
    int[] empty = [];
    assert([1,2,3,4].map!(x => x == 2).equal([false, true, false, false]));
    assert(empty.map!(x => x == 2).equal(empty));
}

auto uniq(alias foo = (a, b) => a == b, R)(R r)
{
    import std.range : ElementType, front, popFront, empty;

    return r.betterGen!(R, ElementType!R,
    (s) { with (s)
    {
        if (input.empty)
            return stop;
        auto inFront = input.front;
        do
            input.popFront();
        while (!input.empty && foo(input.front, inFront));

        return val(inFront);
    }});
}

unittest
{
    import std.algorithm : equal;
    int[] empty = [];
    assert([1,2,2,3,3,3,4].uniq.equal([1,2,3,4]));
    assert(empty.uniq.equal(empty));
}

auto group(alias foo = (a, b) => a == b, R)(R r)
{
    import std.range : ElementType, front, popFront, empty;
    import std.typecons : Tuple, tuple;

    return r.betterGen!(R, Tuple!(ElementType!R, size_t),
    (s) { with (s)
    {
        if (input.empty)
            return stop;
        auto inFront = input.front;
        size_t n = 0;
        do
        {
            input.popFront();
            ++n;
        } while (!input.empty && foo(input.front, inFront));

        return val(tuple(inFront, n));
    }});
}

unittest
{
    import std.algorithm : equal;
    import std.typecons : tuple, Tuple;

    int[] empty = [];
    Tuple!(int, size_t)[] emptyRes = [];
    assert([1,2,2,3,3,3,4].group.equal([tuple(1, 1), tuple(2, 2), tuple(3, 3), tuple(4, 1)]));
    assert(empty.group.equal(emptyRes));
}

auto until(alias foo, R)(R r)
{
    import std.range : ElementType, empty, front, popFront;

    return r.betterGen!(R, ElementType!R,
    (s) { with (s)
    {
        if (input.empty || foo(input.front))
            return stop;
        return val(input.front)
            .popInput;
    }});
}

unittest
{
    import std.algorithm : equal;
    import std.typecons : tuple, Tuple;
    import std.range : take;

    int[] empty = [];
    assert([1,2,3,4].until!(x => x == 3).equal([1, 2]));
    assert(empty.until!(x => 4).equal(empty));
}

/+
auto chunkBy(alias foo = (a, b) => a == b, R)(R r)
{
    static auto ret(R r, ElementType!R v)
    {
        return r.until!(x => !foo(v, x);
    }

    return betterGen!(R, ReturnType!ret,
    (s)
    {
        typeof(s.input.front) inFront;
        if (s.input.empty)
            return s.stop;
        inFront = s.input.front;
        return s.val();
    }
}

unittest
{

}
+/

