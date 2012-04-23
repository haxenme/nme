package format.swf.symbol;


import flash.display.GradientType;
import flash.display.Graphics;
import flash.display.JointStyle;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import format.swf.data.SWFStream;
import format.SWF;


class MorphShape {
	
	
	// TODO: make common with shape.hx
	private static var ftSolid  = 0x00;
	private static var ftLinear = 0x10;
	private static var ftRadial = 0x12;
	private static var ftRadialF= 0x13;
	private static var ftBitmapRepeat  = 0x40;
	private static var ftBitmapClipped = 0x41;
	private static var ftBitmapRepeatR = 0x42;
	private static var ftBitmapClippedR = 0x43;
	
	private var bounds0:Rectangle;
	private var bounds1:Rectangle;
	private var commands:Array <MorphRenderCommand>;
	private var edgeBounds0:Rectangle;
	private var edgeBounds1:Rectangle;
	private var hasNonScaled:Bool;
	private var hasScaled:Bool;
	private var swf:SWF;
	private var waitingLoader:Bool;
	
	
	public function new (swf:SWF, stream:SWFStream, version:Int) {
		
		this.swf = swf;
		
		stream.alignBits ();
		
		commands = [];
		bounds0 = stream.readRect ();
		bounds1 = stream.readRect ();
		waitingLoader = false;
		
		if (version == 2) {
			
			stream.alignBits ();
			
			edgeBounds0 = stream.readRect ();
			edgeBounds1 = stream.readRect ();
			
			stream.alignBits ();
			stream.readBits (6);
			
			hasNonScaled = stream.readBool ();
			hasScaled = stream.readBool ();
			
		} else {
			
			edgeBounds0 = bounds0;
			edgeBounds1 = bounds1;
			
			hasScaled = true;
			hasNonScaled = true;
			
		}
		
		stream.alignBits ();
		
		var offset = stream.readInt ();
		var endStart = stream.getBytesLeft () - offset;
		
		var fillStyles = readFillStyles (stream, version);
		var lineStyles = readLineStyles (stream, version);
		
		stream.alignBits ();
		
		var fillBits = stream.readBits (4);
		var lineBits = stream.readBits (4);
		
		var edges = new List <MorphEdge> ();
		
		var penX = 0.0;
		var penY = 0.0;
		
		while (true) {
			
			var edge = stream.readBool ();
			
			if (!edge) {
				
				var newStyles = stream.readBool ();
				var newLineStyle = stream.readBool ();
				var newFillStyle1 = stream.readBool ();
				var newFillStyle0 = stream.readBool ();
				var moveTo = stream.readBool ();
				
				if (!moveTo && !newStyles && !newLineStyle && !newFillStyle1 && !newFillStyle0) {
					
					break;
					
				}
				
				if (true) {
					
					// The case where new_styles==true seems to have some
				   //  additional data (bitmap?) for embeded line styles.
				   newStyles = false;
					
				}
				
				// Style changed record ...
				if (moveTo) {
					
					var bits = stream.readBits (5);
					penX = stream.readTwips (bits);
					penY = stream.readTwips (bits);
					edges.add (meMove (penX, penY));
					
				}
				
				if (newFillStyle0) {
					
					var fillStyle = stream.readBits (fillBits);
					
					if (fillStyle >= fillStyles.length) {
						
						throw ("Invalid fill style");
						
					}
					
					edges.add (meStyle (fillStyles[fillStyle]));
					
				}
				
				if (newFillStyle1) {
					
					var fillStyle = stream.readBits (fillBits);
					
					if (fillStyle >= fillStyles.length) {
						
						throw ("Invalid fill style");
						
					}
					
					edges.add (meStyle (fillStyles[fillStyle]));
					
				}
				
				if (newLineStyle) {
					
					var lineStyle = stream.readBits (lineBits);
					
					if (lineStyle >= lineStyles.length) {
						
						throw ("Invalid line style: " + lineStyle + "/" + lineStyles.length + " (" + lineBits + ")");
					
					}
					
					edges.add (meStyle (lineStyles[lineStyle]));
					
				}
				
			} else {
				
				// straight
				if (stream.readBool ()) {
					
					var deltaBits = stream.readBits (4) + 2;
					
					var x0 = penX;
					var y0 = penY;
					
					if (stream.readBool ()) {
						
						penX += stream.readTwips (deltaBits);
						penY += stream.readTwips (deltaBits);
						
					} else if (stream.readBool ()) {
						
						penY += stream.readTwips (deltaBits);
						
					} else {
						
						penX += stream.readTwips (deltaBits);
						
					}
					
					edges.add (meLine ((penX + x0) * 0.5, (penY + y0) * 0.5, penX, penY));
					
				} else {
					
					// Curved ...
					var deltaBits = stream.readBits (4) + 2;
					var cx = penX + stream.readTwips (deltaBits);
					var cy = penY + stream.readTwips (deltaBits);
					var px = cx + stream.readTwips (deltaBits);
					var py = cy + stream.readTwips (deltaBits);
					// Can't push "pen_x/y" in closure because it uses a reference
					//  to the member variable, not a copy of the current value.
					penX = px;
					penY = py;
					edges.add (meCurve (cx, cy, penX, penY));
					
				}
			}
		}
		
		// Ok, now read the second half of the shape
		
		penX = 0.0;
		penY = 0.0;
		stream.alignBits ();
		
		if (endStart != stream.getBytesLeft ()) {
			
			throw ("End offset mismatch");
			
		}
		
		fillBits = stream.readBits (4);
		lineBits = stream.readBits (4);
		
		if (fillBits != 0 || lineBits != 0) {
			
			throw ("Unexpected style data in morph");
			
		}
		
		while (true) {
			
			var edge = stream.readBool ();
			
			if (!edge) {
				
				var newStyles = stream.readBool ();
				var newLineStyle = stream.readBool ();
				var newFillStyle1 = stream.readBool ();
				var newFillStyle0 = stream.readBool ();
				var moveTo = stream.readBool ();
				
				if (newLineStyle || newFillStyle0 || newFillStyle1 || newStyles) {
					
					throw ("Style change in Morph");
					
				}
				
				// End-of-shape - Done !
				if (!moveTo) {
					
					break;
					
				}
				
			}
			
			// Get start entry ...
			var x:Float = 0;
			var y:Float = 0;
			var cx:Float = 0;
			var cy:Float = 0;
			var isMove = false;
			var isCurve = false;
			var isLine = false;
			
			var edgeFound = false;
			
			while (!edgeFound) {
				
				var original = edges.pop ();
				if (original == null) {
					
					throw "Too few edges in first shape";
					
				}
				
				edgeFound = true;
				
				switch (original) {
					
					case meMove (meX, meY):
						
						x = meX;
						y = meY;
						isMove = true;
						
						// here we have a "moveTo" in the first list and a "lineTo"
						// in the second.  Combine these to a "move", and find the
						// next line entry ...
						//  ... or maybe just ignore it.
						
						if (edge) {
							
							var px = penX;
							var py = penY;
							//mCommands.push( function(g:Graphics,f:Float)
							//{ g.moveTo(x+(px-x)*f, y+(py-y)*f); } );
							edgeFound = false;
							
						}
					
					case meLine (meCX, meCY, meX, meY):
						
						cx = meCX;
						cy = meCY;
						x = meX;
						y = meY;
						isLine = true;
						
						// trace("  pop line:" + x + "," + y);
					
					case meCurve (meCX, meCY, meX, meY):
						
						cx = meCX;
						cy = meCY;
						x = meX;
						y = meY;
						isCurve = true;
						// trace("  pop curve");
						
					case meStyle (command):
						
						commands.push (command);
						edgeFound = false;
						// trace("  pop style");
						
				}
				
			}
			
			if (!edge) {
				
				if (!isMove) {
					
					throw ("MorphShape: mismatched move");
					
				}
				
				var bits = stream.readBits (5);
				penX = stream.readTwips (bits);
				penY = stream.readTwips (bits);
				var px = penX;
				var py = penY;
				
				commands.push (function (g:Graphics, f:Float) { 
					
					g.moveTo(x + (px - x) * f, y + (py - y) * f); 
					
				});
				
			} else {
				
				// straight
				if (stream.readBool ()) {
					
					var deltaBits = stream.readBits (4) + 2;
					
					var x0 = penX;
					var y0 = penY;
					
					if (stream.readBool ()) {
						
						penX += stream.readTwips (deltaBits);
						penY += stream.readTwips (deltaBits);
						
					} else if (stream.readBool ()) {
						
						penY += stream.readTwips (deltaBits);
						
					} else {
						
						penX += stream.readTwips (deltaBits);
						
					}
					
					var px = penX;
					var py = penY;
					
					if (!isLine) {
						
						var cx2 = (px + x0) * 0.5;
						var cy2 = (py + y0) * 0.5;
						
						commands.push (function (g:Graphics, f:Float) {
							
							g.curveTo(cx + (cx2 - cx) * f, cy + (cy2 - cy) * f, x + (px - x) * f, y + (py - y) * f);
							
						});
						
					} else {
						
						commands.push (function (g:Graphics, f:Float) { 
							
							g.lineTo(x + (px - x) * f, y + (py - y) * f);
							
						});
						
					}
					
				} else {
					
					// Curved ...
					
					var deltaBits = stream.readBits (4) + 2;
					var cx2 = penX + stream.readTwips (deltaBits);
					var cy2 = penY + stream.readTwips (deltaBits);
					var px = cx2 + stream.readTwips (deltaBits);
					var py = cy2 + stream.readTwips (deltaBits);
					
					// Can't push "pen_x/y" in closure because it uses a reference
					//  to the member variable, not a copy of the current value.
					
					penX = px;
					penY = py;
					
					commands.push (function (g:Graphics, f:Float) {
						
						g.curveTo(cx + (cx2 - cx) * f, cy + (cy2 - cy) * f, x + (px - x) * f, y + (py - y) * f);
						
					});
					
				}
				
			}
			
		}
		
		for (edge in edges) {
			
			switch (edge) {
				
				case meStyle (command):
					
					commands.push (command);
				
				default:
					
					throw ("Edge count mismatch");
				
			}
			
		}
		
		this.swf = null;
		
		// Render( new nme.display.DebugGfx());
		
	}
	
	
	private static function interpolateColor (color0:Int, color1:Int, f:Float):Int {
		
		var r0 = (color0 >> 16) & 0xff;
		var g0 = (color0 >> 8) & 0xff;
		var b0 = (color0) & 0xff;
		
		return (Std.int (r0 + (((color1 >> 16) & 0xff) - r0) * f) << 16) | (Std.int (g0 + (((color1 >> 8) & 0xff) - g0) * f) << 8) | (Std.int (b0 + (((color1) & 0xff) - b0) * f));
		
	}
	
	
	private static function interpolateMatrix (matrix0:Matrix, matrix1:Matrix, f:Float):Matrix {
		
		var matrix = new Matrix ();
		
		matrix.a = matrix0.a + (matrix1.a - matrix0.a) * f;
		matrix.b = matrix0.b + (matrix1.b - matrix0.b) * f;
		matrix.c = matrix0.c + (matrix1.c - matrix0.c) * f;
		matrix.d = matrix0.d + (matrix1.d - matrix0.d) * f;
		matrix.tx = matrix0.tx + (matrix1.tx - matrix0.tx) * f;
		matrix.ty = matrix0.ty + (matrix1.ty - matrix0.ty) * f;
		
		return matrix;
		
	}
	
	
	private function readFillStyles (stream:SWFStream, version:Int):Array <MorphRenderCommand> {
		
		var result = new Array <MorphRenderCommand> ();
		
		// Special null fill-style
		result.push (function (g:Graphics, f:Float) {
			
			g.endFill();
			
		});
		
		var count = stream.readArraySize (true);
		
		for (i in 0...count) {
			
			var fill = stream.readByte ();
			
			if (fill == ftSolid) {
				
				var RGB0 = stream.readRGB ();
				var A0 = stream.readByte () / 255.0;
				var RGB1 = stream.readRGB ();
				var A1 = stream.readByte () / 255.0;
				var dA = A1 - A0;
				
				result.push (function (g:Graphics, f:Float) {
					
					g.beginFill (interpolateColor (RGB0, RGB1, f), (A0 + dA * f));
					
				});
				
			} else if ((fill & 0x10) != 0) {
				
				// Gradient
				
				var matrix0 = stream.readMatrix ();
				
				stream.alignBits ();
				
				var matrix1 = stream.readMatrix ();
				
				stream.alignBits ();
				
				//var spread = inStream.ReadSpreadMethod();
				//var interp = inStream.ReadInterpolationMethod();
				
				var numColors = stream.readBits (4);
				
				var colors0 = [];
				var colors1 = [];
				var alphas0 = [];
				var alphas1 = [];
				var ratios0 = [];
				var ratios1 = [];
				
				for (i in 0...numColors) {
					
					ratios0.push (stream.readByte ());
					colors0.push (stream.readRGB ());
					alphas0.push (stream.readByte () / 255.0);
					ratios1.push (stream.readByte ());
					colors1.push (stream.readRGB ());
					alphas1.push (stream.readByte () / 255.0);
					
				}
				
				//var focus = fill==ftRadialF ?  inStream.ReadByte()/255.0 : 0.0;
				//var type = fill==ftLinear ? nme.display.GradientType.LINEAR :
				//nme.display.GradientType.RADIAL;
				
				result.push (function (g:Graphics, f:Float) {
					
					var cols = [];
					var alphas = [];
					var ratios = [];
					
					for (i in 0...numColors) {
						
						cols.push (interpolateColor(colors0[i], colors1[i], f));
						alphas.push (alphas0[i] + (alphas1[i] - alphas0[i]) * f);
						ratios.push (ratios0[i] + (ratios1[i] - ratios0[i]) * f);
						
					}
					
					g.beginGradientFill (GradientType.LINEAR, cols, alphas, ratios, interpolateMatrix(matrix0, matrix1, f));
					
				});
				
			} else if ((fill & 0x40) != 0) {
				
				// bitmap fill
				
				var id = stream.readID ();
				var bitmap = null;
				
				if (id != 0xffff) {
					
					switch (swf.getSymbol (id)) {
						
						case bitmapSymbol (data):
							
							bitmap = data.bitmapData;
						
						default:
							
						
					}
					
				}
				
				stream.alignBits ();
				
				var matrix0 = stream.readMatrix ();
				
				// Not too sure about these.
				// A scale of (20,20) is 1 pixel-per-unit.
				matrix0.a *= 0.05;
				matrix0.b *= 0.05;
				matrix0.c *= 0.05;
				matrix0.d *= 0.05;
				
				stream.alignBits ();
				
				var matrix1 = stream.readMatrix ();
				
				// Not too sure about these.
				// A scale of (20,20) is 1 pixel-per-unit.
				matrix1.a *= 0.05;
				matrix1.b *= 0.05;
				matrix1.c *= 0.05;
				matrix1.d *= 0.05;
				
				stream.alignBits ();
				
				//var repeat = fill == ftBitmapRepeat || fill==ftBitmapRepeatR;
				//var smooth = fill == ftBitmapRepeatR || fill ==ftBitmapClippedR;
				
				if (bitmap != null) {
					
					result.push (function (g:Graphics, f:Float) {
						
						g.beginBitmapFill (bitmap, interpolateMatrix (matrix0, matrix1, f));
						
					});
					
				} else {
					
					// May take some time for bitmap to load ...
					
					var s = swf;
					var me = this;
					
					result.push (function (g:Graphics, f:Float) {
						
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
								g.endFill ();
								
								return;
								
							} else {
								
								me = null;
								
							}
							
						}
						
						g.beginBitmapFill (bitmap, interpolateMatrix (matrix0, matrix1, f));
						
					});
					
				}
				
			}
			
		}
		
		return result;
		
	}
	
	
	private function readLineStyles (stream:SWFStream, version:Int):Array <MorphRenderCommand> {
		
		var result = new Array <MorphRenderCommand> ();
		
		// Special null line-style
		result.push (function (g:Graphics, f:Float) {
			
			g.lineStyle(null);
			
		});
		
		var numStyles = stream.readArraySize (true);
		
		for (i in 0...numStyles) {
			
			if (version == 1) {
				
				stream.alignBits ();
				
				var w0 = stream.readDepth () * 0.05;
				var w1 = stream.readDepth () * 0.05;
				var RGB0 = stream.readRGB ();
				var A0 = stream.readByte () / 255.0;
				var RGB1 = stream.readRGB ();
				var A1 = stream.readByte () / 255.0;
				
				result.push (function (g:Graphics, f:Float) { 
					
					g.lineStyle (w0 + (w1 - w0) * f, interpolateColor (RGB0, RGB1, f), A0 + (A1 - A0) * f);
					
				});
				
			} else {
				
				// MorphLinestyle 2
				
				stream.alignBits ();
				
				var w0 = stream.readDepth () * 0.05;
				var w1 = stream.readDepth () * 0.05;
				
				var startCaps = stream.readCapsStyle ();
				var joints = stream.readJoinStyle ();
				var hasFill = stream.readBool ();
				var scale = stream.readScaleMode ();
				var pixelHint = stream.readBool ();
				var reserved = stream.readBits (5);
				var noClose = stream.readBool ();
				var endCaps = stream.readCapsStyle ();
				
				var miter = 1.0;
				
				if (joints == JointStyle.MITER) {
					
					miter = stream.readDepth () / 256.0;
					
				}
				
				if (!hasFill) {
					
					var c0 = stream.readRGB ();
					var A0 =  (stream.readByte () / 255.0);
					var c1 = stream.readRGB ();
					var A1 =  (stream.readByte () / 255.0);
					
					result.push (function (g:Graphics, f:Float) {
						
						g.lineStyle (w0 + (w1 - w0) * f, interpolateColor (c0, c1, f), A0 + (A1 - A0) * f, pixelHint, scale, startCaps, joints, miter);
						
					});
					
				} else {
					
					var fill = stream.readByte ();
					
					// Gradient
					if ((fill & 0x10) != 0) {
						
						var matrix0 = stream.readMatrix ();
						
						stream.alignBits ();
						
						var matrix1 = stream.readMatrix ();
						
						stream.alignBits ();
						
						//var spread = inStream.ReadSpreadMethod();
						//var interp = inStream.ReadInterpolationMethod();
						
						var numColors = stream.readBits (4);
						
						var colors0 = [];
						var colors1 = [];
						var alphas0 = [];
						var alphas1 = [];
						var ratios0 = [];
						var ratios1 = [];
						
						for (i in 0...numColors) {
							
							ratios0.push (stream.readByte ());
							colors0.push (stream.readRGB ());
							alphas0.push (stream.readByte () / 255.0);
							ratios1.push (stream.readByte ());
							colors1.push (stream.readRGB ());
							alphas1.push (stream.readByte () / 255.0);
							
						}
						
						//var focus = fill==ftRadialF ?  inStream.ReadByte()/255.0 : 0.0;
						//var type = fill==ftLinear ? nme.display.GradientType.LINEAR :
						//nme.display.GradientType.RADIAL;
						
						result.push (function (g:Graphics, f:Float) {
							
							var cols = [];
							var alphas = [];
							var ratios = [];
							
							for (i in 0...numColors) {
								
								cols.push (interpolateColor (colors0[i], colors1[i], f));
								alphas.push (alphas0[i] + (alphas1[i] - alphas0[i]) * f);
								ratios.push (ratios0[i] + (ratios1[i] - ratios0[i]) * f);
								
							}
							
							g.lineGradientStyle(GradientType.LINEAR, cols, alphas, ratios, interpolateMatrix (matrix0, matrix1, f));
							
						});
						
					} else {
						
						throw ("Unknown fillstyle (" + fill + ")");
						
					}
					
				}
				
			}
			
		}
		
		return result;
		
	}
	
	
	public function render (graphics:Graphics, f:Float):Bool {
		
		waitingLoader = false;
		
		for (command in commands) {
			
			command (graphics, f);
			
		}
		
		return waitingLoader;
		
	}
	
	
}


typedef MorphRenderCommand = Graphics -> Float -> Void;

enum MorphEdge {
	
	meStyle (func:Graphics -> Float -> Void);
	meMove (x:Float, y:Float);
	meLine (cx:Float, cy:Float, x:Float, y:Float);
	meCurve (cx:Float, cy:Float, x:Float, y:Float);
   
}