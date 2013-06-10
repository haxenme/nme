package nme.display;
#if (cpp || neko)

class IGraphicsData 
{
   /** @private */ public var nmeHandle:Dynamic;
   public function new(inHandle:Dynamic) 
   {
      nmeHandle = inHandle;
   }
}

#end