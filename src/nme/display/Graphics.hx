package nme.display;
#if (!flash)

import nme.geom.Matrix;
import nme.PrimeLoader;
import nme.NativeHandle;

@:nativeProperty
class Graphics 
{
   public static inline var TILE_SCALE   = 0x0001;
   public static inline var TILE_ROTATION = 0x0002;
   public static inline var TILE_RGB     = 0x0004;
   public static inline var TILE_ALPHA   = 0x0008;
   public static inline var TILE_TRANS_2x2 = 0x0010; // Will ignore scale and rotation....
   public static inline var TILE_RECT    = 0x0020;		// won't use tile ids
   public static inline var TILE_ORIGIN  = 0x0040;
   public static inline var TILE_NO_ID   = 0x0080;  // Assume ID0
   public static inline var TILE_MOUSE_ENABLE   = 0x0100;
   public static inline var TILE_FIXED_SIZE     = 0x0200;
   private static inline var TILE_SMOOTH = 0x1000;
   public static inline var TILE_BLEND_NORMAL   = 0x00000000;
   public static inline var TILE_BLEND_ADD      = 0x00010000;

   //public static inline var TILE_BLEND_SUBTRACT = 0x00020000;
   /** @private */ var nmeHandle:NativeHandle;
   public function new(inHandle:Dynamic) 
   {
      nmeHandle = inHandle;
   }

   public function arcTo(inCX:Float, inCY:Float, inX:Float, inY:Float) 
   {
      nme_gfx_arc_to(nmeHandle, inCX, inCY, inX, inY);
   }

   public function beginBitmapFill(bitmap:BitmapData, ?matrix:Matrix, repeat:Bool = true, smooth:Bool = false) 
   {
      nme_gfx_begin_bitmap_fill(nmeHandle, bitmap.nmeHandle, matrix, repeat, smooth);
   }

   public function beginFill(color:Int, alpha:Float = 1.0) 
   {
      nme_gfx_begin_fill(nmeHandle, color, alpha);
   }

   public function beginGradientFill(type:GradientType, colors:Array<Dynamic>, alphas:Array<Dynamic>, ratios:Array<Dynamic>, ?matrix:Matrix, ?spreadMethod:Null<SpreadMethod>, ?interpolationMethod:Null<InterpolationMethod>, focalPointRatio:Float = 0.0):Void 
   {
      if (matrix == null) 
      {
         matrix = new Matrix();
         matrix.createGradientBox(200, 200, 0, -100, -100);
      }

      nme_gfx_begin_set_gradient_fill(nmeHandle, Type.enumIndex(type), colors, alphas, ratios, matrix, spreadMethod == null ? 0 : Type.enumIndex(spreadMethod), interpolationMethod == null ? 0 : Type.enumIndex(interpolationMethod), focalPointRatio, true);
   }

   public function clear() 
   {
      nme_gfx_clear(nmeHandle);
   }

   public function curveTo(inCX:Float, inCY:Float, inX:Float, inY:Float) 
   {
      nme_gfx_curve_to(nmeHandle, inCX, inCY, inX, inY);
   }

   public function cubicTo(inCx0:Float, inCy0:Float, inCx1:Float, inCy1:Float, inX:Float, inY:Float) 
   {
      nme_gfx_cubic_to(nmeHandle, inCx0, inCy0, inCx1, inCy1, inX, inY);
   }

   public function drawCircle(inX:Float, inY:Float, inRadius:Float) 
   {
      nme_gfx_draw_ellipse(nmeHandle, inX - inRadius, inY - inRadius, inRadius * 2, inRadius * 2);
   }

   public function drawEllipse(inX:Float, inY:Float, inWidth:Float, inHeight:Float) 
   {
      nme_gfx_draw_ellipse(nmeHandle, inX, inY, inWidth, inHeight);
   }

   public function drawGraphicsData(graphicsData:Array<IGraphicsData>):Void 
   {
      var handles = new Array<Dynamic>();

      for(datum in graphicsData)
         handles.push(datum.nmeHandle);

      nme_gfx_draw_data(nmeHandle, handles);
   }

