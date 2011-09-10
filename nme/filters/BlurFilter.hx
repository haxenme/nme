#if flash


package nme.filters;


@:native ("flash.filters.BlurFilter")
@:final extern class BlurFilter extends BitmapFilter {
	var blurX : Float;
	var blurY : Float;
	var quality : Int;
	function new(blurX : Float = 4, blurY : Float = 4, quality : Int = 1) : Void;
}



#else


package nme.filters;

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


#end