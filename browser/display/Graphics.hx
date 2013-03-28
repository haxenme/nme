package browser.display;
#if js


import browser.display.BitmapData;
import browser.display.CapsStyle;
import browser.display.GradientType;
import browser.display.IGraphicsData;
import browser.display.IGraphicsFill;
import browser.display.InterpolationMethod;
import browser.display.JointStyle;
import browser.display.LineScaleMode;
import browser.display.SpreadMethod;
import browser.filters.BitmapFilter;
import browser.filters.DropShadowFilter;
import browser.geom.Matrix;
import browser.geom.Point;
import browser.geom.Rectangle;
import browser.Lib;
import nme.Vector;
import js.html.CanvasElement;
import js.html.CanvasGradient;
import js.html.CanvasRenderingContext2D;
import js.html.Element;
import js.html.MediaElement;
import js.Browser;


class Graphics {
	
	/*
		Lines, fill styles and closing polygons.
		Flash allows the line stype to be changed within one filled polygon.
		A single NME "DrawObject" has a point list, an optional solid fill style
		and a list of lines.  Each of these lines has a line style and a
		list of "point indices", which are indices into the DrawObject's point array.
		The solid does not need a point-index list because it uses all the
		points in order.
		
		When building up a filled polygon, eveytime the line style changes, the
		current "line fragment" is stored in the "mLineJobs" list and a new line
		is started, without affecting the solid fill bit.
	*/
	
	public static inline var TILE_SCALE = 0x0001;
	public static inline var TILE_ROTATION = 0x0002;
	public static inline var TILE_RGB = 0x0004;
	public static inline var TILE_ALPHA = 0x0008;
	public static inline var TILE_TRANS_2x2 = 0x0010;
	public static inline var TILE_BLEND_NORMAL = 0x00000000;
	public static inline var TILE_BLEND_ADD = 0x00010000;
	
	private static inline var BMP_REPEAT = 0x0010;
	private static inline var BMP_SMOOTH = 0x10000;
	private static inline var CORNER_ROUND = 0x0000;
	private static inline var CORNER_MITER = 0x1000;
	private static inline var CORNER_BEVEL = 0x2000;
	private static inline var CURVE = 2;
	private static inline var END_NONE = 0x0000;
	private static inline var END_ROUND = 0x0100;
	private static inline var END_SQUARE = 0x0200;
	private static inline var LINE = 1;
	private static inline var MOVE = 0;
	private static inline var NME_MAX_DIM = 5000;
	private static inline var PIXEL_HINTING = 0x4000;
	private static inline var RADIAL = 0x0001;
	private static inline var SCALE_HORIZONTAL = 2;
	private static inline var SCALE_NONE = 0;
	private static inline var SCALE_NORMAL = 3;
	private static inline var SCALE_VERTICAL = 1;
	private static inline var SPREAD_REPEAT = 0x0002;
	private static inline var SPREAD_REFLECT = 0x0004;
	
	public var boundsDirty:Bool;
	public var nmeExtent(default, null):Rectangle;
	public var nmeExtentWithFilters(default, null):Rectangle;
	public var nmeSurface(default, null):CanvasElement;
	
	private var mBitmap(default, null):Texture;
	private var mCurrentLine:LineJob;
	private var mDrawList(default, null):DrawList;
	private var mFillColour:Int;
	private var mFillAlpha:Float;
	private var mFilling:Bool;
	private var mLastMoveID:Int;
	private var mLineDraws:DrawList;
	private var mLineJobs:LineJobs;
	private var mPenX:Float;
	private var mPenY:Float;
	private var mPoints:GfxPoints;
	private var mSolidGradient:Grad;
	private var nextDrawIndex:Int;
	private var nmeChanged:Bool;
	private var nmeClearNextCycle:Bool;
	
