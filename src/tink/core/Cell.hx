package tink.core;

class Cell<T>
{
	static var pool:Array<Cell<Dynamic>> = [];

	//TODO: the cell (or some super class of it) could just as easily act as callback link
	public var cb:Callback<T>;

	function new() {}

	public inline function free():Void {
		this.cb = null;
		pool.push(this);
	}

	static public inline function get<A>():Cell<A>
	{
		return (pool.length > 0) ? cast pool.pop() : new Cell();
	}
}