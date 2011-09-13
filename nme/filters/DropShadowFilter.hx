package nme.filters;
#if (cpp || neko)


class DropShadowFilter extends nme.filters.BitmapFilter
{
   var distance : Float;
   var angle : Float;
   var color : Int;
   var alpha : Float;
   var blurX : Float;
   var blurY : Float;
   var quality : Int;
   var strength : Float;
   var inner : Bool;
   var knockout : Bool;
   var hideObject : Bool;

   public function new(in_distance:Float = 4.0, in_angle:Float = 45.0, in_color:Int = 0,
                       in_alpha:Float = 1.0, in_blurX:Float = 4.0, in_blurY:Float = 4.0,
                       in_strength:Float = 1.0, in_quality:Int = 1, in_inner:Bool = false,
                       in_knockout:Bool = false, in_hideObject:Bool = false)
   {
      super("DropShadowFilter");

      distance = in_distance;
      angle = in_angle;
      color = in_color;
      alpha = in_alpha;
      blurX = in_blurX;
      blurY = in_blurX;
      strength = in_strength;
      quality = in_quality;
      inner = in_inner;
      knockout = in_knockout;
      hideObject = in_hideObject;
   }
   override public function clone() : nme.filters.BitmapFilter
   {
      return new DropShadowFilter(distance, angle, color, alpha, blurX, blurY,
                                  strength, quality, inner, knockout, hideObject );

   }

}


#else
typedef DropShadowFilter = flash.filters.DropShadowFilter;
#end