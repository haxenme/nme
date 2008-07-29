package nme.filters;

class BlurFilter extends nme.filters.BitmapFilter
{
   public function new(?inBlurX : Float, ?inBlurY : Float, ?inQuality : Int)
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

   var blurX : Float;
   var blurY : Float;
   var quality : Int;
}
