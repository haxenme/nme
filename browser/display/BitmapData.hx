package browser.display;
#if js


import browser.display.BlendMode;
import browser.display.IBitmapDrawable;
import browser.display.Loader;
import browser.display.LoaderInfo;
import browser.errors.IOError;
import browser.events.Event;
import browser.filters.BitmapFilter;
import browser.geom.ColorTransform;
import browser.geom.Matrix;
import browser.geom.Point;
import browser.geom.Rectangle;
import browser.gl.GLTexture;
import browser.utils.ByteArray;
import browser.utils.Uuid;
import browser.Lib;
import haxe.xml.Check;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.ImageData;
import js.html.ImageElement;
import js.html.Uint8ClampedArray;
import js.Browser;


@:autoBuild(nme.Assets.embedBitmap())
class BitmapData implements IBitmapDrawable {
	
	
	public var height(get_height, null):Int;
	public var nmeImageData:ImageData;
	public var nmeGLTexture:GLTexture;
	public var nmeReferenceCount:Int;
	public var rect:Rectangle;
	public var transparent(get_transparent, null):Bool;
	public var width(get_width,null):Int;
	
	private var nmeAssignedBitmaps:Int;
	private var nmeCopyPixelList:Array<CopyPixelAtom>;
	private var nmeImageDataChanged:Bool;
	private var nmeInitColor:Int;
	private var nmeLease:ImageDataLease;
	private var nmeLeaseNum:Int;
	private var nmeLocked:Bool;
	private var nmeTransparent:Bool;
	private var nmeTransparentFiller:CanvasElement;
	
