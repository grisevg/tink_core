package tink.core;

import haxe.ds.Option;
import tink.core.Either;

//TODO: turn into abstract when this commit is released: https://github.com/HaxeFoundation/haxe/commit/e8715189fc055220f2f33a06c5e1331c96310a88
enum Outcome<Data, Failure> 
{	Success(data:Data);
	Failure(failure:Failure);
}