package native.net;
#if (cpp || neko)

@:fakeEnum(String) enum SharedObjectFlushStatus 
{
   FLUSHED;
   PENDING;
}

#end