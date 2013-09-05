/*
 * format - haXe File Formats
 *
 *  SWF File Format
 *  Copyright (C) 2004-2008 Nicolas Cannasse
 *
 * Copyright (c) 2008, The haXe Project Contributors
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
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package format.swf;
import format.swf.Data;
import format.swf.Constants;

class Reader {

	var i : haxe.io.Input;
	var bits : format.tools.BitsInput;

	var version : Int;

	var bitsRead : Int; // TODO not really used, maybe remove later

	public function new(i) {
		this.i = i;
	}

	inline function readFixed8(?i : haxe.io.Input) {
		if (i == null) i = this.i;
		return i.readUInt16();
	}

	inline function readFixed() {
		return i.readInt32();
	}

	function readUTF8Bytes() {
		var b = new haxe.io.BytesBuffer();
		while( true ) {
			var c = i.readByte();
			if( c == 0 ) break;
			b.addByte(c);
		}
		return b.getBytes();
	}

	function readRect() {
		bits.reset();
		var nbits = bits.readBits(5);
		return {
			left : Tools.signExtend(bits.readBits(nbits), nbits),
			right : Tools.signExtend(bits.readBits(nbits), nbits),
			top : Tools.signExtend(bits.readBits(nbits), nbits),
			bottom : Tools.signExtend(bits.readBits(nbits), nbits),
		};
	}

	function readMatrixPart() : MatrixPart {
		var nbits = bits.readBits(5);
		return {
			nbits : nbits,
			x : bits.readBits(nbits),
			y : bits.readBits(nbits),
		};
	}

	function readMatrix() : Matrix {
		bits.reset();

		var scale: MatrixPartScale = null;
		if(bits.read()) {
			// Scale part
			var nbits = bits.readBits(5);
			var _x = Tools.floatFixedBits(bits.readBits(nbits), nbits);
			var _y = Tools.floatFixedBits(bits.readBits(nbits), nbits);
			scale = {
				x: _x,
				y: _y
			}
		}
		
		var rotate: MatrixPartRotateSkew = null;
		if(bits.read()) {
			// Rotate part
			var nbits = bits.readBits(5);
			var _rs0 = Tools.floatFixedBits(bits.readBits(nbits), nbits);
			var _rs1 = Tools.floatFixedBits(bits.readBits(nbits), nbits);
			rotate = {
				rs0: _rs0,
				rs1: _rs1
			}
		}
		
		// Translate part (always present)
		var nbits = bits.readBits(5);
		var translate: MatrixPartTranslate = {
			x: Tools.signExtend(bits.readBits(nbits), nbits),
			y: Tools.signExtend(bits.readBits(nbits), nbits)
		};
			
		return {
			scale : scale,
			rotate : rotate,
			translate : translate
		};
	}

	function readRGBA(?i : haxe.io.Input) : RGBA {
		if (i == null) i = this.i;
		return {
			r : i.readByte(),
			g : i.readByte(),
			b : i.readByte(),
			a : i.readByte(),
		};
	}
	
	function readRGB(?i : haxe.io.Input) : RGB {
		if (i == null) i = this.i;
		return {
			r : i.readByte(),
			g : i.readByte(),
			b : i.readByte(),
		};
	}

	function readCXAColor(nbits) : RGBA {
		return {
			r : bits.readBits(nbits),
			g : bits.readBits(nbits),
			b : bits.readBits(nbits),
			a : bits.readBits(nbits),
		};
	}

	function readCXA() : CXA {
		bits.reset();
		var add = bits.read();
		var mult = bits.read();
		var nbits = bits.readBits(4);
		return {
			nbits : nbits,
			mult : if( mult ) readCXAColor(nbits) else null,
			add : if( add ) readCXAColor(nbits) else null,
		};
	}

	function readGradient(ver : Int) : Gradient {
		bits.reset();
		var spread = switch(bits.readBits(2)) {
			case 0: SMPad;
			case 1: SMReflect;
			case 2: SMRepeat;
			case 3: SMReserved;
		};

		var interp = switch(bits.readBits(2)) {
			case 0: IMNormalRGB;
			case 1: IMLinearRGB;
			case 2: IMReserved1;
			case 3: IMReserved2;
		};

		var nGrad = bits.readBits(4);
		var arr = new Array<GradRecord>();

		for (c in 0...nGrad) {
			var pos = i.readByte();
			if (ver <= 2)
				arr.push(GRRGB(pos, readRGB()));
			else
				arr.push(GRRGBA(pos, readRGBA()));
		}

		return {
			spread: spread,
			interpolate: interp,
			data: arr
		};
	}

	function getLineCap(t : Int) {
		return switch(t) {
			case 0: LCRound;
			case 1: LCNone;
			case 2: LCSquare;
			default: throw error();
		};
	}
	
	function readLineStyles(ver : Int) : Array<LineStyle> {	

		var cnt = i.readByte();
		if (cnt == 0xFF) {
			if (ver == 1)
				throw error();
			cnt = i.readUInt16();
		}

		var arr = new Array<LineStyle>();

		for (c in 0...cnt) {
			var width = i.readUInt16();

			arr.push({
				width: width,
				data: if (ver <= 2) {
					LSRGB(readRGB(i));
				}
				else if (ver == 3) {
					LSRGBA(readRGBA(i));
				}
				else if (ver == 4) {
					bits.reset();
					var startCap = getLineCap(bits.readBits(2));
					var _join = bits.readBits(2);
					var _fill = bits.read();
					var noHScale = bits.read();
					var noVScale = bits.read();
					var pixelHinting = bits.read();
					
					if (bits.readBits(5) != 0)
						throw error();

					var noClose = bits.read();
					var endCap = getLineCap(bits.readBits(2));
					
					var join = switch (_join) {
						case 0: LJRound;
						case 1: LJBevel;
						case 2: LJMiter(readFixed8());
						default: throw error();
					};

					var fill = switch (_fill) {
						case false: LS2FColor(readRGBA(i));
						case true: LS2FStyle(readFillStyle(ver));
					};

					LS2({
						startCap: startCap,
						join: join,
						fill: fill,
						noHScale: noHScale,
						noVScale: noVScale,
						pixelHinting: pixelHinting,
						noClose: noClose,
						endCap: endCap
					});
				}
				else throw error()
			});
		}

		return arr;
	}

	function readFillStyle(ver : Int) : FillStyle {
		var type = i.readByte();
		
		return switch( type ) {
			case FillStyleTypeId.Solid:
				(ver <= 2) ? FSSolid(readRGB(i)) : FSSolidAlpha(readRGBA(i));
			case
				FillStyleTypeId.LinearGradient,
				FillStyleTypeId.RadialGradient,
				FillStyleTypeId.FocalRadialGradient:
				
				var mat = readMatrix();
				var grad = readGradient(ver);

				switch (type) {
					case FillStyleTypeId.FocalRadialGradient:
						FSFocalGradient(mat, {
							focalPoint: readFixed8(i),
							data: grad
						});
					case FillStyleTypeId.LinearGradient:
						FSLinearGradient(mat, grad);
					case FillStyleTypeId.RadialGradient:
						FSRadialGradient(mat, grad);
					default: throw error();
				}
			case 
				FillStyleTypeId.RepeatingBitmap,
				FillStyleTypeId.ClippedBitmap,
				FillStyleTypeId.NonSmoothedRepeatingBitmap,
				FillStyleTypeId.NonSmoothedClippedBitmap:
				
				var cid = i.readUInt16();
				var mat = readMatrix();
				var isRepeat = (type == FillStyleTypeId.RepeatingBitmap || type == FillStyleTypeId.NonSmoothedRepeatingBitmap);
				var isSmooth = (type == FillStyleTypeId.RepeatingBitmap || type == FillStyleTypeId.ClippedBitmap);
				FSBitmap(cid, mat, isRepeat, isSmooth);
				
			default: throw error() + " code " + type;
		};
	}
	
	function readFillStyles(ver : Int) : Array<FillStyle> {
		var cnt = i.readByte();
		if (cnt == 0xFF && ver > 1)
			cnt = i.readUInt16();

		var arr = new Array<FillStyle>();

		for (c in 0...cnt) {
			var fillStyle = readFillStyle(ver);
			arr.push(fillStyle);
		}
		return arr;
	}

	function readShapeWithStyle(ver : Int) : ShapeWithStyleData {
		var fillStyles = readFillStyles(ver);
		var lineStyles = readLineStyles(ver);
		return {
			fillStyles: fillStyles,
			lineStyles: lineStyles,
			shapeRecords: readShapeRecords(ver)
		};
	}
	
	function readShapeWithoutStyle(ver : Int) : ShapeWithoutStyleData {
		return {
			shapeRecords: readShapeRecords(ver)
		};
	}


	//
	// reads a SHAPE field
	//
	function readShapeRecords(ver : Int) : Array<ShapeRecord> {
		bits.reset();
		var fillBits = bits.readBits(4);
		var lineBits = bits.readBits(4);

		var recs = new Array<ShapeRecord>();

		do {
			//bits.reset(); // Byte-align shape records
			if (bits.read()) {
				// Edge record
				if (bits.read()) {
					// Straight
					var nbits = bits.readBits(4) + 2;
					var isGeneral = bits.read();
					var isVertical = (!isGeneral) ? bits.read() : false;

					var dx = (isGeneral || !isVertical)
						? Tools.signExtend(bits.readBits(nbits), nbits)
						: 0;
					
					var dy = (isGeneral || isVertical) 
						? Tools.signExtend(bits.readBits(nbits), nbits)
						: 0;

					recs.push(SHREdge(dx, dy));
				}
				else {
					// Curved
					var nbits = bits.readBits(4) + 2;
					var cdx = Tools.signExtend(bits.readBits(nbits), nbits);
					var cdy = Tools.signExtend(bits.readBits(nbits), nbits);
					var adx = Tools.signExtend(bits.readBits(nbits), nbits);
					var ady = Tools.signExtend(bits.readBits(nbits), nbits);
					recs.push(SHRCurvedEdge(cdx, cdy, adx, ady));
				}
			}
			else {
				var flags = bits.readBits(5);

				if (flags == 0) {
					// End record
					recs.push(SHREnd);
					break;
				}
				else {
					// Change record
					var cdata : ShapeChangeRec = {
						moveTo : null,
						fillStyle0 : null,
						fillStyle1 : null,
						lineStyle : null,
						newStyles : null
					};
					if (flags & 1 != 0) {
						// Move 
						var mbits = bits.readBits(5);
						var dx = Tools.signExtend(bits.readBits(mbits), mbits);
						var dy = Tools.signExtend(bits.readBits(mbits), mbits);
						cdata.moveTo = {
							dx: dx,
							dy: dy
						};
					}
					if (flags & 2 != 0) {
						cdata.fillStyle0 = { idx: bits.readBits(fillBits) }
					}
					if (flags & 4 != 0) {
						cdata.fillStyle1 = { idx: bits.readBits(fillBits) }
					}
					if (flags & 8 != 0) {
						cdata.lineStyle = { idx: bits.readBits(lineBits) }
					}
					//
					// WARN: Can Shape4 and above use the New state?
					// doc mentions 2&3 only
					//
					if ((flags & 16 != 0)) {
						var fst = readFillStyles(ver);
						var lst = readLineStyles(ver);
						bits.reset();
						fillBits = bits.readBits(4);
						lineBits = bits.readBits(4);
						cdata.newStyles = {
							fillStyles: fst,
							lineStyles: lst
						}						
					}
					recs.push(SHRChange(cdata));
				}
			}

		} while (true);

		return recs;
	}

	function readClipEvents() : Array<ClipEvent> {
		if( i.readUInt16() != 0 ) throw error();
		i.readUInt30(); // all events flags
		var a = new Array();
		while( true ) {
			var code = i.readUInt30();
			if( code == 0 ) break;
			var data = i.read(i.readUInt30());
			a.push({ eventsFlags : code, data : data });
		}
		return a;
	}

	function readFilterFlags(top) {
		var flags = i.readByte();
		return {
			inner : flags & 128 != 0,
			knockout : flags & 64 != 0,
			// composite : flags & 32 != 0, // always 1 ?
			ontop : top ? (flags & 16 != 0) : false,
			passes : flags & (top ? 15 : 31),
		};
	}

	function readFilterGradient() : GradientFilterData {
		var ncolors = i.readByte();
		var colors = new Array();
		for( i in 0...ncolors )
			colors.push({ color : readRGBA(), position : 0 });
		for( c in colors )
			c.position = i.readByte();
		var data : FilterData = {
			color : null,
			color2 : null,
			blurX : readFixed(),
			blurY : readFixed(),
			angle : readFixed(),
			distance : readFixed(),
			strength : readFixed8(),
			flags : readFilterFlags(true),
		};
		return {
			colors : colors,
			data : data,
		};
	}

	function readFilter() {
		var n = i.readByte();
		return switch( n ) {
			case 0: FDropShadow({
				color : readRGBA(),
				color2 : null,
				blurX : readFixed(),
				blurY : readFixed(),
				angle : readFixed(),
				distance : readFixed(),
				strength : readFixed8(),
				flags : readFilterFlags(false),
			});
			case 1: FBlur({
				blurX : readFixed(),
				blurY : readFixed(),
				passes : i.readByte() >> 3
			});
			case 2: FGlow({
				color : readRGBA(),
				color2 : null,
				blurX : readFixed(),
				blurY : readFixed(),
				angle : haxe.Int32.ofInt(0),
				distance : haxe.Int32.ofInt(0),
				strength : readFixed8(),
				flags : readFilterFlags(false),
			});
			case 3: FBevel({
				color : readRGBA(),
				color2 : readRGBA(),
				blurX : readFixed(),
				blurY : readFixed(),
				angle : readFixed(),
				distance : readFixed(),
				strength : readFixed8(),
				flags : readFilterFlags(true),
			});
			case 5:
				// ConvolutionFilter
				throw error();
			case 4: FGradientGlow(readFilterGradient());
			case 6:
				var a = new Array();
				for( n in 0...20 )
					a.push(i.readFloat());
				FColorMatrix(a);
			case 7: FGradientBevel(readFilterGradient());
			default:
				throw error();
				null;
		}
	}

	function readFilters() {
		var filters = new Array();
		for( i in 0...i.readByte() )
			filters.push(readFilter());
		return filters;
	}

	function error() {
		return "Invalid SWF";
	}

	public function readHeader() : SWFHeader {
		var tag = i.readString(3);
		var compressed;
		if( tag == "CWS" )
			compressed = true;
		else if( tag == "FWS" )
			compressed = false;
		else
			throw error();
		version = i.readByte();
		var size = i.readUInt30();
		if( compressed ) {
			var bytes = format.tools.Inflate.run(i.readAll());
			if( bytes.length + 8 != size ) throw error();
			i = new haxe.io.BytesInput(bytes);
		}
		bits = new format.tools.BitsInput(i);
		var r = readRect();
      if( (r.right - r.left) % 20 != 0 || (r.bottom - r.top) % 20 != 0)
			throw error();
		var fps = readFixed8();
		var nframes = i.readUInt16();
		return {
			version : version,
			compressed : compressed,
			width : Std.int(r.right/20),
			height : Std.int(r.bottom/20),
			fps : fps,
			nframes : nframes,
		};
	}

	public function readTagList() {
		var a = new Array();
		while( true ) {
			var t = readTag();
			if( t == null )
				break;
			a.push(t);
		}
		return a;
	}

	function readShape(len : Int, ver : Int) {
		var id = i.readUInt16();

		if (ver <= 3) {
			var bounds = readRect();
			var sws = readShapeWithStyle(ver);
			// var remain = len - 2 - Math.ceil(bitsRead/8.0);
			return TShape(id, switch (ver) {
				case 1: SHDShape1(bounds, sws);
				case 2: SHDShape2(bounds, sws);
				case 3: SHDShape3(bounds, sws);
				default: throw error();
			});
		}

		var shapeBounds = readRect();
		var edgeBounds = readRect();
		bits.readBits(5);
		var useWinding = bits.read();
		var useNonScalingStroke = bits.read();
		var useScalingStroke = bits.read();
		var shapes = readShapeWithStyle(ver);
		
		return TShape(id, SHDShape4({
			shapeBounds: shapeBounds,
			edgeBounds: edgeBounds,
			useWinding: useWinding,
			useNonScalingStroke: useNonScalingStroke,
			useScalingStroke: useScalingStroke,
			shapes: shapes
		}));
	}

	function readMorphGradient(ver: Int) {
		var sr = i.readByte();
		var sc = readRGBA(i);
		var er = i.readByte();
		var ec = readRGBA(i);

		return {
			startRatio: sr,
			startColor: sc,
			endRatio: er,
			endColor: ec
		};
	}

	function readMorphGradients(ver: Int) {
		var num = i.readByte();
		if(num < 1 || num > 8)
			throw "Invalid number of morph gradients ("+num+"). Should be in range 1..8!";

		var grads = new Array<MorphGradient>();
		for(i in 0...num) {
			grads.push(readMorphGradient(ver));
		}

		return grads;
	}

	function readMorphFillStyle(ver: Int) {
		var type = i.readByte();
		
		return switch( type ) {
			case FillStyleTypeId.Solid:
				var startColor = readRGBA(i);
				var endColor = readRGBA(i);

				return MFSSolid(startColor, endColor);
			case
				FillStyleTypeId.LinearGradient,
				FillStyleTypeId.RadialGradient,
				FillStyleTypeId.FocalRadialGradient:
				
				var startMatrix = readMatrix();
				var endMatrix = readMatrix();
				var grads = readMorphGradients(ver);

				switch (type) {
					case FillStyleTypeId.LinearGradient:
						MFSLinearGradient(startMatrix, endMatrix, grads);
					case FillStyleTypeId.RadialGradient:
						MFSRadialGradient(startMatrix, endMatrix, grads);
					default: throw error();
				}
			case 
				FillStyleTypeId.RepeatingBitmap,
				FillStyleTypeId.ClippedBitmap,
				FillStyleTypeId.NonSmoothedRepeatingBitmap,
				FillStyleTypeId.NonSmoothedClippedBitmap:
				
				var cid = i.readUInt16();
				var startMatrix = readMatrix();
				var endMatrix = readMatrix();
				var isRepeat = (type == FillStyleTypeId.RepeatingBitmap || type == FillStyleTypeId.NonSmoothedRepeatingBitmap);
				var isSmooth = (type == FillStyleTypeId.RepeatingBitmap || type == FillStyleTypeId.ClippedBitmap);
				MFSBitmap(cid, startMatrix, endMatrix, isRepeat, isSmooth);
				
			default: throw error() + " code " + type;
		};
	}

	function readMorphFillStyles(ver: Int) {
		var len = i.readByte();
		if(len == 0xff)
			len = i.readUInt16();

		var fill_styles = new Array<MorphFillStyle>();
		for(i in 0...len) {
			fill_styles.push(readMorphFillStyle(ver));
		}

		return fill_styles;
	}

	function readMorph1LineStyle() {
		var sw = i.readUInt16();
		var ew = i.readUInt16();
		var sc = readRGBA(i);
		var ec = readRGBA(i);

		return {
			startWidth: sw,
			endWidth: ew,
			startColor: sc,
			endColor: ec
		};
	}

	function readMorph2LineStyle() {
		var startWidth = i.readUInt16();
		var endWidth = i.readUInt16();
		bits.reset();
		var startCapStyle = bits.readBits(2);
		var joinStyle  = bits.readBits(2);
		var hasFill = bits.read();
		var noHScale = bits.read();
		var noVScale = bits.read();
		var pixelHinting = bits.read();
		bits.readBits(5);
		var noClose = bits.read();
		var endCapStyle = bits.readBits(2);
		bits.reset();

		var morphData: Morph2LineStyleData = {
			startWidth: startWidth,
			endWidth: endWidth,
			startCapStyle: switch(startCapStyle) {
				case 0: LCRound;
				case 1: LCNone;
				case 2: LCSquare;
			},
			joinStyle: switch(joinStyle) {
				case 0: LJRound;
				case 1: LJBevel;
				case 2: LJMiter(readFixed8(i));
			},
			noHScale: noHScale,
			noVScale: noVScale,
			pixelHinting: pixelHinting,
			noClose: noClose,
			endCapStyle: switch(endCapStyle) {
				case 0: LCRound;
				case 1: LCNone;
				case 2: LCSquare;
			}
		};

		if(hasFill)
			return M2LSFill(readMorphFillStyle(2), morphData);

		var startColor = readRGBA(i);
		var endColor = readRGBA(i);
		return M2LSNoFill(startColor, endColor, morphData);
	}

	function readMorph1LineStyles() {
		var len = i.readByte();
		if(len == 0xff)
			len = i.readUInt16();

		var styles = new Array<Morph1LineStyle>();

		for(i in 0...len) {
			styles.push(readMorph1LineStyle());
		}

		return styles;
	}
	
	function readMorph2LineStyles() {
		var len = i.readByte();
		if(len == 0xff)
			len = i.readUInt16();

		var styles = new Array<Morph2LineStyle>();

		for(i in 0...len) {
			styles.push(readMorph2LineStyle());
		}

		return styles;
	}

	function readMorphShape(ver: Int) {
		var id = i.readUInt16();

		var startBounds = readRect();
		var endBounds = readRect();
		switch(ver) {
			case 1:
				i.readUInt30();
				var fillStyles = readMorphFillStyles(ver);
				var lineStyles = readMorph1LineStyles();
				var startEdges = readShapeWithoutStyle(3); // Assume DefineShape3
				bits.reset();
				var endEdges = readShapeWithoutStyle(3);

				return TMorphShape(id, MSDShape1({
					startBounds: startBounds,
					endBounds: endBounds,
					fillStyles: fillStyles,
					lineStyles: lineStyles,
					startEdges: startEdges,
					endEdges: endEdges
				}));

			case 2:
				var startEdgeBounds = readRect();
				var endEdgeBounds = readRect();
				bits.reset();
				bits.readBits(6);
				var useNonScalingStrokes = bits.read();
				var useScalingStrokes = bits.read();
				bits.reset();
				i.readUInt30();
				var fillStyles = readMorphFillStyles(ver);
				var lineStyles = readMorph2LineStyles();
				var startEdges = readShapeWithoutStyle(4); // Assume DefineShape4
				bits.reset();
				var endEdges = readShapeWithoutStyle(4);

				return TMorphShape(id, MSDShape2({
					startBounds: startBounds,
					endBounds: endBounds,
					startEdgeBounds: startEdgeBounds,
					endEdgeBounds: endEdgeBounds,
					useNonScalingStrokes: useNonScalingStrokes,
					useScalingStrokes: useScalingStrokes,
					fillStyles: fillStyles,
					lineStyles: lineStyles,
					startEdges: startEdges,
					endEdges: endEdges
				}));
			
			default: throw "Unsupported morph fill style version!";
		}
	}

	function readBlendMode() {
		return switch( i.readByte() ) {
		case 0,1: BNormal;
		case 2: BLayer;
		case 3: BMultiply;
		case 4: BScreen;
		case 5: BLighten;
		case 6: BDarken;
		case 7: BAdd;
		case 8: BSubtract;
		case 9: BDifference;
		case 10: BInvert;
		case 11: BAlpha;
		case 12: BErase;
		case 13: BOverlay;
		case 14: BHardLight;
		default: throw error();
		}
	}

	function readPlaceObject(v3) : PlaceObject {
		var f = i.readByte();
		var f2 = if( v3 ) i.readByte() else 0;
		if( f2 >> 3 != 0 ) throw error(); // unsupported bit flags
		var po = new PlaceObject();
		po.depth = i.readUInt16();
		if( f & 1 != 0 ) po.move = true;
		if( f & 2 != 0 ) po.cid = i.readUInt16();
		if( f & 4 != 0 ) po.matrix = readMatrix();
		if( f & 8 != 0 ) po.color = readCXA();
		if( f & 16 != 0 ) po.ratio = i.readUInt16();
		if( f & 32 != 0 ) po.instanceName = readUTF8Bytes().toString();
		if( f & 64 != 0 ) po.clipDepth = i.readUInt16();
		if( f2 & 1 != 0 ) po.filters = readFilters();
		if( f2 & 2 != 0 ) po.blendMode = readBlendMode();
		if( f2 & 4 != 0 ) po.bitmapCache = true;
		if( f & 128 != 0 ) po.events = readClipEvents();
		return po;
	}

	function readLossless(len,v2) {
		var cid = i.readUInt16();
		var bits = i.readByte();
		return {
			cid : cid,
			width : i.readUInt16(),
			height : i.readUInt16(),
			color : switch( bits ) {
				case 3: CM8Bits(i.readByte());
				case 4: CM15Bits;
				case 5: if( v2 ) CM32Bits else CM24Bits;
				default: throw error();
			},
			data : i.read(len - (if(bits == 3) 8 else 7)),
		};
	}

	function readSymbols() : Array<SymData> {
		var sl = new Array<SymData>();
		for( n in 0...i.readUInt16() )
			sl.push({
				cid : i.readUInt16(),
				className : i.readUntil(0),
			});
		return sl;
	}

	function readSound( len : Int ) {
		var sid = i.readUInt16();
		bits.reset();
		var soundFormat = switch( bits.readBits(4) ) {
			case 0: SFNativeEndianUncompressed;
			case 1: SFADPCM;
			case 2: SFMP3;
			case 3: SFLittleEndianUncompressed;
			case 4: SFNellymoser16k;
			case 5: SFNellymoser8k;
			case 6: SFNellymoser;
			case 11: SFSpeex;
			default: throw error();
		};
		var soundRate = switch( bits.readBits(2) ) {
			case 0: SR5k;
			case 1: SR11k;
			case 2: SR22k;
			case 3: SR44k;
			default: throw error();
		};
		var is16bit = bits.read();
		var isStereo = bits.read();
		var soundSamples = i.readInt32(); // number of pairs in case of stereo
		var sdata = switch (soundFormat) {
			case SFMP3:
				var seek = i.readInt16();
				SDMp3(seek,i.read(len-9));
			case SFLittleEndianUncompressed:
				SDRaw(i.read(len - 7));
			default:
				SDOther(i.read(len - 7));
		};
		return TSound({
			sid : sid,
			format : soundFormat,
			rate : soundRate,
			is16bit : is16bit,
			isStereo : isStereo,
			samples : soundSamples,
			data : sdata,
		});
	}

	function readLanguage() {
		return switch(i.readByte()) {
			case 0: LangCode.LCNone;
			case 1: LCLatin;
			case 2: LCJapanese;
			case 3: LCKorean;
			case 4: LCSimplifiedChinese;
			case 5: LCTraditionalChinese;
			default: throw "Unknown language code!";
		}
	}

	function readGlyphs(len: Int, offsets: Array<Int>) {
		var shape_data = i.read(len);
		
		var glyphs = new Array<ShapeWithoutStyleData>();
		if(offsets.length == 0)
			return glyphs;

		for(offs in offsets) {
			var old_i = i;
			var old_bits = bits;
			i = new haxe.io.BytesInput(shape_data, offs);
			bits = new format.tools.BitsInput(i);

			glyphs.push(readShapeWithoutStyle(1));

			i = old_i;
			bits = old_bits;
		}

		return glyphs;
	}

	function readKerningRecord(hasWideCodes: Bool) {
		return {
			charCode1: if(hasWideCodes) i.readUInt16() else i.readByte(),
			charCode2: if(hasWideCodes) i.readUInt16() else i.readByte(),
			adjust: i.readInt16()
		};
	}

	function readFont1Data(len: Int) {
		var offs1 = i.readUInt16();
		var num_glyphs = offs1 >> 1;

		var offset_table = new Array<Int>();

		offset_table.push(0);
		for(j in 1...num_glyphs)
			offset_table.push(i.readUInt16() - offs1);

		return FDFont1({
			glyphs: readGlyphs(len - 2 - num_glyphs * 2, offset_table)
		});
	}

	function readFont2Data(ver: Int) {
		bits.reset();
		var hasLayout = bits.read();
		var shiftJIS = bits.read();
		var isSmall = bits.read();
		var isANSI = bits.read();
		var hasWideOffsets = bits.read();
		var hasWideCodes = bits.read();
		var isItalic = bits.read();
		var isBold = bits.read();

		var language = readLanguage();
		var name = i.readString(i.readByte());
		var num_glyphs = i.readUInt16();

		var offset_table = new Array<Int>();
		var shape_data_length: Int = 0;
		if(hasWideOffsets) {
			var first_glyph_offset = num_glyphs * 4 + 4;

			for(j in 0...num_glyphs)
				offset_table.push(i.readUInt30() - first_glyph_offset);

			var code_table_offset = i.readUInt30();
			shape_data_length = code_table_offset - first_glyph_offset;
		
		} else {
			var first_glyph_offset = num_glyphs * 2 + 2;
			for(j in 0...num_glyphs) {
				var offs = i.readUInt16();
				offset_table.push(offs - first_glyph_offset);
			}
			
			var code_table_offset = i.readUInt16();
			shape_data_length = code_table_offset - first_glyph_offset;
		}

		var glyph_shapes = readGlyphs(shape_data_length, offset_table);
		var glyphs = new Array<Font2GlyphData>();

		if(hasWideCodes) {
			for(j in 0...num_glyphs)
				glyphs.push({
					charCode: i.readUInt16(),
					shape: glyph_shapes[j]
				});

		} else {
			for(j in 0...num_glyphs)
				glyphs.push({
					charCode: i.readByte(),
					shape: glyph_shapes[j]
				});
		}

		var layout: Null<FontLayoutData> = null;
		if(hasLayout) {
			var ascent = i.readInt16();
			var descent = i.readInt16();
			var leading = i.readInt16();
			
			var advance_table = new Array<Int>();
			for(j in 0...num_glyphs)
				advance_table.push(i.readInt16());

			var glyph_layout = new Array<FontLayoutGlyphData>();
			for(j in 0...num_glyphs) {
				var bounds = readRect();

				glyph_layout.push({
					advance: advance_table[j],
					bounds: bounds
				});
			}

			var num_kerning = i.readUInt16();
			var kerning = new Array<FontKerningData>();
			for(i in 0...num_kerning)
				kerning.push(readKerningRecord(hasWideCodes));

			layout = {
				ascent: ascent,
				descent: descent,
				leading: leading,
				glyphs: glyph_layout,
				kerning: kerning
			};
		}

		var f2data: Font2Data = {
			shiftJIS: shiftJIS,
			isSmall: isSmall,
			isANSI: isANSI,
			isItalic: isItalic,
			isBold: isBold,
			language: language,
			name: name,
			glyphs: glyphs,
			layout: layout
		};

		return switch(ver) {
			case 2: FDFont2(hasWideCodes, f2data);
			case 3: FDFont3(f2data);
		};
	}

	function readFont(len: Int, ver: Int) {
		var cid = i.readUInt16();

		return TFont(cid, switch(ver) {
			case 1:
				readFont1Data(len);

			case 2:
				readFont2Data(ver);

			case 3:
				readFont2Data(ver);
		});
	}

	function readFontInfo(len:Int, ver: Int) {
		var cid = i.readUInt16();
		var name = i.readString(i.readByte());

		bits.reset();
		bits.readBits(2);
		var isSmall = bits.read();
		var shiftJIS = bits.read();
		var isANSI = bits.read();
		var isItalic = bits.read();
		var isBold = bits.read();
		var hasWideCodes = bits.read();
		var language = if(ver == 2) readLanguage() else LangCode.LCNone;

		var num_glyphs = len - 4 - name.length;
		var code_table = new Array<Int>();
		
		if(hasWideCodes) {
			num_glyphs >>= 1;
			for(j in 0...num_glyphs)
				code_table.push(i.readUInt16());

		} else { 
			for(j in 0...num_glyphs)
				code_table.push(i.readByte());
		}

		var fi_data: FIData = {
			name: name,
			isSmall: isSmall,
			isItalic: isItalic,
			isBold: isBold,
			codeTable: code_table
		};

		return TFontInfo(cid, switch(ver) {
			case 1: FIDFont1(shiftJIS, isANSI, hasWideCodes, fi_data);
			case 2: FIDFont2(language, fi_data);
		});
	}

	public function readTag() : SWFTag {
		var h = i.readUInt16();
		var id = h >> 6;
		var len = h & 63;
		var ext = false;
		if( len == 63 ) {
			len = i.readUInt30();
			if( len < 63 ) ext = true;
		}
      
      // It's safer to read the whole tag than to rely on
      // reading every data. For example swfc from swftools
      // creates SetBackgroundColor tag with a length of 5
      // (I don't know why) but the reader reads only 3 bytes
      // and gets confused afer that.
      // -- KukkerMan
      var old_i = i;
      var old_bits = bits;
      i = new haxe.io.BytesInput(i.read(len));
      bits = new format.tools.BitsInput(i);

		var tag = switch( id ) {
		case TagId.End:
			null;
		case TagId.ShowFrame:
			TShowFrame;
		case TagId.DefineShape:
			readShape(len,1);
		case TagId.DefineShape2:
			readShape(len,2);
		case TagId.DefineShape3:
			readShape(len,3);
		case TagId.DefineShape4:
			readShape(len,4);
		case TagId.DefineMorphShape:
			readMorphShape(1);
		case TagId.DefineMorphShape2:
			readMorphShape(2);
		
		case TagId.DefineFont:
			readFont(len, 1);
		case TagId.DefineFont2:
			readFont(len, 2);
		case TagId.DefineFont3:
			readFont(len, 3);
		case TagId.DefineFontInfo:
			readFontInfo(len, 1);
		case TagId.DefineFontInfo2:
			readFontInfo(len, 2);
		
		case TagId.SetBackgroundColor:
			i.bigEndian = true;
			var color = i.readUInt24();
			i.bigEndian = false;
			TBackgroundColor(color);
		case TagId.DefineBitsLossless:
			TBitsLossless(readLossless(len,false));
		case TagId.DefineBitsLossless2:
			TBitsLossless2(readLossless(len,true));
		case TagId.JPEGTables:
			TJPEGTables(i.read(len));
		case TagId.DefineBits:
			var cid = i.readUInt16();
			TBitsJPEG(cid, JDJPEG1(i.read(len - 2)));
		case TagId.DefineBitsJPEG2:
			var cid = i.readUInt16();
			TBitsJPEG(cid, JDJPEG2(i.read(len - 2)));
		case TagId.DefineBitsJPEG3:
			var cid = i.readUInt16();
			var dataSize = i.readUInt30();
			var data = i.read(dataSize);
			var mask = i.read(len - dataSize - 6);
			TBitsJPEG(cid, JDJPEG3(data, mask));
		case TagId.PlaceObject2:
			TPlaceObject2(readPlaceObject(false));
		case TagId.PlaceObject3:
			TPlaceObject3(readPlaceObject(true));
		case TagId.RemoveObject2:
			TRemoveObject2(i.readUInt16());
		case TagId.DefineSprite:
			var cid = i.readUInt16();
			var fcount = i.readUInt16();
			var tags = readTagList();
			TClip(cid,fcount,tags);
		case TagId.FrameLabel:
			var label = readUTF8Bytes();
			var anchor = if( len == label.length + 2 ) i.readByte() == 1 else false;
			TFrameLabel(label.toString(),anchor);
		case TagId.DoInitAction:
			var cid = i.readUInt16();
			TDoInitActions(cid,i.read(len-2));
		case TagId.FileAttributes:
         bits.reset();
         bits.read();
         var useDirectBlit = bits.read();
         var useGpu = bits.read();
         var hasMeta = bits.read();
         var useAs3 = bits.read();
         bits.readBits(2);
         var useNetwork = bits.read();
         bits.readBits(24);
			TSandBox(useDirectBlit, useGpu, hasMeta, useAs3, useNetwork);
		case TagId.RawABC:
			TActionScript3(i.read(len),null);
		case TagId.SymbolClass:
			TSymbolClass(readSymbols());
		case TagId.ExportAssets:
			TExportAssets(readSymbols());
		case TagId.DoABC:
			var infos = {
				id : i.readUInt30(),
				label : i.readUntil(0),
			};
			len -= 4 + infos.label.length + 1;
			TActionScript3(i.read(len),infos);
		case TagId.DefineBinaryData:
			var id = i.readUInt16();
			if( i.readUInt30() != 0 ) throw error();
			TBinaryData(id, i.read(len - 6));
		case TagId.DefineSound:
			readSound(len);
		default:
			var data = i.read(len);
			TUnknown(id,data);
		}
      
      i = old_i;
      bits = old_bits;

      return tag;
	}

	public function read() : SWF {
		return {
			header : readHeader(),
			tags : readTagList(),
		};
	}

}
