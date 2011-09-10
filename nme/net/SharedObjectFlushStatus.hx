#if flash


package nme.net;


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


#end