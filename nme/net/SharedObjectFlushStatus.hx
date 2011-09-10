package nme.net;


#if flash
/*
@:native ("flash.net.SharedObjectFlushStatus")
@:fakeEnum(String) extern enum SharedObjectFlushStatus {
	FLUSHED;
	PENDING;
}
*/

@:native ("flash.net.SharedObjectFlushStatus")
extern class SharedObjectFlushStatus {
	public static var FLUSHED:String = "flushed";
	public static var PENDING:String = "pending";
}
#else



@:fakeEnum(String) enum SharedObjectFlushStatus 
{
	FLUSHED;
	PENDING;
}
#end