	private var _padding:Float;
	
	
	public function new(inSurface:Element = null) {
		
		Lib.nmeBootstrap(); // sanity check
		
		if (inSurface == null) {
			
			nmeSurface = cast Browser.document.createElement("canvas");
			nmeSurface.width = 0;
			nmeSurface.height = 0;
			
		} else {
			
			nmeSurface = cast inSurface;
			
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
		
		nmeClearLine();
		mLineJobs = [];
		nmeChanged = true;
		nextDrawIndex = 0;
		
		nmeExtent = new Rectangle();
		nmeExtentWithFilters = new Rectangle();
		_padding = 0.0;
		nmeClearNextCycle = true;
		
	}
	
	
	private function addDrawable(inDrawable:Drawable):Void {
		
		if (inDrawable == null) {
			
			return; // throw ?
			
		}
		
		mDrawList.unshift(inDrawable);
		
	}
	
	
	private function addLineSegment():Void {
		
		if (mCurrentLine.point_idx1 > 0) {
			
			mLineJobs.push(new LineJob(mCurrentLine.grad, mCurrentLine.point_idx0, mCurrentLine.point_idx1, mCurrentLine.thickness, mCurrentLine.alpha, mCurrentLine.colour, mCurrentLine.pixel_hinting, mCurrentLine.joints, mCurrentLine.caps, mCurrentLine.scale_mode, mCurrentLine.miter_limit));
			
		}
		
		mCurrentLine.point_idx0 = mCurrentLine.point_idx1 = -1;
		
	}
	
	
	public function beginBitmapFill(bitmap:BitmapData, matrix:Matrix = null, in_repeat:Bool = true, in_smooth:Bool = false):Void {
		
		closePolygon(true);
		var repeat:Bool = (in_repeat == null ? true : in_repeat);
		var smooth:Bool = (in_smooth == null ? false : in_smooth);
		
		mFilling = true;
		mSolidGradient = null;
		nmeExpandStandardExtent(bitmap.width, bitmap.height);
		
		mBitmap = { texture_buffer: bitmap.handle(), matrix: matrix == null ? matrix : matrix.clone(), flags :(repeat ? BMP_REPEAT : 0) |(smooth ? BMP_SMOOTH : 0 ) };
		
	}
	
	
	public function beginFill(color:Int, alpha:Null<Float> = null):Void {
		
		closePolygon(true);
		mFillColour = color;
		mFillAlpha = (alpha == null ? 1.0 : alpha);
		mFilling = true;
		mSolidGradient = null;
		mBitmap = null;
		
	}
	
	
	public function beginGradientFill(type:GradientType, colors:Array<Dynamic>, alphas:Array<Dynamic>, ratios:Array<Dynamic>, matrix:Matrix = null, spreadMethod:Null<SpreadMethod> = null, interpolationMethod:Null<InterpolationMethod> = null, focalPointRatio:Null<Float> = null):Void {
		
		closePolygon(true);
		mFilling = true;
		mBitmap = null;
		
		mSolidGradient = createGradient(type, colors, alphas, ratios, matrix, spreadMethod, interpolationMethod, focalPointRatio);
		
	}
	
	
	public function blit(inTexture:BitmapData):Void {
		
		closePolygon(true);
		var ctx = getContext();
		
		if (ctx != null) {
			
			ctx.drawImage(inTexture.handle(), mPenX, mPenY);
			
		}
		
	}
	
	
	public function clear():Void {
		
		nmeClearLine();
		
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
		nmeClearNextCycle = true;
		
		boundsDirty = true;
		nmeExtent.x = 0.0;
		nmeExtent.y = 0.0;
		nmeExtent.width = 0.0;
		nmeExtent.height = 0.0;
		_padding = 0.0;
		
		mLineJobs = [];
		
	}
	
	
	private function closePolygon(inCancelFill:Bool):Void {
		
		var l = mPoints.length;
		
		if (l > 0) {
			
			if (l > 1) {
				
				if (mFilling && l > 2) {
					
					// Make implicit closing line
					if (mPoints[mLastMoveID].x != mPoints[l - 1].x || mPoints[mLastMoveID].y != mPoints[l - 1].y) {
						
						lineTo(mPoints[mLastMoveID].x, mPoints[mLastMoveID].y);
						
					}
					
				}
				
				addLineSegment();
				
				var drawable = new Drawable(mPoints, mFillColour, mFillAlpha, mSolidGradient, mBitmap, mLineJobs, null);
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
		
		nmeChanged = true;
		
	}
	
	
	private function createCanvasColor(color:Int, alpha:Float):String {
		
		var r = (0xFF0000 & color) >> 16;
		var g = (0x00FF00 & color) >> 8;
		var b = (0x0000FF & color);
		
		return 'rgba' + '(' + r + ',' + g + ',' + b + ',' + alpha + ')';
		
	}
	
	
	private function createCanvasGradient(ctx:CanvasRenderingContext2D, g:Grad):CanvasGradient {
		
		//TODO handle spreadMethod flags REPEAT and REFLECT(defaults to PAD behavior)
		var gradient:CanvasGradient;
		var matrix = g.matrix;
		
		if ((g.flags & RADIAL) == 0) {
			
			var p1 = matrix.transformPoint(new Point(-819.2, 0));
			var p2 = matrix.transformPoint(new Point(819.2, 0));
			gradient = ctx.createLinearGradient(p1.x, p1.y, p2.x, p2.y);
			
		} else {
			
			//TODO not quite right(no ellipses when width != height)
			var p1 = matrix.transformPoint(new Point(g.focal * 819.2, 0));
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
	
	
	private function createGradient(type:GradientType, colors:Array<Dynamic>, alphas:Array<Dynamic>, ratios:Array<Dynamic>, matrix:Null<Matrix>, spreadMethod:Null<SpreadMethod>, interpolationMethod:Null<InterpolationMethod>, focalPointRatio:Null<Float>):Grad {
		
		var points = new GradPoints();
		
		for (i in 0...colors.length) {
			
			points.push(new GradPoint(colors[i], alphas[i], ratios[i]));
			
		}
		
		var flags = 0;
		
		if (type == GradientType.RADIAL) {
			
			flags |= RADIAL;
			
		}
		
		if (spreadMethod == SpreadMethod.REPEAT) {
			
			flags |= SPREAD_REPEAT;
			
		} else if (spreadMethod == SpreadMethod.REFLECT) {
			
			flags |= SPREAD_REFLECT;
			
		}
		
		if (matrix == null) {
			
			matrix = new Matrix();
			matrix.createGradientBox(25, 25);
			
		} else {
			
			matrix = matrix.clone();
			
		}
		
		var focal:Float = (focalPointRatio == null ? 0 : focalPointRatio);
		return new Grad(points, matrix, flags, focal);
		
	}
	
	
	public function curveTo(inCX:Float, inCY:Float, inX:Float, inY:Float):Void {
		
		var pid = mPoints.length;
		
		if (pid == 0) {
			
			mPoints.push(new GfxPoint(mPenX, mPenY, 0.0, 0.0, MOVE));
			pid++;
			
		}
		
		mPenX = inX;
		mPenY = inY;
		nmeExpandStandardExtent(inX, inY, mCurrentLine.thickness);
		mPoints.push(new GfxPoint(inX, inY, inCX, inCY, CURVE));
		
		if (mCurrentLine.grad != null || mCurrentLine.alpha > 0) {
			
			if (mCurrentLine.point_idx0 < 0) {
				
				mCurrentLine.point_idx0 = pid - 1;
				
			}
			
			mCurrentLine.point_idx1 = pid;
			
		}
		
	}
	
	
	public function drawCircle(x:Float, y:Float, rad:Float):Void {
		
		closePolygon(false);
		nmeDrawEllipse(x, y, rad, rad);
		closePolygon(false);
		
	}
	
	
	public function drawEllipse(x:Float, y:Float, rx:Float, ry:Float):Void {
		
		closePolygon(false);
		rx /= 2;
		ry /= 2;
		nmeDrawEllipse(x + rx, y + ry, rx, ry);
		closePolygon(false);
		
	}
	
	
	public function drawGraphicsData(points:Vector<IGraphicsData>):Void {
		
		for (data in points) {
			
			if (data == null) {
				
				mFilling = true;
				
			} else {
				
				switch (data.nmeGraphicsDataType) {
					
					case STROKE:
						
						var stroke:GraphicsStroke = cast data;
						
						if (stroke.fill == null) {
							
							lineStyle(stroke.thickness, 0x000000, 1., stroke.pixelHinting, stroke.scaleMode, stroke.caps, stroke.joints, stroke.miterLimit);
							
						} else {
							
							switch (stroke.fill.nmeGraphicsFillType) {
								
								case SOLID_FILL:
									
									var fill:GraphicsSolidFill = cast stroke.fill;
									lineStyle(stroke.thickness, fill.color, fill.alpha, stroke.pixelHinting, stroke.scaleMode, stroke.caps, stroke.joints, stroke.miterLimit);
								
								case GRADIENT_FILL:
									
									var fill:GraphicsGradientFill = cast stroke.fill;
									lineGradientStyle(fill.type, fill.colors, fill.alphas, fill.ratios, fill.matrix, fill.spreadMethod, fill.interpolationMethod, fill.focalPointRatio);
								
							}
							
						}
					
					case PATH:
						
						var path:GraphicsPath = cast data;
						var j = 0;
						
						for (i in 0...path.commands.length) {
							
							var command = path.commands[i];
							
							switch (command) {
								
								case GraphicsPathCommand.MOVE_TO: 
									
									moveTo(path.data[j], path.data[j + 1]);
									j = j + 2;
								
								case GraphicsPathCommand.LINE_TO:
									
									lineTo(path.data[j], path.data[j + 1]);
									j = j + 2;
								
								case GraphicsPathCommand.CURVE_TO:
									
									curveTo(path.data[j], path.data[j + 1], path.data[j + 2], path.data[j + 3]);
									j = j + 4;
								
							}
							
						}
					
					case SOLID:
						
						var fill:GraphicsSolidFill = cast data;
						beginFill(fill.color, fill.alpha);
					
					case GRADIENT:
						
						var fill:GraphicsGradientFill = cast data;
						beginGradientFill(fill.type, fill.colors, fill.alphas, fill.ratios, fill.matrix, fill.spreadMethod, fill.interpolationMethod, fill.focalPointRatio);
					
				}
				
			}
			
		}
		
	}
	
	
	public function drawRect(x:Float, y:Float, width:Float, height:Float):Void {
		
		closePolygon(false);
		
		moveTo(x, y);
		lineTo(x + width, y);
		lineTo(x + width, y + height);
		lineTo(x, y + height);
		lineTo(x, y);
		
		closePolygon(false);
		
	}
	
	
	public function drawRoundRect(x:Float, y:Float, width:Float, height:Float, rx:Float, ry:Float):Void {
		
		rx *= 0.5;
		ry *= 0.5;
		
		var w = width * 0.5;
		x += w;
		
		if (rx > w) rx = w;
		
		var lw = w - rx;
		var w_ = lw + rx * Math.sin(Math.PI / 4);
		var cw_ = lw + rx * Math.tan(Math.PI / 8);
		
		var h = height * 0.5;
		y += h;
		
		if (ry > h) ry = h;
		
		var lh = h - ry;
		var h_ = lh + ry * Math.sin(Math.PI / 4);
		var ch_ = lh + ry * Math.tan(Math.PI / 8);
		
		closePolygon(false);
		
		moveTo(x + w, y + lh);
		curveTo(x + w, y + ch_, x + w_, y + h_);
		curveTo(x + cw_, y + h, x + lw, y + h);
		lineTo(x - lw, y + h);
		curveTo(x - cw_, y + h, x - w_, y + h_);
		curveTo(x - w, y + ch_, x - w, y + lh);
		lineTo(x - w, y - lh);
		curveTo(x - w, y - ch_, x - w_, y - h_);
		curveTo(x - cw_, y - h, x - lw, y - h);
		lineTo(x + lw, y - h);
		curveTo(x + cw_, y - h, x + w_, y - h_);
		curveTo(x + w, y - ch_, x + w, y - lh);
		lineTo(x + w, y + lh);
		
		closePolygon(false);
		
	}
	
	
	/** @private */
	public function drawTiles(sheet:Tilesheet, tileData:Array<Float>, smooth:Bool = false, flags:Int = 0):Void {
		
		// Checking each tile for extents did not include rotation or scale, and could overflow the maximum canvas
		// size of some mobile browsers. Always use the full stage size for drawTiles instead?
		
		nmeExpandStandardExtent(Lib.current.stage.stageWidth, Lib.current.stage.stageHeight);
		
		//var useScale = (flags & TILE_SCALE) > 0;
		//var useRotation = (flags & TILE_ROTATION) > 0;
		//var useTransform = (flags & TILE_TRANS_2x2) > 0;
		//var useRGB = (flags & TILE_RGB) > 0;
		//var useAlpha = (flags & TILE_ALPHA) > 0;
		
		//if (useTransform) { useScale = false; useRotation = false; }
		
		//var index = 0;
		//var numValues = 3;
		
		//if (useScale) numValues ++;
		//if (useRotation) numValues ++;
		//if (useTransform) numValues += 4;
		//if (useRGB) numValues += 3;
		//if (useAlpha) numValues ++;
		
		//while (index < tileData.length) {
			
			//nmeExpandStandardExtent(tileData[index] + sheet.nmeBitmap.width, tileData[index + 1] + sheet.nmeBitmap.height);
			//index += numValues;
			
		//}
		
		addDrawable(new Drawable(null, null, null, null, null, null, new TileJob(sheet, tileData, flags)));
		nmeChanged = true;
		
	}
	
	
	public function endFill():Void {
		
		closePolygon(true);
		
	}
	
	
	public function flush():Void {
		
		closePolygon(true);
		
	}
	
	
	private inline function getContext():CanvasRenderingContext2D {
		
		try {
			
			return nmeSurface.getContext("2d");
			
		} catch(e:Dynamic) {
			
			return null;
			
		}
		
	}
	
	
	public function lineGradientStyle(type:GradientType, colors:Array<Dynamic>, alphas:Array<Dynamic>, ratios:Array<Dynamic>, matrix:Matrix = null, spreadMethod:SpreadMethod = null, interpolationMethod:InterpolationMethod = null, focalPointRatio:Null<Float> = null):Void {
		
		mCurrentLine.grad = createGradient(type, colors, alphas, ratios, matrix, spreadMethod, interpolationMethod, focalPointRatio);
		
	}
	
	
	public function lineStyle(thickness:Null<Float> = null, color:Null<Int> = null, alpha:Null<Float> = null, pixelHinting:Null<Bool> = null, scaleMode:LineScaleMode = null, caps:CapsStyle = null, joints:JointStyle = null, miterLimit:Null<Float> = null):Void {
		
		// Finish off old line before starting a new one
		addLineSegment();
		
		if (thickness == null) {
			
			//with no parameters it clears the current line(to draw nothing)
			nmeClearLine();
			return;
			
		} else {
			
			mCurrentLine.grad = null;
			mCurrentLine.thickness = thickness;
			mCurrentLine.colour = (color == null ? 0 : color);
			mCurrentLine.alpha = (alpha == null ? 1.0 : alpha);
			mCurrentLine.miter_limit = (miterLimit == null ? 3.0 : miterLimit);
			mCurrentLine.pixel_hinting = (pixelHinting == null || !pixelHinting) ? 0 : PIXEL_HINTING;
			
		}
		
		//mCurrentLine.caps = END_ROUND;
		
		if (caps != null) {
			
			switch (caps) {
				
				case ROUND: mCurrentLine.caps = END_ROUND;
				case SQUARE: mCurrentLine.caps = END_SQUARE;
				case NONE: mCurrentLine.caps = END_NONE;
				
			}
			
		}
		
		mCurrentLine.scale_mode = SCALE_NORMAL;
		
		if (scaleMode != null) {
			
			switch (scaleMode) {
				
				case NORMAL: mCurrentLine.scale_mode = SCALE_NORMAL;
				case VERTICAL: mCurrentLine.scale_mode = SCALE_VERTICAL;
				case HORIZONTAL: mCurrentLine.scale_mode = SCALE_HORIZONTAL;
				case NONE: mCurrentLine.scale_mode = SCALE_NONE;
				
			}
			
		}
		
		mCurrentLine.joints = CORNER_ROUND;
		
		if (joints != null) {
			
			switch (joints) {
				
				case ROUND: mCurrentLine.joints = CORNER_ROUND;
				case MITER: mCurrentLine.joints = CORNER_MITER;
				case BEVEL: mCurrentLine.joints = CORNER_BEVEL;
				
			}
			
		}
		
	}
	
	
	public function lineTo(inX:Float, inY:Float):Void {
		
		var pid = mPoints.length;
		
		if (pid == 0) {
			
			mPoints.push(new GfxPoint(mPenX, mPenY, 0.0, 0.0, MOVE));
			pid++;
			
		}
		
		mPenX = inX;
		mPenY = inY;
		nmeExpandStandardExtent(inX, inY, mCurrentLine.thickness);
		mPoints.push(new GfxPoint(mPenX, mPenY, 0.0, 0.0, LINE));
		
		if (mCurrentLine.grad != null || mCurrentLine.alpha > 0) {
			
			if (mCurrentLine.point_idx0 < 0) {
				
				mCurrentLine.point_idx0 = pid - 1;
				
			}
			
			mCurrentLine.point_idx1 = pid;
			
		}
		
		if (!mFilling) closePolygon(false);
		
	}
	
	
	public function moveTo(inX:Float, inY:Float):Void {
		
		mPenX = inX;
		mPenY = inY;
		
		nmeExpandStandardExtent(inX, inY);
		
		if (!mFilling) {
			
			closePolygon(false);
			
		} else {
			
			addLineSegment();
			mLastMoveID = mPoints.length;
			mPoints.push(new GfxPoint(mPenX, mPenY, 0.0, 0.0, MOVE));
			
		}
		
	}
	
	
	private function nmeAdjustSurface(sx:Float = 1.0, sy:Float = 1.0):Void {
		
		if (Reflect.field(nmeSurface, "getContext") != null) {
			
			var width = Math.ceil((nmeExtentWithFilters.width - nmeExtentWithFilters.x) * sx);
			var height = Math.ceil((nmeExtentWithFilters.height - nmeExtentWithFilters.y) * sy);
			
			// prevent allocating too large canvas sizes
			if (width <= NME_MAX_DIM && height <= NME_MAX_DIM) {
				
				// re-allocate canvas, copy into larger canvas.
				var dstCanvas:CanvasElement = cast Browser.document.createElement("canvas");
				dstCanvas.width = width;
				dstCanvas.height = height;
				
				Lib.nmeDrawToSurface(nmeSurface, dstCanvas);
				
				if (Lib.nmeIsOnStage(nmeSurface)) {
					
					Lib.nmeAppendSurface(dstCanvas);
					Lib.nmeCopyStyle(nmeSurface, dstCanvas);
					Lib.nmeSwapSurface(nmeSurface, dstCanvas);
					Lib.nmeRemoveSurface(nmeSurface);
					
					if (nmeSurface.id != null) Lib.nmeSetSurfaceId(dstCanvas, nmeSurface.id);
					
				}
				
				nmeSurface = dstCanvas;
				
			}
			
		}
		
	}
	
	
	public inline function nmeClearCanvas():Void {
		
		if (nmeSurface != null) {
			
			var ctx = getContext();
			
			if (ctx != null) {
				
				ctx.clearRect(0, 0, nmeSurface.width, nmeSurface.height);
				
			}
			
			//var w = nmeSurface.width;
			//nmeSurface.width = w;
			
		}
		
	}
	
	
	public function nmeClearLine():Void {
		
		mCurrentLine = new LineJob(null, -1, -1, 0.0, 0.0, 0x000, 1, CORNER_ROUND, END_ROUND, SCALE_NORMAL, 3.0);
		
	}
	
	
	public static function nmeDetectIsPointInPathMode():PointInPathMode {
		
		var canvas:CanvasElement = cast Browser.document.createElement("canvas");
		var ctx = canvas.getContext('2d');
		
		if (ctx.isPointInPath == null) {
			
			return USER_SPACE;
			
		}
		
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
	
	
	private function nmeDrawEllipse(x:Float, y:Float, rx:Float, ry:Float):Void {
		
		moveTo(x + rx, y);
		curveTo(rx + x, -0.4142 * ry + y, 0.7071 * rx + x , -0.7071 * ry + y);
		curveTo(0.4142 * rx + x , -ry + y, x, -ry + y);
		curveTo( -0.4142 * rx + x, -ry + y, -0.7071 * rx + x, -0.7071 * ry + y);
		curveTo( -rx + x, -0.4142 * ry + y, -rx + x, y);
		curveTo( -rx + x, 0.4142 * ry + y, -0.7071 * rx + x, 0.7071 * ry + y);
		curveTo( -0.4142 * rx + x, ry + y, x, ry + y);
		curveTo(0.4142 * rx + x, ry + y, 0.7071 * rx + x, 0.7071 * ry + y);
		curveTo(rx + x, 0.4142 * ry + y, rx + x, y);
		
	}
	
	
	private function nmeDrawTiles(sheet:Tilesheet, tileData:Array<Float>, flags:Int = 0):Void {
		
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
		var itemCount = Std.int(totalCount / numValues);
		var index = 0;
		
		var rect = null;
		var center = null;
		var previousTileID = -1;
		
		var surface = sheet.nmeBitmap.handle();
		var ctx = getContext();
		
		if (ctx != null) {
			
			while (index < totalCount) {
				
				var tileID = Std.int(tileData[index + 2]);
				
				if (tileID != previousTileID) {
					
					rect = sheet.nmeTileRects[tileID];
					center = sheet.nmeCenterPoints[tileID];
					
					previousTileID = tileID;
					
				}
				
				if (rect != null && center != null) {
					
					ctx.save();
					ctx.translate(tileData[index], tileData[index + 1]);
					
					if (useRotation) {
						
						ctx.rotate(-tileData[index + rotationIndex]);
						
					}
					
					var scale = 1.0;
					
					if (useScale) {
						
						scale = tileData[index + scaleIndex];
						
					}
					
					if (useTransform) {
						
						ctx.transform(tileData[index + transformIndex], tileData[index + transformIndex + 2], tileData[index + transformIndex + 1], tileData[index + transformIndex + 3], 0, 0);
						
					}
					
					if (useAlpha) {
						
						ctx.globalAlpha = tileData[index + alphaIndex];
						
					}
					
					ctx.drawImage(surface, rect.x, rect.y, rect.width, rect.height, -center.x * scale, -center.y * scale, rect.width * scale, rect.height * scale);
					ctx.restore();
					
				}
				
				index += numValues;
				
			}
			
		}
		
	}
	
	
	private function nmeExpandFilteredExtent(x:Float, y:Float):Void {
		
		var maxX, minX, maxY, minY;
		
		minX = nmeExtent.x;
		minY = nmeExtent.y;
		maxX = nmeExtent.width + minX;
		maxY = nmeExtent.height + minY;
		
		maxX = x > maxX ? x : maxX;
		minX = x < minX ? x : minX;
		maxY = y > maxY ? y : maxY;
		minY = y < minY ? y : minY;
		
		nmeExtentWithFilters.x = minX;
		nmeExtentWithFilters.y = minY;
		nmeExtentWithFilters.width = maxX - minX;
		nmeExtentWithFilters.height = maxY - minY;
		
	}
	
	
	private function nmeExpandStandardExtent(x:Float, y:Float, thickness:Float = 0):Void {
		
		if (_padding > 0) {
			
			nmeExtent.width -= _padding;
			nmeExtent.height -= _padding;
			
		}
		
		if (thickness != null && thickness > _padding) _padding = thickness;
		
		var maxX, minX, maxY, minY;
		
		minX = nmeExtent.x;
		minY = nmeExtent.y;
		maxX = nmeExtent.width + minX;
		maxY = nmeExtent.height + minY;
		
		maxX = x > maxX ? x : maxX;
		minX = x < minX ? x : minX;
		maxY = y > maxY ? y : maxY;
		minY = y < minY ? y : minY;
		
		nmeExtent.x = minX;
		nmeExtent.y = minY;
		nmeExtent.width = maxX - minX + _padding;
		nmeExtent.height = maxY - minY + _padding;
		
		boundsDirty = true;
		
	}
	
	
	public function nmeHitTest(inX:Float, inY:Float):Bool {
		
		var ctx:CanvasRenderingContext2D = getContext();
		if (ctx == null) return false;
		
		if (ctx.isPointInPath(inX, inY)) {
			
			return true;
			
		} else if (mDrawList.length == 0 && nmeExtent.width > 0 && nmeExtent.height > 0) {
			
			return true;
			
		}
		
		return false;
		
	}
	
	
	public inline function nmeInvalidate():Void {
		
		nmeChanged = true;
		nmeClearNextCycle = true;
		
	}
	
	
	public function nmeMediaSurface(surface:MediaElement):Void {
		
		this.nmeSurface = cast surface;
		
	}
	
	
	public function nmeRender(maskHandle:CanvasElement = null, filters:Array<BitmapFilter> = null, sx:Float = 1.0, sy:Float = 1.0, clip0:Point = null, clip1:Point = null, clip2:Point = null, clip3:Point = null) {
		
		if (!nmeChanged) return false;
		
		closePolygon(true);
		var padding = _padding;
		
		if (filters != null) {
			
			for (filter in filters) {
				
				if (Reflect.hasField(filter, "blurX")) {
					
					padding += (Math.max(Reflect.field(filter, "blurX"), Reflect.field(filter, "blurY")) * 4);
					
				}
				
			}
			
		}
		
		nmeExpandFilteredExtent( - (padding * sx) / 2, - (padding * sy) / 2);
		
		if (nmeClearNextCycle) {
			
			nextDrawIndex = 0;
			nmeClearCanvas();
			nmeClearNextCycle = false;
			
		} 
		
		if (nmeExtentWithFilters.width - nmeExtentWithFilters.x > nmeSurface.width || nmeExtentWithFilters.height - nmeExtentWithFilters.y > nmeSurface.height) {
			
			nmeAdjustSurface(sx, sy);
			
		}
		
		var ctx = getContext();
		if (ctx == null) return false;
		
		if (clip0 != null) {
			
			ctx.beginPath();
			ctx.moveTo(clip0.x * sx, clip0.y * sy);
			ctx.lineTo(clip1.x * sx, clip1.y * sy);
			ctx.lineTo(clip2.x * sx, clip2.y * sy);
			ctx.lineTo(clip3.x * sx, clip3.y * sy);
			ctx.closePath();
			ctx.clip();
			
		}
		
		if (filters != null) {
			
			for (filter in filters) {
				
				if (Std.is(filter, DropShadowFilter)) {
					
					// shadow must be applied before we draw to the context
					filter.nmeApplyFilter(nmeSurface, true);
					
				}
				
			}
			
		}
		
		var len:Int = mDrawList.length;
		ctx.save();
		
		if (nmeExtentWithFilters.x != 0 || nmeExtentWithFilters.y != 0) {
			
			ctx.translate( -nmeExtentWithFilters.x * sx, -nmeExtentWithFilters.y * sy);
			
		}
		
		if (sx != 1 || sy != 0) {
			
			ctx.scale(sx, sy);
			
		}
		
		var doStroke = false;
		
		for (i in nextDrawIndex...len) {
			
			var d = mDrawList[(len - 1) - i];
			
			if (d.tileJob != null) {
				
				nmeDrawTiles(d.tileJob.sheet, d.tileJob.drawList, d.tileJob.flags);
				
			} else {
				
				if (d.lineJobs.length > 0) {
					
					for (lj in d.lineJobs) {
						
						ctx.lineWidth = lj.thickness;
						
						switch (lj.joints) {
							
							case CORNER_ROUND: ctx.lineJoin = "round";
							case CORNER_MITER: ctx.lineJoin = "miter";
							case CORNER_BEVEL: ctx.lineJoin = "bevel";
							
						}
						
						switch (lj.caps) {
							
							case END_ROUND: ctx.lineCap = "round";
							case END_SQUARE: ctx.lineCap = "square";
							case END_NONE: ctx.lineCap = "butt";
							
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
								
								case MOVE: ctx.moveTo(p.x, p.y);
								case CURVE: ctx.quadraticCurveTo(p.cx, p.cy, p.x, p.y);
								default: ctx.lineTo(p.x, p.y);
								
							}
							
						}
						
						ctx.closePath();
						doStroke = true;
						
					}
					
				} else {
					
					ctx.beginPath();
					
					for (p in d.points) {
						
						switch (p.type) {
							
							case MOVE: ctx.moveTo(p.x, p.y);
							case CURVE: ctx.quadraticCurveTo(p.cx, p.cy, p.x, p.y);
							default: ctx.lineTo(p.x, p.y);
							
						}
						
					}
					
					ctx.closePath();
					
				}
				
				var fillColour = d.fillColour;
				var fillAlpha = d.fillAlpha;
				var g = d.solidGradient;
				var bitmap = d.bitmap;
				
				if (g != null) {
					
					ctx.fillStyle = createCanvasGradient(ctx, g);
					
				} else if (bitmap != null && ((bitmap.flags & BMP_REPEAT) > 0)) {
					
					var m = bitmap.matrix;
					
					if (m != null) {
						
						ctx.transform(m.a, m.b, m.c, m.d, m.tx, m.ty);
						
					}
					
					if (bitmap.flags & BMP_SMOOTH == 0) {
						
						untyped ctx.mozImageSmoothingEnabled = false;
						untyped ctx.webkitImageSmoothingEnabled = false;
						
					}
					
					ctx.fillStyle = ctx.createPattern(bitmap.texture_buffer, "repeat");
					
				} else {
					
					// Alpha value gets clamped in [0;1] range.
					ctx.fillStyle = createCanvasColor(fillColour, Math.min(1.0, Math.max(0.0, fillAlpha)));
					
				}
				
				ctx.fill();
				if (doStroke) ctx.stroke();
				ctx.save();
				
				if (bitmap != null && ((bitmap.flags & BMP_REPEAT) == 0)) {
					
					//ctx.clip();
					var img = bitmap.texture_buffer;
					var m = bitmap.matrix;
					
					if (m != null) {
						
						ctx.transform(m.a, m.b, m.c, m.d, m.tx, m.ty);
						
					}
					
					//if (bitmap.flags & BMP_SMOOTH == 0) {
						//
						//untyped ctx.mozImageSmoothingEnabled = false;
						//untyped ctx.webkitImageSmoothingEnabled = false;
						//
					//}
					
					ctx.drawImage(img, 0, 0);
					
				}
				
				ctx.restore();
				
			}
			
		}
		
		ctx.restore();
		
		nmeChanged = false;
		nextDrawIndex = len;
		mDrawList = [];
		
		return true;
		
	}
	
	
}


class Drawable {
	
	
	public var bitmap:Texture;
	public var fillAlpha:Float;
	public var fillColour:Int;
	public var lineJobs:LineJobs;
	public var points:GfxPoints;
	public var solidGradient:Grad;
	public var tileJob:TileJob;
	
	
	public function new(inPoints:GfxPoints, inFillColour:Int, inFillAlpha:Float, inSolidGradient:Grad, inBitmap:Texture, inLineJobs:LineJobs, inTileJob:TileJob) {
		
		points = inPoints;
		fillColour = inFillColour;
		fillAlpha = inFillAlpha;
		solidGradient = inSolidGradient;
		bitmap = inBitmap;
		lineJobs = inLineJobs;
		tileJob = inTileJob;
		
	}
	
	
}


typedef DrawList = Array<Drawable>;


class GfxPoint {
	
	
	public var cx:Float;
	public var cy:Float;
	public var type:Int;
	public var x:Float;
	public var y:Float;
	
	
	public function new(inX:Float, inY:Float, inCX:Float, inCY:Float, inType:Int) {
		
		x = inX;
		y = inY;
		cx = inCX;
		cy = inCY;
		type = inType;
		
	}

	
}


typedef GfxPoints = Array<GfxPoint>;


class Grad {
	
	
	public var flags:Int;
	public var focal:Float;
	public var matrix:Matrix;
	public var points:GradPoints;
	
	
	public function new(inPoints:GradPoints, inMatrix:Matrix, inFlags:Int, inFocal:Float) {
		
		points = inPoints;
		matrix = inMatrix;
		flags = inFlags;
		focal = inFocal;
		
	}
	
	
}


class GradPoint {
	
	
	public var alpha:Float;
	public var col:Int;
	public var ratio:Int;
	
	
	public function new(inCol:Int, inAlpha:Float, inRatio:Int) {
		
		col = inCol;
		alpha = inAlpha;
		ratio = inRatio;
		
	}
	
	
}


typedef GradPoints = Array<GradPoint>;


class LineJob {
	
	
	public var alpha:Float;
	public var caps:Int;
	public var colour:Int;
	public var grad:Grad;
	public var joints:Int;
	public var miter_limit:Float;
	public var pixel_hinting:Int;
	public var point_idx0:Int;
	public var point_idx1:Int;
	public var scale_mode:Int;
	public var thickness:Float;
	
	
	public function new(inGrad:Grad, inPoint_idx0:Int, inPoint_idx1:Int, inThickness:Float, inAlpha:Float, inColour:Int, inPixel_hinting:Int, inJoints:Int, inCaps:Int, inScale_mode:Int, inMiter_limit:Float) {
		
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
	
	
}


typedef LineJobs = Array<LineJob>;


enum PointInPathMode {
	
	USER_SPACE;
	DEVICE_SPACE;
	
}


typedef Texture = {
	
	var texture_buffer:Dynamic;
	var matrix:Matrix;
	var flags:Int;
	
}


class TileJob {
	
	
	public var drawList:Array<Float>;
	public var flags:Int;
	public var sheet:Tilesheet;
	
	
	public function new(sheet:Tilesheet, drawList:Array<Float>, flags:Int) {
		
		this.sheet = sheet;
		this.drawList = drawList;
		this.flags = flags;
		
	}
	
	
}


#end