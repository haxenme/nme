package nme.geom;


/*

  Points transform with:

   [ X' ]  =   [ X ]   [  a   b    tx  ]
   [ Y' ]      [ Y ]   [  c   d    ty  ]
               [ 1 ]

*/

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

      // rotation is clockwise
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
      c = Math.sin(inTheta)*scale;
      b = -c;
      d = a;
   }

   public function invert() : Matrix
   {
      var norm = a*d-b*c;
      if (norm==0)
      {
         a = b = c = d = 0;
         tx=-tx;
         ty=-ty;
      }
      else
      {
         norm = 1.0/norm;
         var a1 = d*norm;
         d = a*norm;
         a = a1;
         b*=-norm;
         c*=-norm;

         var tx1 = - a*tx - c*ty; 
         ty = - b*tx - d*ty; 
         tx = tx1;
      }
      return this;
   }

   public function transformPoint(inPos:Point)
   {
      return new Point( inPos.x*a + inPos.y*c + tx,
                        inPos.x*b + inPos.y*d + ty );
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

      var a_ = a*cos + b*sin;
      b = a*-sin + b*cos;
      a = a_;
      var c_ = c*cos + d*sin;
      d =  c*-sin + d*cos;
      c = c_;
   }



   public function scale(inSX:Float, inSY:Float)
   {
      a*=inSX;
      c*=inSX;
      tx*=inSX;

      b*=inSY;
      d*=inSY;
      ty*=inSY;

   }


   public function concat(inRHS:Matrix)
   {
      var a1 = a*inRHS.a + b*inRHS.c;
      var b1 = a*inRHS.b + b*inRHS.d;
      var tx1 = a*inRHS.tx + b*inRHS.ty + tx;

      var c1 = c*inRHS.a + d*inRHS.c;
      var d1 = c*inRHS.b + d*inRHS.d;
      var ty1 = c*inRHS.tx + d*inRHS.ty + ty;

      a = a1;
      b = b1;
      c = c1;
      d = d1;
      tx = tx1;
      ty = ty1;
   }
}

