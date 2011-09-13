package nme.display;
#if cpp || neko


class IGraphicsData
{
   public var nmeHandle:Dynamic;

   function new(inHandle:Dynamic) { nmeHandle = inHandle; }
}


#else
typedef IGraphicsData = flash.display.IGraphicsData;
#end