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

typedef DrawList = Array<Dynamic>;

class GfxPoint
{
   public function new(inX:Float,inY:Float,inCX:Float,inCY:Float,inType:Int)
      { x = inX; y=inY; cx=inCX; cy=inCY; type=inType; }

   public var x:Float;
   public var y:Float;
   public var cx:Float;
   public var cy:Float;
   public var type:Int;
}

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

class LineJob
{
   public function new( inGrad:Grad, inPoint_idx0:Int, inPoint_idx1:Int, inThickness:Float,
         inAlpha:Float, inColour:Int, inPixel_hinting:Int, inJoints:Int, inCaps:Int,
         inScale_mode:Int, inMiter_limit:Float)
   {
     grad = inGrad;
     point_idx0 = inPoint_idx0;
     point_idx1 = inPoint_idx1;
     thickness = inThickness;
     alpha = inAlpha;
     colour = inColour;
     pixel_hinting = inPixel_hinting;
     joints = inJoints;
     caps = inCaps;
     scale_mode = inScale_mode;
     miter_limit = inMiter_limit;
   }

   public var grad:Grad;
   public var point_idx0:Int;
   public var point_idx1:Int;
   public var thickness:Float;
   public var alpha:Float;
   public var colour:Int;
   public var pixel_hinting:Int;
   public var joints:Int;
   public var caps:Int;
   public var scale_mode:Int;
   public var miter_limit:Float;
}

typedef Texture =
{
   var texture_buffer:Dynamic;
   var matrix:Matrix;
   var flags:Int;
}

typedef LineJobs = Array<LineJob>;

class Graphics
{
   public static var defaultFontName = "ARIAL.TTF";
   public static var defaultFontSize = 12;
   public static var immediateMatrix = null;
   public static var immediateMask:Dynamic = null;



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


   private static var  SCALE_NONE       = 0;
   private static var  SCALE_VERTICAL   = 1;
   private static var  SCALE_HORIZONTAL = 2;
   private static var  SCALE_NORMAL     = 3;

   static var MOVE = 0;
   static var LINE = 1;
   static var CURVE = 2;


   public static var BLEND_ADD = 0;
   public static var BLEND_ALPHA = 1;
   public static var BLEND_DARKEN = 2;
   public static var BLEND_DIFFERENCE = 3;
   public static var BLEND_ERASE = 4;
   public static var BLEND_HARDLIGHT = 5;
   public static var BLEND_INVERT = 6;
   public static var BLEND_LAYER = 7;
   public static var BLEND_LIGHTEN = 8;
   public static var BLEND_MULTIPLY = 9;
   public static var BLEND_NORMAL = 10;
   public static var BLEND_OVERLAY = 11;
   public static var BLEND_SCREEN = 12;
   public static var BLEND_SUBTRACT = 13;
   public static var BLEND_SHADER = 14;


   private var mSurface:Dynamic;
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
   private var mLastMoveID:Int;

   //public var clipRect(GetClipRect,SetClipRect):Rectangle;

   public function new(?inSurface:Dynamic)
   {
      mChanged = false;
      mSurface = inSurface;
      mLastMoveID = 0;
      clear();
   }

   public function SetSurface(inSurface:Dynamic)
   {
      mSurface = inSurface;
   }

   public function GetSurfaceRect()
   {
      var s = mSurface==null ? nme.Manager.getScreen() : mSurface;
      return nme.Surface.GetSurfaceRect(s);
   }


   public static function setBlendMode(inBlendMode:Int)
   {
      nme_set_blend_mode(inBlendMode);
   }

   public function render(?inMatrix:Matrix,?inSurface:Dynamic,?inMaskHandle:Dynamic,?inScrollRect:Rectangle)
   {
      ClosePolygon(true);

      var dest:Dynamic = inSurface == null ? nme.Manager.getScreen() : inSurface;
      for(obj in mDrawList)
         nme_draw_object_to(obj,dest,inMatrix,inMaskHandle,inScrollRect);
   }