	private var _nmeId:String;
	private var _nmeTextureBuffer:CanvasElement;
	
	
	public function new(width:Int, height:Int, transparent:Bool = true, inFillColor:Int = 0xFFFFFFFF) {
		
		nmeLocked = false;
		nmeReferenceCount = 0;
		nmeLeaseNum = 0;
		nmeLease = new ImageDataLease();
		nmeBuildLease();
		
		_nmeTextureBuffer = cast Browser.document.createElement('canvas');
		_nmeTextureBuffer.width = width;
		_nmeTextureBuffer.height = height;
		_nmeId = Uuid.uuid();
		Lib.nmeSetSurfaceId(_nmeTextureBuffer, _nmeId);
		
		nmeTransparent = transparent;
		rect = new Rectangle(0, 0, width, height);
		
		if (nmeTransparent) {
			
			nmeTransparentFiller = cast Browser.document.createElement('canvas');
			nmeTransparentFiller.width = width;
			nmeTransparentFiller.height = height;
			
			var ctx = nmeTransparentFiller.getContext('2d');
			ctx.fillStyle = 'rgba(0,0,0,0);';
			ctx.fill();
			
		}

		if (inFillColor != null && width > 0 && height > 0) {
			
			if (!nmeTransparent) inFillColor |= 0xFF000000;
			
			nmeInitColor = inFillColor;
			nmeFillRect(rect, inFillColor);
			
		}
		
	}
	
	
	public function applyFilter(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, filter:BitmapFilter):Void {
		
		trace("BitmapData.applyFilter not implemented");
		
	}
	
	
	public function clear (color:Int):Void {
		
		fillRect (rect, color);
		
	}
	
	
	private function clipRect(r:Rectangle):Rectangle {
		
		if (r.x < 0) {
			
			r.width -= -r.x;
			r.x = 0;
			
			if (r.x + r.width <= 0) return null;
			
		}
		
		if (r.y < 0) {
			
			r.height -= -r.y;
			r.y = 0;
			
			if (r.y + r.height <= 0) return null;
			
		}
		
		if (r.x + r.width >= this.width) {
			
			r.width -= r.x + r.width - this.width;
			
			if (r.width <= 0) return null;
			
		}
		
		if (r.y + r.height >= this.height) {
			
			r.height -= r.y + r.height - this.height;
			
			if (r.height <= 0) return null;
			
		}
		
		return r;
		
	}
	
	
	public function clone():BitmapData {
		
		var bitmapData = new BitmapData(width, height, nmeTransparent);
		var rect = new Rectangle(0, 0, width, height);
		
		bitmapData.setPixels(rect, getPixels(rect));
		bitmapData.nmeBuildLease();
		
		return bitmapData;
		
	}
	
	
	public function colorTransform(rect:Rectangle, colorTransform:ColorTransform) {
		
		if (rect == null) return;
		rect = clipRect(rect);
		
		if (!nmeLocked) {
			
			nmeBuildLease();
			var ctx:CanvasRenderingContext2D = handle().getContext('2d');
			
			var imagedata = ctx.getImageData(rect.x, rect.y, rect.width, rect.height);
			var offsetX:Int;
			
			for (i in 0...imagedata.data.length >> 2) {
				
				offsetX = i * 4;
				imagedata.data[offsetX] = Std.int((imagedata.data[offsetX] * colorTransform.redMultiplier) + colorTransform.redOffset);
				imagedata.data[offsetX + 1] = Std.int((imagedata.data[offsetX + 1] * colorTransform.greenMultiplier) + colorTransform.greenOffset);
				imagedata.data[offsetX + 2] = Std.int((imagedata.data[offsetX + 2] * colorTransform.blueMultiplier) + colorTransform.blueOffset);
				imagedata.data[offsetX + 3] = Std.int((imagedata.data[offsetX + 3] * colorTransform.alphaMultiplier) + colorTransform.alphaOffset);
				
			}
			
			ctx.putImageData(imagedata, rect.x, rect.y);
			
		} else {
			
			var s = 4 * (Math.round(rect.x) + (Math.round(rect.y) * nmeImageData.width));
			var offsetY:Int;
			var offsetX:Int;
			
			for (i in 0...Math.round(rect.height)) {
				
				offsetY = (i * nmeImageData.width);
				
				for (j in 0...Math.round(rect.width)) {
					
					offsetX = 4 * (j + offsetY);
					nmeImageData.data[s + offsetX] = Std.int((nmeImageData.data[s + offsetX] * colorTransform.redMultiplier) + colorTransform.redOffset);
					nmeImageData.data[s + offsetX + 1] = Std.int((nmeImageData.data[s + offsetX + 1] * colorTransform.greenMultiplier) + colorTransform.greenOffset);
					nmeImageData.data[s + offsetX + 2] = Std.int((nmeImageData.data[s + offsetX + 2] * colorTransform.blueMultiplier) + colorTransform.blueOffset);
					nmeImageData.data[s + offsetX + 3] = Std.int((nmeImageData.data[s + offsetX + 3] * colorTransform.alphaMultiplier) + colorTransform.alphaOffset);
					
				}
				
			}
			
			nmeImageDataChanged = true;
			
		}
		
	}
	
	
	public function compare(inBitmapTexture:BitmapData):Int {
		
		throw "bitmapData.compare is currently not supported for HTML5";
		return 0x00000000;
		
	}
	
	
	public function copyChannel(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, sourceChannel:Int, destChannel:Int):Void {
		
		rect = clipRect(rect);
		if (rect == null) return;
		
		if (sourceBitmapData.handle() == null || _nmeTextureBuffer == null || sourceRect.width <= 0 || sourceRect.height <= 0 ) return;
		if (sourceRect.x + sourceRect.width > sourceBitmapData.handle().width) sourceRect.width = sourceBitmapData.handle().width - sourceRect.x;
		if (sourceRect.y + sourceRect.height > sourceBitmapData.handle().height) sourceRect.height = sourceBitmapData.handle().height - sourceRect.y;
		
		var doChannelCopy = function(imageData:ImageData) {
			
			var srcCtx:CanvasRenderingContext2D = sourceBitmapData.handle().getContext('2d');
			var srcImageData = srcCtx.getImageData(sourceRect.x, sourceRect.y, sourceRect.width, sourceRect.height);
			
			var destIdx = -1;
			
			if (destChannel == BitmapDataChannel.ALPHA) { 
				
				destIdx = 3;
				
			} else if (destChannel == BitmapDataChannel.BLUE) {
				
				destIdx = 2;
				
			} else if (destChannel == BitmapDataChannel.GREEN) {
				
				destIdx = 1;
				
			} else if (destChannel == BitmapDataChannel.RED) {
				
				destIdx = 0;
				
			} else {
				
				throw "Invalid destination BitmapDataChannel passed to BitmapData::copyChannel.";
				
			}
			
			var pos = 4 * (Math.round(destPoint.x) + (Math.round(destPoint.y) * imageData.width)) + destIdx;
			var boundR = Math.round(4 * (destPoint.x + sourceRect.width));
			
			var setPos = function(val:Int) {
				
				if ((pos % (imageData.width * 4)) > boundR - 1) {
					
					pos += imageData.width * 4 - boundR;
					
				}
				
				imageData.data[pos] = val;
				pos += 4;
				
			}
			
			var srcIdx = -1;
			
			if (sourceChannel == BitmapDataChannel.ALPHA) {
				
				srcIdx = 3;
				
			} else if (sourceChannel == BitmapDataChannel.BLUE) {
				
				srcIdx = 2;
				
			} else if (sourceChannel == BitmapDataChannel.GREEN) {
				
				srcIdx = 1;
				
			} else if (sourceChannel == BitmapDataChannel.RED) {
				
				srcIdx = 0;
				
			} else {
				
				throw "Invalid source BitmapDataChannel passed to BitmapData::copyChannel.";
				
			}
			
			while (srcIdx < srcImageData.data.length) {
				
				setPos(srcImageData.data[srcIdx]);
				srcIdx += 4;
				
			}
			
		}
		
		if (!nmeLocked) {
			
			nmeBuildLease();
			
			var ctx:CanvasRenderingContext2D = _nmeTextureBuffer.getContext('2d');
			var imageData = ctx.getImageData(0, 0, width, height);
			
			doChannelCopy(imageData);
			ctx.putImageData(imageData, 0, 0);
			
		} else {
			
			doChannelCopy(nmeImageData);
			nmeImageDataChanged = true;
			
		}
		
	}
	
	
	public function copyPixels(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, alphaBitmapData:BitmapData = null, alphaPoint:Point = null, mergeAlpha:Bool = false):Void {
		
		if (sourceBitmapData.handle() == null || _nmeTextureBuffer == null || sourceBitmapData.handle().width == 0 || sourceBitmapData.handle().height == 0 || sourceRect.width <= 0 || sourceRect.height <= 0 ) return;
		if (sourceRect.x + sourceRect.width > sourceBitmapData.handle().width) sourceRect.width = sourceBitmapData.handle().width - sourceRect.x;
		if (sourceRect.y + sourceRect.height > sourceBitmapData.handle().height) sourceRect.height = sourceBitmapData.handle().height - sourceRect.y;
		
		if (!nmeLocked) {
			
			nmeBuildLease();
			
			var ctx:CanvasRenderingContext2D = _nmeTextureBuffer.getContext('2d');
			
			if (nmeTransparent && sourceBitmapData.nmeTransparent) {
				
				var trpCtx:CanvasRenderingContext2D = sourceBitmapData.nmeTransparentFiller.getContext('2d');
				var trpData = trpCtx.getImageData(sourceRect.x, sourceRect.y, sourceRect.width, sourceRect.height);
				ctx.putImageData(trpData, destPoint.x, destPoint.y);
				
			}
			
			ctx.drawImage(sourceBitmapData.handle(), sourceRect.x, sourceRect.y, sourceRect.width, sourceRect.height, destPoint.x, destPoint.y, sourceRect.width, sourceRect.height);
			
		} else {
			
			nmeCopyPixelList[nmeCopyPixelList.length] = { handle: sourceBitmapData.handle(), transparentFiller: sourceBitmapData.nmeTransparentFiller, sourceX: sourceRect.x, sourceY: sourceRect.y, sourceWidth: sourceRect.width, sourceHeight: sourceRect.height, destX: destPoint.x, destY: destPoint.y };
			
		}
		
	}
	
	
	public function destroy():Void {
		
		_nmeTextureBuffer = null;
		
	}
	
	
	public function dispose():Void {
		
		nmeClearCanvas();
		_nmeTextureBuffer = null;
		nmeLeaseNum = 0;
		nmeLease = null;
		nmeImageData = null;
		
	}
	
	
	public function draw(source:IBitmapDrawable, matrix:Matrix = null, inColorTransform:ColorTransform = null, blendMode:BlendMode = null, clipRect:Rectangle = null, smoothing:Bool = false):Void {
		
		nmeBuildLease();
		source.drawToSurface(handle(), matrix, inColorTransform, blendMode, clipRect, smoothing);
		
		if (inColorTransform != null) {
			
			var rect = new Rectangle();
			var object:DisplayObject = cast source;
			
			rect.x = matrix != null ? matrix.tx : 0;
			rect.y = matrix != null ? matrix.ty : 0;
			
			try {
				
				rect.width = Reflect.getProperty(source, "width");
				rect.height = Reflect.getProperty(source, "height");
				
			} catch(e:Dynamic) {
				
				rect.width = handle().width;
				rect.height = handle().height;
				
			}
			
			this.colorTransform(rect, inColorTransform);
			
		}
		
	}
	
	
	public function drawToSurface(inSurface:Dynamic, matrix:Matrix, inColorTransform:ColorTransform, blendMode:BlendMode, clipRect:Rectangle, smothing:Bool):Void {
		
		nmeBuildLease();
		var ctx:CanvasRenderingContext2D = inSurface.getContext('2d');
		
		if (matrix != null) {
			
			ctx.save();
			
			if (matrix.a == 1 && matrix.b == 0 && matrix.c == 0 && matrix.d == 1) {
				
				ctx.translate(matrix.tx, matrix.ty);
				
			} else {
				
				ctx.setTransform(matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty);
				
			}
			
			ctx.drawImage(handle(), 0, 0);
			ctx.restore();
			
		} else {
			
			ctx.drawImage(handle(), 0, 0);
			
		}
		
		if (inColorTransform != null) {
			
			this.colorTransform(new Rectangle(0, 0, handle().width, handle().height), inColorTransform);
			
		}
		
	}
	
	
	public function fillRect(rect:Rectangle, color:Int):Void {
		
		if (rect == null) return;
		if (rect.width <= 0 || rect.height <= 0) return;
		
		if (rect.x == 0 && rect.y == 0 && rect.width == _nmeTextureBuffer.width && rect.height == _nmeTextureBuffer.height) {
			
			if (nmeTransparent) {
				
				if ((color >>> 24 == 0) || color == nmeInitColor) {
					
					return nmeClearCanvas();
					
				}
				
			} else {
				
				if ((color | 0xFF000000) == (nmeInitColor | 0xFF000000)) {
					
					return nmeClearCanvas();
					
				}
				
			}
			
		}
		
		return nmeFillRect(rect, color);
		
	}
	
	
	public function floodFill(x:Int, y:Int, color:Int):Void
   {
	   //nmeFloodFill (x, y, color, getPixel32(x, y));
	   clear(color);
   }
	
	
	public function getColorBoundsRect(mask:Int, color:Int, findColor:Bool = true):Rectangle {
		
		var me = this;
		
		var doGetColorBoundsRect = function(data:Uint8ClampedArray) {
			
			var minX = me.width, maxX = 0, minY = me.height, maxY = 0, i = 0;
			
			while (i < data.length) {
				
				var value = me.getInt32(i, data);
				
				if (findColor) {
					
					if ((value & mask) == color) {
						
						var x = Math.round((i % (me.width * 4)) / 4);
						var y = Math.round(i / (me.width * 4));
						
						if (x < minX) minX = x;
						if (x > maxX) maxX = x;
						if (y < minY) minY = y;
						if (y > maxY) maxY = y;
						
					}
					
				} else {
					
					if ((value & mask) != color) {
						
						var x = Math.round((i % (me.width * 4)) / 4);
						var y = Math.round(i / (me.width * 4));
						
						if (x < minX) minX = x;
						if (x > maxX) maxX = x;
						if (y < minY) minY = y;
						if (y > maxY) maxY = y;
						
					}
					
				}
				
				i += 4;
				
			}
			
			if (minX < maxX && minY < maxY) {
				
				return new Rectangle(minX, minY, maxX - minX + 1 /* +1 - bug? */, maxY - minY);
				
			} else {
				
				return new Rectangle(0, 0, me.width, me.height);
				
			}
			
		}
		
		if (!nmeLocked) {
			
			var ctx = _nmeTextureBuffer.getContext('2d');
			var imageData = ctx.getImageData(0, 0, width, height);
			
			return doGetColorBoundsRect(imageData.data);
			
		} else {
			
			return doGetColorBoundsRect(nmeImageData.data);
			
		}
		
	}
	
	
	private function getInt32(offset:Int, data:Uint8ClampedArray) {
		
		// code to deal with 31-bit ints.
		
		var b5, b6, b7, b8, pow = Math.pow;
		
		b5 = if (!nmeTransparent) 0xFF; else data[offset + 3] & 0xFF;
		b6 = data[offset] & 0xFF;
		b7 = data[offset + 1] & 0xFF;
		b8 = data[offset + 2] & 0xFF;
		
		return untyped {
			
			parseInt(((b5 >> 7) * pow(2, 31)).toString(2), 2) + parseInt((((b5 & 0x7F) << 24) |(b6 << 16) |(b7 << 8) | b8).toString(2), 2);
			
		}
		
	}
	
	
	public function getPixel(x:Int, y:Int):Int {
		
		if (x < 0 || y < 0 || x >= this.width || y >= this.height) return 0;
		
		if (!nmeLocked) {
			
			var ctx:CanvasRenderingContext2D = _nmeTextureBuffer.getContext('2d');
			var imagedata = ctx.getImageData(x, y, 1, 1);
			
			return (imagedata.data[0] << 16) |(imagedata.data[1] << 8) |(imagedata.data[2]);
			
		} else {
			
			var offset = (4 * y * width + x * 4);
			
			return (nmeImageData.data[offset] << 16) |(nmeImageData.data[offset + 1] << 8) |(nmeImageData.data[offset + 2]);
			
		}
		
	}
	
	
	public function getPixel32(x:Int, y:Int) {
		
		if (x < 0 || y < 0 || x >= this.width || y >= this.height) return 0;
		
		if (!nmeLocked) {
			
			var ctx:CanvasRenderingContext2D = _nmeTextureBuffer.getContext('2d');
			return getInt32(0, ctx.getImageData(x, y, 1, 1).data);
			
		} else {
			
			return getInt32((4 * y * _nmeTextureBuffer.width + x * 4), nmeImageData.data);
			
		}
		
	}
	
	
	public function getPixels(rect:Rectangle):ByteArray {
		
		var len = Math.round(4 * rect.width * rect.height);
		var byteArray = new ByteArray();
		byteArray.length = len;
		//var byteArray = new ByteArray(len);
		
		rect = clipRect(rect);
		if (rect == null) return byteArray;
		
		if (!nmeLocked) {
			
			var ctx:CanvasRenderingContext2D = _nmeTextureBuffer.getContext('2d');
			var imagedata = ctx.getImageData(rect.x, rect.y, rect.width, rect.height);
			
			for (i in 0...len) {
				
				byteArray.writeByte(imagedata.data[i]);
				
			}
			
		} else {
			
			var offset = Math.round(4 * nmeImageData.width * rect.y + rect.x * 4);
			var pos = offset;
			var boundR = Math.round(4 * (rect.x + rect.width));
			
			for (i in 0...len) {
				
				if (((pos) % (nmeImageData.width * 4)) > boundR - 1) {
					
					pos += nmeImageData.width * 4 - boundR;
					
				}
				
				byteArray.writeByte(nmeImageData.data[pos]);
				pos++;
				
			}
			
		}
		
		byteArray.position = 0;
		return byteArray;
		
	}

