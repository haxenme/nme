package format;


import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.SimpleButton;
import flash.geom.Rectangle;
import flash.utils.ByteArray;
import format.swf.data.Frame;
import format.swf.data.SWFStream;
import format.swf.data.Tags;
import format.swf.symbol.Bitmap;
import format.swf.symbol.Button;
import format.swf.symbol.EditText;
import format.swf.symbol.Font;
import format.swf.symbol.MorphShape;
import format.swf.symbol.Sprite;
import format.swf.symbol.Shape;
import format.swf.symbol.StaticText;
import format.swf.symbol.Symbol;
import format.swf.MovieClip;


class SWF {
	
	
	public static var instances:Hash <SWF> = new Hash <SWF> ();
	
	public var backgroundColor (default, null):Int;
	public var frameRate (default, null):Float;
	public var height (default, null):Int;
	public var symbols:Hash <Int>;
	public var width (default, null):Int;
	
	private var symbolData:IntHash <Symbol>;
	private var stream:SWFStream;
	private var streamPositions:IntHash <Int>;
	private var version:Int;
	
	
	public function new (data:ByteArray) {
		
		stream = new SWFStream (data);
		
		symbolData = new IntHash <Symbol> ();
		streamPositions = new IntHash <Int> ();
		symbols = new Hash <Int> ();
		
		var dimensions = stream.readRect ();
		width = Std.int (dimensions.width);
		height = Std.int (dimensions.height);
		frameRate = stream.readFrameRate ();
		
		streamPositions.set (0, stream.position);
		var numFrames = stream.readFrames ();
		
		var tag = 0;
		var position = stream.position;
		
		while ((tag = stream.beginTag ()) != 0) {
			
			switch (tag) {
				
				case Tags.SetBackgroundColor:
					
					backgroundColor = stream.readRGB ();
				
				case Tags.DefineShape, Tags.DefineShape2, Tags.DefineShape3, Tags.DefineShape4, Tags.DefineMorphShape, Tags.DefineMorphShape2, Tags.DefineSprite, Tags.DefineBitsJPEG2, Tags.DefineBitsJPEG3, Tags.DefineBitsLossless, Tags.DefineBitsLossless2, Tags.DefineFont, Tags.DefineFont2, Tags.DefineFont3, Tags.DefineText, Tags.DefineEditText, Tags.DefineButton, Tags.DefineButton2:
					
					var id = stream.readID ();
					
					streamPositions.set (id, position);
				
				case Tags.SymbolClass:
					
					readSymbolClass ();
				
			}
			
			stream.endTag();
			position = stream.position;
			
		}
		
	}
	
	
	public function createButton (className:String):SimpleButton {
		
		var id = symbols.get (className);
		
		switch (getSymbol (id)) {
			
			case buttonSymbol (data):
				
				var b = new SimpleButton ();
				data.apply (b);
				return b;
			
			default:
				
				return null;
			
		}
		
		return null;
		
	}
	
	
	public function createMovieClip (className:String = ""):MovieClip {
		
		var id = 0;
		
		if (className != "") {
			
			if (!symbols.exists (className)) {
				
				return null;
				
			}
			
			id = symbols.get (className);
			
		}
		
		switch (getSymbol (id)) {
			
			case spriteSymbol (data):
				
				return new MovieClip (data);
			
			default:
				
				return null;
			
		}
		
		return null;
		
	}
	
	
	public function getBitmapData (className:String):BitmapData {
		
		if (!symbols.exists (className)) {
			
			return null;
			
		}
		
		switch (getSymbol (symbols.get (className))) {
			
			case bitmapSymbol (bitmap):
				
				return bitmap.bitmapData;
			
			default:
				
				return null;
			
		}
		
		return null;
		
	}
	
	
	public function getSymbol (id:Int) {
		
		if (!streamPositions.exists (id)) {
			
			throw "Invalid symbol ID (" + id + ")";
			
		}
		
		if (!symbolData.exists (id)) {
			
			var cachePosition = stream.position;
			stream.pushTag ();
			
			stream.position = streamPositions.get (id);
			
			if (id == 0) {
				
				readSprite (true);
				
			} else {
				
				switch (stream.beginTag ()) {
					
					case Tags.DefineShape: readShape (1);
					case Tags.DefineShape2: readShape (2);
					case Tags.DefineShape3: readShape (3);
					case Tags.DefineShape4: readShape (4);
					
					case Tags.DefineMorphShape: readMorphShape (1);			
					case Tags.DefineMorphShape2: readMorphShape (2);	
					
					case Tags.DefineSprite: readSprite (false);
					
					case Tags.DefineButton: readButton (1);
					case Tags.DefineButton2: readButton (2);
					
					case Tags.DefineBitsJPEG2: readBitmap (false, 2);
					case Tags.DefineBitsJPEG3: readBitmap (false, 3);
					case Tags.DefineBitsLossless: readBitmap (true, 1);
					case Tags.DefineBitsLossless2: readBitmap (true, 2);
					
					case Tags.DefineFont: readFont (1);
					case Tags.DefineFont2: readFont (2);
					case Tags.DefineFont3: readFont (3);
					
					case Tags.DefineText: readText (1);
					case Tags.DefineEditText: readEditText (1);
					
				}
				
			}
			
			stream.position = cachePosition;
			stream.popTag ();
			
		}
		
		return symbolData.get (id);
		
	}
	
	
	private inline function readBitmap (lossless:Bool, version:Int):Void {
		
		var id = stream.readID ();
		symbolData.set (id, bitmapSymbol (new Bitmap (stream, lossless, version)));
		
	}
	
	
	private inline function readButton (version:Int):Void {
		
		var id = stream.readID ();
		symbolData.set (id, buttonSymbol (new Button (this, stream, version)));
		
	}
	
	
	private inline function readEditText (version:Int):Void {
		
		var id = stream.readID ();
		symbolData.set (id, editTextSymbol (new EditText (this, stream, version)));
		
	}
	
	
	private function readFileAttributes ():Void {
		
		var flags = stream.readByte ();
		var zero = stream.readByte ();
		zero = stream.readByte ();
		zero = stream.readByte ();
		
	}
	
	
	private inline function readFont (version:Int):Void {
		
		var id = stream.readID ();
		symbolData.set (id, fontSymbol (new Font (stream, version)));
		
	}
	
	
	private inline function readMorphShape (version:Int):Void {
		
		var id = stream.readID ();
		symbolData.set (id, morphShapeSymbol (new MorphShape (this, stream, version)));
		
	}
	
	
	private inline function readShape (version:Int):Void {
		
		var id = stream.readID ();
		symbolData.set (id, shapeSymbol (new Shape (this, stream, version)));
		
	}
	
	
	private function readSprite (isStage:Bool):Void {
		
		var id:Int;
		
		if (isStage) {
			
			id = 0;
			
		} else {
			
			id = stream.readID ();
			
		}
		
		var sprite = new Sprite (this, id, stream.readFrames ());
		var tag = 0;
		
		while ((tag = stream.beginTag ()) != 0) {
			
			switch (tag) {
				
				case Tags.FrameLabel:
					
					sprite.labelFrame (stream.readString ());
				
				case Tags.ShowFrame:
					
					sprite.showFrame ();
				
				case Tags.PlaceObject:
					
					sprite.placeObject (stream, 1);
				
				case Tags.PlaceObject2:
					
					sprite.placeObject (stream, 2);
				
				case Tags.PlaceObject3:
					
					sprite.placeObject(stream, 3);
				
				case Tags.RemoveObject:
					
					sprite.removeObject (stream, 1);
				
				case Tags.RemoveObject2:
					
					sprite.removeObject (stream, 2);
				
				case Tags.DoAction:
					
					// not implemented
				
				case Tags.Protect:
					
					// ignore
				
				default:
					
					if (!isStage) {
						
						trace ("Unknown sub tag: " +  Tags.string (tag));
						
					}
				
			}
			
			stream.endTag ();
			
		}
		
		symbolData.set (id, spriteSymbol (sprite));
		
	}
	
	
	private inline function readText (version:Int):Void {
		
		var id = stream.readID ();
		symbolData.set (id, staticTextSymbol (new StaticText (this, stream, version)));
		
	}
	
	
	private inline function readSymbolClass () {
		
		var numberOfSymbols = stream.readUInt16 ();
		
		for (i in 0...numberOfSymbols) {
			
			var symbolID = stream.readUInt16 ();
			var className = stream.readString ();
			symbols.set (className, symbolID);
			
		}
		
	}
	
	
}