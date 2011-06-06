package nme.display;

import nme.geom.Matrix;

class Graphics
{
   var nmeHandle:Dynamic;

   public function new(inHandle:Dynamic)
   {
      nmeHandle = inHandle;
   }

   public function beginFill(color:Int, alpha:Float = 1.0)
   {
      nme_gfx_begin_fill(nmeHandle,color,alpha);
   }

   public function beginBitmapFill(bitmap:BitmapData, ?matrix:Matrix,
               repeat:Bool = true, smooth:Bool = false)
   {
      nme_gfx_begin_bitmap_fill(nmeHandle,bitmap.nmeHandle,matrix,repeat,smooth);
   }

   public function lineBitmapStyle(bitmap:BitmapData, ?matrix:Matrix,
               repeat:Bool = true, smooth:Bool = false)
   {
      nme_gfx_line_bitmap_fill(nmeHandle,bitmap.nmeHandle,matrix,repeat,smooth);
   }



   public function beginGradientFill(type : GradientType,
                 colors : Array<Dynamic>,
                 alphas : Array<Dynamic>,
                 ratios : Array<Dynamic>,
                 ?matrix : Matrix,
                 ?spreadMethod : Null<SpreadMethod>,
                 ?interpolationMethod : Null<InterpolationMethod>,
                 focalPointRatio:Float = 0.0 ) : Void
   {
	   if (matrix==null)
		{
		   matrix = new Matrix();
			matrix.createGradientBox(200,200,0,-100,-100);
		}
      nme_gfx_begin_gradient_fill(nmeHandle,Type.enumIndex(type),
                        colors,alphas,ratios, matrix,
                        spreadMethod ==null ? 0 : Type.enumIndex(spreadMethod),
                        interpolationMethod ==null ? 0 : Type.enumIndex(interpolationMethod),
                        focalPointRatio);
   }

   public function lineGradientStyle(type : GradientType,
                 colors : Array<Dynamic>,
                 alphas : Array<Dynamic>,
                 ratios : Array<Dynamic>,
                 ?matrix : Matrix,
                 ?spreadMethod : Null<SpreadMethod>,
                 ?interpolationMethod : Null<InterpolationMethod>,
                 focalPointRatio:Float = 0.0 ) : Void
   {
	   if (matrix==null)
		{
		   matrix = new Matrix();
			matrix.createGradientBox(200,200,0,-100,-100);
		}
      nme_gfx_line_gradient_fill(nmeHandle,Type.enumIndex(type),
                        colors,alphas,ratios, matrix,
                        spreadMethod ==null ? 0 : Type.enumIndex(spreadMethod),
                        interpolationMethod ==null ? 0 : Type.enumIndex(interpolationMethod),
                        focalPointRatio);
   }


   public function endFill()
   {
      nme_gfx_end_fill(nmeHandle);
   }

   public function clear()
   {
      nme_gfx_clear(nmeHandle);
   }

   public function lineStyle(?thickness:Null<Float>, color:Int = 0, alpha:Float = 1.0,
                      pixelHinting:Bool = false, ?scaleMode:LineScaleMode, ?caps:CapsStyle,
                      ?joints:JointStyle, miterLimit:Float = 3) : Void
   {
      nme_gfx_line_style(nmeHandle, thickness, color, alpha, pixelHinting,
         scaleMode==null ?  0 : Type.enumIndex(scaleMode),
         caps==null ?  0 : Type.enumIndex(caps),
         joints==null ?  0 : Type.enumIndex(joints),
         miterLimit );
   }




   public function moveTo(inX:Float, inY:Float)
   {
      nme_gfx_move_to(nmeHandle,inX,inY);
   }

   public function lineTo(inX:Float, inY:Float)
   {
      nme_gfx_line_to(nmeHandle,inX,inY);
   }

   public function curveTo(inCX:Float, inCY:Float, inX:Float, inY:Float)
   {
      nme_gfx_curve_to(nmeHandle,inCX,inCY,inX,inY);
   }

   public function arcTo(inCX:Float, inCY:Float, inX:Float, inY:Float)
   {
      nme_gfx_arc_to(nmeHandle,inCX,inCY,inX,inY);
   }

   public function drawEllipse(inX:Float, inY:Float, inWidth:Float, inHeight:Float)
   {
      nme_gfx_draw_ellipse(nmeHandle,inX,inY,inWidth,inHeight);
   }

   public function drawCircle(inX:Float, inY:Float, inRadius:Float)
   {
      nme_gfx_draw_ellipse(nmeHandle,inX,inY,inRadius,inRadius);
   }

