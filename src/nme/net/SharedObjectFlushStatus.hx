package nme.net;

#if (!flash)

#if haxe4
@:enum(String) abstract SharedObjectFlushStatus(String)
{
   var FLUSHED = "FLUSHED";
   var PENDING = "PENDING";
}
#else
@:fakeEnum(String) enum SharedObjectFlushStatus 
{
   FLUSHED;
   PENDING;
}
#end

#else
typedef SharedObjectFlushStatus = flash.net.SharedObjectFlushStatus;
#end
