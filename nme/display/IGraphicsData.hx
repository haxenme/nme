#if flash


package nme.display;

@:native ("flash.display.IGraphicsData")
extern interface IGraphicsData {
}



#else


package nme.display;

class IGraphicsData
{
   public var nmeHandle:Dynamic;

   function new(inHandle:Dynamic) { nmeHandle = inHandle; }
}


#end