package tink.core;

import tink.core.Callback;
import haxe.ds.Option;

using tink.core.Outcome;

abstract Future<T>(Callback<T>->CallbackLink) 
{
	public function new(f:Callback<T>->CallbackLink) 
	{
		this = f;
	}

	//TODO: consider null-case
	public inline function handle(callback:Callback<T>):CallbackLink 
	{
		return (this)(callback);
	}
	
	public function gather():Future<T> 
	{
		var op = Future.trigger();
		var self = this;
	
		return new Future(function (cb:Callback<T>) 
		{
			if (self != null) {
				handle(op.trigger);
				self = null;
			}
			return op.asFuture().handle(cb);
		});
	}
	
	public function first(other:Future<T>):Future<T>
	{
		return Future.async(function (cb:T->Void) {
			handle(cb);
			other.handle(cb);
		});
	}
	
	public function map<A>(f:T->A, ?gather = true):Future<A> 
	{
		var ret = new Future(function (callback) return (this)(function (result) callback.invoke(f(result))));
		return (gather) ? ret.gather() : ret;
	}
	
	public function flatMap<A>(next:T->Future<A>, ?gather = true):Future<A> 
	{
		var ret = flatten(map(next, gather));
		return (gather) ? ret.gather() : ret;
	}
	
	public function merge<A, R>(other:Future<A>, merger:T->A->R, ?gather = true):Future<R> 
	{
		return flatMap(function (t:T) 
		{
			return other.map(function (a:A) return merger(t, a), false);
		}, gather);
	}
	
	static public function flatten<A>(f:Future<Future<A>>):Future<A> 
	{
		return new Future(function (callback) {
			var ret = null;
			ret = f.handle(function (next:Future<A>) 
			{
				ret = next.handle(function (result) callback.invoke(result));
			});
			return ret;
		});
	}
	
	@:from inline static function fromTrigger<A>(trigger:FutureTrigger<A>):Future<A> 
	{
		return trigger.asFuture();
	}
	
	static public function ofMany<A>(futures:Array<Future<A>>, ?gather:Bool = true) {
		var ret = sync([]);
		for (f in futures) {
			ret = ret.flatMap(function (results:Array<A>) 
			{
				return f.map( function (result) { return results.concat([result]) }, false );
			}, false);
		}
		return (gather) ? ret.gather() : ret;
	}
	
	@:from static function fromMany<A>(futures:Array<Future<A>>):Future<Array<A>>
	{
		return ofMany(futures);
	}
	
	//TODO: use this as `sync` when Haxe stops upcasting ints
	@:noUsing static public function lazy<A>(l:Lazy<A>):Future<A>
	{
		return new Future(function (cb:Callback<A>) { cb.invoke(l); return null; });
	}

	
	@:noUsing static public function sync<A>(v:A):Future<A> 
	{
		return new Future(function (callback) { callback.invoke(v); return null; } );
	}

	@:noUsing static public function async<A>(f:(A->Void)->Void, ?lazy = false):Future<A> 
	{
		if (lazy) {
			return flatten(Future.lazy(async.bind(f, false)));
		} else {
			var op = trigger();
			f(op.trigger);
			return op;
		}
	}
	
	@:noCompletion @:op(a || b) static public function or<A>(a:Future<A>, b:Future<A>):Future<A>
	{
		return a.first(b);
	}
	
	@:noCompletion @:op(a || b) static public function either<A, B>(a:Future<A>, b:Future<B>):Future<Either<A, B>>
	{
		return a.map(Either.Left, false).first(b.map(Either.Right, false));
	}

	@:noCompletion @:op(a && b) static public function and<A, B>(a:Future<A>, b:Future<B>):Future<Pair<A, B>>
	{
		return a.merge(b, function (a, b) return new Pair(a, b));
	}
	
	@:noCompletion @:op(a >> b) static public function _tryFailingFlatMap<D, F, R>(f:Surprise<D, F>, map:D->Surprise<R, F>)
	{
		return f.flatMap(function (o) return switch o {
			case Success(d): map(d);
			case Failure(f): Future.sync(Failure(f));
		});
	}
	
	@:noCompletion @:op(a >> b) static public function _tryFlatMap<D, F, R>(f:Surprise<D, F>, map:D->Future<R>):Surprise<R, F> 
	{
		return f.flatMap(function (o) return switch o {
			case Success(d): map(d).map(Success);
			case Failure(f): Future.sync(Failure(f));
		});
	}
	
		
	@:noCompletion @:op(a >> b) static public function _tryFailingMap<D, F, R>(f:Surprise<D, F>, map:D->Outcome<R, F>)
	{
		return f.map(function (o) return o.flatMap(map));
	}


	@:noCompletion @:op(a >> b) static public function _tryMap<D, F, R>(f:Surprise<D, F>, map:D->R)
	{
		return f.map(function (o) return o.map(map));
	}

	
	@:noCompletion @:op(a >> b) static public function _flatMap<T, R>(f:Future<T>, map:T->Future<R>)
	{
		return f.flatMap(map);
	}

	@:noCompletion @:op(a >> b) static public function _map<T, R>(f:Future<T>, map:T->R)
	{
		return f.map(map);
	}

	@:noUsing static public inline function trigger<A>():FutureTrigger<A> 
	{
		return new FutureTrigger();
	}
}