   // Only works properly after a render ...
   public function hitTest(inX:Int,inY:Int) : Bool
   {
      for(obj in mDrawList)
      {
         if (nme_hit_object(obj,inX,inY))
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
         mCurrentLine.thickness = Math.round(thickness);
         mCurrentLine.colour = color==null ? 0 : color;
         mCurrentLine.alpha = alpha==null ? 1.0 : alpha;
         mCurrentLine.miter_limit = miterLimit==null ? 3.0 : miterLimit;
         mCurrentLine.pixel_hinting = (pixelHinting==null || !pixelHinting)?
                                             0 : PIXEL_HINTING;
      }
      mCurrentLine.caps = END_ROUND;
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

      mCurrentLine.scale_mode = SCALE_NORMAL;
      if (scaleMode!=null)
      {
         switch(scaleMode)
         {
            case LineScaleMode.NORMAL:
               mCurrentLine.scale_mode = SCALE_NORMAL;
            case LineScaleMode.VERTICAL:
               mCurrentLine.scale_mode = SCALE_VERTICAL;
            case LineScaleMode.HORIZONTAL:
               mCurrentLine.scale_mode = SCALE_HORIZONTAL;
            case LineScaleMode.NONE:
               mCurrentLine.scale_mode = SCALE_NONE;
         }
      }


      mCurrentLine.joints = CORNER_ROUND;
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

   public function drawEllipse(x:Float,y:Float,rx:Float,ry:Float)
   {
      ClosePolygon(false);

      moveTo(x+rx, y);
      curveTo(rx+x        ,-0.4142*ry+y,0.7071*rx+x ,-0.7071*ry+y);
      curveTo(0.4142*rx+x ,-ry+y       ,x           ,-ry+y);
      curveTo(-0.4142*rx+x,-ry+y       ,-0.7071*rx+x,-0.7071*ry+y);
      curveTo(-rx+x       ,-0.4142*ry+y,-rx+x       , y);
      curveTo(-rx+x       ,0.4142*ry+y ,-0.7071*rx+x,0.7071*ry+y);
      curveTo(-0.4142*rx+x,ry+y        ,x           ,ry+y);
      curveTo(0.4142*rx+x ,ry+y        ,0.7071*rx+x ,0.7071*ry+y) ;
      curveTo(rx+x        ,0.4142*ry+y ,rx+x        ,y);

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

      var w = ellipseWidth * 0.5;
      var h = ellipseHeight * 0.5;

      moveTo(x,y+h);
      // top-left
      curveTo(x,y,x+w,y);

      lineTo(x+width-w,y);
      // top-right
      curveTo(x+width,y,x+width,y+w);

      lineTo(x+width,y+height-h);

      // bottom-right
      curveTo(x+width,y+height,x+width-w,y+height);

      lineTo(x+w,y+height);

      // bottom-left
      curveTo(x,y+height,x,y+height-h);

      lineTo(x,y+h);

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
        (mSolidGradient==null && mBitmap==null && mCurrentLine.thickness==0):
          inUseFreeType;

      AddDrawable(nme_create_glyph_draw_obj(inX,inY,
             inFont.handle,inChar,
             mFillColour, mFillAlpha,
             untyped mSolidGradient==null? mBitmap : mSolidGradient,
             mCurrentLine,
             free_type) );
   }

   public function drawTriangles(vertices:Array<Float>,
          ?indices:Array<Int>,
          ?uvtData:Array<Float>,
          ?culling:flash.display.TriangleCulling)
   {
      var cull = culling==null ? 0 : switch(culling) {
         case NONE: 0;
         case NEGATIVE: -1;
         case POSITIVE: 1;
      }
      ClosePolygon(false);
      //trace("drawTriangles " + vertices.length );
      AddDrawable(nme_create_draw_triangles(
             vertices,indices,uvtData,cull,
             mFillColour, mFillAlpha, mBitmap, mCurrentLine ));
   }


   public function ClearLine()
   {
      mCurrentLine = new LineJob( null,-1,-1,  0.0,
            0.0, 0x000, 1, CORNER_ROUND, END_ROUND,
            SCALE_NORMAL, 3.0);
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
      mLastMoveID = 0;

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
         mLastMoveID = mPoints.length;
         mPoints.push( new GfxPoint( mPenX, mPenY, 0.0, 0.0, MOVE ) );
      }
   }

   public function lineTo(inX:Float,inY:Float)
   {
      var pid = mPoints.length;
      if (pid==0)
      {
         mPoints.push( new GfxPoint( mPenX, mPenY, 0.0, 0.0, MOVE ) );
         pid++;
      }

      mPenX = inX;
      mPenY = inY;
      mPoints.push( new GfxPoint( mPenX, mPenY, 0.0, 0.0, LINE ) );

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
         mPoints.push( new GfxPoint( mPenX, mPenY, 0.0, 0.0, MOVE ) );
         pid++;
      }

