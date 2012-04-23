package nme.net;
#if code_completion


extern class SharedObjectFlushStatus {
	function new() : Void;
	static var FLUSHED : String;
	static var PENDING : String;
}


#elseif (cpp || neko)
typedef SharedObjectFlushStatus = neash.net.SharedObjectFlushStatus;
#elseif js
typedef SharedObjectFlushStatus = jeash.net.SharedObjectFlushStatus;
#else
typedef SharedObjectFlushStatus = flash.net.SharedObjectFlushStatus;
#end