package format.swf.symbol;


import flash.display.Graphics;
import flash.geom.Matrix;
import format.swf.data.SWFStream;


class Font {
	
	
	private var advance:Array <Float>;
	private var ascent:Float;
	private var descent:Float;
	private var fontName:String;
	private var glyphsByCode:Array <Glyph>;
	private var glyphsByIndex:Array <Glyph>;
	private var leading:Float;
	
	
	public function new (stream:SWFStream, version:Int) {
		
		glyphsByIndex = [];
		
		stream.alignBits ();
		
		var hasLayout = false;
		var hasJIS = false;
		var smallText = false;
		var isANSI = false;
		var wideOffsets = false;
		var wideCodes = false;
		var italic = false;
		var bold = false;
		var languageCode = 0;
		fontName = "font";
		
		if (version > 1) {
			
			hasLayout = stream.readBool ();
			hasJIS = stream.readBool ();
			smallText = stream.readBool ();
			isANSI = stream.readBool ();
			wideOffsets = stream.readBool ();
			wideCodes = stream.readBool ();
			italic = stream.readBool ();
			bold = stream.readBool ();
			languageCode = stream.readByte ();
			fontName = stream.readPascalString ();
			
		}
		
		var numGlyphs:Int = 0;
		var fontBytes:Int = 0;
		
		var offsets = new Array <Int> ();
		var codeOffset = 0;
		var v3scale = version > 2 ?  1.0 : 0.05;
		
		if (version > 1) {
			
			numGlyphs = stream.readUInt16 ();
			fontBytes = stream.getBytesLeft ();
			
			for (i in 0...numGlyphs) {
				
				if (wideOffsets) {
					
					offsets.push (stream.readInt ());
					
				} else {
					
					offsets.push (stream.readUInt16 ());
					
				}
				
			}
			
			if (wideOffsets) {
				
				codeOffset = stream.readInt ();
				
			} else {
				
				codeOffset = stream.readUInt16 ();
				
			}
			
			codeOffset = fontBytes - codeOffset;
			
		} else {
			
			fontBytes = stream.getBytesLeft ();
			var firstOffset = stream.readUInt16 ();
			
			// deduce numGlyphs from the first offset
			
			numGlyphs = firstOffset >> 1;
			offsets.push (firstOffset);
			
			for (i in 1...numGlyphs) {
				
				offsets.push (stream.readUInt16 ());
				
			}
			
		}
		
		stream.alignBits ();
		
		for (i in 0...numGlyphs) {
			
			if (stream.getBytesLeft () != (fontBytes - offsets[i])) {
				
				throw ("Bad offset in font stream (" + stream.getBytesLeft () + " != " + (fontBytes - offsets[i]) + ")");
				
			}
			
			var moved = false;
			
			var penX = 0.0;
			var penY = 0.0;
			
			var commands = new Array <FontCommand> ();
			
			stream.alignBits ();
			
			var fillBits = stream.readBits (4);
			var lineBits = stream.readBits (4);
			
			while (true) {
				
				var edge = stream.readBool ();
				
				if (!edge) {
					
					var newStyles = stream.readBool ();
					var newLineStyle = stream.readBool ();
					var newFillStyle1 = stream.readBool ();
					var newFillStyle0 = stream.readBool ();
					var moveTo = stream.readBool ();
					
					if (newStyles || newFillStyle1) {
						
						throw ("Fill style can't be changed here " + newStyles + ", " + newFillStyle0);
						
					}
					
					if (!moveTo) {
						
						break;
						
					}
					
					if (!newFillStyle0 && commands.length == 0) {
						
						throw ("Fill style should be defined");
						
					}
					
					var position = stream.readBits (5);
					
					penX = stream.readTwips (position) * v3scale;
					penY = stream.readTwips (position) * v3scale;
					
					var px = penX;
					var py = penY;
					
					commands.push (function (g:Graphics, m:Matrix) {
						
						g.moveTo(px * m.a + py * m.c + m.tx, px * m.b + py * m.d + m.ty);
						
					});
					
					if (newFillStyle0) {
						
						var fillStyle = stream.readBits (1);
						
					}
					
				} else {
					
					var lineTo = stream.readBool ();
					
					if (lineTo) {
						
						var deltaBits = stream.readBits (4) + 2;
						
						if (stream.readBool ()) {
							
							penX += stream.readTwips (deltaBits) * v3scale;
							penY += stream.readTwips (deltaBits) * v3scale;
							
						} else if (stream.readBool ()) {
							
							penY += stream.readTwips (deltaBits) * v3scale;
							
						} else {
							
							penX += stream.readTwips (deltaBits) * v3scale;
							
						}
						
						var px = penX;
						var py = penY;
						
						commands.push (function (g:Graphics, m:Matrix) {
							
							g.lineTo(px * m.a + py * m.c + m.tx, px * m.b + py * m.d + m.ty);
							
						});
						
					} else {
						
						var deltaBits = stream.readBits (4) + 2;
						
						var cx = penX + stream.readTwips (deltaBits) * v3scale;
						var cy = penY + stream.readTwips (deltaBits) * v3scale;
						var px = cx + stream.readTwips (deltaBits) * v3scale;
						var py = cy + stream.readTwips (deltaBits) * v3scale;
						
						penX = px;
						penY = py;
						
						commands.push (function (g:Graphics, m:Matrix) {
							
							g.curveTo(cx * m.a + cy * m.c + m.tx, cx * m.b + cy * m.d + m.ty, px * m.a + py * m.c + m.tx, px * m.b + py * m.d + m.ty);
							
						});
						
					}
					
				}
				
			}
			
			commands.push (function (g:Graphics, m:Matrix) { 
				
				g.endFill();
				
			});
			
			glyphsByIndex[i] = { commands: commands, advance: 1024.0 };
			
		}
		
		if (codeOffset != 0) {
			
			stream.alignBits ();
			
			if (stream.getBytesLeft () != codeOffset) {
				
				throw ("Code offset miscalculation");
				
			}
			
			glyphsByCode = new Array <Glyph> ();
			
			for (i in 0...numGlyphs) {
				
				var code = 0;
				
				if (wideCodes) {
					
					code = stream.readUInt16 ();
					
				} else {
					
					code = stream.readByte ();
					
				}
				
				glyphsByCode[code] = glyphsByIndex[i];
				
			}
			
		} else {
			
			glyphsByCode = glyphsByIndex;
			
		}
		
		if (hasLayout) {
			
			ascent = stream.readSTwips ();
			descent = stream.readSTwips ();
			leading = stream.readSTwips ();
			
			advance = new Array <Float> ();
			
			for (i in 0...numGlyphs) {
				
				glyphsByIndex[i].advance = stream.readSTwips ();
				
			}
			
		} else {
			
			ascent = 800;
			descent = 224;
			leading = 0;
			
		}
		
		// TODO:
		//nme.text.FontManager.RegisterFont(this);
		
	}
	
	
	public function getAdvance (characterCode:Int, ?next:Null<Int>):Float {
		
		if (glyphsByCode.length > characterCode) {
			
			var glyph = glyphsByCode[characterCode];
			
			if (glyph != null) {
				
				return glyph.advance;
				
			}
			
		}
		
		return 1024.0;
		
	}
	
	
	public function getAscent ():Float {
		
		return ascent;
		
	}
	
	
	public function getDescent ():Float {
		
		return descent;
		
	}
	
	
	public function getFontName ():String {
		
		return fontName;
		
	}
	
	
	public function getLeading ():Float {
		
		return leading;
		
	}
	
	
	public function renderCharacter (graphics:Graphics, code:Int, matrix:Matrix):Float {
		
		if (glyphsByCode.length > code) {
			
			var glyph = glyphsByCode[code];
			
			if (glyph != null) {
				
				for (command in glyph.commands) {
					
					command (graphics, matrix);
					
				}
				
				return glyph.advance;
				
			}
			
		}
		
		return 0;
		
	}


	public function renderGlyph (graphics:Graphics, index:Int, matrix:Matrix):Void {
		
		if (glyphsByIndex.length > index) {
			
			var commands = glyphsByIndex[index].commands;
			
			for (command in commands) {
				
				command (graphics, matrix);
				
			}
			
		} else {
			
			trace ("Unsupported glyph: " + String.fromCharCode (index));
			
		}
		
	}
	
	
}


typedef FontCommand = Graphics -> Matrix -> Void;

typedef Glyph = {
	
	var commands:Array <FontCommand>;
	var advance:Float;
	
}