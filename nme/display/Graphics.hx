/*


  Lines, fill styles and closing polygons.
   Flash allows the line stype to be changed withing one filled polygon.
   A single NME "DrawObject" has a point list, an optional solid fill style
   and a list of lines.  Each of these lines has a line style and a
   list of "point indices", which are indices into the DrawObject's point array.
   The solid does not need a point-index list because it uses all the
   points in order.

   When building up a filled polygon, eveytime the line style changes, the
    current "line fragment" is stored in the "mLineJobs" list and a new line
    is started, without affecting the solid fill bit.
*/


package nme.display;

import nme.geom.Matrix;
import nme.geom.Rectangle;
import nme.display.BitmapData;

typedef DrawList = Array<Void>;

typedef GfxPoint =
{
   var x:Float;
   var y:Float;
   var cx:Float;
   var cy:Float;
   var type:Int;
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
   var matrix:Matrix;
   var flags:Int;
   var focal:Float;
}

typedef LineJob =
{
   var grad:Grad;
   var point_idx0:Int;
   var point_idx1:Int;
   var thickness:Float;
   var alpha:Float;
   var colour:Int;
   var pixel_hinting:Int;
   var joints:Int;
   var caps:Int;
   var miter_limit:Float;
}

typedef Texture =
{
   var texture_buffer:Void;
   var matrix:Matrix;
   var flags:Int;
}

typedef LineJobs = Array<LineJob>;

class Graphics
{
   public static var defaultFontName = "ARIAL.TTF";
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

   public static var BMP_REPEAT  = 0x0010;
   public static var BMP_SMOOTH  = 0x10000;



   static var MOVE = 0;
   static var LINE = 1;
   static var CURVE = 2;


   private var mSurface:Void;
   private var mChanged:Bool;

   // Current set of points
   private var mPoints:GfxPoints;

   // Solids ...
   private var mSolid:Bool;
   private var mFilling:Bool;
   private var mFillColour:Int;
   private var mFillAlpha:Float;
   private var mSolidGradient:Grad;
   private var mBitmap:Texture;

   // Lines ...
   private var mCurrentLine:LineJob;
   private var mLineJobs:LineJobs;

   // List of drawing commands ...
   private var mDrawList:DrawList;
   private var mLineDraws:DrawList;

   // Current position ...
   private var mPenX:Float;
   private var mPenY:Float;

   public var clipRect(GetClipRect,SetClipRect):Rectangle;

   public function new(?inSurface:Void)
   {
      mChanged = false;
      mSurface = inSurface;
      clear();
   }



   public function render(?inMatrix:Matrix,?inSurface:Void)
   {
      ClosePolygon(true);

      var dest:Void = inSurface == null ? nme.Manager.getScreen() : inSurface;
      for(obj in mDrawList)
         nme_draw_object_to(obj,dest,inMatrix);
   }

   public function hitTest(inMatrix:Matrix,inX:Int,inY:Int) : Bool
   {
      ClosePolygon(true);
      for(obj in mDrawList)
      {
         if (nme_hit_object(nme.Manager.getScreen(),obj,inMatrix,inX,inY))
            return true;
      }
      return false;
   }



   public function blit(inTexture:BitmapData)
   {
      ClosePolygon(true);
      AddDrawable( nme_create_blit_drawable(inTexture.handle(),mPenX,mPenY) );
   }



   public function lineStyle(?thickness:Null<Float>,
                             ?color:Null<Int> /* = 0 */,
                             ?alpha:Null<Float> /* = 1.0 */,
                             ?pixelHinting:Null<Bool> /* = false */,
                             ?scaleMode:Null<LineScaleMode> /* = "normal" */,
                             ?caps:Null<CapsStyle>,
                             ?joints:Null<JointStyle>,
                             ?miterLimit:Null<Float> /*= 3*/)
   {
      // Finish off old line before starting a new one
      AddLineSegment();
      
      //with no parameters it clears the current line (to draw nothing)
      if( thickness == null )
      {
         ClearLine();
         return;
      }
      else
      {
         mCurrentLine.grad = null;
         mCurrentLine.thickness = thickness;
         mCurrentLine.colour = color==null ? 0 : color;
         mCurrentLine.alpha = alpha==null ? 1.0 : alpha;
         mCurrentLine.miter_limit = miterLimit==null ? 3.0 : miterLimit;
         mCurrentLine.pixel_hinting = (pixelHinting==null || !pixelHinting)?
                                             0 : PIXEL_HINTING;
      }

      if (caps!=null)
      {
         switch(caps)
         {
            case CapsStyle.ROUND:
               mCurrentLine.caps = END_ROUND;
            case CapsStyle.SQUARE:
               mCurrentLine.caps = END_SQUARE;
            case CapsStyle.NONE:
               mCurrentLine.caps = END_NONE;
         }
      }
      else
         mCurrentLine.caps = END_NONE;


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
      else
         mCurrentLine.joints = CORNER_ROUND;
   }

