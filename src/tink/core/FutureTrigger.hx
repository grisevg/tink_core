package tink.core;

class FutureTrigger<T> 
{
	var result:T;
	var list:CallbackList<T>;
	var future:Future<T>;
	
	public function new() 
	{
		this.list = new CallbackList();
		future = new Future(function (callback) 
		{
			if (list == null) {
				callback.invoke(result);
				return null;
			} else {
				return list.add(callback);
			}
		});
	}
	
	public inline function asFuture() return future;

	public inline function trigger(result:T):Bool
	{
		if (list == null) {
			return false;
		} else {
			var list = this.list;
			this.list = null;
			this.result = result;
			list.invoke(result);
			list.clear();//free callback links
			return true;
		}
	}
}