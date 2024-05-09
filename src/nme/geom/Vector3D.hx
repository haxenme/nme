package nme.geom;
#if (!flash)

@:nativeProperty
class Vector3D 
{
   public static var X_AXIS(get, null):Vector3D;
   public static var Y_AXIS(get, null):Vector3D;
   public static var Z_AXIS(get, null):Vector3D;

   public var length(get, null):Float;
   public var lengthSquared(get, null):Float;
   public var w:Float;
   public var x:Float;
   public var y:Float;
   public var z:Float;

   public function new(?x:Float = 0., ?y:Float = 0., ?z:Float = 0., ?w:Float = 1.0) 
   {
      this.w = w;
      this.x = x;
      this.y = y;
      this.z = z;
   }

   public function normW()
   {
      if (w!=0 && w!=1)
      {
         x/=w;
         y/=w;
         z/=w;
         w = 1.0;
      }
      return this;
   }

   inline public function toPoint() return new Point(x,y);

   inline public function add(a:Vector3D):Vector3D 
   {
      return new Vector3D(this.x + a.x, this.y + a.y, this.z + a.z);
   }

   public static function slerp(a:Vector3D, b:Vector3D, t:Float):Vector3D
   {
      var d = a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w;
      var dN = Math.abs(d);
      if (dN>=1.0)
         return a.clone();
      var theta = Math.acos(dN);
      var denom = Math.sin(theta);
      var wa = Math.sin( (1-t)*theta )/denom;
      if (d<0)
         wa = -wa;
      var wb =Math.sin(t*theta)/denom;
      return new Vector3D( a.x*wa + b.x*wb,
                           a.y*wa + b.y*wb,
                           a.z*wa + b.z*wb,
                           a.w*wa + b.w*wb );
   }

   inline public static function angleBetween(a:Vector3D, b:Vector3D):Float 
   {
      var a0 = a.clone();
      a0.normalize();
      var b0 = b.clone();
      b0.normalize();
      return Math.acos(a0.dotProduct(b0));
   }

   inline public function clone():Vector3D 
   {
      return new Vector3D(x, y, z, w);
   }
   
   inline public function copyFrom(sourceVector3D:Vector3D): Void {
      x = sourceVector3D.x;
      y = sourceVector3D.y;
      z = sourceVector3D.z;
   }

   inline public function crossProduct(a:Vector3D):Vector3D 
   {
      return new Vector3D(y * a.z - z * a.y, z * a.x - x * a.z, x * a.y - y * a.x, 1);
   }

   inline public function decrementBy(a:Vector3D):Void 
   {
      x -= a.x;
      y -= a.y;
      z -= a.z;
   }

   inline public static function distance(pt1:Vector3D, pt2:Vector3D):Float 
   {
      var x:Float = pt2.x - pt1.x;
      var y:Float = pt2.y - pt1.y;
      var z:Float = pt2.z - pt1.z;

      return Math.sqrt(x * x + y * y + z * z);
   }

   inline public function dotProduct(a:Vector3D):Float 
   {
      return x * a.x + y * a.y + z * a.z;
   }

   inline public function equals(toCompare:Vector3D, ?allFour:Bool = false):Bool 
   {
      return x == toCompare.x && y == toCompare.y && z == toCompare.z && (!allFour || w == toCompare.w);
   }

   inline public function incrementBy(a:Vector3D):Void 
   {
      x += a.x;
      y += a.y;
      z += a.z;
   }

   inline public function nearEquals(toCompare:Vector3D, tolerance:Float, ?allFour:Bool = false):Bool 
   {
      return Math.abs(x - toCompare.x) < tolerance && Math.abs(y - toCompare.y) < tolerance && Math.abs(z - toCompare.z) < tolerance && (!allFour || Math.abs(w - toCompare.w) < tolerance);
   }

   inline public function negate():Void 
   {
      x *= -1;
      y *= -1;
      z *= -1;
   }

   inline public function normalize():Float 
   {
      var l = length;

      if (l != 0) 
      {
         x /= l;
         y /= l;
         z /= l;
      }

      return l;
   }

   inline public function normalized(inplace=false):Vector3D 
   {
      var l = length;
      var invL = l==0 ? 1 : 1.0/l;
      var result = this;
      if (inplace)
      {
         x *= invL;
         y *= invL;
         z *= invL;
      }
      else
      {
         result = new Vector3D(x*invL, y*invL, z*invL);
      }

      return result;
   }



   inline public function project():Vector3D
   {
      x /= w;
      y /= w;
      z /= w;
      w = 1.0;
      return this;
   }

   inline public function setTo(xa:Float, ya:Float, za:Float):Vector3D {
      x = xa;
      y = ya;
      z = za;
      return this;
   }

   inline public function scaleBy(s:Float):Vector3D 
   {
      x *= s;
      y *= s;
      z *= s;
      return this;
   }

   public function scaled(s:Float):Vector3D 
   {
      return new Vector3D(x*s, y*s, z*s, 1);
   }

   public function addScaled(v:Vector3D, s:Float):Vector3D 
   {
      return new Vector3D(x + v.x*s, y + v.y*s, z + v.z*s, 1);
   }



   inline public function subtract(a:Vector3D):Vector3D 
   {
      return new Vector3D(x - a.x, y - a.y, z - a.z);
   }

   inline public function toString():String 
   {
      return 'Vector3D($x,$y,$z,$w)';
   }

   // Getters & Setters
   inline private function get_length():Float { return Math.sqrt(x * x + y * y + z * z); }
   inline private function get_lengthSquared():Float { return x * x + y * y + z * z; }
   inline private static function get_X_AXIS():Vector3D { return new Vector3D(1, 0, 0);   }
   inline private static function get_Y_AXIS():Vector3D { return new Vector3D(0, 1, 0);   }
   inline private static function get_Z_AXIS():Vector3D { return new Vector3D(0, 0, 1);   }
}

#else
typedef Vector3D = flash.geom.Vector3D;
#end
