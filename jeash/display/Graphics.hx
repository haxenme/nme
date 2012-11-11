/**
 * Copyright (c) 2010, Jeash contributors.
 * 
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

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


package jeash.display;

import jeash.Html5Dom;
import jeash.geom.Matrix;
import jeash.geom.Point;
import jeash.geom.Rectangle;
import jeash.display.LineScaleMode;
import jeash.display.CapsStyle;
import jeash.display.JointStyle;
import jeash.display.GradientType;
import jeash.display.SpreadMethod;
import jeash.display.InterpolationMethod;
import jeash.display.BitmapData;
import jeash.display.IGraphicsData;
import jeash.display.IGraphicsFill;

typedef DrawList = Array<Drawable>;

class GfxPoint {
	public function new(inX:Float,inY:Float,inCX:Float,inCY:Float,inType:Int)
	{ x=inX; y=inY; cx=inCX; cy=inCY; type=inType; }

	public var x:Float;
	public var y:Float;
	public var cx:Float;
	public var cy:Float;
	public var type:Int;
}

typedef GfxPoints = Array<GfxPoint>;

class GradPoint {
	public function new (inCol: Int, inAlpha: Float, inRatio: Int)
	{ col=inCol; alpha=inAlpha; ratio=inRatio; }
	public var col:Int;
	public var alpha:Float;
	public var ratio:Int;
}

typedef GradPoints = Array<GradPoint>;

class Grad {
	public function new (inPoints: GradPoints, inMatrix: Matrix, inFlags: Int, inFocal: Float) { points=inPoints; matrix=inMatrix; flags=inFlags; focal=inFocal; }
	public var points:GradPoints;
	public var matrix:Matrix;
	public var flags:Int;
	public var focal:Float;
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

class TileJob
{
	public function new (sheet:Tilesheet, drawList:Array <Float>, flags:Int)
	{
		this.sheet = sheet;
		this.drawList = drawList;
		this.flags = flags;
	}
	
	public var sheet:Tilesheet;
	public var drawList:Array <Float>;
	public var flags:Int;
}

class Drawable {
	public function new (inPoints: GfxPoints, inFillColour: Int, inFillAlpha: Float, inSolidGradient: Grad, inBitmap: Texture, inLineJobs: LineJobs, inTileJob:TileJob) { 
		points = inPoints; fillColour = inFillColour; fillAlpha = inFillAlpha; solidGradient = inSolidGradient; bitmap = inBitmap; lineJobs = inLineJobs; tileJob = inTileJob;
	}
	public var points:GfxPoints;
	public var fillColour:Int;
	public var fillAlpha:Float;
	public var solidGradient:Grad;
	public var bitmap:Texture;
	public var lineJobs:LineJobs;
	public var tileJob:TileJob;
}

typedef Texture = {
	var texture_buffer:Dynamic;
	var matrix:Matrix;
	var flags:Int;
}

typedef LineJobs = Array<LineJob>;

enum PointInPathMode {
	USER_SPACE;
	DEVICE_SPACE;
}

class Graphics
{
	private static inline var JEASH_MAX_DIM 	= 5000;

	private static inline var RADIAL  			= 0x0001;

	private static inline var SPREAD_REPEAT  	= 0x0002;
	private static inline var SPREAD_REFLECT 	= 0x0004;

	private static inline var END_NONE         	= 0x0000;
	private static inline var END_ROUND        	= 0x0100;
	private static inline var END_SQUARE       	= 0x0200;

	private static inline var CORNER_ROUND     	= 0x0000;
	private static inline var CORNER_MITER     	= 0x1000;
	private static inline var CORNER_BEVEL     	= 0x2000;

	private static inline var ROUND:String     	= "round";
	private static inline var MITER:String     	= "miter";
	private static inline var BEVEL:String     	= "bevel";
	private static inline var SQUARE:String     = "square";
	private static inline var BUTT:String     	= "butt";

	private static inline var PIXEL_HINTING    	= 0x4000;

	private static inline var BMP_REPEAT  		= 0x0010;
	private static inline var BMP_SMOOTH  		= 0x10000;

	private static inline var SCALE_NONE       	= 0;
	private static inline var SCALE_VERTICAL   	= 1;
	private static inline var SCALE_HORIZONTAL 	= 2;
	private static inline var SCALE_NORMAL     	= 3;

	private static inline var MOVE 				= 0;
	private static inline var LINE 				= 1;
	private static inline var CURVE 			= 2;

	public static inline var TILE_SCALE = 0x0001;
	public static inline var TILE_ROTATION = 0x0002;
	public static inline var TILE_RGB = 0x0004;
	public static inline var TILE_ALPHA = 0x0008;
	public static inline var TILE_TRANS_2x2 = 0x0010;
	
	public static inline var TILE_BLEND_NORMAL   = 0x00000000;
	public static inline var TILE_BLEND_ADD      = 0x00010000;
	
	public var jeashSurface(default, null):HTMLCanvasElement;
	private var jeashChanged:Bool;

	// Current set of points
	private var mPoints:GfxPoints;

	// Solids ...
	private var mFilling:Bool;
	private var mFillColour:Int;
	private var mFillAlpha:Float;
	private var mSolidGradient:Grad;
	private var mBitmap(default, null):Texture;

	// Lines ...
	private var mCurrentLine:LineJob;
	private var mLineJobs:LineJobs;

	// List of drawing commands ...
	private var mDrawList(default, null):DrawList;
	private var mLineDraws:DrawList;

	// Current position ...
	private var mPenX:Float;
	private var mPenY:Float;
	private var mLastMoveID:Int;

	public var boundsDirty:Bool;
	public var jeashExtent(default, null):Rectangle;
	public var jeashExtentWithFilters(default, null):Rectangle;
	private var _padding:Float;
	private var nextDrawIndex:Int;
	private var jeashClearNextCycle:Bool;

	public function new(?inSurface:HTMLElement) {
		// sanity check
		Lib.jeashBootstrap();

		if (inSurface == null) {
			jeashSurface = cast js.Lib.document.createElement("canvas");
			jeashSurface.width = 0;
			jeashSurface.height = 0;
		} else {
			jeashSurface = cast inSurface;
		}

		mLastMoveID = 0;
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
		boundsDirty = true;

		jeashClearLine();
		mLineJobs = [];
		jeashChanged = true;
		nextDrawIndex = 0;

		jeashExtent = new Rectangle();
		jeashExtentWithFilters = new Rectangle();
		_padding = 0.0;
		jeashClearNextCycle = true;
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
			var p1 = matrix.transformPoint(new Point(-819.2, 0));
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

	public function jeashRender(?maskHandle:HTMLCanvasElement, ?filters:Array<jeash.filters.BitmapFilter>, 
			sx:Float=1.0, sy:Float=1.0, ?clip0:Point, ?clip1:Point, ?clip2:Point, ?clip3:Point) {
		if (!jeashChanged) return false;

		closePolygon(true);
		var padding = _padding;

		if (filters != null) {
			for (filter in filters) {
				if (Reflect.hasField(filter, "blurX")) {
					padding += (Math.max(Reflect.field(filter, "blurX"), Reflect.field(filter, "blurY")) * 4);
				}
			}
		}

		jeashExpandFilteredExtent(-(padding*sx)/2, -(padding*sy)/2);

		if (jeashClearNextCycle) {
			nextDrawIndex = 0;
			jeashClearCanvas();
			jeashClearNextCycle = false;
		} 

		if (jeashExtentWithFilters.width - jeashExtentWithFilters.x > jeashSurface.width 
				|| jeashExtentWithFilters.height - jeashExtentWithFilters.y > jeashSurface.height) {
			jeashAdjustSurface(sx, sy);
		}

		var ctx = getContext();
		if (ctx == null) return false;

		if (clip0 != null) {
			ctx.beginPath();
			ctx.moveTo(clip0.x*sx, clip0.y*sy);
			ctx.lineTo(clip1.x*sx, clip1.y*sy);
			ctx.lineTo(clip2.x*sx, clip2.y*sy);
			ctx.lineTo(clip3.x*sx, clip3.y*sy);
			ctx.closePath();
			ctx.clip();
		}

		if (filters != null) {
			for (filter in filters) {
				if (Std.is(filter, jeash.filters.DropShadowFilter)) {
					// shadow must be applied before we draw to the context
					filter.jeashApplyFilter(jeashSurface, true);
				}
			}
		}

		var len:Int = mDrawList.length;

		ctx.save();
		
		if (jeashExtentWithFilters.x != 0 || jeashExtentWithFilters.y != 0)
			ctx.translate(-jeashExtentWithFilters.x*sx, -jeashExtentWithFilters.y*sy);
		if (sx != 1 || sy != 0)
			ctx.scale(sx, sy);

		var doStroke = false;
		for (i in nextDrawIndex...len) {
			var d = mDrawList[(len-1)-i];
			
			if (d.tileJob != null) {
				
				jeashDrawTiles (d.tileJob.sheet, d.tileJob.drawList, d.tileJob.flags);
				
			} else {
			
				if (d.lineJobs.length > 0) {
					for (lj in d.lineJobs) {
						ctx.lineWidth = lj.thickness;

						switch(lj.joints) {
							case CORNER_ROUND:
								ctx.lineJoin = ROUND;
							case CORNER_MITER:
								ctx.lineJoin = MITER;
							case CORNER_BEVEL:
								ctx.lineJoin = BEVEL;
						}

						switch(lj.caps) {
							case END_ROUND:
								ctx.lineCap = ROUND;
							case END_SQUARE:
								ctx.lineCap = SQUARE;
							case END_NONE:
								ctx.lineCap = BUTT;
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
									ctx.moveTo(p.x, p.y);
								case CURVE:
									ctx.quadraticCurveTo(p.cx, p.cy, p.x, p.y);
								default:
									ctx.lineTo(p.x, p.y);
							}
						}
						ctx.closePath();
						doStroke = true;
					}
				} else {
					ctx.beginPath();

					for (p in d.points) {
						switch (p.type) {
							case MOVE:
								ctx.moveTo(p.x, p.y);
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
				var g = d.solidGradient;
				if (g != null)
					ctx.fillStyle = createCanvasGradient(ctx, g);
				else  // Alpha value gets clamped in [0;1] range.
					ctx.fillStyle = createCanvasColor(fillColour, Math.min(1.0, Math.max(0.0, fillAlpha)));
				ctx.fill();
				if (doStroke) ctx.stroke();
				ctx.save();

				var bitmap = d.bitmap;
				if (bitmap != null) {
					//ctx.clip();

					var img = bitmap.texture_buffer;
					var m = bitmap.matrix;
					if (m != null) {
						ctx.transform(m.a, m.b, m.c, m.d, m.tx, m.ty);
					}
					ctx.drawImage(img, 0, 0);
				}
				ctx.restore();
				
			}
		}
		ctx.restore();

		jeashChanged = false;
		nextDrawIndex = len;
		mDrawList = [];

		return true;
	}

	public function jeashHitTest(inX:Float, inY:Float) : Bool {
		var ctx : CanvasRenderingContext2D = getContext();
		if (ctx == null) return false;

		if (ctx.isPointInPath(inX, inY)) return true;
		else if (mDrawList.length == 0 && jeashExtent.width > 0 && jeashExtent.height > 0) return true;
		return false;
	}

	public function blit(inTexture:BitmapData) {
		closePolygon(true);

		var ctx = getContext();
		if (ctx != null) 
			ctx.drawImage(inTexture.handle(), mPenX, mPenY);
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
		addLineSegment();

		//with no parameters it clears the current line (to draw nothing)
		if(thickness == null) {
			jeashClearLine();
			return;
		} else {
			mCurrentLine.grad = null;
			mCurrentLine.thickness = thickness;
			mCurrentLine.colour = color==null ? 0 : color;
			mCurrentLine.alpha = alpha==null ? 1.0 : alpha;
			mCurrentLine.miter_limit = miterLimit==null ? 3.0 : miterLimit;
			mCurrentLine.pixel_hinting = (pixelHinting==null || !pixelHinting) ? 0 : PIXEL_HINTING;
		}

		//mCurrentLine.caps = END_ROUND;
		if (caps != null) {
			switch(caps) {
				case CapsStyle.ROUND:
					mCurrentLine.caps = END_ROUND;
				case CapsStyle.SQUARE:
					mCurrentLine.caps = END_SQUARE;
				case CapsStyle.NONE:
					mCurrentLine.caps = END_NONE;
			}
		}

		mCurrentLine.scale_mode = SCALE_NORMAL;
		if (scaleMode != null) {
			switch(scaleMode) {
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
		if (joints != null) {
			switch(joints) {
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
		mCurrentLine.grad = createGradient(type, colors, alphas, ratios,
				matrix,spreadMethod,
				interpolationMethod,
				focalPointRatio);
	}



	public function beginFill(color:Int, ?alpha:Null<Float>) {
		closePolygon(true);

		mFillColour =  color;
		mFillAlpha = alpha==null ? 1.0 : alpha;
		mFilling = true;
		mSolidGradient = null;
		mBitmap = null;
	}

	public function endFill() {
		closePolygon(true);
	}

	function jeashDrawEllipse(x:Float, y:Float, rx:Float, ry:Float) {
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

	public function drawEllipse(x:Float, y:Float, rx:Float, ry:Float) {
		closePolygon(false);

		rx /= 2; ry /= 2;
		jeashDrawEllipse(x + rx, y + ry, rx, ry);

		closePolygon(false);
	}

	public function drawCircle(x:Float, y:Float, rad:Float) {
		closePolygon(false);

		jeashDrawEllipse(x, y, rad, rad);

		closePolygon(false);
	}

	public function drawRect(x:Float, y:Float, width:Float, height:Float) {
		closePolygon(false);
		
		moveTo(x,y);
		lineTo(x + width, y);
		lineTo(x + width, y + height);
		lineTo(x, y + height);
		lineTo(x, y);

		closePolygon(false);
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

		closePolygon(false);

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

		closePolygon(false);
	}
	
	/**
	 * @private
	 */
	public function drawTiles(sheet:Tilesheet, tileData:Array<Float>, smooth:Bool = false, flags:Int = 0):Void
	{
		var useScale = (flags & TILE_SCALE) > 0;
		var useRotation = (flags & TILE_ROTATION) > 0;
		var useTransform = (flags & TILE_TRANS_2x2) > 0;
		var useRGB = (flags & TILE_RGB) > 0;
		var useAlpha = (flags & TILE_ALPHA) > 0;
		
		if (useTransform) { useScale = false; useRotation = false; }
		
		var index = 0;
		var numValues = 3;
		
		if (useScale) numValues ++;
		if (useRotation) numValues ++;
		if (useTransform) numValues += 4;
		if (useRGB) numValues += 3;
		if (useAlpha) numValues ++;
		
		while (index < tileData.length) {
			
			jeashExpandStandardExtent (tileData[index] + sheet.jeashBitmap.width, tileData[index + 1] + sheet.jeashBitmap.height);
			index += numValues;
			
		}
		
		addDrawable (new Drawable (null, null, null, null, null, null, new TileJob (sheet, tileData, flags)));
		jeashChanged = true;
	}
	
	private function jeashDrawTiles(sheet:Tilesheet, tileData:Array<Float>, flags:Int = 0):Void {
		
		var useScale = (flags & TILE_SCALE) > 0;
		var useRotation = (flags & TILE_ROTATION) > 0;
		var useTransform = (flags & TILE_TRANS_2x2) > 0;
		var useRGB = (flags & TILE_RGB) > 0;
		var useAlpha = (flags & TILE_ALPHA) > 0;
		
		if (useTransform) { useScale = false; useRotation = false; }
		
		var scaleIndex = 0;
		var rotationIndex = 0;
		var rgbIndex = 0;
		var alphaIndex = 0;
		var transformIndex = 0;
		
		var numValues = 3;
		
		if (useScale) { scaleIndex = numValues; numValues ++; }
		if (useRotation) { rotationIndex = numValues; numValues ++; }
		if (useTransform) { transformIndex = numValues; numValues += 4; }
		if (useRGB) { rgbIndex = numValues; numValues += 3; }
		if (useAlpha) { alphaIndex = numValues; numValues ++; }
		
		var totalCount = tileData.length;
		var itemCount = Std.int (totalCount / numValues);
		var index = 0;
		
		var rect = null;
		var center = null;
		var previousTileID = -1;
		
		var surface = sheet.jeashBitmap.handle ();
		var ctx = getContext ();
		
		if (ctx != null) {
			
			while (index < totalCount)
			{
				var tileID = Std.int(tileData[index + 2]);
				
				if (tileID != previousTileID) {
					
					rect = sheet.jeashTileRects[tileID];
					center = sheet.jeashCenterPoints[tileID];
					
					previousTileID = tileID;
					
				}
				
				if (rect != null && center != null) {
					
					ctx.save ();
					ctx.translate (tileData[index], tileData[index + 1]);
					
					if (useRotation) {
						
						ctx.rotate (-tileData[index + rotationIndex]);
						
					}
					
					var scale = 1.0;
					
					if (useScale) {
						
						scale = tileData[index + scaleIndex];
						
					}
					
					if (useTransform) {
						
						ctx.transform (tileData[index + transformIndex], tileData[index + transformIndex + 1], tileData[index + transformIndex + 2], tileData[index + transformIndex + 3], 0, 0);
						
					}
					
					if (useAlpha) {
						
						ctx.globalAlpha = tileData[index + alphaIndex];
						
					}
					
					ctx.drawImage (surface, rect.x, rect.y, rect.width, rect.height, -center.x * scale, -center.y * scale, rect.width * scale, rect.height * scale);
					ctx.restore ();
					
				}
				
				index += numValues;
				
			}
			
		}
		
	}

	function createGradient(type : GradientType,
			colors : Array<Dynamic>,
			alphas : Array<Dynamic>,
			ratios : Array<Dynamic>,
			matrix : Null<Matrix>,
			spreadMethod : Null<SpreadMethod>,
			interpolationMethod : Null<InterpolationMethod>,
			focalPointRatio : Null<Float>)
	{
		var points = new GradPoints();
		for (i in 0...colors.length)
			points.push(new GradPoint(colors[i], alphas[i], ratios[i]));

		var flags = 0;

		if (type == GradientType.RADIAL)
			flags |= RADIAL;

		if (spreadMethod == SpreadMethod.REPEAT)
			flags |= SPREAD_REPEAT;
		else if (spreadMethod==SpreadMethod.REFLECT)
			flags |= SPREAD_REFLECT;


		if (matrix == null) {
			matrix = new Matrix();
			matrix.createGradientBox(25,25);
		} else
			matrix = matrix.clone();

		var focal : Float = focalPointRatio ==null ? 0 : focalPointRatio;
		return new Grad(points, matrix, flags, focal);
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
		closePolygon(true);

		mFilling = true;
		mBitmap = null;
		mSolidGradient = createGradient(type,colors,alphas,ratios,
				matrix,spreadMethod,
				interpolationMethod,
				focalPointRatio);
	}

	public function beginBitmapFill(bitmap:BitmapData, ?matrix:Matrix,
			?in_repeat:Bool, ?in_smooth:Bool)
	{
		closePolygon(true);

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

	public function jeashClearLine() {
		mCurrentLine = new LineJob( null, -1, -1, 0.0,
				0.0, 0x000, 1, CORNER_ROUND, END_ROUND,
				SCALE_NORMAL, 3.0);
	}

	inline public function jeashClearCanvas() {
		if (jeashSurface != null) {
			var ctx = getContext ();
			if (ctx != null) {
				ctx.clearRect (0, 0, jeashSurface.width, jeashSurface.height);
			}
			//var w = jeashSurface.width;
			//jeashSurface.width = w;
		}
	}

	public function clear() {
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
		jeashClearNextCycle = true;

		boundsDirty = true;
		jeashExtent.x = 0.0;
		jeashExtent.y = 0.0;
		jeashExtent.width = 0.0;
		jeashExtent.height = 0.0;
		_padding = 0.0;

		mLineJobs = [];
	}

	public inline function jeashInvalidate():Void {
		jeashChanged = jeashClearNextCycle = true;
	}

	function jeashExpandStandardExtent(x:Float, y:Float, ?thickness:Float) {
		if (_padding > 0) {
			jeashExtent.width -= _padding;
			jeashExtent.height -= _padding;
		}
		if (thickness != null && thickness > _padding) _padding = thickness;

		var maxX, minX, maxY, minY;
		minX = jeashExtent.x;
		minY = jeashExtent.y;
		maxX = jeashExtent.width + minX;
		maxY = jeashExtent.height + minY;
		maxX = x > maxX ? x : maxX;
		minX = x < minX ? x : minX;
		maxY = y > maxY ? y : maxY;
		minY = y < minY ? y : minY;
		jeashExtent.x = minX;
		jeashExtent.y = minY;
		jeashExtent.width = maxX - minX + _padding;
		jeashExtent.height = maxY - minY + _padding;
		boundsDirty = true;
	}

	function jeashExpandFilteredExtent(x:Float, y:Float) {
		var maxX, minX, maxY, minY;
		minX = jeashExtent.x;
		minY = jeashExtent.y;
		maxX = jeashExtent.width + minX;
		maxY = jeashExtent.height + minY;
		maxX = x > maxX ? x : maxX;
		minX = x < minX ? x : minX;
		maxY = y > maxY ? y : maxY;
		minY = y < minY ? y : minY;
		jeashExtentWithFilters.x = minX;
		jeashExtentWithFilters.y = minY;
		jeashExtentWithFilters.width = maxX - minX;
		jeashExtentWithFilters.height = maxY - minY;
	}

	public function moveTo(inX:Float, inY:Float) {
		mPenX = inX;
		mPenY = inY;

		jeashExpandStandardExtent(inX, inY);

		if (!mFilling) {
			closePolygon(false);
		} else {
			addLineSegment();
			mLastMoveID = mPoints.length;
			mPoints.push(new GfxPoint(mPenX, mPenY, 0.0, 0.0, MOVE));
		}
	}

	public function lineTo(inX:Float, inY:Float) {
		var pid = mPoints.length;
		if (pid == 0) {
			mPoints.push(new GfxPoint(mPenX, mPenY, 0.0, 0.0, MOVE));
			pid++;
		}

		mPenX = inX;
		mPenY = inY;
		jeashExpandStandardExtent(inX, inY, mCurrentLine.thickness);
		mPoints.push(new GfxPoint(mPenX, mPenY, 0.0, 0.0, LINE));

		if (mCurrentLine.grad != null || mCurrentLine.alpha > 0) {
			if (mCurrentLine.point_idx0 < 0)
				mCurrentLine.point_idx0 = pid - 1;
			mCurrentLine.point_idx1 = pid;
		}

		if (!mFilling) closePolygon(false);
	}

	public function curveTo(inCX:Float, inCY:Float, inX:Float, inY:Float) {
		var pid = mPoints.length;
		if (pid == 0) {
			mPoints.push( new GfxPoint( mPenX, mPenY, 0.0, 0.0, MOVE ) );
			pid++;
		}

		mPenX = inX;
		mPenY = inY;
		jeashExpandStandardExtent(inX, inY, mCurrentLine.thickness);
		mPoints.push(new GfxPoint(inX, inY, inCX, inCY, CURVE));

		if (mCurrentLine.grad != null || mCurrentLine.alpha > 0) {
			if (mCurrentLine.point_idx0 < 0)
				mCurrentLine.point_idx0 = pid-1;
			mCurrentLine.point_idx1 = pid;
		}
	}

	public function flush() { closePolygon(true); }

	private function addDrawable(inDrawable:Drawable) {
		if (inDrawable == null)
			return; // throw ?

		mDrawList.unshift( inDrawable );
	}

	private function addLineSegment() {
		if (mCurrentLine.point_idx1 > 0) {
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

	private function closePolygon(inCancelFill) {
		var l = mPoints.length;
		if (l > 0) {
			if (l > 1) {
				if (mFilling && l > 2) {
					// Make implicit closing line
					if (mPoints[mLastMoveID].x != mPoints[l-1].x || mPoints[mLastMoveID].y != mPoints[l-1].y) {
						lineTo(mPoints[mLastMoveID].x, mPoints[mLastMoveID].y);
					}
				}

				addLineSegment();

				var drawable : Drawable = new Drawable ( 
					mPoints, 
					mFillColour, 
					mFillAlpha,
					mSolidGradient, 
					mBitmap,
					mLineJobs,
					null
				);
				addDrawable(drawable);
			}

			mLineJobs = [];
			mPoints = [];
		}

		if (inCancelFill) {
			mFillAlpha = 0;
			mSolidGradient = null;
			mBitmap = null;
			mFilling = false;
		}

		jeashChanged = true;
	}

	public function drawGraphicsData(points:Vector<IGraphicsData>) {
		for (data in points) {
			if (data == null) {
				mFilling = true;
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

	public static function jeashDetectIsPointInPathMode() {
		var canvas : HTMLCanvasElement = cast js.Lib.document.createElement("canvas");
		var ctx = canvas.getContext('2d');
		if (ctx.isPointInPath == null)
			return USER_SPACE;
		ctx.save();
		ctx.translate(1, 0);
		ctx.beginPath();
		ctx.rect(0, 0, 1, 1);
		var rv = if (ctx.isPointInPath(0.3, 0.3)) {
			USER_SPACE;
		} else {
			DEVICE_SPACE;
		}
		ctx.restore();
		return rv;
	}

	inline function getContext() : CanvasRenderingContext2D {
		try {
			return jeashSurface.getContext("2d");
		} catch (e:Dynamic) {
			return null;
		}
	}

	function jeashAdjustSurface(sx:Float=1.0, sy:Float=1.0):Void {
		if (Reflect.field(jeashSurface, "getContext") != null) {
			var width = Math.ceil((jeashExtentWithFilters.width - jeashExtentWithFilters.x)*sx);
			var height = Math.ceil((jeashExtentWithFilters.height - jeashExtentWithFilters.y)*sy);

			// prevent allocating too large canvas sizes
			if (width <= JEASH_MAX_DIM && height <= JEASH_MAX_DIM) {
				// re-allocate canvas, copy into larger canvas.
				var dstCanvas : HTMLCanvasElement = cast js.Lib.document.createElement("canvas");
				dstCanvas.width = width;
				dstCanvas.height = height;

				Lib.jeashDrawToSurface(jeashSurface, dstCanvas);

				if (Lib.jeashIsOnStage(jeashSurface)) {
					Lib.jeashAppendSurface(dstCanvas);
					Lib.jeashCopyStyle(jeashSurface, dstCanvas);
					Lib.jeashSwapSurface(jeashSurface, dstCanvas);
					Lib.jeashRemoveSurface(jeashSurface);
					if (jeashSurface.id != null) Lib.jeashSetSurfaceId(dstCanvas, jeashSurface.id);
				}
				
				jeashSurface = dstCanvas;
			}
		}
	}

	public function jeashMediaSurface(surface:HTMLMediaElement) this.jeashSurface = cast surface
}
