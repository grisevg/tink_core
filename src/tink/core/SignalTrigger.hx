package tink.core;

abstract SignalTrigger<T>(CallbackList<T>) from CallbackList<T> 
{
	public inline function new() 
	{
		this = new CallbackList();
	}
	
	public inline function trigger(event:T):Void
	{
		this.invoke(event);
	}
	
	public inline function getLength():Int
	{
		return this.length;
	}
	
	public inline function clear():Void
	{
		this.clear();
	}

	@:to public function asSignal():Signal<T>
	{
		return new Signal(this.add);
	}
}