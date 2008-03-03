package nme.geom;

class Matrix
{
   public var a : Float;
   public var b : Float;
   public var c : Float;
   public var d : Float;
   public var tx : Float;
   public var ty : Float;

   public function new(?in_a : Float, ?in_b : Float, ?in_c : Float, ?in_d : Float,
          ?in_tx : Float, ?in_ty : Float)
   {
      a = in_a==null ? 1.0 : in_a;
      b = in_b==null ? 0.0 : in_b;
      c = in_c==null ? 0.0 : in_c;
      d = in_d==null ? 1.0 : in_d;
      tx = in_tx==null ? 0.0 : in_tx;
      ty = in_ty==null ? 0.0 : in_ty;
   }


   public function clone() { return new Matrix(a,b,c,d,tx,ty); }

   public function createGradientBox(in_width : Float, in_height : Float,
         ?rotation : Float, ?in_tx : Float, ?in_ty : Float) : Void
   {
      a = in_width/1638.4;
      d = in_height/1638.4;

      if (rotation!=null && rotation!=0.0)
      {
         var cos = Math.cos(rotation);
         var sin = Math.sin(rotation);
         b = sin*d;
         c = -sin*a;
         a *= cos;
         d *= cos;
      }
      else
      {
         b = c = 0;
      }

      tx = in_tx!=null ? in_tx+in_width/2 : in_width/2;
      ty = in_ty!=null ? in_ty+in_height/2 : in_height/2;
   }

   public function setRotation(inTheta:Float,?inScale:Float)
   {
      var scale:Float = inScale==null ? 1.0 : inScale;
      a = Math.cos(inTheta)*scale;
      b = Math.sin(inTheta)*scale;
      c = -b;
      d = a;
   }

   public function translate(inDX:Float, inDY:Float)
   {
      tx += inDX;
      ty += inDY;
   }

   public function rotate(inTheta:Float)
   {
      var cos = Math.cos(inTheta);
      var sin = Math.sin(inTheta);
      var a_ = cos*a + sin*c;
      var b_ = cos*b + sin*d;
      var tx_ = cos*tx + sin*ty;
      c = -sin*a + cos*c;
      d = -sin*b + cos*d;
      ty = -sin*tx + cos*ty;
      a = a_;
      b = b_;
      tx = tx_;
   }



   public function scale(inSX:Float, inSY:Float)
   {
      a*=inSX;
      b*=inSX;
      tx*=inSX;

      c*=inSY;
      d*=inSY;
      ty*=inSY;

   }


   public function concat(inLHS:Matrix)
   {
      var a1 = inLHS.a*a + inLHS.b*c;
      var b1 = inLHS.a*b + inLHS.b*d;
      var tx1 = inLHS.a*tx + inLHS.b*ty + inLHS.tx;

      var c1 = inLHS.c*a + inLHS.d*c;
      var d1 = inLHS.c*b + inLHS.d*d;
      var ty1 = inLHS.c*tx + inLHS.d*ty + inLHS.ty;

      a = a1;
      b = b1;
      c = c1;
      d = d1;
      tx = tx1;
      ty = ty1;
   }
}

