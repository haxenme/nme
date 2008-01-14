package nme;

typedef DrawList = Array<Void>;

typedef GfxPoint =
{
   var x:Float;
   var y:Float;
};

typedef GfxPoints = Array<GfxPoint>;

typedef GradPoint = 
{
   var col:Int;
   var alpha:Float;
   var ratio:Int;
}

typedef GradPoints = Array<GradPoint>;

typedef Grad =
{
   var points:GradPoints;
   var matrix:nme.Matrix;
   var flags:Int;
   var focal:Float;
}

typedef LineJob =
{
   var grad:Grad;
   var point_idx:Array<Int>;
   var thickness:Float;
   var alpha:Float;
   var colour:Int;
   var pixel_hinting:Int;
   var joints:Int;
   var caps:Int;
   var miter_limit:Float;
}

typedef LineJobs = Array<LineJob>;

class Graphics
{
   public static var defaultFontName = "Times";
   public static var defaultFontSize = 12;

   public static var TOP = 0;
   public static var CENTER = 1;
   public static var BOTTOM = 2;

   public static var LEFT = 0;
   public static var RIGHT = 2;

   public static var RADIAL  = 0x0001;

   public static var REPEAT  = 0x0002;
   public static var REFLECT = 0x0004;


   private static var  EDGE_MASK        = 0x00f0;
   private static var  EDGE_CLAMP       = 0x0000;
   private static var  EDGE_REPEAT      = 0x0010;
   private static var  EDGE_UNCHECKED   = 0x0020;
   private static var  EDGE_REPEAT_POW2 = 0x0030;

   private static var  END_NONE         = 0x0000;
   private static var  END_ROUND        = 0x0100;
   private static var  END_SQUARE       = 0x0200;
   private static var  END_MASK         = 0x0300;
   private static var  END_SHIFT        = 8;

   private static var  CORNER_ROUND     = 0x0000;
   private static var  CORNER_MITER     = 0x1000;
   private static var  CORNER_BEVEL     = 0x2000;
   private static var  CORNER_MASK      = 0x3000;
   private static var  CORNER_SHIFT     = 12;

   private static var  PIXEL_HINTING    = 0x4000;


   private var mSurface:Void;

   // Current set of points
   private var mPoints:GfxPoints;

   // Solids ...
   private var mSolid:Bool;
   private var mFilling:Bool;
   private var mFillColour:Int;
   private var mFillAlpha:Float;
   private var mSolidGradient:Grad;

   // Lines ...
   private var mCurrentLine:LineJob;
   private var mLineJobs:LineJobs;

   // List of drawing commands ...
   private var mDrawList:DrawList;
   private var mLineDraws:DrawList;

   // Current position ...
   private var mPenX:Float;
   private var mPenY:Float;

   public function new(?inSurface:Void)
   {
      mSurface = inSurface;
      clear();
   }



   public function render(?inMatrix:Matrix,?inSurface:Void)
   {
      var dest:Void = inSurface == null ? Manager.getScreen() : inSurface;
      CloseList(true);
      for(obj in mDrawList)
         nme_draw_object_to(obj,dest,inMatrix);
   }


   public function blit(inTexture:nme.BitmapData)
   {
      CloseLines(false);
      AddDrawable( nme_create_blit_drawable(inTexture.handle(),mPenX,mPenY) );
   }


   public function lineStyle(thickness:Float,
                             ?color:Null<Int> /* = 0 */,
                             ?alpha:Null<Float> /* = 1.0 */,
                             ?pixelHinting:Null<Bool> /* = false */,
                             ?scaleMode:Null<String> /* = "normal" */,
                             ?caps:Null<String>,
                             ?joints:Null<String>,
                             ?miterLimit:Null<Float> /*= 3*/)
   {
      CloseLines(false);

      mCurrentLine.grad = null;
      mCurrentLine.thickness = thickness;
      mCurrentLine.colour = color==null ? 0 : color;
      mCurrentLine.alpha = alpha==null ? 1.0 : alpha;
      mCurrentLine.miter_limit = miterLimit==null ? 3.0 : miterLimit;
      mCurrentLine.pixel_hinting = (pixelHinting==null || !pixelHinting)?
                                           0 : PIXEL_HINTING;

      if (caps!=null)
      {
         switch(caps)
         {
            case nme.CapsStyle.ROUND:
               mCurrentLine.caps = END_ROUND;
            case nme.CapsStyle.SQUARE:
               mCurrentLine.caps = END_SQUARE;
            case nme.CapsStyle.NONE:
               mCurrentLine.caps = END_NONE;
         }
      }


      if (joints!=null)
      {
         switch(joints)
         {
            case JointStyle.ROUND:
               mCurrentLine.joints = CORNER_ROUND;
            case JointStyle.MITER:
               mCurrentLine.joints = CORNER_MITER;
            case JointStyle.BEVEL:
               mCurrentLine.joints = CORNER_BEVEL;
         }
      }
   }