	inline public static function getRGBAPixels(bitmapData:BitmapData):ByteArray {

		var p = bitmapData.getPixels(new Rectangle(0, 0, bitmapData.width, bitmapData.height));
		var num = bitmapData.width * bitmapData.height;

        p.position = 0;
		for (i in 0...num) {
            var pos = p.position;

			var alpha = p.readByte();
			var red = p.readByte();
			var green = p.readByte();
			var blue = p.readByte();

            p.position = pos;
			p.writeByte(red);
			p.writeByte(green);
			p.writeByte(blue);
			p.writeByte(alpha);

		}

		return p;
	}
	
	
	public inline function handle() {
		
		return _nmeTextureBuffer;
		
	}
	
	
	public function hitTest(firstPoint:Point, firstAlphaThreshold:Int, secondObject:Dynamic, secondBitmapDataPoint:Point = null, secondAlphaThreshold:Int = 1):Bool {
		
		var type = Type.getClassName(Type.getClass(secondObject));
		firstAlphaThreshold = firstAlphaThreshold & 0xFFFFFFFF;
		
		var me = this;
		var doHitTest = function(imageData:ImageData) {
			
			// TODO: Use standard Haxe Type and Reflect classes?
			if (secondObject.__proto__ == null || secondObject.__proto__.__class__ == null || secondObject.__proto__.__class__.__name__ == null) return false;
			
			switch (secondObject.__proto__.__class__.__name__[2]) {
				
				case "Rectangle":
					
					var rect:Rectangle = cast secondObject;
					rect.x -= firstPoint.x;
					rect.y -= firstPoint.y;
					
					rect = me.clipRect(me.rect);
					if (me.rect == null) return false;
					
					var boundingBox = new Rectangle(0, 0, me.width, me.height);
					if (!rect.intersects(boundingBox)) return false;
					
					var diff = rect.intersection(boundingBox);
					var offset = 4 * (Math.round(diff.x) + (Math.round(diff.y) * imageData.width)) + 3;
					var pos = offset;
					var boundR = Math.round(4 * (diff.x + diff.width));
					
					while (pos < offset + Math.round(4 * (diff.width + imageData.width * diff.height))) {
						
						if ((pos % (imageData.width * 4)) > boundR - 1) {
							
							pos += imageData.width * 4 - boundR;
							
						}
						
						if (imageData.data[pos] - firstAlphaThreshold >= 0) return true;
						pos += 4;
						
					}
					
					return false;
				
				case "Point":
					
					var point : Point = cast secondObject;
					var x = point.x - firstPoint.x;
					var y = point.y - firstPoint.y;
					
					if (x < 0 || y < 0 || x >= me.width || y >= me.height) return false;
					if (imageData.data[Math.round(4 * (y * me.width + x)) + 3] - firstAlphaThreshold > 0) return true;
					
					return false;
				
				case "Bitmap":
					
					throw "bitmapData.hitTest with a second object of type Bitmap is currently not supported for HTML5";
					return false;
				
				case "BitmapData":
					
					throw "bitmapData.hitTest with a second object of type BitmapData is currently not supported for HTML5";
					return false;
				
				default:
					
					throw "BitmapData::hitTest secondObject argument must be either a Rectangle, a Point, a Bitmap or a BitmapData object.";
					return false;
				
			}
			
		}
		
		if (!nmeLocked) {
			
			nmeBuildLease();
			var ctx:CanvasRenderingContext2D = _nmeTextureBuffer.getContext('2d');
			var imageData = ctx.getImageData(0, 0, width, height);
			
			return doHitTest(imageData);
			
		} else {
			
			return doHitTest(nmeImageData);
			
		}
		
	}
	
	
	public static function loadFromBytes(bytes:ByteArray, inRawAlpha:ByteArray = null, onload:BitmapData -> Void) {
		
		var bitmapData = new BitmapData(0, 0);
		bitmapData.nmeLoadFromBytes(bytes, inRawAlpha, onload);
		return bitmapData;
		
	}
	
	
	public function lock():Void {
		
		nmeLocked = true;
		var ctx:CanvasRenderingContext2D = _nmeTextureBuffer.getContext('2d');
		nmeImageData = ctx.getImageData(0, 0, width, height);
		nmeImageDataChanged = false;
		nmeCopyPixelList = [];
		
	}
	
	
	private static function nmeBase64Encode(bytes:ByteArray) {
		
		var blob = "";
		var codex = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
		bytes.position = 0;
		
		while (bytes.position < bytes.length) {
			
			var by1 = 0, by2 = 0, by3 = 0;
			
			by1 = bytes.readByte();
			
			if (bytes.position < bytes.length) by2 = bytes.readByte();
			if (bytes.position < bytes.length) by3 = bytes.readByte();
			
			var by4 = 0, by5 = 0, by6 = 0, by7 = 0;
			
			by4 = by1 >> 2;
			by5 = ((by1 & 0x3) << 4) |(by2 >> 4);
			by6 = ((by2 & 0xF) << 2) |(by3 >> 6);
			by7 = by3 & 0x3F;
			
			blob += codex.charAt(by4);
			blob += codex.charAt(by5);
			
			if (bytes.position < bytes.length) {
				
				blob += codex.charAt(by6);
				
			} else {
				
				blob += "=";
				
			}
			
			if (bytes.position < bytes.length) {
				
				blob += codex.charAt(by7);
				
			} else {
				
				blob += "=";
				
			}
			
		}
		
		return blob;
		
	}
	
	
	private inline function nmeBuildLease():Void {
		
		nmeLease.set(nmeLeaseNum++, Date.now().getTime());
		
	}
	
	
	public inline function nmeClearCanvas():Void {
		
		var ctx:CanvasRenderingContext2D = _nmeTextureBuffer.getContext('2d');
		ctx.clearRect(0, 0, _nmeTextureBuffer.width, _nmeTextureBuffer.height);
		//_nmeTextureBuffer.width = _nmeTextureBuffer.width;
		
	}
	
	
	public static function nmeCreateFromHandle(inHandle:CanvasElement):BitmapData {
		
		var result = new BitmapData(0, 0);
		result._nmeTextureBuffer = inHandle;
		return result;
		
	}
	
	
	public function nmeDecrNumRefBitmaps():Void {
		
		nmeAssignedBitmaps--;
		
	}
	
	
	private function nmeFillRect(rect:Rectangle, color:Int) {
		
		nmeBuildLease();
		
		var ctx:CanvasRenderingContext2D = _nmeTextureBuffer.getContext('2d');
		
		var r = (color & 0xFF0000) >>> 16;
		var g = (color & 0x00FF00) >>> 8;
		var b = (color & 0x0000FF);
		var a = (nmeTransparent) ?(color >>> 24) : 0xFF;
		
		if (!nmeLocked) {
			
			if (nmeTransparent) {
				
				var trpCtx:CanvasRenderingContext2D = nmeTransparentFiller.getContext('2d');
				var trpData = trpCtx.getImageData(rect.x, rect.y, rect.width, rect.height);
				
				ctx.putImageData(trpData, rect.x, rect.y);
				
			}
			
			var style = 'rgba(' + r + ', ' + g + ', ' + b + ', ' + (a / 255) + ')';
			
			ctx.fillStyle = style;
			ctx.fillRect(rect.x, rect.y, rect.width, rect.height);
			
		} else {
			
			var s = 4 * (Math.round(rect.x) + (Math.round(rect.y) * nmeImageData.width));
			var offsetY:Int;
			var offsetX:Int;
			
			for (i in 0...Math.round(rect.height)) {
				
				offsetY = (i * nmeImageData.width);
				
				for (j in 0...Math.round(rect.width)) {
					
					offsetX = 4 * (j + offsetY);
					nmeImageData.data[s + offsetX] = r;
					nmeImageData.data[s + offsetX + 1] = g;
					nmeImageData.data[s + offsetX + 2] = b;
					nmeImageData.data[s + offsetX + 3] = a;
					
				}
				
			}
			
			nmeImageDataChanged = true;
			ctx.putImageData(nmeImageData, 0, 0, rect.x, rect.y, rect.width, rect.height);
			
		}
		
	}
	
	
	private function nmeFloodFill(x:Int, y:Int, color:Int, replaceColor:Int):Void
   {
	   if (getPixel32(x, y) == replaceColor) {
		   
		   setPixel32(x, y, color);
		   nmeFloodFill(x + 1, y, color, replaceColor);
		   nmeFloodFill(x + 1, y + 1, color, replaceColor);
		   nmeFloodFill(x + 1, y - 1, color, replaceColor);
		   nmeFloodFill(x - 1, y, color, replaceColor);
		   nmeFloodFill(x - 1, y + 1, color, replaceColor);
		   nmeFloodFill(x - 1, y - 1, color, replaceColor);
		   nmeFloodFill(x, y + 1, color, replaceColor);
		   nmeFloodFill(x, y - 1, color, replaceColor);
		   
	   }
   }
	
	
	public inline function nmeGetLease():ImageDataLease {
		
		return nmeLease;
		
	}
	
	
	private inline function nmeLoadFromBytes(bytes:ByteArray, inRawAlpha:ByteArray = null, ?onload:BitmapData -> Void) {
		
		var type = "";
		
		if (nmeIsPNG(bytes)) {
			
			type = "image/png";
			
		} else if (nmeIsJPG(bytes)) {
			
			type = "image/jpeg";
			
		} else {
			
			throw new IOError("BitmapData tried to read a PNG/JPG ByteArray, but found an invalid header.");
			
		}
		
		var img:ImageElement = cast Browser.document.createElement("img");
		var canvas = _nmeTextureBuffer;
		
		var drawImage = function(_) {
			
			canvas.width = img.width;
			canvas.height = img.height;
			
			var ctx = canvas.getContext('2d');
			ctx.drawImage(img, 0, 0);
			
			if (inRawAlpha != null) {
				
				var pixels = ctx.getImageData(0, 0, img.width, img.height);
				
				for (i in 0...inRawAlpha.length) {
					
					pixels.data[i * 4 + 3] = inRawAlpha.readUnsignedByte();
					
				}
				
				ctx.putImageData(pixels, 0, 0);
				
			}
			
			rect = new Rectangle (0, 0, canvas.width, canvas.height);
			
			if (onload != null) {
				
				onload(this);
				
			}
			
		}
		
		img.addEventListener("load", drawImage, false);
		img.src = 'data:$type;base64,${nmeBase64Encode(bytes)}';
		
	}
	
	
	public function nmeGetNumRefBitmaps():Int {
		
		return nmeAssignedBitmaps;
		
	}
	
	
	public function nmeIncrNumRefBitmaps():Void {
		
		nmeAssignedBitmaps++;
		
	}
	
	
	private static function nmeIsJPG(bytes:ByteArray) {
		
		bytes.position = 0;
		return bytes.readByte() == 0xFF && bytes.readByte() == 0xD8;
		/*if (bytes.readByte() == 0xFF && bytes.readByte() == 0xD8 && bytes.readByte() == 0xFF) {
			
			bytes.readByte();
			bytes.readByte();
			bytes.readByte();
			
			if (bytes.readByte() == 0x4A && bytes.readByte() == 0x46 && bytes.readByte() == 0x49 && bytes.readByte() == 0x46 && bytes.readByte() == 0x00) {
				
				return true;
				
			}
			
		}
		
		return false;
        */
	}
	
	
	private static function nmeIsPNG(bytes:ByteArray) {
		
		bytes.position = 0;
		return (bytes.readByte() == 0x89 && bytes.readByte() == 0x50 && bytes.readByte() == 0x4E && bytes.readByte() == 0x47 && bytes.readByte() == 0x0D && bytes.readByte() == 0x0A && bytes.readByte() == 0x1A && bytes.readByte() == 0x0A);
		
	}
	
	
	public function nmeLoadFromFile(inFilename:String, inLoader:LoaderInfo = null) {
		
		var image:ImageElement = cast Browser.document.createElement("img");
		
		if (inLoader != null) {
			
			var data:LoadData = { image: image, texture: _nmeTextureBuffer, inLoader: inLoader, bitmapData: this };
			
			image.addEventListener("load", nmeOnLoad.bind (data), false);
			// IE9 bug, force a load, if error called and complete is false.
			image.addEventListener("error", function(e) { if (!image.complete) nmeOnLoad(data, e); }, false);
			
		}
		
		image.src = inFilename;
		
		// Another IE9 bug: loading 20+ images fails unless this line is added.
		// (issue #1019768)
		if (image.complete) { }
		
	}
	
	
	public function noise(randomSeed:Int, low:Int = 0, high:Int = 255, channelOptions:Int = 7, grayScale:Bool = false):Void {
		
		var generator = new MinstdGenerator(randomSeed);
		var ctx:CanvasRenderingContext2D = _nmeTextureBuffer.getContext('2d');
		
		var imageData = null;
		
		if (nmeLocked) {
			
			imageData = nmeImageData;
			
		} else {
			
			imageData = ctx.createImageData(_nmeTextureBuffer.width, _nmeTextureBuffer.height);
			
		}
		
		for (i in 0...(_nmeTextureBuffer.width * _nmeTextureBuffer.height)) {
			
			if (grayScale) {
				
				imageData.data[i * 4] = imageData.data[i * 4 + 1] = imageData.data[i * 4 + 2] = low + generator.nextValue() % (high - low + 1);
				
			} else {
				
				imageData.data[i * 4] = if (channelOptions & BitmapDataChannel.RED == 0) 0 else low + generator.nextValue() % (high - low + 1);
				imageData.data[i * 4 + 1] = if (channelOptions & BitmapDataChannel.GREEN == 0) 0 else low + generator.nextValue() % (high - low + 1);
				imageData.data[i * 4 + 2] = if (channelOptions & BitmapDataChannel.BLUE == 0) 0 else low + generator.nextValue() % (high - low + 1);
				
			}
			
			imageData.data[i * 4 + 3] = if (channelOptions & BitmapDataChannel.ALPHA == 0) 255 else low + generator.nextValue() % (high - low + 1);
			
		}
		
		if (nmeLocked) {
			
			nmeImageDataChanged = true;
			
		} else {
			
			ctx.putImageData(imageData, 0, 0);
			
		}
		
	}
	
	
	public function scroll(x:Int, y:Int):Void {
		
		throw("bitmapData.scroll is currently not supported for HTML5");
		
	}
	
	
	public function setPixel(x:Int, y:Int, color:Int):Void {
		
		if (x < 0 || y < 0 || x >= this.width || y >= this.height) return;
		
		if (!nmeLocked) {
			
			nmeBuildLease();
			
			var ctx:CanvasRenderingContext2D = _nmeTextureBuffer.getContext('2d');
			
			var imageData = ctx.createImageData(1, 1);
			imageData.data[0] = (color & 0xFF0000) >>> 16;
			imageData.data[1] = (color & 0x00FF00) >>> 8;
			imageData.data[2] = (color & 0x0000FF);
			if (nmeTransparent) imageData.data[3] = (0xFF);
			
			ctx.putImageData(imageData, x, y);
			
		} else {
			
			var offset = (4 * y * nmeImageData.width + x * 4);
			
			nmeImageData.data[offset] = (color & 0xFF0000) >>> 16;
			nmeImageData.data[offset + 1] = (color & 0x00FF00) >>> 8;
			nmeImageData.data[offset + 2] = (color & 0x0000FF);
			if (nmeTransparent) nmeImageData.data[offset + 3] = (0xFF);
			
			nmeImageDataChanged = true;
			
		}
		
	}
	
	
	public function setPixel32(x:Int, y:Int, color:Int):Void {
		
		if (x < 0 || y < 0 || x >= this.width || y >= this.height) return;
		
		if (!nmeLocked) {
			
			nmeBuildLease();
			
			var ctx:CanvasRenderingContext2D = _nmeTextureBuffer.getContext('2d');
			var imageData = ctx.createImageData(1, 1);
			
			imageData.data[0] = (color & 0xFF0000) >>> 16;
			imageData.data[1] = (color & 0x00FF00) >>> 8;
			imageData.data[2] = (color & 0x0000FF);
			
			if (nmeTransparent) {
				
				imageData.data[3] = (color & 0xFF000000) >>> 24;
				
			} else {
				
				imageData.data[3] = (0xFF);
				
			}
			
			ctx.putImageData(imageData, x, y);
			
		} else {
			
			var offset = (4 * y * nmeImageData.width + x * 4);
			
			nmeImageData.data[offset] = (color & 0x00FF0000) >>> 16;
			nmeImageData.data[offset + 1] = (color & 0x0000FF00) >>> 8;
			nmeImageData.data[offset + 2] = (color & 0x000000FF);
			
			if (nmeTransparent) {
				
				nmeImageData.data[offset + 3] = (color & 0xFF000000) >>> 24;
				
			} else {
				
				nmeImageData.data[offset + 3] = (0xFF);
				
			}
			
			nmeImageDataChanged = true;
			
		}
		
	}
	
	
	public function setPixels(rect:Rectangle, byteArray:ByteArray):Void {
		
		rect = clipRect(rect);
		if (rect == null) return;
		
		var len = Math.round(4 * rect.width * rect.height);
		
		if (!nmeLocked) {
			
			var ctx:CanvasRenderingContext2D = _nmeTextureBuffer.getContext('2d');
			var imageData = ctx.createImageData(rect.width, rect.height);
			
			for (i in 0...len) {
				
				imageData.data[i] = byteArray.readByte();
				
			}
			
			ctx.putImageData(imageData, rect.x, rect.y);
			
		} else {
			
			var offset = Math.round(4 * nmeImageData.width * rect.y + rect.x * 4);
			var pos = offset;
			var boundR = Math.round(4 * (rect.x + rect.width));
			
			for (i in 0...len) {
				
				if (((pos) % (nmeImageData.width * 4)) > boundR - 1) {
					
					pos += nmeImageData.width * 4 - boundR;
					
				}
				
				nmeImageData.data[pos] = byteArray.readByte();
				pos++;
				
			}
			
			nmeImageDataChanged = true;
			
		}
		
	}
	
	
	public function threshold(sourceBitmapData:BitmapData, sourceRect:Rectangle, destPoint:Point, operation:String, threshold:Int, color:Int = 0, mask:Int = 0xFFFFFFFF, copySource:Bool = false):Int {
		
		trace("BitmapData.threshold not implemented");
		return 0;
		
	}
	
	
	public function unlock(changeRect:Rectangle = null):Void {
		
		nmeLocked = false;
		
		var ctx:CanvasRenderingContext2D = _nmeTextureBuffer.getContext('2d');
		
		if (nmeImageDataChanged) {
			
			if (changeRect != null) {
				
				ctx.putImageData(nmeImageData, 0, 0, changeRect.x, changeRect.y, changeRect.width, changeRect.height);
				
			} else {
				
				ctx.putImageData(nmeImageData, 0, 0);
				
			}
			
		}
		
		for (copyCache in nmeCopyPixelList) {
			
			if (nmeTransparent && copyCache.transparentFiller != null) {
				
				var trpCtx:CanvasRenderingContext2D = copyCache.transparentFiller.getContext('2d');
				var trpData = trpCtx.getImageData(copyCache.sourceX, copyCache.sourceY, copyCache.sourceWidth, copyCache.sourceHeight);
				ctx.putImageData(trpData, copyCache.destX, copyCache.destY);
				
			}
			
			ctx.drawImage(copyCache.handle, copyCache.sourceX, copyCache.sourceY, copyCache.sourceWidth, copyCache.sourceHeight, copyCache.destX, copyCache.destY, copyCache.sourceWidth, copyCache.sourceHeight);
			
		}
		
		nmeBuildLease();
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function nmeOnLoad(data:LoadData, e) {
		
		var canvas:CanvasElement = cast data.texture;
		var width = data.image.width;
		var height = data.image.height;
		canvas.width = width;
		canvas.height = height;
		
		// TODO: Should copy later, only if the bitmapData is going to be modified
		
		var ctx:CanvasRenderingContext2D = canvas.getContext("2d");
		ctx.drawImage(data.image, 0, 0, width, height);
		
		data.bitmapData.width = width;
		data.bitmapData.height = height;
		data.bitmapData.rect = new Rectangle(0, 0, width, height);
		data.bitmapData.nmeBuildLease();
		
		if (data.inLoader != null) {
			
			var e = new Event(Event.COMPLETE);
			e.target = data.inLoader;
			data.inLoader.dispatchEvent(e);
			
		}
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private inline function get_height():Int {
		
		if ( _nmeTextureBuffer != null ) {
			
			return _nmeTextureBuffer.height;
			
		} else {
			
			return 0;
			
		}
		
	}
	
	
	private function get_transparent():Bool {
		
		return nmeTransparent;
		
	}
	
	
	private inline function get_width():Int {
		
		if ( _nmeTextureBuffer != null ) {
			
			return _nmeTextureBuffer.width;
			
		} else {
			
			return 0;
			
		}
		
	}
	
	
}


typedef LoadData = {
	
	var image:ImageElement;
	var texture:CanvasElement;
	var inLoader:Null<LoaderInfo>;
	var bitmapData:BitmapData;
	
}


class ImageDataLease {
	
	
	public var seed:Float;
	public var time:Float;
	
	
	public function new() {
		
		
		
	}
	
	
	public function clone():ImageDataLease {
		
		var leaseClone = new ImageDataLease();
		leaseClone.seed = seed;
		leaseClone.time = time;
		return leaseClone;
		
	}
	
	
	public function set(s:Float, t:Float):Void { 
		
		this.seed = s;
		this.time = t;
		
	}
	
	
}


typedef CopyPixelAtom = {
	
	var handle:CanvasElement;
	var transparentFiller:CanvasElement;
	var sourceX:Float;
	var sourceY:Float;
	var sourceWidth:Float;
	var sourceHeight:Float;
	var destX:Float;
	var destY:Float;
	
}


private class MinstdGenerator {
	
	/** A MINSTD pseudo-random number generator.
	 *
	 * This generates a pseudo-random number sequence equivalent to std::minstd_rand0 from the C++ standard library, which
	 * is the generator that Flash uses to generate noise for BitmapData.noise().
	 *
	 * MINSTD was originally suggested in "A pseudo-random number generator for the System/360", P.A. Lewis, A.S. Goodman,
	 * J.M. Miller, IBM Systems Journal, Vol. 8, No. 2, 1969, pp. 136-146 */
	
	private static inline var a = 16807;
	private static inline var m = (1 << 31) - 1;

	private var value:Int;
	

	public function new(seed:Int) {
		
		if (seed == 0) {
			
			this.value = 1;
			
		} else {
			
			this.value = seed;
			
		}
		
	}
	
	
	public function nextValue():Int {
		
		var lo = a * (value & 0xffff);
		var hi = a * (value >>> 16);
		lo += (hi & 0x7fff) << 16;
		
		if (lo < 0 || lo > m) {
			
			lo &= m;
			++lo;
			
		}
		
		lo += hi >>> 15;
		
		if (lo < 0 || lo > m) {
			
			lo &= m;
			++lo;
			
		}
		
		return value = lo;
		
	}
	
	
}


#end