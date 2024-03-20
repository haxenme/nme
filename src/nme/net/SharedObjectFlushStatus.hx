package nme.net;

#if (!flash)

enum abstract SharedObjectFlushStatus(String)
{
   var FLUSHED = "FLUSHED";
   var PENDING = "PENDING";
}

#else
typedef SharedObjectFlushStatus = flash.net.SharedObjectFlushStatus;
#end