   public function lineGradientStyle(type : GradientType,
                 colors : Array<Dynamic>,
                 alphas : Array<Dynamic>,
                 ratios : Array<Dynamic>,
                 ?matrix : Matrix,
                 ?spreadMethod : SpreadMethod,
                 ?interpolationMethod : InterpolationMethod,
                 ?focalPointRatio : Null<Float>) : Void
   {
      mCurrentLine.grad = CreateGradient(type,colors,alphas,ratios,
                              matrix,spreadMethod,
                              interpolationMethod,
                              focalPointRatio);
   }



   public function beginFill(color:Int, ?alpha:Null<Float>)
   {
      ClosePolygon(true);

      mFillColour =  color;
      mFillAlpha = alpha==null ? 1.0 : alpha;
      mFilling=true;
      mSolidGradient = null;
      mBitmap = null;
   }

   public function endFill()
   {
      ClosePolygon(true);
   }

   // TODO: could me more efficient to leave this up to implementation
   public function drawEllipse(x:Float,y:Float,x_rad:Float,y_rad:Float)
   {
      ClosePolygon(false);

      var rad = x_rad>y_rad ? x_rad : y_rad;
      var steps = Math.round(rad*2);
      if (steps<4)
         steps = 4;

      {
         var theta = 0.0;
         var d_theta = Math.PI * 2.0 / steps;
         moveTo( x+rad, y );
         for(s in 1...steps)
         {
            theta += d_theta;
            lineTo( x+x_rad*Math.cos(theta)+0.5, y+y_rad*Math.sin(theta)+0.5 );
         }
         lineTo( x+rad, y );
      }

      ClosePolygon(false);
   }

   public function drawCircle(x:Float,y:Float,rad:Float)
   {
      drawEllipse(x,y,rad,rad);
   }

   public function drawRect(x:Float,y:Float,width:Float,height:Float)
   {
      ClosePolygon(false);

      moveTo(x,y);
      lineTo(x+width,y);
      lineTo(x+width,y+height);
      lineTo(x,y+height);
      lineTo(x,y);

      ClosePolygon(false);
   }



   public function drawRoundRect(x:Float,y:Float,width:Float,height:Float,
                       ellipseWidth:Float, ellipseHeight:Float)
   {
      if (ellipseHeight<1 || ellipseHeight<1)
      {
         drawRect(x,y,width,height);
         return;
      }

      ClosePolygon(false);

      moveTo(x,y+ellipseHeight);
      // top-left
      curveTo(x,y,x+ellipseWidth,y);

      lineTo(x+width-ellipseWidth,y);
      // top-right
      curveTo(x+width,y,x+width,y+ellipseWidth);

      lineTo(x+width,y+height-ellipseHeight);

      // bottom-right
      curveTo(x+width,y+height,x+width-ellipseWidth,y+height);

      lineTo(x+ellipseWidth,y+height);

      // bottom-left
      curveTo(x,y+height,x,y+height-ellipseHeight);

      lineTo(x,y+ellipseHeight);

      ClosePolygon(false);
   }