      mPenX = inX;
      mPenY = inY;
      mPoints.push( new GfxPoint( inX, inY, inCX, inCY, CURVE ) );

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
      #if neko
          untyped text.__s,untyped font.__s,size,
      #else
          text,font,size,
      #end
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

   private function AddDrawable(inDrawable:Dynamic)
   {
      if (inDrawable==null)
         return; // throw ?

      mChanged = true;
      if (mSurface==null)
         // Store for 'ron ...
         mDrawList.push( inDrawable );
      else
      {
         nme_draw_object_to(inDrawable,mSurface,immediateMatrix,immediateMask,null);
      }
   }


   private function AddLineSegment()
   {
      if (mCurrentLine.point_idx1>0)
      {
            mLineJobs.push(
               new LineJob(
                  mCurrentLine.grad,
                  mCurrentLine.point_idx0,
                  mCurrentLine.point_idx1,
                  mCurrentLine.thickness,
                  mCurrentLine.alpha,
                  mCurrentLine.colour,
                  mCurrentLine.pixel_hinting,
                  mCurrentLine.joints,
                  mCurrentLine.caps,
                  mCurrentLine.scale_mode,
                  mCurrentLine.miter_limit
               ) );
      }
      mCurrentLine.point_idx0 = mCurrentLine.point_idx1 = -1;
   }

   private function ClosePolygon(inCancelFill)
   {
      var l =  mPoints.length;
      if (l>0)
      {
         if (l>1)
         {
            if (mFilling && l>2)
            {
               // Make implicit closing line
               if (mPoints[mLastMoveID].x!=mPoints[l-1].x || mPoints[mLastMoveID].y!=mPoints[l-1].y)
               {
                  lineTo(mPoints[mLastMoveID].x, mPoints[mLastMoveID].y);
               }
            }

            AddLineSegment();

            #if neko
            AddDrawable( nme_create_draw_obj( untyped mPoints.__neko(),
                      mFillColour, mFillAlpha,
                      untyped mSolidGradient==null ? mBitmap:mSolidGradient,
                      untyped mLineJobs.__neko() ) );
            #else
            AddDrawable( nme_create_draw_obj( mPoints,
                      mFillColour, mFillAlpha,
                      untyped mSolidGradient==null ? mBitmap:mSolidGradient,
                      mLineJobs ) );
            #end

         }

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

   public function AddToMask(ioMask:Dynamic,inMatrix:Matrix,?inSurface:Dynamic)
   {
      if (mDrawList.length>0)
      {
         var dest:Dynamic = inSurface == null ? nme.Manager.getScreen() : inSurface;
         nme_add_to_mask(mDrawList,dest,ioMask,inMatrix);
      }
   }

   public function CreateMask(inMatrix:Matrix):Dynamic
   {
      var mask:Dynamic = nme_create_mask();
      AddToMask(mask,inMatrix);
      return mask;
   }

   public function SetScale9Grid(inRect:Rectangle,inSX:Float,inSY:Float,inExtent:Rectangle)
   {
      nme_set_scale9_grid(inRect,inSX,inSY,inExtent);
   }

/*
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
*/



   static var nme_draw_object_to = nme.Loader.load("nme_draw_object_to",5);
   static var nme_hit_object = nme.Loader.load("nme_hit_object",3);
   static var nme_create_blit_drawable = nme.Loader.load("nme_create_blit_drawable",3);
   static var nme_create_draw_obj = nme.Loader.load("nme_create_draw_obj",5);
   static var nme_create_text_drawable = nme.Loader.load("nme_create_text_drawable",-1);
   static var nme_create_draw_triangles = nme.Loader.load("nme_create_draw_triangles",-1);
   static var nme_get_clip_rect = nme.Loader.load("nme_get_clip_rect",1);
   static var nme_set_clip_rect = nme.Loader.load("nme_set_clip_rect",2);
   static var nme_get_extent = nme.Loader.load("nme_get_extent",4);
   static var nme_create_glyph_draw_obj = nme.Loader.load("nme_create_glyph_draw_obj",-1);
   static var nme_create_mask = nme.Loader.load("nme_create_mask",0);
   static var nme_add_to_mask = nme.Loader.load("nme_add_to_mask",4);
   static var nme_set_scale9_grid = nme.Loader.load("nme_set_scale9_grid",4);
   static var nme_set_blend_mode = nme.Loader.load("nme_set_blend_mode",1);

}