   public function beginFill(color:Null<Int>, ?alpha:Null<Float>)
   {
      CloseList(true);

      mFillColour = color==null ? 0x000000 : color;
      mFillAlpha = alpha==null ? 1.0 : alpha;
      mFilling=true;
      mSolidGradient = null;
   }

   public function endFill()
   {
      CloseList(true);
   }

   // TODO: could me more efficient to leave this up to implementation
   public function drawCircle(x:Float,y:Float,rad:Float)
   {
      CloseList(false);

      var steps = Math.round(rad*3);
      if (steps>4)
      {
         var theta = 0.0;
         var d_theta = Math.PI * 2.0 / steps;
         moveTo( x+rad, y );
         for(s in 1...steps)
         {
            theta += d_theta;
            lineTo( x+rad*Math.cos(theta)+0.5, y + rad*Math.sin(theta)+0.5 );
         }
         lineTo( x+rad, y );
      }

      CloseList(false);
   }

   public function drawRect(x:Float,y:Float,width:Float,height:Float)
   {
      CloseList(false);

      moveTo(x,y);
      lineTo(x+width,y);
      lineTo(x+width,y+height);
      lineTo(x,y+height);
      lineTo(x,y);

      CloseList(false);
   }

   function CreateGradient(type : GradientType,
                 colors : Array<Dynamic>,
                 alphas : Array<Dynamic>,
                 ratios : Array<Dynamic>,
                 matrix : Null<Matrix>,
                 spreadMethod : Null<SpreadMethod>,
                 interpolationMethod : Null<nme.InterpolationMethod>,
                 focalPointRatio : Null<Float>)
   {

      var points = new GradPoints();
      for(i in 0...colors.length)
         points.push({col:colors[i], alpha:alphas[i], ratio:ratios[i]});


      var flags = 0;

      if (type==nme.GradientType.RADIAL)
         flags |= RADIAL;

      if (spreadMethod==nme.SpreadMethod.REPEAT)
         flags |= REPEAT;
      else if (spreadMethod==nme.SpreadMethod.REFLECT)
         flags |= REFLECT;


      if (matrix==null)
      {
         matrix = new nme.Matrix();
         matrix.createGradientBox(25,25);
      }
      else
         matrix = matrix.clone();

      var focal : Float = focalPointRatio ==null ? 0 : focalPointRatio;
      return  { points : points, matrix : matrix, flags : flags, focal:focal };
   }


   public function beginGradientFill(type : GradientType,
                 colors : Array<Dynamic>,
                 alphas : Array<Dynamic>,
                 ratios : Array<Dynamic>,
                 ?matrix : Matrix,
                 ?spreadMethod : Null<SpreadMethod>,
                 ?interpolationMethod : Null<nme.InterpolationMethod>,
                 ?focalPointRatio : Null<Float>) : Void
   {
      CloseList(true);

      mFilling = true;
      mSolidGradient = CreateGradient(type,colors,alphas,ratios,
                        matrix,spreadMethod,
                        interpolationMethod,
                        focalPointRatio);
   }


   public function clear()
   {
      mPenX = 0.0;
      mPenY = 0.0;

      mDrawList = new DrawList();

      mPoints = [];

      mSolidGradient = null;
      mFilling = false;
      mFillColour = 0x000000;
      mFillAlpha = 0.0;

      mCurrentLine = { grad: null,
                     point_idx:[],
                     thickness:0.0,
                     alpha:0.0,
                     colour:0x000,
                     miter_limit: 3.0,
                     caps:END_ROUND,
                     joints:CORNER_ROUND,
                     pixel_hinting : 0 };

      mLineJobs = [];
   }

   public function moveTo(inX:Float,inY:Float)
   {
      CloseList(false);
      mPenX = inX;
      mPenY = inY;
   }

   public function lineTo(inX:Float,inY:Float)
   {
      var pid = mPoints.length;
      if (pid==0)
      {
         mPoints.push( { x:mPenX, y:mPenY } );
         pid++;
      }

      mPenX = inX;
      mPenY = inY;
      mPoints.push( { x:mPenX, y:mPenY } );

      if (mCurrentLine.grad!=null || mCurrentLine.alpha>0)
      {
         if (mCurrentLine.point_idx.length==0)
            mCurrentLine.point_idx.push(pid-1);
         mCurrentLine.point_idx.push(pid);
      }
   }

