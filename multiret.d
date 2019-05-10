import std.meta : allSatisfy, staticMap;
import std.traits : isCallable, Parameters;

enum onlyOne(Args ...) = Args.length == 1;

struct multiRet(handlers ...)
if (allSatisfy!(isCallable, typeof(handlers))
    && allSatisfy!(onlyOne, staticMap!(Parameters, typeof(handlers))))
{
    static struct HandlerGroup
    {
        static foreach (handler; handlers)
            static auto ref opCall()(auto ref Parameters!handler[0] v)
            {
                return handler(v);
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
	static struct Err { string msg; }
	foreach (x; [-1, 1])
		multiRet!(
    			(int x) => x.writeln,
    			(Err x) => x.msg.writeln)
    		.call!((r, x) {
        		if (x > 0)
            		return r(x);
				return r(Err("OH NO!"));
    		})(x);
}
