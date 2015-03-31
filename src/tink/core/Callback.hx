package tink.core;

//TODO: To work around #2881 the abstracts are declared over Null. Remove this when no longer necessary.
abstract Callback<T>(Null<T->Void>) from (T->Void) 
{
	inline function new(f)
	{
		this = f;
	}
		
	public inline function invoke(data:T):Void //TODO: consider swallowing null here
	{
		(this)(data);
	}
		
	@:from static inline function fromNiladic<A>(f:Void->Void):Callback<A> 
	{
		return new Callback(function (r) f());
	}

	public inline function toVoid():Void -> Void
	{
		return function() this(null);
	}

	@:from static function fromMany<A>(callbacks:Array<Callback<A>>):Callback<A> 
	{
		return function (v:A)
		{
			for (callback in callbacks) callback.invoke(v);
		}
	}
}

