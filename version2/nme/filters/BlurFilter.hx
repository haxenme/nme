package nme.filters;

class BlurFilter extends nme.filters.BitmapFilter
{
   var blurX : Float;
   var blurY : Float;
   var quality : Int;

   public function new(inBlurX : Float=4.0, inBlurY : Float=4.0, inQuality : Int=1)
   {
      super("BlurFilter");
      blurX = inBlurX==null ? 4.0 : inBlurX;
      blurY = inBlurY==null ? 4.0 : inBlurY;
      quality = inQuality==null ? 1 : inQuality;
   }

   override public function clone() : nme.filters.BitmapFilter
   {
      return new BlurFilter(blurX,blurY,quality);
   }
}