   public function drawRect(inX:Float, inY:Float, inWidth:Float, inHeight:Float)
   {
      nme_gfx_draw_rect(nmeHandle,inX,inY,inWidth,inHeight);
   }

   public function drawRoundRect(inX:Float, inY:Float, inWidth:Float, inHeight:Float,
                                 inRadX:Float, ?inRadY:Float)
   {
      nme_gfx_draw_round_rect(nmeHandle,
            inX,inY,inWidth,inHeight,inRadX,inRadY==null?inRadX:inRadY);
   }

   public function drawTriangles(vertices:Array<Float>,
          ?indices:Array<Int>,
          ?uvtData:Array<Float>,
          ?culling:nme.display.TriangleCulling)
   {
      var cull:Int = culling==null ? 0 : Type.enumIndex(culling)-1;

      nme_gfx_draw_triangles(nmeHandle,vertices,indices,uvtData,cull );
   }


   public function drawGraphicsData(graphicsData:Array<IGraphicsData>):Void
   {
      var handles = new Array<Dynamic>();
      for(datum in graphicsData)
         handles.push(datum.nmeHandle);
      nme_gfx_draw_data(nmeHandle,handles);
   }

   public function drawGraphicsDatum(graphicsDatum:IGraphicsData):Void
   {
      nme_gfx_draw_datum(nmeHandle,graphicsDatum.nmeHandle);
   }

   public function drawTiles(sheet:Tilesheet, inXYID:Array<Float>,inSmooth:Bool=false):Void
   {
      beginBitmapFill(sheet.nmeBitmap,null,false,inSmooth);
      nme_gfx_draw_tiles(nmeHandle,sheet.nmeHandle,inXYID);
   }

   inline static public function RGBA(inRGB:Int,inA:Int=0xff) : Int
	{
		#if neko
		return inRGB | ((inA & 0xfc)<<22);
		#else
		return inRGB | (inA <<24);
		#end
	}
   public function drawPoints(inXY:Array<Float>, inPointRGBA:Array<Int>=null,
         inDefaultRGBA:Int = #if neko 0x7fffffff #else 0xffffffff #end, inSize:Float = -1.0 )
   {
      nme_gfx_draw_points(nmeHandle,inXY,inPointRGBA,inDefaultRGBA,#if neko true #else false #end,inSize);
   }

   static var nme_gfx_clear = nme.Loader.load("nme_gfx_clear",1);
   static var nme_gfx_begin_fill = nme.Loader.load("nme_gfx_begin_fill",3);
   static var nme_gfx_begin_bitmap_fill = nme.Loader.load("nme_gfx_begin_bitmap_fill",5);
   static var nme_gfx_line_bitmap_fill = nme.Loader.load("nme_gfx_line_bitmap_fill",5);
   static var nme_gfx_begin_gradient_fill = nme.Loader.load("nme_gfx_begin_gradient_fill",-1);
   static var nme_gfx_line_gradient_fill = nme.Loader.load("nme_gfx_line_gradient_fill",-1);
   static var nme_gfx_end_fill = nme.Loader.load("nme_gfx_end_fill",1);
   static var nme_gfx_line_style = nme.Loader.load("nme_gfx_line_style",-1);

   static var nme_gfx_move_to = nme.Loader.load("nme_gfx_move_to",3);
   static var nme_gfx_line_to = nme.Loader.load("nme_gfx_line_to",3);
   static var nme_gfx_curve_to = nme.Loader.load("nme_gfx_curve_to",5);
   static var nme_gfx_arc_to = nme.Loader.load("nme_gfx_arc_to",5);
   static var nme_gfx_draw_ellipse = nme.Loader.load("nme_gfx_draw_ellipse",5);
   static var nme_gfx_draw_data = nme.Loader.load("nme_gfx_draw_data",2);
   static var nme_gfx_draw_datum = nme.Loader.load("nme_gfx_draw_datum",2);
   static var nme_gfx_draw_rect = nme.Loader.load("nme_gfx_draw_rect",5);
   static var nme_gfx_draw_tiles = nme.Loader.load("nme_gfx_draw_tiles",3);
   static var nme_gfx_draw_points = nme.Loader.load("nme_gfx_draw_points",-1);
   static var nme_gfx_draw_round_rect = nme.Loader.load("nme_gfx_draw_round_rect",-1);
   static var nme_gfx_draw_triangles = nme.Loader.load("nme_gfx_draw_triangles",5);
}
