package nme.filters;
#if (cpp || neko)


class BlurFilter extends nme.filters.BitmapFilter
{
   var blurX : Float;
   var blurY : Float;
   var quality : Int;

   public function new(inBlurX : Float=4.0, inBlurY : Float=4.0, inQuality : Int=1)
   {
      super("BlurFilter");
      blurX = inBlurX;
      blurY = inBlurY;
      quality = inQuality;
   }

   override public function clone() : nme.filters.BitmapFilter
   {
      return new BlurFilter(blurX,blurY,quality);
   }
}


#else
typedef BlurFilter = flash.filters.BlurFilter;
#end