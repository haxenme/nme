package format.swf.symbol;


import flash.display.GradientType;
import flash.display.Graphics;
import flash.display.JointStyle;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import format.swf.data.SWFStream;
import format.swf.symbol.Symbol;
import format.SWF;


class Shape {
	
	
	private static var ftSolid = 0x00;
	private static var ftLinear = 0x10;
	private static var ftRadial = 0x12;
	private static var ftRadialF = 0x13;
	private static var ftBitmapRepeatSmooth = 0x40;
	private static var ftBitmapClippedSmooth = 0x41;
	private static var ftBitmapRepeat = 0x42;
	private static var ftBitmapClipped = 0x43;
	
	private var bounds:Rectangle;
	private var commands:Array <RenderCommand>;
	private var edgeBounds:Rectangle;
	private var fillStyles:Array <RenderCommand>;
	private var hasNonScaled:Bool;
	private var hasScaled:Bool;
	private var swf:SWF;
	private var waitingLoader:Bool;
	
	
	public function new (swf:SWF, stream:SWFStream, version:Int) {
		
		this.swf = swf;
		
		stream.alignBits ();
		
		commands = [];
		bounds = stream.readRect ();
		waitingLoader = false;
		
		if (version == 4) {
			
			stream.alignBits ();
			
			edgeBounds = stream.readRect ();
			
			stream.alignBits ();
			
			stream.readBits (6);
			hasNonScaled = stream.readBool ();
			hasScaled = stream.readBool ();
			
		} else {
			
			edgeBounds = bounds.clone ();
			hasScaled = true;
			hasNonScaled = true;
			
		}
		
		fillStyles = readFillStyles (stream, version);
		var lineStyles = readLineStyles (stream, version);
		
		stream.alignBits ();
		
		var fillBits = stream.readBits (4);
		var lineBits = stream.readBits (4);
		
		var penX = 0.0;
		var penY = 0.0;
		
		var currentFill0 = -1;
		var currentFill1 = -1;
		var currentLine = -1;
		
		var edges = new Array <RenderCommand> ();
		var fills = new Array <ShapeEdge> ();
		
		while (true) {
			
			var edge = stream.readBool ();
			
			if (!edge) {
				
				var newStyles = stream.readBool ();
				var newLineStyle = stream.readBool ();
				var newFillStyle1 = stream.readBool ();
				var newFillStyle0 = stream.readBool ();
				var moveTo = stream.readBool ();
				
				// End-of-shape - Done !
				if (!moveTo && !newStyles && !newLineStyle && !newFillStyle1 && !newFillStyle0) {
					
					break;
					
				}
				
				if (version != 2 && version != 3) {
					
					// The case where newStyles==true seems to have some
					//  additional data (bitmap?) for embeded line styles.
					
					//newStyles = false;
					
					// Forcing newStyles to false was causing incorrect rendering
					// Will have to keep an eye out for this additional data?
					
				}
				
				// Style changed record ...
				if (moveTo) {
					
					var bits = stream.readBits (5);
					var px = stream.readTwips (bits);
					var py = stream.readTwips (bits);
					
					edges.push (function (g:Graphics) {
						
						g.moveTo (px, py);
						
					});
					
					penX = px;
					penY = py;
					
				}
				
				if (newFillStyle0) {
					
					currentFill0 = stream.readBits (fillBits);
					
				}
				
				if (newFillStyle1) {
					
					currentFill1 = stream.readBits (fillBits);
					
				}
				
				if (newLineStyle) {
					
					var lineStyle = stream.readBits (lineBits);
					
					if (lineStyle >= lineStyles.length) {
						
						throw("Invalid line style: " + lineStyle + "/" + lineStyles.length + " (" + lineBits + ")");
						
					}
					
					var func = lineStyles[lineStyle];
					edges.push (func);
					currentLine = lineStyle;
					
				}
				
				// Hmmm - do this, or just flush fills?
				if (newStyles) {
					
					flushCommands (edges, fills);
					
					if (edges.length > 0) {
						
						edges = [];
						
					}
					
					if (fills.length > 0) {
						
						fills = [];
						
					}
					
					stream.alignBits ();
					
					fillStyles = readFillStyles (stream, version);
					lineStyles = readLineStyles (stream, version);
					fillBits = stream.readBits (4);
					lineBits = stream.readBits (4);
					
					currentLine = -1;
					currentFill0 = -1;
					currentFill1 = -1;
					
				}
				
			} else {
				
				// edge ..
				
				if (stream.readBool ()) {
					
					// straight
					
					var px = penX;
					var py = penY;
					
					var deltaBits = stream.readBits (4) + 2;
					
					if (stream.readBool ()) {
						
						px += stream.readTwips (deltaBits);
						py += stream.readTwips (deltaBits);
						
					} else if (stream.readBool ()) {
						
						py += stream.readTwips (deltaBits);
						
					} else {
						
						px += stream.readTwips (deltaBits);
						
					}
				
					if (currentLine > 0) {
						
						edges.push (function (g:Graphics) {
							
							g.lineTo (px, py);
							
						});
						
					} else {
						
						edges.push (function (g:Graphics) {
							
							g.moveTo (px, py);
							
						});
						
					}
					
					if (currentFill0 > 0) {
						
						fills.push (ShapeEdge.line (currentFill0, penX, penY, px, py));
						
					}
					
					if (currentFill1 > 0) {
						
						fills.push (ShapeEdge.line (currentFill1, px, py, penX, penY));
						
					}
					
					penX = px;
					penY = py;
					
				} else {
					
					// Curved ...
					
					var deltaBits = stream.readBits (4) + 2;
					var cx = penX + stream.readTwips (deltaBits);
					var cy = penY + stream.readTwips (deltaBits);
					var px = cx + stream.readTwips (deltaBits);
					var py = cy + stream.readTwips (deltaBits);
					
					// Can't push "pen_x/y" in closure because it uses a reference
					//  to the member variable, not a copy of the current value.
					
					if (currentLine > 0) {
						
						edges.push (function (g:Graphics) {
							
							g.curveTo (cx, cy, px, py);
							
						});
						
					}
					
					if (currentFill0 > 0) {
						
						fills.push (ShapeEdge.curve (currentFill0, penX, penY, cx, cy, px, py));
						
					}
					
					if (currentFill1 > 0) {
						
						fills.push (ShapeEdge.curve (currentFill1, px, py, cx, cy, penX, penY));
						
					}
					
					penX = px;
					penY = py;
					
				}
				
			}
			
		}
		
		flushCommands (edges, fills);
		
		this.swf = null;
		
	}
	
	
	private function flushCommands (edges:Array <RenderCommand>, fills:Array <ShapeEdge>) {
		
		var left = fills.length;
		
		while (left > 0) {
			
			var first = fills[0];
			fills[0] = fills[--left];
			
			if (first.fillStyle >= fillStyles.length) {
				
				throw ("Invalid fill style");
				
			}
			
			commands.push (fillStyles[first.fillStyle]);
			
			var mx = first.x0;
			var my = first.y0;
			
			commands.push (function (gfx:Graphics) { 
				
				gfx.moveTo (mx, my);
				
			});
			
			commands.push (first.asCommand ());
			
			var prev = first;
			var loop = false;
			
			while (!loop) {
				
				var found = false;
				
				for (i in 0...left) {
					
					if (prev.connects(fills[i])) {
						
						prev = fills[i];
						fills[i] = fills[--left];
						
						commands.push (prev.asCommand ());
						
						found = true;
						
						if (prev.connects (first)) {
							
							loop = true;
							
						}
						
						break;
						
					}
					
				}
				
				if (!found) {
					
					trace("Remaining:");
					
					for (f in 0...left)
						fills[f].dump ();
					
					throw("Dangling fill : " + prev.x1 + "," + prev.y1 + "  " + prev.fillStyle);
					
					break;
					
				}
				
			}
			
		}
		
		if (fills.length > 0) {
			
			commands.push (function (gfx:Graphics) {
				
				gfx.endFill ();
				
			});
			
		}
		
		commands = commands.concat (edges);
		
		if (edges.length > 0) {
			
			commands.push (function(gfx:Graphics) {
				
				gfx.lineStyle ();
				
			});
			
		}
		
	}
	
	
	private function readFillStyles (stream:SWFStream, version:Int):Array <RenderCommand> {
		
		var result:Array <RenderCommand> = [];
		
		// Special null fill-style
		result.push (function(g:Graphics) {
			
			g.endFill();
			
		});
		
		var count = stream.readArraySize (true);
		
		for (i in 0...count) {
			
			var fill = stream.readByte ();
			
			if (fill == ftSolid) {
				
				var RGB = stream.readRGB();
				// trace("FILL " + i + " = " + RGB );
				var A = version >= 3 ? (stream.readByte () / 255.0) : 1.0;
				
				result.push (function (g:Graphics) {
					
					g.beginFill (RGB, A);
					
				});
				
			} else if (fill == ftLinear || fill == ftRadial || fill == ftRadialF) {
				
				// Gradient
				
				var matrix = stream.readMatrix ();
				
				stream.alignBits ();
				
				var spread = stream.readSpreadMethod ();
				var interp = stream.readInterpolationMethod ();
				var numColors = stream.readBits (4);
				
				var colors = [];
				var alphas = [];
				var ratios = [];
				
				for (i in 0...numColors) {
					
					ratios.push (stream.readByte ());
					colors.push (stream.readRGB ());
					alphas.push (version >= 3 ? stream.readByte () / 255.0 : 1.0);
					
				}
				
				var focus = fill == ftRadialF ? stream.readByte () / 255.0 : 0.0;
				var type = fill == ftLinear ? GradientType.LINEAR : GradientType.RADIAL;
				
				result.push (function (g:Graphics) {
					
					g.beginGradientFill (type, colors, alphas, ratios, matrix, spread, interp, focus);
					
				});
				
			} else if (fill == ftBitmapRepeatSmooth || fill == ftBitmapClippedSmooth || fill == ftBitmapRepeat || fill == ftBitmapClipped) {
				
				// Bitmap
				
				stream.alignBits ();
				
				var id = stream.readID ();
				var matrix = stream.readMatrix ();
				
				// Not too sure about these.
				// A scale of (20,20) is 1 pixel-per-unit.
				matrix.a *= 0.05;
				matrix.b *= 0.05;
				matrix.c *= 0.05;
				matrix.d *= 0.05;
				
				stream.alignBits ();
				
				var repeat = fill == ftBitmapRepeat || fill == ftBitmapRepeatSmooth;
				var smooth = fill == ftBitmapRepeatSmooth || fill == ftBitmapClippedSmooth;
				
				var bitmap = null;
				
				if (id != 0xffff) {
					
					switch (swf.getSymbol (id)) {
						
						case bitmapSymbol (data):
							
							bitmap = data.bitmapData;
						
						default:
							
						
					}
					
				}
				
				if (bitmap != null) {
					
					result.push (function (g:Graphics) {
						
						g.beginBitmapFill(bitmap, matrix, repeat, smooth);
						
					});
					
				} else {
					
					// May take some time for bitmap to load ...
					
					var s = swf;
					var me = this;
					
					result.push (function (g:Graphics) {
						
						if (bitmap == null) {
							
							if (id != 0xffff) {
								
								switch (s.getSymbol (id)) {
									
									case bitmapSymbol (data):
										
										bitmap = data.bitmapData;
									
									default:
										
									
								}
								
							}
							
							if (bitmap == null) {
								
								me.waitingLoader = true;
								g.endFill();
								return;
								
							} else {
								
								me = null;
								
							}
							
						}
						
						g.beginBitmapFill (bitmap, matrix, repeat, smooth);
						
					});
					
				}
				
			} else {
				
				throw ("Unknown fill style : 0x" + StringTools.hex (fill));
				
			}
			
		}
		
		return result;
		
	}
	
	
	private function readLineStyles (stream:SWFStream, version:Int):Array <RenderCommand> {
		
		var result:Array <RenderCommand> = [];
		
		// Special null line-style
		result.push (function (g:Graphics) {
			
			g.lineStyle ();
			
		});
		
		var count = stream.readArraySize (true);
		
		for (i in 0...count) {
			
			// Linestyle 2
			if (version >= 4) {
				
				stream.alignBits ();
				
				var width = stream.readDepth () * 0.05;
				var startCaps = stream.readCapsStyle ();
				var joints = stream.readJoinStyle ();
				var hasFill = stream.readBool ();
				var scale = stream.readScaleMode ();
				var pixelHint = stream.readBool ();
				var reserved = stream.readBits (5);
				var noClose = stream.readBool ();
				var endCaps = stream.readCapsStyle ();
				var miter = joints == JointStyle.MITER ? stream.readDepth () / 256.0:1;
				var color = hasFill ? 0 : stream.readRGB ();
				var A = hasFill  ? 1.0 : (stream.readByte () / 255.0);
				
				if (hasFill) {
					
					var fill = stream.readByte ();
					
					// Gradient
					if ((fill & 0x10) != 0) {
						
						var matrix = stream.readMatrix ();
						
						stream.alignBits ();
						
						var spread = stream.readSpreadMethod ();
						var interp = stream.readInterpolationMethod ();
						var numColors = stream.readBits (4);
						
						var colors = [];
						var alphas = [];
						var ratios = [];
						
						for (i in 0...numColors) {
							
							ratios.push (stream.readByte ());
							colors.push (stream.readRGB ());
							alphas.push (stream.readByte () / 255.0);
							
						}
						
						var focus = fill == ftRadialF ? stream.readByte () / 255.0 : 0.0;
						var type = fill == ftLinear ? GradientType.LINEAR : GradientType.RADIAL;
						
						result.push (function (g:Graphics) {
							
							g.lineStyle (width, 0, 1, pixelHint, scale, startCaps, joints, miter);
							g.lineGradientStyle (type, colors, alphas, ratios, matrix, spread, interp, focus);
							
						});
						
					} else {
						
						throw ("Unknown fillStyle");
						
					}
					
				} else {
					
					result.push (function (g:Graphics) {
						
						g.lineStyle (width, color, A, pixelHint, scale, startCaps, joints, miter);
						
					});
					
				}
				
			} else {
				
				stream.alignBits ();
				
				var width = stream.readDepth () * 0.05;
				var RGB = stream.readRGB ();
				var A = version >= 3 ? (stream.readByte () / 255.0) : 1.0;
				
				result.push (function (g:Graphics) {
					
					g.lineStyle (width, RGB, A);
					
				});
				
			}
			
		}
		
		return result;
		
	}
	
	
	public function render (graphics:Graphics) {
		
		waitingLoader = false;
		
		for (command in commands) {
			
			command (graphics);
			
		}
		
		return waitingLoader;
		
	}
	

}


