package nme.geom;
#if !flash

@:nativeProperty
class Point 
{
   public var length(get, never):Float;
   public var x:Float;
   public var y:Float;

   public function new(inX:Float = 0, inY:Float = 0) 
   {
      x = inX;
      y = inY;
   }

   public function add(v:Point):Point 
   {
      return new Point(v.x + x, v.y + y);
   }

   public function scaled(scale:Float):Point 
   {
      return new Point( x*scale, y*scale );
   }


   public function clone():Point 
   {
      return new Point(x, y);
   }
   public function setTo(inX:Float, inY:Float):Point 
   {
      x = inX;
      y = inY;
      return this;
   }

   public function copyFrom(sourcePoint:Point):Void
   {
      x = sourcePoint.x;
      y = sourcePoint.y;
   }

   public function dist(pt2:Point):Float 
   {
      var dx = x - pt2.x;
      var dy = y - pt2.y;
      return Math.sqrt(dx * dx + dy * dy);
   }

   public function dist2(pt2:Point):Float 
   {
      var dx = x - pt2.x;
      var dy = y - pt2.y;
      return (dx * dx + dy * dy);
   }

   public static function distance(pt1:Point, pt2:Point):Float 
   {
      var dx = pt1.x - pt2.x;
      var dy = pt1.y - pt2.y;
      return Math.sqrt(dx * dx + dy * dy);
   }

   public function equals(toCompare:Point):Bool 
   {
      return toCompare.x == x && toCompare.y == y;
   }

   public static function interpolate(pt1:Point, pt2:Point, f:Float):Point 
   {
      return new Point(pt2.x + f * (pt1.x - pt2.x), pt2.y + f * (pt1.y - pt2.y));
   }

   public function normalize(thickness:Float):Void 
   {
      if (x == 0 && y == 0) 
      {
         return;
      }
      else 
      {
         var norm = thickness / Math.sqrt(x * x + y * y);
         x *= norm;
         y *= norm;
      }
   }

   inline public function dot(inPoint:Point):Float
   {
     return x*inPoint.x + y*inPoint.y;
   }

   inline public function normalized(inplace=false):Point
   {
      var result = this;
      var len = Math.sqrt(x*x+y*y);
      var scale  =  Math.abs(len)>1e-7 ? 1.0/len : 0.0;
      if (inplace)
      {
         x *= scale;
         y *= scale;
      }
      else 
      {
         result = new Point(x*scale, y*scale);
      }
      return result;
   }


   public function offset(dx:Float, dy:Float):Void 
   {
      x += dx;
      y += dy;
   }

   public static function polar(len:Float, angle:Float):Point 
   {
      return new Point(len * Math.cos(angle), len * Math.sin(angle));
   }

   public function subtract(v:Point):Point 
   {
      return new Point(x - v.x, y - v.y);
   }

   public function toString():String 
   {
      return "(x=" + x + ", y=" + y + ")";
   }

   // Getters & Setters
   private function get_length() { return Math.sqrt(x * x + y * y); }
}

#else
typedef Point = flash.geom.Point;
#end
