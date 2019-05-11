template OverloadSet(Args ...)
{
    static foreach (Arg; Args)
        alias overloads = Arg;
}

struct multiRet(handlers ...)
{
    static struct HandlerGroup
    {
        static auto ref opCall(Args ...)(auto ref Args args)
        {
            return OverloadSet!(handlers).overloads(args);
        }
    }

    static auto ref call(alias f, Args ...)(auto ref Args args)
    {
        return f(HandlerGroup.init, args);
    }
}

unittest
{
    import std.stdio;
    import std.conv;

    static struct Err { string msg; }

    alias foo = (r, x) {
        if (x > 0)
            return r(x);
        else if (x < 0)
            return r(Err("woops!"));
        else
            return r("OH SHIT");
    };

    foreach (x; [-1.0, 1.0, double.nan])
        multiRet!(
                (double x) => x.writeln,
                (Err x) => x.msg.writeln,
                (x) { throw new Exception(
                    text("Got ", x, " what are you doing?!?")); })
            .call!foo(x);
}
