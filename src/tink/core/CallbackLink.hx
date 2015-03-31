package tink.core;

abstract CallbackLink(Null<Void->Void>)
{
	inline function new(link:Void->Void)
	{
		this = link;
	}

	public inline function dissolve():Void
	{
		if (this != null) (this)();
	}

	@:to function toCallback<A>():Callback<A>
	{
		return this;
	}

	@:from static inline function fromFunction(f:Void->Void)
	{
		return new CallbackLink(f);
	}

	@:from static function fromMany(callbacks:Array<CallbackLink>)
	{
		return fromFunction(function () for (cb in callbacks) cb.dissolve());
	}
}