   function CreateGradient(type : GradientType,
                 colors : Array<Dynamic>,
                 alphas : Array<Dynamic>,
                 ratios : Array<Dynamic>,
                 matrix : Null<Matrix>,
                 spreadMethod : Null<SpreadMethod>,
                 interpolationMethod : Null<InterpolationMethod>,
                 focalPointRatio : Null<Float>)
   {

      var points = new GradPoints();
      for(i in 0...colors.length)
         points.push({col:colors[i], alpha:alphas[i], ratio:ratios[i]});


      var flags = 0;

      if (type==GradientType.RADIAL)
         flags |= RADIAL;

      if (spreadMethod==SpreadMethod.REPEAT)
         flags |= REPEAT;
      else if (spreadMethod==SpreadMethod.REFLECT)
         flags |= REFLECT;


      if (matrix==null)
      {
         matrix = new Matrix();
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
                 ?interpolationMethod : Null<InterpolationMethod>,
                 ?focalPointRatio : Null<Float>) : Void
   {
      ClosePolygon(true);

      mFilling = true;
      mBitmap = null;
      mSolidGradient = CreateGradient(type,colors,alphas,ratios,
                        matrix,spreadMethod,
                        interpolationMethod,
                        focalPointRatio);
   }




   public function beginBitmapFill(bitmap:BitmapData, ?matrix:Matrix,
                  ?in_repeat:Bool, ?in_smooth:Bool)
   {
      ClosePolygon(true);

      var repeat:Bool = in_repeat==null ? true : in_repeat;
      var smooth:Bool = in_smooth==null ? false : in_smooth;

      mFilling = true;

      mSolidGradient = null;

      mBitmap = { texture_buffer: bitmap.handle(),
                  matrix: matrix==null ? matrix : matrix.clone(),
                  flags : (repeat ? BMP_REPEAT : 0) |
                          (smooth ? BMP_SMOOTH : 0) };

   }

   public function RenderGlyph(inFont:nme.FontHandle,inChar:Int,
            inX:Float,inY:Float,?inUseFreeType:Bool)
   {
      ClosePolygon(false);

      var free_type = inUseFreeType==null ? 
        (mSolidGradient==null && mBitmap==null &&
            (mCurrentLine.thickness==null || mCurrentLine.thickness==0)):
          inUseFreeType;

      AddDrawable(nme_create_glyph_draw_obj(inX,inY,
             inFont.handle,inChar,
             mFillColour, mFillAlpha,
             untyped mSolidGradient==null? mBitmap : mSolidGradient,
             mCurrentLine,
             free_type) );
   }


   public function ClearLine()
   {
      mCurrentLine = { grad: null,
                     point_idx0:-1,
                     point_idx1:-1,
                     thickness:0.0,
                     alpha:0.0,
                     colour:0x000,
                     miter_limit: 3.0,
                     caps:END_ROUND,
                     joints:CORNER_ROUND,
                     pixel_hinting : 0 };

   }


   public function clear()
   {
      mChanged = true;
      mPenX = 0.0;
      mPenY = 0.0;

      mDrawList = new DrawList();

      mPoints = [];

      mSolidGradient = null;
      mBitmap = null;
      mFilling = false;
      mFillColour = 0x000000;
      mFillAlpha = 0.0;

      ClearLine();

      mLineJobs = [];
   }

   public function GetExtent(inMatrix:Matrix) : Rectangle
   {
      flush();
      var result = new Rectangle();

      nme_get_extent(mDrawList,result,inMatrix,true);

      return result;
   }

   public function moveTo(inX:Float,inY:Float)
   {
      mPenX = inX;
      mPenY = inY;

      if (!mFilling)
         ClosePolygon(false);
      else
      {
         AddLineSegment();
         mPoints.push( { x:mPenX, y:mPenY, cx:0.0, cy:0.0, type:MOVE } );
      }
   }

   public function lineTo(inX:Float,inY:Float)
   {
      var pid = mPoints.length;
      if (pid==0)
      {
         mPoints.push( { x:mPenX, y:mPenY, cx:0.0, cy:0.0, type:MOVE } );
         pid++;
      }

      mPenX = inX;
      mPenY = inY;
      mPoints.push( { x:mPenX, y:mPenY, cx:0.0, cy:0.0, type:LINE } );

      if (mCurrentLine.grad!=null || mCurrentLine.alpha>0)
      {
         if (mCurrentLine.point_idx0<0)
            mCurrentLine.point_idx0 = pid-1;
         mCurrentLine.point_idx1 = pid;
      }
   }

   public function curveTo(inCX:Float,inCY:Float,inX:Float,inY:Float)
   {
      var pid = mPoints.length;
      if (pid==0)
      {
         mPoints.push( { x:mPenX, y:mPenY, cx:0.0, cy:0.0, type:MOVE } );
         pid++;
      }

      mPenX = inX;
      mPenY = inY;
      mPoints.push( { x:inX, y:inY, cx:inCX, cy:inCY, type:CURVE } );

      if (mCurrentLine.grad!=null || mCurrentLine.alpha>0)
      {
         if (mCurrentLine.point_idx0<0)
            mCurrentLine.point_idx0 = pid-1;
         mCurrentLine.point_idx1 = pid;
      }

   }

   // Uses line style
   public function text(text:String,?fontSize:Int,?fontName:String,?bgColor:Int,
                     ?alignX:Int, ?alignY:Int)
   {
      ClosePolygon(true);
      var size:Int = fontSize==null ? defaultFontSize : fontSize;
      var font:String = fontName==null ? defaultFontName: fontName;

      AddDrawable( nme_create_text_drawable(
          untyped text.__s,untyped font.__s,size,
          mPenX, mPenY,
          mCurrentLine.colour, mCurrentLine.alpha, bgColor, alignX, alignY ) );
   }

   public function flush() { ClosePolygon(true); }

   public function CheckChanged() : Bool
   {
      ClosePolygon(true);
      var result = mChanged;
      mChanged = false;
      return result;
   }

   private function AddDrawable(inDrawable:Void)
   {
      if (inDrawable==null)
         return; // throw ?

      mChanged = true;
      if (mSurface==null)
         // Store for 'ron ...
         mDrawList.push( inDrawable );
      else
      {
         nme_draw_object_to(inDrawable,mSurface,null);
      }
   }


   private function AddLineSegment()
   {
      if (mCurrentLine.point_idx1>0)
      {
            mLineJobs.push(
               {
                  grad:mCurrentLine.grad,
                  point_idx0:mCurrentLine.point_idx0,
                  point_idx1:mCurrentLine.point_idx1,
                  thickness:mCurrentLine.thickness,
                  alpha:mCurrentLine.alpha,
                  pixel_hinting:mCurrentLine.pixel_hinting,
                  colour:mCurrentLine.colour,
                  joints:mCurrentLine.joints,
                  caps:mCurrentLine.caps,
                  miter_limit:mCurrentLine.miter_limit,
               } );
      }
      mCurrentLine.point_idx0 = mCurrentLine.point_idx1 = -1;
   }

   private function ClosePolygon(inCancelFill)
   {
      var l =  mPoints.length;
      if (l>0)
      {
         if (mFilling && l>2)
         {
            // Make implicit closing line
            //if (mPoints[0].x!=mPoints[l-1].x || mPoints[0].y!=mPoints[l-1].y)
               //lineTo(mPoints[0].x, mPoints[0].y);
         }

         AddLineSegment();

         AddDrawable( nme_create_draw_obj( untyped mPoints.__neko(),
                      mFillColour, mFillAlpha,
                      untyped mSolidGradient==null ? mBitmap:mSolidGradient,
                      untyped mLineJobs.__neko() ) );

         mLineJobs = [];
         mPoints = [];
      }

      if (inCancelFill)
      {
         mFillAlpha = 0;
         mSolidGradient = null;
         mBitmap = null;
         mFilling = false;
      }
   }

   function GetClipRect() : Rectangle
   {
     var r:Dynamic =  nme_get_clip_rect(mSurface);
     return new Rectangle(r.x,r.y,r.w,r.h);
   }

   function SetClipRect(inRect:Rectangle) : Rectangle
   {
     var r:Dynamic =  nme_set_clip_rect(mSurface,inRect);
     return new Rectangle(r.x,r.y,r.w,r.h);
   }




   static var nme_draw_object_to = neko.Lib.load("nme","nme_draw_object_to",3);
   static var nme_hit_object = neko.Lib.load("nme","nme_hit_object",5);
   static var nme_create_blit_drawable = neko.Lib.load("nme","nme_create_blit_drawable",3);
   static var nme_create_draw_obj = neko.Lib.load("nme","nme_create_draw_obj",5);
   static var nme_create_text_drawable = neko.Lib.load("nme","nme_create_text_drawable",-1);
   static var nme_get_clip_rect = neko.Lib.load("nme","nme_get_clip_rect",1);
   static var nme_set_clip_rect = neko.Lib.load("nme","nme_set_clip_rect",2);
   static var nme_get_extent = neko.Lib.load("nme","nme_get_extent",4);
   static var nme_create_glyph_draw_obj = neko.Lib.load("nme","nme_create_glyph_draw_obj",-1);

}



