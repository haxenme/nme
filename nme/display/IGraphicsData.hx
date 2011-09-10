package nme.display;


#if flash
@:native ("flash.display.IGraphicsData")
extern interface IGraphicsData {
}
#else



class IGraphicsData
{
   public var nmeHandle:Dynamic;

   function new(inHandle:Dynamic) { nmeHandle = inHandle; }
}
#end