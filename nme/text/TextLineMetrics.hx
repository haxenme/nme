package nme.text;
#if (!flash)

@:nativeProperty
class TextLineMetrics 
{
   public var x:Float;
   public var width:Float;
   public var height:Float;
   public var ascent:Float;
   public var descent:Float;
   public var leading:Float;

   public function new(?in_x:Float, ?in_width:Float, ?in_height:Float, ?in_ascent:Float, ?in_descent:Float, ?in_leading:Float) 
   {
      x = in_x;
      width = in_width;
      height = in_height;
      ascent = in_ascent;
      descent = in_descent;
      leading = in_leading;
   }
}

#else
typedef TextLineMetrics = flash.text.TextLineMetrics;
#end
