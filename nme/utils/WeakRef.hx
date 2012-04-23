package nme.utils;
#if code_completion


extern class WeakRef<T>
{
	function new(inObject:T, inMakeWeak:Bool = true):Void;
	function get():T;
	function toString():String;
}


#elseif (cpp || neko)
typedef WeakRef<T> = neash.utils.WeakRef<T>;
#end