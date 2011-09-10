package nme.filters;


#if flash
@:native ("flash.filters.GlowFilter")
@:final extern class GlowFilter extends BitmapFilter {
	var alpha : Float;
	var blurX : Float;
	var blurY : Float;
	var color : UInt;
	var inner : Bool;
	var knockout : Bool;
	var quality : Int;
	var strength : Float;
	function new(color : UInt = 16711680, alpha : Float = 1, blurX : Float = 6, blurY : Float = 6, strength : Float = 2, quality : Int = 1, inner : Bool = false, knockout : Bool = false) : Void;
}
#else



class GlowFilter extends nme.filters.DropShadowFilter
{
   public function new(in_color:Int = 0,
                       in_alpha:Float = 1.0, in_blurX:Float = 6.0, in_blurY:Float = 6.0,
                       in_strength:Float = 2.0, in_quality:Int = 1, in_inner:Bool = false,
                       in_knockout:Bool = false)

   {
      super(0,0,in_color,in_alpha,in_blurX, in_blurY, in_strength,
            in_quality, in_inner, in_knockout,false);
   }

}
#end