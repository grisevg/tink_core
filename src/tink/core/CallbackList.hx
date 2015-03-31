package tink.core;

abstract CallbackList<T>(Array<Cell<T>>)
{
	public var length(get, never):Int;

	inline public function new():Void
	{
		this = [];
	}

	inline function get_length():Int
	{
		return this.length;
	}

	public function add(cb:Callback<T>):CallbackLink
	{
		var cell = Cell.get();
		cell.cb = cb;
		this.push(cell);
		return function ():Void
		{
			if (this.remove(cell)) cell.free();
			cell = null;
		}
	}

	public function invoke(data:T):Void
	{
		for (cell in this.copy()) {
			//This occurs when an earlier cell in this run dissolves the link for a later cell - usually a sign of convoluted code, but who am I to judge
			if (cell.cb != null) cell.cb.invoke(data);
		}
	}

	public function clear():Void
	{
		for (cell in this.splice(0, this.length)) cell.free();
	}
}