package nme.display;
#if (cpp || neko)


import nme.geom.Matrix;
import nme.Loader;


class Graphics
{	
	
	public static inline var TILE_SCALE = 0x0001;
	public static inline var TILE_ROTATION = 0x0002;
	public static inline var TILE_RGB = 0x0004;
	public static inline var TILE_ALPHA = 0x0008;
	
	private static inline var TILE_SMOOTH = 0x1000;

	public static inline var TILE_BLEND_NORMAL   = 0x00000000;
	public static inline var TILE_BLEND_ADD      = 0x00010000;
	//public static inline var TILE_BLEND_SUBTRACT = 0x00020000;
	
	private var nmeHandle:Dynamic;
	
	
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
		
		nme_gfx_begin_gradient_fill(nmeHandle, Type.enumIndex(type), colors, alphas, ratios, matrix, spreadMethod == null ? 0 : Type.enumIndex(spreadMethod), interpolationMethod == null ? 0 : Type.enumIndex(interpolationMethod), focalPointRatio);
	}
	
	
	public function clear()
	{	
		nme_gfx_clear(nmeHandle);	
	}
	
	
	public function curveTo(inCX:Float, inCY:Float, inX:Float, inY:Float)
	{	
		nme_gfx_curve_to(nmeHandle, inCX, inCY, inX, inY);	
	}
	
	
	public function drawCircle(inX:Float, inY:Float, inRadius:Float)
	{
		nme_gfx_draw_ellipse(nmeHandle, inX, inY, inRadius * 2, inRadius * 2);
	}

	
	public function drawEllipse(inX:Float, inY:Float, inWidth:Float, inHeight:Float)
	{	
		nme_gfx_draw_ellipse(nmeHandle, inX, inY, inWidth, inHeight); 
	}
	
	
	public function drawGraphicsData(graphicsData:Array<IGraphicsData>):Void
	{	
		var handles = new Array<Dynamic>();
		
		for (datum in graphicsData)
			handles.push(datum.nmeHandle);
		
		nme_gfx_draw_data(nmeHandle, handles);
	}
	
	
	public function drawGraphicsDatum(graphicsDatum:IGraphicsData):Void
	{
		nme_gfx_draw_datum(nmeHandle, graphicsDatum.nmeHandle);
	}
	
	
	public function drawPoints(inXY:Array<Float>, inPointRGBA:Array<Int> = null, inDefaultRGBA:Int = #if neko 0x7fffffff #else 0xffffffff #end, inSize:Float = -1.0)
	{
		nme_gfx_draw_points(nmeHandle, inXY, inPointRGBA, inDefaultRGBA, #if neko true #else false #end, inSize);
	}
	
	
	public function drawRect(inX:Float, inY:Float, inWidth:Float, inHeight:Float)
	{
		nme_gfx_draw_rect(nmeHandle, inX, inY, inWidth, inHeight);
	}
	
	
	public function drawRoundRect(inX:Float, inY:Float, inWidth:Float, inHeight:Float, inRadX:Float, ?inRadY:Float)
	{
		nme_gfx_draw_round_rect(nmeHandle, inX, inY, inWidth, inHeight, inRadX, inRadY == null ? inRadX : inRadY);
	}
	
	
	/**
	 * @private
	 */
	public function drawTiles(sheet:Tilesheet, inXYID:Array<Float>, inSmooth:Bool = false, inFlags:Int = 0):Void
	{
		beginBitmapFill(sheet.nmeBitmap, null, false, inSmooth);
		
		if (inSmooth)
			inFlags |= TILE_SMOOTH;
		
		nme_gfx_draw_tiles(nmeHandle, sheet.nmeHandle, inXYID, inFlags);
	}
	
	
	public function drawTriangles(vertices:Array<Float>, ?indices:Array<Int>, ?uvtData:Array<Float>, ?culling:TriangleCulling, ?colours:Array<Int>, blendMode:Int = 0, viewport:Array<Float> = null)
	{
		var cull:Int = culling == null ? 0 : Type.enumIndex(culling) - 1;
		nme_gfx_draw_triangles(nmeHandle, vertices, indices, uvtData, cull, colours, blendMode, viewport);
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
		
		nme_gfx_line_gradient_fill(nmeHandle, Type.enumIndex(type), colors, alphas, ratios, matrix, spreadMethod == null ? 0 : Type.enumIndex(spreadMethod), interpolationMethod == null ? 0 : Type.enumIndex(interpolationMethod), focalPointRatio);
	}
	
	
	public function lineStyle(?thickness:Null<Float>, color:Int = 0, alpha:Float = 1.0, pixelHinting:Bool = false, ?scaleMode:LineScaleMode, ?caps:CapsStyle, ?joints:JointStyle, miterLimit:Float = 3):Void
	{	
		nme_gfx_line_style (nmeHandle, thickness, color, alpha, pixelHinting, scaleMode == null ?  0 : Type.enumIndex(scaleMode), caps == null ?  0 : Type.enumIndex(caps), joints == null ?  0 : Type.enumIndex(joints), miterLimit);	
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
		#if neko	
		return inRGB | ((inA & 0xfc) << 22);
		#else
		return inRGB | (inA << 24);
		#end
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_gfx_clear = Loader.load("nme_gfx_clear", 1);
	private static var nme_gfx_begin_fill = Loader.load("nme_gfx_begin_fill", 3);
	private static var nme_gfx_begin_bitmap_fill = Loader.load("nme_gfx_begin_bitmap_fill", 5);
	private static var nme_gfx_line_bitmap_fill = Loader.load("nme_gfx_line_bitmap_fill", 5);
	private static var nme_gfx_begin_gradient_fill = Loader.load("nme_gfx_begin_gradient_fill", -1);
	private static var nme_gfx_line_gradient_fill = Loader.load("nme_gfx_line_gradient_fill", -1);
	private static var nme_gfx_end_fill = Loader.load("nme_gfx_end_fill", 1);
	private static var nme_gfx_line_style = Loader.load("nme_gfx_line_style", -1);
	private static var nme_gfx_move_to = Loader.load("nme_gfx_move_to", 3);
	private static var nme_gfx_line_to = Loader.load("nme_gfx_line_to", 3);
	private static var nme_gfx_curve_to = Loader.load("nme_gfx_curve_to", 5);
	private static var nme_gfx_arc_to = Loader.load("nme_gfx_arc_to", 5);
	private static var nme_gfx_draw_ellipse = Loader.load("nme_gfx_draw_ellipse", 5);
	private static var nme_gfx_draw_data = Loader.load("nme_gfx_draw_data", 2);
	private static var nme_gfx_draw_datum = Loader.load("nme_gfx_draw_datum", 2);
	private static var nme_gfx_draw_rect = Loader.load("nme_gfx_draw_rect", 5);
	private static var nme_gfx_draw_tiles = Loader.load("nme_gfx_draw_tiles", 4);
	private static var nme_gfx_draw_points = Loader.load("nme_gfx_draw_points", -1);
	private static var nme_gfx_draw_round_rect = Loader.load("nme_gfx_draw_round_rect", -1);
	private static var nme_gfx_draw_triangles = Loader.load("nme_gfx_draw_triangles", -1);
	
	
}


#elseif js


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
 

import Html5Dom;
import nme.geom.Matrix;
import nme.geom.Point;
import nme.geom.Rectangle;
import nme.geom.ColorTransform;
import nme.display.LineScaleMode;
import nme.display.CapsStyle;
import nme.display.JointStyle;
import nme.display.GradientType;
import nme.display.SpreadMethod;
import nme.display.InterpolationMethod;
import nme.display.BitmapData;
import nme.display.IGraphicsData;
import nme.display.IGraphicsFill;

typedef DrawList = Array<Drawable>;

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

typedef Drawable =
{
	var points:GfxPoints;
	var fillColour:Int;
	var fillAlpha:Float;
	var solidGradient:Grad;
	var bitmap:Texture;
	var lineJobs:LineJobs;
}

typedef Texture =
{
	var texture_buffer:Dynamic;
	var matrix:Matrix;
	var flags:Int;
}

typedef LineJobs = Array<LineJob>;

enum PointInPathMode
{
	USER_SPACE;
	DEVICE_SPACE;
}

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

	public static var SPREAD_REPEAT  = 0x0002;
	public static var SPREAD_REFLECT = 0x0004;


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

	public static inline var TILE_SCALE    = 0x0001;
	public static inline var TILE_ROTATION = 0x0002;
	public static inline var TILE_RGB      = 0x0004;
	public static inline var TILE_ALPHA    = 0x0008;

	static inline var TILE_SMOOTH         = 0x1000;

	public var jeashSurface(default,null):HTMLCanvasElement;
	public var jeashChanged:Bool;

	// Current set of points
	private var mPoints:GfxPoints;

	// Solids ...
	private var mSolid:Bool;
	private var mFilling:Bool;
	private var mFillColour:Int;
	private var mFillAlpha:Float;
	private var mSolidGradient:Grad;
	public var mBitmap(default,null):Texture;

	// Lines ...
	private var mCurrentLine:LineJob;
	private var mLineJobs:LineJobs;
	private var mNoClip:Bool;

	// List of drawing commands ...
	public var mDrawList(default,null):DrawList;
	private var mLineDraws:DrawList;

	// Current position ...
	private var mPenX:Float;
	private var mPenY:Float;
	private var mLastMoveID:Int;

	public var mMatrix(default,null):Matrix;

	public var owner:DisplayObject;
	private var mBoundsDirty:Bool;
	public var jeashExtent(default,null):Rectangle;
	private var originX:Float;
	private var originY:Float;
	private var nextDrawIndex:Int;
	
	// After this ("warm up") period, the canvas sheet will only expand,
	// and will not contract if the drawing list changes. 
	private var jeashRenderFrame:Int;
	private static inline var JEASH_SIZING_WARM_UP = 10;
	private static inline var JEASH_MAX_DIMENSION = 5000;
	public var jeashExtentBuffer:Float;
	public var jeashIsTile:Bool;

	public function new(?inSurface:HTMLCanvasElement)
	{
		if ( inSurface == null ) {
			jeashSurface = cast js.Lib.document.createElement("canvas");
			jeashSurface.width = 0;
			jeashSurface.height = 0;
		} else {
			jeashSurface = inSurface;
		}

		mMatrix = new Matrix();

		mLastMoveID = 0;
		mPenX = 0.0;
		mPenY = 0.0;
		originX = 0;
		originY = 0;

		mDrawList = new DrawList();

		mPoints = [];

		mSolidGradient = null;
		mBitmap = null;
		mFilling = false;
		mFillColour = 0x000000;
		mFillAlpha = 0.0;
		mLastMoveID = 0;
		mNoClip = false;
		//mSurfaceAlpha = 1.0;

		jeashClearLine();
		mLineJobs = [];
		jeashChanged = true;
		nextDrawIndex = 0;
		jeashRenderFrame = 0;

		jeashExtentBuffer = 0;
		jeashIsTile = false;
		jeashExtent = new Rectangle();
	}

	public function SetSurface(inSurface:Dynamic) {
		jeashSurface = inSurface;
	}

	private function createCanvasColor(color : Int, alpha : Float) {
		var r:Float;
		var g:Float;
		var b:Float;
		r = (0xFF0000 & color) >> 16;
		g = (0x00FF00 & color) >> 8;
		b = (0x0000FF & color);
		return 'rgba' + '(' + r + ',' + g + ',' + b + ',' + alpha + ')';

	}

	private function createCanvasGradient(ctx : CanvasRenderingContext2D, g : Grad) : CanvasGradient {
		var gradient : CanvasGradient;
		//TODO handle spreadMethod flags REPEAT and REFLECT (defaults to PAD behavior)

		var matrix = g.matrix;
		if ((g.flags & RADIAL) == 0) {
			var p1 = matrix.transformPoint(new Point( -819.2, 0));
			var p2 = matrix.transformPoint(new Point(819.2, 0));
			gradient = ctx.createLinearGradient(p1.x, p1.y, p2.x, p2.y);
		} else {
			//TODO not quite right (no ellipses when width != height)
			var p1 = matrix.transformPoint(new Point(g.focal*819.2, 0));
			var p2 = matrix.transformPoint(new Point(0, 819.2));
			gradient = ctx.createRadialGradient(p1.x, p1.y, 0, p2.x, p1.y, p2.y);
		}

		for (point in g.points) {
			var color = createCanvasColor(point.col, point.alpha);
			var pos = point.ratio / 255;
			gradient.addColorStop(pos, color);
		}
		return gradient;
	}

	public function jeashRender(?maskHandle:HTMLCanvasElement, ?matrix:Matrix) {

		if (!jeashChanged) {
			return false;
		}

		ClosePolygon(true);

		if (jeashExtent.width - jeashExtent.x != jeashSurface.width || jeashExtent.height - jeashExtent.y != jeashSurface.height) {
			jeashAdjustSurface();
		}

		var ctx = getContext();
		if (ctx==null) return false;

		var len : Int = mDrawList.length;

		ctx.save();
		
		if (jeashExtent.x != 0 || jeashExtent.y != 0)
			ctx.translate(-jeashExtent.x, -jeashExtent.y);

		for ( i in nextDrawIndex...len ) {
			var d = mDrawList[(len-1)-i];
	
			if (d.lineJobs.length > 0) {
				for (lj in d.lineJobs) {
					ctx.lineWidth = lj.thickness;

					switch(lj.joints)
					{
						case CORNER_ROUND:
							ctx.lineJoin = "round";
						case CORNER_MITER:
							ctx.lineJoin = "miter";
						case CORNER_BEVEL:
							ctx.lineJoin = "bevel";
					}

					switch(lj.caps) {
						case END_ROUND:
							ctx.lineCap = "round";
						case END_SQUARE:
							ctx.lineCap = "square";
						case END_NONE:
							ctx.lineCap = "butt";
					}

					ctx.miterLimit = lj.miter_limit;

					if (lj.grad != null) {
						ctx.strokeStyle = createCanvasGradient(ctx, lj.grad);
					} else {
						ctx.strokeStyle = createCanvasColor(lj.colour, lj.alpha);
					}

					ctx.beginPath();
					for (i in lj.point_idx0...lj.point_idx1 + 1) {
						var p = d.points[i];

						switch (p.type) {
							case MOVE:
								ctx.moveTo(p.x , p.y);
							case CURVE:
								ctx.quadraticCurveTo(p.cx, p.cy, p.x, p.y);
							default:
								ctx.lineTo(p.x, p.y);
						}

					}
					ctx.closePath();
					ctx.stroke();
				}
			} else {
				ctx.beginPath();

				for ( p in d.points ) {

					switch (p.type) {
						case MOVE:
							ctx.moveTo(p.x , p.y);
						case CURVE:
							ctx.quadraticCurveTo(p.cx, p.cy, p.x, p.y);
						default:
							ctx.lineTo(p.x, p.y);
					}
				}
				ctx.closePath();
			}

			var fillColour = d.fillColour;
			var fillAlpha = d.fillAlpha;
			if (  fillAlpha >= 0. && fillAlpha <= 1.) {
				var g = d.solidGradient;
				if (g != null)
					ctx.fillStyle = createCanvasGradient(ctx, g);
				else 
					ctx.fillStyle = createCanvasColor(fillColour, fillAlpha);
			}
			ctx.fill();

			ctx.save();
			var bitmap = d.bitmap;
			if ( bitmap != null) {
				ctx.clip();

				if (jeashExtent.x != 0 || jeashExtent.y != 0)
					ctx.translate(-jeashExtent.x, -jeashExtent.y);

				var img = bitmap.texture_buffer;
				var matrix = bitmap.matrix;

				if(matrix != null) {
					ctx.transform( matrix.a,  matrix.b,  matrix.c,  matrix.d,  matrix.tx,  matrix.ty );
				}

				ctx.drawImage( img, 0, 0 );

			}
			ctx.restore();
		}
		
		ctx.restore();
		

		jeashChanged = false;
		nextDrawIndex = len;


		return true;

	}


	public function jeashHitTest(inX:Float, inY:Float) : Bool
	{
		var ctx : CanvasRenderingContext2D = getContext();
		if (ctx==null) return false;

		ctx.save();
		for(d in mDrawList)
		{
			ctx.beginPath();
			for ( p in d.points ) {
				switch (p.type) {
					case MOVE:
						ctx.moveTo(p.x , p.y);
					case CURVE:
						ctx.quadraticCurveTo(p.cx, p.cy, p.x, p.y);
					default:
						ctx.lineTo(p.x, p.y);
				}
			}
			ctx.closePath();
			if ( ctx.isPointInPath(inX, inY) ) return true;
		}
		ctx.restore();
		return false;
	}


	public function blit(inTexture:BitmapData)
	{
		ClosePolygon(true);

		var ctx = getContext();
		if (ctx != null) 
			ctx.drawImage(inTexture.handle(),mPenX,mPenY);
	}



	public function lineStyle(?thickness:Null<Float>,
			?color:Null<Int>,
			?alpha:Null<Float> ,
			?pixelHinting:Null<Bool> ,
			?scaleMode:Null<LineScaleMode> ,
			?caps:Null<CapsStyle>,
			?joints:Null<JointStyle>,
			?miterLimit:Null<Float> )
	{
		// Finish off old line before starting a new one
		AddLineSegment();

		//with no parameters it clears the current line (to draw nothing)
		if( thickness == null )
		{
			jeashClearLine();
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

		//mCurrentLine.caps = END_ROUND;
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

	function DrawEllipse(x:Float,y:Float,rx:Float,ry:Float)
	{
		moveTo(x+rx, y);
		curveTo(rx+x        ,-0.4142*ry+y,0.7071*rx+x ,-0.7071*ry+y);
		curveTo(0.4142*rx+x ,-ry+y       ,x           ,-ry+y);
		curveTo(-0.4142*rx+x,-ry+y       ,-0.7071*rx+x,-0.7071*ry+y);
		curveTo(-rx+x       ,-0.4142*ry+y,-rx+x       , y);
		curveTo(-rx+x       ,0.4142*ry+y ,-0.7071*rx+x,0.7071*ry+y);
		curveTo(-0.4142*rx+x,ry+y        ,x           ,ry+y);
		curveTo(0.4142*rx+x ,ry+y        ,0.7071*rx+x ,0.7071*ry+y) ;
		curveTo(rx+x        ,0.4142*ry+y ,rx+x        ,y);
	}
	public function drawEllipse(x:Float,y:Float,rx:Float,ry:Float)
	{
		ClosePolygon(false);

		rx /= 2; ry /= 2;
		DrawEllipse(x+rx,y+ry,rx,ry);

		ClosePolygon(false);
	}

	public function drawCircle(x:Float,y:Float,rad:Float)
	{
		ClosePolygon(false);

		DrawEllipse(x,y,rad,rad);

		ClosePolygon(false);
	}

	public function drawRect(x:Float,y:Float,width:Float,height:Float) {
		ClosePolygon(false);

		moveTo(x,y);
		lineTo(x+width,y);
		lineTo(x+width,y+height);
		lineTo(x,y+height);
		lineTo(x,y);

		ClosePolygon(false);
	}

	public function drawRoundRect(x:Float, y:Float, width:Float, height:Float, rx:Float, ry:Float) {
		rx *= 0.5;
		ry *= 0.5;
		var w = width*0.5;
		x+=w;
		if (rx>w) rx = w;
		var lw = w - rx;
		var w_ = lw + rx*Math.sin(Math.PI/4);
		var cw_ = lw + rx*Math.tan(Math.PI/8);
		var h = height*0.5;
		y+=h;
		if (ry>h) ry = h;
		var lh = h - ry;
		var h_ = lh + ry*Math.sin(Math.PI/4);
		var ch_ = lh + ry*Math.tan(Math.PI/8);

		ClosePolygon(false);

		moveTo(x+w,y+lh);
		curveTo(x+w,  y+ch_, x+w_, y+h_);
		curveTo(x+cw_,y+h,   x+lw,    y+h);
		lineTo(x-lw,    y+h);
		curveTo(x-cw_,y+h,   x-w_, y+h_);
		curveTo(x-w,  y+ch_, x-w,  y+lh);
		lineTo( x-w, y-lh);
		curveTo(x-w,  y-ch_, x-w_, y-h_);
		curveTo(x-cw_,y-h,   x-lw,    y-h);
		lineTo(x+lw,    y-h);
		curveTo(x+cw_,y-h,   x+w_, y-h_);
		curveTo(x+w,  y-ch_, x+w,  y-lh);
		lineTo(x+w,  y+lh);

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
			flags |= SPREAD_REPEAT;
		else if (spreadMethod==SpreadMethod.REFLECT)
			flags |= SPREAD_REFLECT;


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

		jeashExpandStandardExtent(bitmap.width, bitmap.height);

		mBitmap  = { texture_buffer: bitmap.handle(),
			matrix: matrix==null ? matrix : matrix.clone(),
			flags : (repeat ? BMP_REPEAT : 0) |
				(smooth ? BMP_SMOOTH : 0) };

	}


	public function jeashClearLine()
	{
		mCurrentLine = new LineJob( null,-1,-1,  0.0,
				0.0, 0x000, 1, CORNER_ROUND, END_ROUND,
				SCALE_NORMAL, 3.0);
	}

	inline public function jeashClearCanvas()
	{
		if (jeashSurface != null) {
			var w = jeashSurface.width;
			jeashSurface.width = w;
		}
	}

	public function clear()
	{
		jeashClearLine();

		mPenX = 0.0;
		mPenY = 0.0;

		mDrawList = new DrawList();
		nextDrawIndex = 0;

		mPoints = [];

		mSolidGradient = null;
		//mBitmap = null;
		mFilling = false;
		mFillColour = 0x000000;
		mFillAlpha = 0.0;
		mLastMoveID = 0;

		// clear the canvas
		jeashClearCanvas();


		mLineJobs = [];
		
		markBoundsDirty();
	}

	function jeashExpandStandardExtent(x:Float, y:Float) {
		var maxX, minX, maxY, minY;
		minX = jeashExtent.x;
		minY = jeashExtent.y;
		maxX = jeashExtent.width+minX;
		maxY = jeashExtent.height+minY;
		maxX=x>maxX?x:maxX;
		minX=x<minX?x:minX;
		maxY=y>maxY?y:maxY;
		minY=y<minY?y:minY;
		jeashExtent.x = minX;
		jeashExtent.y = minY;
		jeashExtent.width = maxX-minX;
		jeashExtent.height = maxY-minY;
	}

	public function moveTo(inX:Float,inY:Float) {
		mPenX = inX;
		mPenY = inY;

		jeashExpandStandardExtent(inX, inY);

		if (!mFilling) {
			ClosePolygon(false);
		} else {
			AddLineSegment();
			mLastMoveID = mPoints.length;
			mPoints.push( new GfxPoint( mPenX, mPenY, 0.0, 0.0, MOVE ) );
		}
	}

	public function lineTo(inX:Float,inY:Float) {
		var pid = mPoints.length;
		if (pid==0) {
			mPoints.push( new GfxPoint( mPenX, mPenY, 0.0, 0.0, MOVE ) );
			pid++;
		}

		mPenX = inX;
		mPenY = inY;
		jeashExpandStandardExtent(inX, inY);
		mPoints.push( new GfxPoint( mPenX, mPenY, 0.0, 0.0, LINE ) );

		if (mCurrentLine.grad!=null || mCurrentLine.alpha>0)
		{
			if (mCurrentLine.point_idx0<0)
				mCurrentLine.point_idx0 = pid-1;
			mCurrentLine.point_idx1 = pid;
		}

		if ( !mFilling ) ClosePolygon(false);

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
		jeashExpandStandardExtent(inX, inY);
		mPoints.push( new GfxPoint( inX, inY, inCX, inCY, CURVE ) );

		if (mCurrentLine.grad!=null || mCurrentLine.alpha>0)
		{
			if (mCurrentLine.point_idx0<0)
				mCurrentLine.point_idx0 = pid-1;
			mCurrentLine.point_idx1 = pid;
		}

	}


	public function flush() { ClosePolygon(true); }

	private function AddDrawable(inDrawable:Drawable)
	{
		if (inDrawable==null)
			return; // throw ?

		mDrawList.unshift( inDrawable );

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

				var drawable : Drawable = { 
					points: mPoints, 
					fillColour: mFillColour, 
					fillAlpha: mFillAlpha,
					solidGradient: mSolidGradient, 
					bitmap: mBitmap,
					lineJobs: mLineJobs 
				};

				AddDrawable( drawable );

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

		jeashChanged = true;
		//standardExtent=null;
		markBoundsDirty();
	}

	public function drawGraphicsData(points:Vector<IGraphicsData>) {
		for (data in points) {
			if (data == null) {
				mFilling=true;
			} else {
				switch (data.jeashGraphicsDataType) {
					case STROKE:
						var stroke : GraphicsStroke = cast data;
						if (stroke.fill == null) {
							lineStyle(stroke.thickness, 0x000000, 1., stroke.pixelHinting, stroke.scaleMode, stroke.caps, stroke.joints, stroke.miterLimit);
						} else {
							switch(stroke.fill.jeashGraphicsFillType) {
								case SOLID_FILL:
						
									var fill : GraphicsSolidFill = cast stroke.fill;
									lineStyle(stroke.thickness, fill.color, fill.alpha, stroke.pixelHinting, stroke.scaleMode, stroke.caps, stroke.joints, stroke.miterLimit);
								case GRADIENT_FILL:

									var fill : GraphicsGradientFill = cast stroke.fill;
									lineGradientStyle(fill.type, fill.colors, fill.alphas, fill.ratios, fill.matrix, fill.spreadMethod, fill.interpolationMethod, fill.focalPointRatio);
							}
						}
					case PATH:
						var path : GraphicsPath = cast data;
						var j = 0;
						for (i in 0...path.commands.length) {
							var command = path.commands[i];
							switch (command) {
								case GraphicsPathCommand.MOVE_TO: 
									moveTo(path.data[j], path.data[j+1]);
									j = j + 2;
								case GraphicsPathCommand.LINE_TO:
									lineTo(path.data[j], path.data[j+1]);
									j = j + 2;
								case GraphicsPathCommand.CURVE_TO:
									curveTo(path.data[j], path.data[j+1], path.data[j+2], path.data[j+3]);
									j = j + 4;

							}
						}
					case SOLID:
						var fill : GraphicsSolidFill = cast data;
						beginFill(fill.color, fill.alpha);
					case GRADIENT:
						var fill : GraphicsGradientFill = cast data;
						beginGradientFill(fill.type, fill.colors, fill.alphas, fill.ratios, fill.matrix, fill.spreadMethod, fill.interpolationMethod, fill.focalPointRatio);
				}
			}
		}
	}

	public static function jeashDetectIsPointInPathMode()
	{
		var canvas : HTMLCanvasElement = cast js.Lib.document.createElement("canvas");
		var ctx = canvas.getContext('2d');
		if (ctx.isPointInPath == null)
			return USER_SPACE;
		ctx.save();
		ctx.translate(1,0);
		ctx.beginPath();
		ctx.rect(0,0,1,1);
		var rv = if (ctx.isPointInPath(0.3,0.3)) {
			USER_SPACE;
		} else {
			DEVICE_SPACE;
		}
		ctx.restore();
		return rv;
	}

	public function drawTiles(sheet:Tilesheet, xyid:Array<Float>, smooth:Bool=false /* NOTE: ignored */, flags:Int = 0) {

		jeashIsTile = true;
		Lib.jeashDrawSurfaceRect(sheet.jeashSurface, jeashSurface, xyid[0], xyid[1], sheet.jeashTileRects[cast xyid[2]]);

		if (flags != 0) {
			if ((flags & TILE_SCALE) == TILE_SCALE) Lib.jeashSetSurfaceScale(jeashSurface, xyid[3]);
			if ((flags & TILE_ROTATION) == TILE_ROTATION) Lib.jeashSetSurfaceRotation(jeashSurface, xyid[4]);

			// TODO: TILE_RGB unsupported, is this just a simple overlay or a more complex shader ? ...

			if ((flags & TILE_ALPHA) == TILE_ALPHA) Lib.jeashSetSurfaceOpacity(jeashSurface, xyid[8]);
		}
	}

	public inline function markBoundsClean(){
		mBoundsDirty=false;
	}

	inline function markBoundsDirty() {
		if(!mBoundsDirty){
			mBoundsDirty=true;
			if(owner!=null)
				owner.jeashInvalidateBounds();
		}
	}

	inline function getContext() : CanvasRenderingContext2D
	{
	       	try {
			return jeashSurface.getContext("2d");
		} catch (e:Dynamic) {
			flash.Lib.trace("2d canvas API not implemented for: " + jeashSurface);
			return null;
		}
	}

	function jeashAdjustSurface() {
		var width = Math.ceil(jeashExtent.width - jeashExtent.x);
		var height = Math.ceil(jeashExtent.height - jeashExtent.y);

		// prevent allocating too large canvas sizes
		if (width > JEASH_MAX_DIMENSION || height > JEASH_MAX_DIMENSION) return;

		// re-allocate canvas, copy into larger canvas.
		var dstCanvas : HTMLCanvasElement = cast js.Lib.document.createElement("canvas");
		var ctx = dstCanvas.getContext("2d");

		dstCanvas.width = width;
		dstCanvas.height = height;

		Lib.jeashDrawToSurface(jeashSurface, dstCanvas);
		if (Lib.jeashIsOnStage(jeashSurface)) {
			Lib.jeashAppendSurface(dstCanvas);
			Lib.jeashCopyStyle(jeashSurface, dstCanvas);
			Lib.jeashSwapSurface(jeashSurface,dstCanvas);
			Lib.jeashRemoveSurface(jeashSurface);
		}

		jeashSurface = dstCanvas;
	}
}


#else
typedef Graphics = flash.display.Graphics;
#end
