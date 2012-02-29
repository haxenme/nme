package nme.net;
#if (cpp || neko)


@:fakeEnum(String) enum SharedObjectFlushStatus 
{
	FLUSHED;
	PENDING;
}


#else
typedef SharedObjectFlushStatus = flash.net.SharedObjectFlushStatus;
#end