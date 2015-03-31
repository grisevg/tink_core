package tink.core;

import tink.core.Noise;

using Lambda;

abstract Signal<T>(Callback<T>->CallbackLink) 
{
	public inline function new(f:Callback<T>->CallbackLink) 
	{
		this = f;
	}
	
	public inline function handle(handler:Callback<T>):CallbackLink 
	{
		return (this)(handler);
	}
	
	public function map<A>(f:T->A, ?gather = true):Signal<A> 
	{
		var ret = new Signal(function (cb) return handle(function (result) cb.invoke(f(result))));
		return (gather) ? ret.gather() : ret;
	}

	public function mapValue<A>(value:A, ?gather = true):Signal<A> 
	{
		return map((function (_) return value), gather);
	}
	
	public function flatMap<A>(f:T->Future<A>, ?gather = true):Signal<A> 
	{
		var ret = new Signal(function (cb) return handle(function (result) f(result).handle(cb)));
		return (gather) ? ret.gather() : ret;
	}
	
	public function filter(f:T->Bool, ?gather = true):Signal<T> 
	{
		var ret = new Signal(function (cb) return handle(function (result) if (f(result)) cb.invoke(result)));
		return (gather) ? ret.gather() : ret;
	}
	
	public function join(other:Signal<T>, ?gather = true):Signal<T> 
	{
		var ret = new Signal(
			function (cb:Callback<T>):CallbackLink 
				return [
					handle(cb),
					other.handle(cb)
				]
		);
		return (gather) ? ret.gather() : ret;
	}
	
	public function next():Future<T> 
	{
		var ret = Future.trigger();
		handle(handle(ret.trigger));
		return ret.asFuture();
	}
	
	public function noise():Signal<Noise>
	{
		return map(function (_) return Noise);
	}
	
	public function gather():Signal<T> 
	{
		var ret = trigger();
		handle(function (x) ret.trigger(x));
		return ret.asSignal();
	}

	public static function fromMany<A>(callbacks:Array<Signal<A>>):Signal<A>
	{
		var ret = new Signal(function (cb:Callback<A>):CallbackLink
		{
			return callbacks.map(function(signal:Signal<A>) return signal.handle(cb));
		});
		return ret;
	}

	static public function trigger<T>():SignalTrigger<T>
	{
		return new SignalTrigger();
	}
	
	static public function ofClassical<A>(add:(A->Void)->Void, remove:(A->Void)->Void, ?gather = true) 
	{
		var ret = new Signal(function (cb:Callback<A>) {
			var f = function (a) cb.invoke(a);
			add(f);
			return remove.bind(f);
		});
		return (gather) ? ret.gather() : ret;
	}
}

