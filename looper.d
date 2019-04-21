import std.stdio;

struct IterState(Input, ResEl, alias step)
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
        debug(IterState) writeln("popFront");
        nothingAvailable = true;
        while (!empty && nothingAvailable)
            this = step(this);
    }

    typeof(this) stop()
    {
        debug (IterState) writeln("stop");
        auto r = this;
        r.empty = true;
        return r;
    }

    typeof(this) val(ResEl v)
    {
        debug (IterState) writeln("val");
        auto r = this;
        r.front = v;
        r.nothingAvailable = false;
        return r;
    }

    typeof(this) nothing() @property
    {
        debug (IterState) writeln("nothing");
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

    string debugString()
    {
        import std.conv;
        import std.range : save;
        return text(input.save, ' ', front, ' ', empty, ' ', nothingAvailable);
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

    return IterState!(R, ElementType!R,
    (s)
    {
        debug (IterState) writeln("calling step with ", s.debugString);
        if (s.input.empty)
            return s.stop;
        auto inFront = s.input.front;
        if (foo(inFront))
            return s.val(inFront)
                .popInput();
        return s.nothing
            .popInput;
    })(r);
}

unittest
{
    import std.algorithm : equal;
    int[] empty;
    assert([1,2,3,4].filter!(x => x == 2).equal([2]));
    assert(empty.filter!(x => x == 2).equal(empty));
}

auto map(alias foo, R)(R r)
{
    import std.range : ElementType, front, empty;

    return IterState!(R, typeof(foo(ElementType!R.init)),
    (s)
    {
        if (s.input.empty)
            return s.stop;
        return s.val(foo(s.input.front))
            .popInput;
    })(r);
}

unittest
{
    import std.algorithm : equal;
    int[] empty = [];
    assert([1,2,3,4].map!(x => x == 2).equal([false, true, false, false]));
    assert(empty.filter!(x => x == 2).equal(empty));
}

auto uniq(alias foo = (a, b) => a == b, R)(R r)
{
    import std.range : ElementType, front, popFront, empty;

    return IterState!(R, ElementType!R,
    (s)
    {
        if (s.input.empty)
            return s.stop;
        auto inFront = s.input.front;
        do
            s.input.popFront();
        while (!s.input.empty && foo(s.input.front, inFront));

        return s.val(inFront);
    })(r);
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

    return IterState!(R, Tuple!(ElementType!R, size_t),
    (s)
    {
        if (s.input.empty)
            return s.stop;
        auto inFront = s.input.front;
        size_t n = 0;
        do
        {
            s.input.popFront();
            ++n;
        } while (!s.input.empty && foo(s.input.front, inFront));

        return s.val(tuple(inFront, n));
    })(r);
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
	return IterState!(R, ElementType!R,
	(s)
	{
    	if (s.input.empty)
			return s.stop;
		s.input.popFront();
		if (s.input.empty || pred(s.input.front))
			return s.stop;
		return s.val(s.input.front);
}

unittest
{
    import std.algorithm : equal;
    import std.typecons : tuple, Tuple;

    int[] empty = [];
    assert([1,2,3,4].until!(x => x == 3).equal([1, 2]));
    assert(empty.until!(x => 4).equal(empty));
}
/+
auto chunkBy(alias foo = (a, b) => a == b, R)(R r)
{
	return IterState!(R, /*something*/,
	(s)
	{
		if (s.input.empty)
			return s.stop;
		auto inFront = s.input.front;
		return s.val(s.input.until!(x => !foo(inFront, x)));
	}
}

unittest
{

}
+/
