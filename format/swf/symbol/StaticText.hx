package format.swf.symbol;


import flash.display.Graphics;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import format.swf.data.SWFStream;
import format.swf.symbol.Symbol;
import format.SWF;


class StaticText {
	
	
	private var bounds:Rectangle;
	private var records:Array <TextRecord>;
	private var textMatrix:Matrix;
	
	
	public function new (swf:SWF, stream:SWFStream, version:Int) {
		
		stream.alignBits ();
		
		records = new Array <TextRecord> ();
		bounds = stream.readRect ();
		textMatrix = stream.readMatrix ();
		
		var glyphBits = stream.readByte ();
		var advanceBits = stream.readByte ();
		var font:Font = null;
		var height = 32.0;
		var color = 0;
		var alpha = 1.0;
		
		stream.alignBits ();
		
		while (stream.readBool ()) {
			
			stream.readBits (3);
			
			var hasFont = stream.readBool ();
			var hasColor = stream.readBool ();
			var hasY = stream.readBool ();
			var hasX = stream.readBool ();
			
			if (hasFont) {
				
				var fontID = stream.readID ();
				var symbol = swf.getSymbol (fontID);
				
				switch (symbol) {
					
					case fontSymbol (f):
						
						font = f;
					
					default:
						
						throw "Not font character";
					
				}
				
			} else if (font == null) {
				
				throw "No font - not implemented";
				
			}
			
			if (hasColor) {
				
				color = stream.readRGB ();
				
				if (version >= 2) {
					
					alpha = stream.readByte () / 255.0;
					
				}
				
			}
			
			var offsetX = hasX ? stream.readSInt16 () : 0;
			var offsetY = hasY ? stream.readSInt16 () : 0;
			
			if (hasFont) {
				
				height = stream.readUInt16 () * 0.05;
				
			}
			
			var count = stream.readByte ();
			
			var glyphs = new Array <Int> ();
			var advances = new Array <Int> ();
			
			for (i in 0...count) {
				
				glyphs.push (stream.readBits (glyphBits) );
				advances.push (stream.readBits (advanceBits, true));
				
			}
			
			records.push ( {
				
				swfFont: font,
				offsetX : offsetX,
				offsetY : offsetY,
				glyphs : glyphs,
				color : color,
				alpha : alpha,
				height : height,
				advances : advances
				
			});
			
			stream.alignBits ();
			
		}
		
	}
	
	
	public function render (graphics:Graphics) {
		
		for (record in records) {
			
			var scale = record.height / 1024;
			
			var matrix = textMatrix.clone ();
			matrix.scale (scale, scale);
			
			matrix.tx = textMatrix.tx;
			matrix.ty = textMatrix.ty;
			
			matrix.tx += record.offsetX * 0.05;
			matrix.ty += record.offsetY * 0.05;
			
			graphics.lineStyle ();
			
			for (i in 0...record.glyphs.length) {
				
				var tx = matrix.tx;
				
				graphics.beginFill (record.color, record.alpha);
				record.swfFont.renderGlyph (graphics, record.glyphs[i], matrix);
				graphics.endFill();
				
				matrix.tx += record.advances[i] * 0.05;
				
			}
			
		}
		
	}
	
	
}


typedef TextRecord = {
	
	var swfFont:Font;
	
	var offsetX:Int;
	var offsetY:Int;
	var height:Float;
	
	var color:Int;
	var alpha:Float;
	
	var glyphs:Array <Int>;
	var advances:Array <Int>;
	
}