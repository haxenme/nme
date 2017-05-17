package nme.filters;
#if (!flash)

@:nativeProperty
class BlurFilter extends BitmapFilter 
{
   public var blurX:Float;
   public var blurY:Float;
   public var quality:Int;
   public function new(inBlurX:Float = 4.0, inBlurY:Float = 4.0, inQuality:Int = 1) 
   {
      super("BlurFilter");

      blurX = inBlurX;
      blurY = inBlurY;
      quality = inQuality;
   }

   override public function clone():BitmapFilter 
   {
      return new BlurFilter(blurX, blurY, quality);
   }
}

#else
typedef BlurFilter = flash.filters.BlurFilter;
#end