typedef RenderCommand = Graphics -> Void;


class ShapeEdge {
	
	
	public var fillStyle:Int;
	public var isQuadratic:Bool;
	public var cx:Float;
	public var cy:Float;
	public var x0:Float;
	public var x1:Float;
	public var y0:Float;
	public var y1:Float;
	
	
	public function new () {
		
		
		
	}
	
	
	public function asCommand ():RenderCommand {
		
		if (isQuadratic) {
			
			return function (gfx:Graphics) { 
				
				gfx.curveTo (cx, cy, x1, y1);
				
			}
			
		} else {
			
			return function (gfx:Graphics) { 
				
				gfx.lineTo (x1, y1); 
				
			}	
			
		}
		
	}
	
	
	public function connects (next:ShapeEdge) {
		
		return fillStyle == next.fillStyle && Math.abs (x1 - next.x0) < 0.00001 && Math.abs (y1 - next.y0) < 0.00001;
		
	}
	
	
	public static function curve (style:Int, x0:Float, y0:Float, cx:Float, cy:Float, x1:Float, y1:Float):ShapeEdge {
		
		var result = new ShapeEdge ();
		
		result.fillStyle = style;
		result.x0 = x0;
		result.y0 = y0;
		result.cx = cx;
		result.cy = cy;
		result.x1 = x1;
		result.y1 = y1;
		result.isQuadratic = true;
		
		return result;
		
	}
	
	
	public function dump ():Void {
		
		trace (x0 + "," + y0 + " -> " + x1 + "," + y1 + " (" + fillStyle + ")" );
		
	}
	
	
	public static function line (style:Int, x0:Float, y0:Float, x1:Float, y1:Float):ShapeEdge {
		
		var result = new ShapeEdge();
		
		result.fillStyle = style;
		result.x0 = x0;
		result.y0 = y0;
		result.x1 = x1;
		result.y1 = y1;
		result.isQuadratic = false;
		
		return result;
		
	}
	
	
}