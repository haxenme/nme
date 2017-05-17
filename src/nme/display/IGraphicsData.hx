package nme.display;
import nme.NativeHandle;

#if (!flash)

class IGraphicsData 
{
   /** @private */ public var nmeHandle:NativeHandle;
   public function new(inHandle:NativeHandle) 
   {
      nmeHandle = inHandle;
   }
}

#else
typedef IGraphicsData = flash.display.IGraphicsData;
#end
