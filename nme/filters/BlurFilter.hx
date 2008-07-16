package nme.filters;

class BlurFilter extends nme.filters.BitmapFilter
{
   public function new(?blurX : Float, ?blurY : Float, ?quality : Int)
   {
      super("BlurFilter");
      blurX = blurX==null ? 4.0 : blurX;
      blurY = blurY==null ? 4.0 : blurY;
      quality = quality==null ? 1 : quality;
   }
   public function clone() : nme.filters.BitmapFilter
   {
      return new BlurFilter(blurX,blurY,quality);
   }

   var blurX : Float;
   var blurY : Float;
   var quality : Int;
}
