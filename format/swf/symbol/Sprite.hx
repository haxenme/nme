package format.swf.symbol;


import flash.display.BlendMode;
import flash.filters.BitmapFilter;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import format.swf.data.Filters;
import format.swf.data.Frame;
import format.swf.data.SWFStream;
import format.swf.data.Tags;
import format.SWF;


class Sprite {
	
	
	public var frameCount (default, null):Int;
	public var frameLabels:Hash<Int>;
	public var frames (default, null):Array <Frame>;
	public var swf (default, null):SWF;
	
	private var blendMode:BlendMode;
	private var cacheAsBitmap:Bool;
	private var className:String;
	private var frame:Frame;
	
	private var name:String;
	
	
	public function new (swf:SWF, id:Int, frameCount:Int) {
		
		this.swf = swf;
		this.frameCount = frameCount;
		frames = [ null ]; // frame 0 is empty
		
		frame = new Frame ();
		frameLabels = new Hash <Int> ();
		name = "Sprite " + id;
		cacheAsBitmap = false;
		
	}
	
	
	public function labelFrame (name:String):Void {
		
		frameLabels.set (name, frame.frame);
		
	}
	
	
	public function placeObject (stream:SWFStream, version:Int) {
		
		if (version == 1) {
			
			var symbolID = stream.readID ();
			var symbol = swf.getSymbol (symbolID);
			var depth = stream.readDepth ();
			var matrix = stream.readMatrix ();
			
			var colorTransform:ColorTransform = null;
			
			if (stream.getBytesLeft () > 0) {
				
				colorTransform = stream.readColorTransform (false);
				
			}
			
			frame.place (symbolID, symbol, depth, matrix, colorTransform, null, null, null);
			
		} else if (version == 2 || version == 3) {
			
			stream.alignBits ();
			
			var hasClipAction = stream.readBool ();
			var hasClipDepth = stream.readBool ();
			var hasName = stream.readBool ();
			var hasRatio = stream.readBool ();
			var hasColorTransform = stream.readBool ();
			var hasMatrix = stream.readBool ();
			var hasSymbol = stream.readBool ();
			var move = stream.readBool ();
			
			var hasImage = false;
			var hasClassName = false;
			var hasCacheAsBitmap = false;
			var hasBlendMode = false;
			var hasFilterList = false;
			
			if (version == 3) {
				
				stream.readBool ();
				stream.readBool ();
				stream.readBool ();
				
				hasImage = stream.readBool ();
				hasClassName = stream.readBool ();
				hasCacheAsBitmap = stream.readBool ();
				hasBlendMode = stream.readBool ();
				hasFilterList = stream.readBool ();
				
			}
			
			var depth = stream.readDepth ();
			
			if (hasClassName) {
				
				className = stream.readString ();
				
			}
			
			var symbolID = hasSymbol ? stream.readID () : 0;
			var matrix = hasMatrix ? stream.readMatrix () : null;
			var colorTransform = hasColorTransform ? stream.readColorTransform (true) : null;
			var ratio:Null<Int> = hasRatio ? stream.readUInt16 () : null;
			var name:String = null;
			
			if (hasName || (hasImage && hasSymbol)) {
				
				name = stream.readString ();
				
			}
			
			var clipDepth = hasClipDepth ? stream.readDepth () : 0;
			var filters:Array <BitmapFilter> = null;
			
			if (hasFilterList) {
				
				filters = Filters.readFilters (stream);
				
			}
			
			if (hasBlendMode) {
				
				blendMode = switch (stream.readByte ()) {
					case 2 : BlendMode.LAYER;
					case 3 : BlendMode.MULTIPLY;
					case 4 : BlendMode.SCREEN;
					case 5 : BlendMode.LIGHTEN;
					case 6 : BlendMode.DARKEN;
					case 7 : BlendMode.DIFFERENCE;
					case 8 : BlendMode.ADD;
					case 9 : BlendMode.SUBTRACT;
					case 10 : BlendMode.INVERT;
					case 11 : BlendMode.ALPHA;
					case 12 : BlendMode.ERASE;
					case 13 : BlendMode.OVERLAY;
					case 14 : BlendMode.HARDLIGHT;
					default: BlendMode.NORMAL;
				}
				
			}
			
			if (hasBlendMode) {
				
				cacheAsBitmap = stream.readByte () > 0;
				
			}
			
			if (hasClipAction) {
				
				var reserved = stream.readID ();
				var actionFlags = stream.readID ();
				
				throw("clip action not implemented");
				
			}
			
			if (move) {
				
				if (hasSymbol) {
					
					frame.remove (depth);
					frame.place (symbolID, swf.getSymbol (symbolID), depth, matrix, colorTransform, ratio, name, filters);
					
				} else {
					
					frame.move (depth, matrix, colorTransform, ratio);
					
				}
				
			} else {
				
				frame.place (symbolID, swf.getSymbol (symbolID), depth, matrix, colorTransform, ratio, name, filters);
				
			}
			
		} else {
			
			throw ("Place object not implemented: " + version);
			
		}
		
	}
	
	
	public function removeObject (stream:SWFStream, version:Int):Void {
		
		if (version == 1) {
			
			stream.readID ();
			
		}
		
		var depth = stream.readDepth ();
		frame.remove (depth);
		
	}
	
	
	public function showFrame ():Void {
		
		frames.push (frame);
		frame = new Frame (frame);
		
	}
	
	
}