   public function curveTo(inX:Float,inY:Float,inX1:Float,inY1:Float)
   {
      var dx1 = inX-mPenX;
      var dy1 = inY-mPenY;
      var dx2 = inX-inX1;
      var dy2 = inY-inY1;
      var len = Math.sqrt(dx1*dx1 + dy1*dy1 + dx2*dx2 + dy2*dy2 );
      var steps = Math.round(len*0.2);

      // make sure we hace point on stack
      var pid = mPoints.length;
      if (pid==0)
      {
         mPoints.push( { x:mPenX, y:mPenY } );
         pid++;
      }
      var do_line = mCurrentLine.grad!=null || mCurrentLine.alpha>0;

      // First point - make sure we get last move-to on "mCurrentLine"
      if (do_line && mCurrentLine.point_idx.length==0)
            mCurrentLine.point_idx.push(pid-1);

      if (steps>1)
      {
          var du = 1.0/steps;
          var u = du;
          for(i in 1...steps)
          {
             var u1 = 1.0-u;
             var c0 = u1*u1;
             var c1 = 2.0*u*u1;
             var c2 = u*u;

             u+=du;

             if (do_line)
               mCurrentLine.point_idx.push(mPoints.length);
             mPoints.push( { x:c0*mPenX + c1*inX + c2*inX1,
                             y:c0*mPenY + c1*inY + c2*inY1 } );
          }
      }

      // past point
      mPenX = inX1;
      mPenY = inY1;
      if (do_line)
         mCurrentLine.point_idx.push(mPoints.length);
      mPoints.push( { x:mPenX, y:mPenY } );
   }

   // Uses line style
   public function text(text:String,?fontSize:Int,?fontName:String,?bgColor:Int,
                     ?alignX:Int, ?alignY:Int)
   {
      CloseList(true);
      var size:Int = fontSize==null ? defaultFontSize : fontSize;
      var font:String = fontName==null ? defaultFontName: fontName;

      AddDrawable( nme_create_text_drawable(
          untyped text.__s,untyped font.__s,size,
          mPenX, mPenY,
          mCurrentLine.colour, mCurrentLine.alpha, bgColor, alignX, alignY ) );
   }

   public function flush() { CloseList(true); }

   private function AddDrawable(inDrawable:Void)
   {
      if (mSurface==null)
         // Store for 'ron ...
         mDrawList.push( inDrawable );
      else
      {
         nme_draw_object_to(inDrawable,mSurface,null);
      }
   }

   private function CloseLines(inTryClose:Bool)
   {
      if (mCurrentLine.point_idx.length>1)
      {
         // Close line to make loop, because this in implied by the solid.
         if (inTryClose && mCurrentLine.point_idx.length==mPoints.length)
         {
            var l = mPoints.length;
            if (mPoints[0].x!=mPoints[l-1].x || mPoints[0].y!=mPoints[l-1].y)
            {
               mCurrentLine.point_idx.push(0);
               mPoints.push( { x:mPoints[0].x, y:mPoints[0].y } );
            }
         }

         mLineJobs.push(
             {
                grad:mCurrentLine.grad,
                point_idx:mCurrentLine.point_idx,
                thickness:mCurrentLine.thickness,
                alpha:mCurrentLine.alpha,
                pixel_hinting:mCurrentLine.pixel_hinting,
                colour:mCurrentLine.colour,
                joints:mCurrentLine.joints,
                caps:mCurrentLine.caps,
                miter_limit:mCurrentLine.miter_limit,
             } );
      }
      mCurrentLine.point_idx = [];
   }

   private function CloseList(inCancelFill)
   {
      var l =  mPoints.length;
      if (l>0)
      {
         CloseLines(mFilling && l>2);
         AddDrawable( nme_create_draw_obj( untyped mPoints.__neko(),
                      mFillColour, mFillAlpha, mSolidGradient,
                      untyped mLineJobs.__neko() ) );

         mLineJobs = [];
         mPoints = [];
      }

      if (inCancelFill)
      {
         mFillAlpha = 0;
         mSolidGradient = null;
         mFilling = false;
      }
   }

   static var nme_draw_object_to = neko.Lib.load("nme","nme_draw_object_to",3);
   static var nme_create_blit_drawable = neko.Lib.load("nme","nme_create_blit_drawable",3);
   static var nme_create_draw_obj = neko.Lib.load("nme","nme_create_draw_obj",5);
   static var nme_create_text_drawable = neko.Lib.load("nme","nme_create_text_drawable",-1);

}