   public function drawGraphicsDatum(graphicsDatum:IGraphicsData):Void 
   {
      nme_gfx_draw_datum(nmeHandle, graphicsDatum.nmeHandle);
   }

   public function drawPoints(inXY:Array<Float>, inPointRGBA:Array<Int> = null, inDefaultRGBA:Int = #if (neko && (!haxe3 || neko_v1)) 0x3fffffff #else 0xffffffff #end, inSize:Float = -1.0) 
   {
      nme_gfx_draw_points(nmeHandle, inXY, inPointRGBA, inDefaultRGBA, #if (neko && (!haxe3 || neko_v1)) true #else false #end, inSize);
   }

   public function drawRect(inX:Float, inY:Float, inWidth:Float, inHeight:Float) 
   {
      nme_gfx_draw_rect(nmeHandle, inX, inY, inWidth, inHeight);
   }

   public function drawRoundRect(inX:Float, inY:Float, inWidth:Float, inHeight:Float, inRadX:Float, ?inRadY:Float) 
   {
      if (inRadX==0 || inRadY==0)
         nme_gfx_draw_rect(nmeHandle, inX, inY, inWidth, inHeight);
      else
         nme_gfx_draw_round_rect(nmeHandle, inX, inY, inWidth, inHeight, inRadX, inRadY == null ? inRadX : inRadY);
   }

   public function drawPath(commands:Array<Int>, data:Array<Float>, winding:String = GraphicsPathWinding.EVEN_ODD) 
   {
      nme_gfx_draw_path(nmeHandle, commands, data, winding == GraphicsPathWinding.EVEN_ODD);
   }

   public function drawTiles(sheet:Tilesheet, inXYID:nme.utils.Floats3264, inSmooth:Bool = false, inFlags:Int = 0, inCount:Int = -1):Void {
      beginBitmapFill(sheet.nmeBitmap, null, false, inSmooth);

      if (inSmooth)
         inFlags |= TILE_SMOOTH;
      #if jsprime
      var buffer:nme.utils.Float32Buffer = 
         Std.is(inXYID,nme.utils.Float32Buffer) ? (inXYID:nme.utils.Float32Buffer) : null;
      #else
      var buffer:nme.utils.Float32Buffer = cast inXYID;
      #end

      if (buffer!=null)
      {
         if (inCount<0)
            inCount = buffer.count;
         #if jsprime
         nme_gfx_draw_tiles(nmeHandle, sheet.nmeHandle, buffer, inFlags, inCount);
         #else
         nme_gfx_draw_tiles(nmeHandle, sheet.nmeHandle, buffer.getData(), inFlags, inCount);
         #end
      }
      else
      {
         nme_gfx_draw_tiles(nmeHandle, sheet.nmeHandle, inXYID, inFlags, inCount);
      }
   }
   
   public function drawTriangles(vertices:Array<Float>, ?indices:Array<Int>, ?uvtData:Array<Float>, ?culling:TriangleCulling, ?colours:Array<Int>, blendMode:Int = 0) 
   {
      var cull:Int = culling == null ? 0 : Type.enumIndex(culling) - 1;
      nme_gfx_draw_triangles(nmeHandle, vertices, indices, uvtData, cull, colours, blendMode);
   }

   public function endFill() 
   {
      nme_gfx_end_fill(nmeHandle);
   }

   public function lineBitmapStyle(bitmap:BitmapData, ?matrix:Matrix, repeat:Bool = true, smooth:Bool = false) 
   {
      nme_gfx_line_bitmap_fill(nmeHandle, bitmap.nmeHandle, matrix, repeat, smooth);
   }

   public function lineGradientStyle(type:GradientType, colors:Array<Dynamic>, alphas:Array<Dynamic>, ratios:Array<Dynamic>, ?matrix:Matrix, ?spreadMethod:Null<SpreadMethod>, ?interpolationMethod:Null<InterpolationMethod>, focalPointRatio:Float = 0.0):Void 
   {
      if (matrix == null) 
      {
         matrix = new Matrix();
         matrix.createGradientBox(200, 200, 0, -100, -100);
      }

      nme_gfx_begin_set_gradient_fill(nmeHandle, Type.enumIndex(type), colors, alphas, ratios, matrix, spreadMethod == null ? 0 : Type.enumIndex(spreadMethod), interpolationMethod == null ? 0 : Type.enumIndex(interpolationMethod), focalPointRatio, false);
   }

   public function lineStyle(?thickness:Null<Float>, color:Int = 0, alpha:Float = 1.0, pixelHinting:Bool = false, ?scaleMode:LineScaleMode, ?caps:CapsStyle, ?joints:JointStyle, miterLimit:Float = 3):Void 
   {
      nme_gfx_line_style(nmeHandle, thickness, color, alpha, pixelHinting, scaleMode == null ?  0 : Type.enumIndex(scaleMode), caps == null ?  0 : Type.enumIndex(caps), joints == null ?  0 : Type.enumIndex(joints), miterLimit);
   }

   public function lineTo(inX:Float, inY:Float) 
   {
      nme_gfx_line_to(nmeHandle, inX, inY);
   }

   public function moveTo(inX:Float, inY:Float) 
   {
      nme_gfx_move_to(nmeHandle, inX, inY);
   }

   inline static public function RGBA(inRGB:Int, inA:Int = 0xff):Int 
   {
      #if (neko && (!haxe3 || neko_v1))
      return inRGB |((inA & 0xfc) << 22);
      #else
      return inRGB |(inA << 24);
      #end
   }

   // Native Methods
   private static var nme_gfx_clear = PrimeLoader.load("nme_gfx_clear", "ov");
   private static var nme_gfx_begin_fill = PrimeLoader.load("nme_gfx_begin_fill", "oidv");
   private static var nme_gfx_begin_bitmap_fill = PrimeLoader.load("nme_gfx_begin_bitmap_fill", "ooobbv");
   private static var nme_gfx_line_bitmap_fill = PrimeLoader.load("nme_gfx_line_bitmap_fill", "ooobbv");
   private static var nme_gfx_begin_set_gradient_fill = nme.PrimeLoader.load("nme_gfx_begin_set_gradient_fill", "oiooooiidbv");
   private static var nme_gfx_end_fill = PrimeLoader.load("nme_gfx_end_fill", "ov");
   private static var nme_gfx_line_style = nme.PrimeLoader.load("nme_gfx_line_style", "ooidbiiidv" );
   private static var nme_gfx_move_to = PrimeLoader.load("nme_gfx_move_to", "oddv");
   private static var nme_gfx_line_to = PrimeLoader.load("nme_gfx_line_to", "oddv");
   private static var nme_gfx_curve_to = PrimeLoader.load("nme_gfx_curve_to", "oddddv");
   private static var nme_gfx_cubic_to = PrimeLoader.load("nme_gfx_cubic_to", "oddddddv");
   private static var nme_gfx_arc_to = PrimeLoader.load("nme_gfx_arc_to", "oddddv");
   private static var nme_gfx_draw_ellipse = PrimeLoader.load("nme_gfx_draw_ellipse", "oddddv");
   private static var nme_gfx_draw_data = PrimeLoader.load("nme_gfx_draw_data", "oov");
   private static var nme_gfx_draw_datum = PrimeLoader.load("nme_gfx_draw_datum", "oov");
   private static var nme_gfx_draw_rect = PrimeLoader.load("nme_gfx_draw_rect", "oddddv");
   private static var nme_gfx_draw_path = PrimeLoader.load("nme_gfx_draw_path", "ooobv");
   private static var nme_gfx_draw_tiles = PrimeLoader.load("nme_gfx_draw_tiles", "oooiiv");
   private static var nme_gfx_draw_points = PrimeLoader.load("nme_gfx_draw_points", "oooibdv");
   private static var nme_gfx_draw_round_rect = nme.PrimeLoader.load("nme_gfx_draw_round_rect", "oddddddv");
   private static var nme_gfx_draw_triangles = nme.PrimeLoader.load("nme_gfx_draw_triangles","ooooioiv");
}

#else
typedef Graphics = flash.display.Graphics;
#end
