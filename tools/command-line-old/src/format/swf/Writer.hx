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

/*
 *	Used during shape writing to keep track of the number of actual fill and line styles
 *	and the minimum number of bits required for indexing.
*/
typedef ShapeStyleInfo = {
	var numFillStyles: Int;
	var fillBits: Int;
	var numLineStyles: Int;
	var lineBits: Int;
}

class Writer {

	var output : haxe.io.Output;
	var o : haxe.io.BytesOutput;
	var compressed : Bool;
	var bits : format.tools.BitsOutput;

	public function new(o) {
		this.output = o;
	}

	public function write( s : SWF ) {
		writeHeader(s.header);
		for( t in s.tags )
			writeTag(t);
		writeEnd();
	}

	function writeRect(r) {
		var nbits = Tools.minBits([r.left, r.right, r.top, r.bottom]) + 1;
		
		bits.writeBits(5,nbits);
		bits.writeBits(nbits,r.left);
		bits.writeBits(nbits,r.right);
		bits.writeBits(nbits,r.top);
		bits.writeBits(nbits,r.bottom);
		bits.flush();
	}

	inline function writeFixed8(v) {
		o.writeUInt16(v);
	}

	inline function writeFixed(v) {
		o.writeInt32(v);
	}

	function openTMP() {
		var old = o;
		o = new haxe.io.BytesOutput();
		bits.o = o;
		return old;
	}

	function closeTMP(old) {
		var bytes = o.getBytes();
		o = old;
		bits.o = old;
		return bytes;
	}

	public function writeHeader( h : SWFHeader ) {
		compressed = h.compressed;
		output.writeString( compressed ? "CWS" : "FWS" );
		output.writeByte(h.version);
		o = new haxe.io.BytesOutput();
		bits = new format.tools.BitsOutput(o);
		writeRect({ left : 0, top : 0, right : h.width * 20, bottom : h.height * 20 });
		writeFixed8(h.fps);
		o.writeUInt16(h.nframes);
	}

	function writeRGB( c : RGB ) {
		o.writeByte(c.r);
		o.writeByte(c.g);
		o.writeByte(c.b);
	}

	function writeRGBA( c : RGBA ) {
		o.writeByte(c.r);
		o.writeByte(c.g);
		o.writeByte(c.b);
		o.writeByte(c.a);
	}

	function writeMatrix( m : Matrix ) {
		bits.flush();
		if( m.scale != null ) {
			bits.writeBit(true);

			var sx = Tools.toFixed16(m.scale.x);
			var sy = Tools.toFixed16(m.scale.y);
			var nbits = Tools.minBits([sx, sy]) + 1;

			bits.writeBits(5, nbits);
			bits.writeBits(nbits, sx);
			bits.writeBits(nbits, sy);

		} else
			bits.writeBit(false);

		if( m.rotate != null ) {
			bits.writeBit(true);
			
			var rs0 = Tools.toFixed16(m.rotate.rs0);
			var rs1 = Tools.toFixed16(m.rotate.rs1);
			var nbits = Tools.minBits([rs0, rs1]) + 1;

			bits.writeBits(5, nbits);
			bits.writeBits(nbits, rs0);
			bits.writeBits(nbits, rs1);

		} else
			bits.writeBit(false);

		var nbits = Tools.minBits([m.translate.x, m.translate.y]) + 1;

		bits.writeBits(5, nbits);
		bits.writeBits(nbits, m.translate.x);
		bits.writeBits(nbits, m.translate.y);
		
		bits.flush();
	}

	function writeCXAColor(c:RGBA,nbits) {
		bits.writeBits(nbits,c.r);
		bits.writeBits(nbits,c.g);
		bits.writeBits(nbits,c.b);
		bits.writeBits(nbits,c.a);
	}

	function writeCXA( c : CXA ) {
		bits.writeBit(c.add != null);
		bits.writeBit(c.mult != null);
		bits.writeBits(4,c.nbits);
		if( c.mult != null ) writeCXAColor(c.mult,c.nbits);
		if( c.add != null ) writeCXAColor(c.add,c.nbits);
		bits.flush();
	}

	function writeClipEvents( events : Array<ClipEvent> ) {
		o.writeUInt16(0);
		var all = 0;
		for( e in events )
			all |= e.eventsFlags;
		o.writeUInt30(all);
		for( e in events ) {
			o.writeUInt30(e.eventsFlags);
			o.writeUInt30(e.data.length);
			o.write(e.data);
		}
		o.writeUInt16(0);
	}

	function writeFilterFlags(f:FilterFlags,top) {
		var flags = 32;
		if( f.inner ) flags |= 128;
		if( f.knockout ) flags |= 64;
		if( f.ontop ) flags |= 16;
		flags |= f.passes;
		o.writeByte(flags);
	}

	function writeFilterGradient(f:GradientFilterData) {
		o.writeByte(f.colors.length);
		for( c in f.colors )
			writeRGBA(c.color);
		for( c in f.colors )
			o.writeByte(c.position);
		var d = f.data;
		writeFixed(d.blurX);
		writeFixed(d.blurY);
		writeFixed(d.angle);
		writeFixed(d.distance);
		writeFixed8(d.strength);
		writeFilterFlags(d.flags,true);
	}

	function writeFilter( f : Filter ) {
		switch( f ) {
		case FDropShadow(d):
			o.writeByte(0);
			writeRGBA(d.color);
			writeFixed(d.blurX);
			writeFixed(d.blurY);
			writeFixed(d.angle);
			writeFixed(d.distance);
			writeFixed8(d.strength);
			writeFilterFlags(d.flags,false);
		case FBlur(d):
			o.writeByte(1);
			writeFixed(d.blurX);
			writeFixed(d.blurY);
			o.writeByte(d.passes << 3);
		case FGlow(d):
			o.writeByte(2);
			writeRGBA(d.color);
			writeFixed(d.blurX);
			writeFixed(d.blurY);
			writeFixed8(d.strength);
			writeFilterFlags(d.flags,false);
		case FBevel(d):
			o.writeByte(3);
			writeRGBA(d.color);
			writeRGBA(d.color2);
			writeFixed(d.blurX);
			writeFixed(d.blurY);
			writeFixed(d.angle);
			writeFixed(d.distance);
			writeFixed8(d.strength);
			writeFilterFlags(d.flags,true);
		case FGradientGlow(d):
			o.writeByte(5);
			writeFilterGradient(d);
		case FColorMatrix(d):
			o.writeByte(6);
			for( f in d )
				o.writeFloat(f);
		case FGradientBevel(d):
			o.writeByte(7);
			writeFilterGradient(d);
		}
	}

	function writeFilters( filters : Array<Filter> ) {
		o.writeByte(filters.length);
		for( f in filters )
			writeFilter(f);
	}

	function writeBlendMode( b : BlendMode ) {
		o.writeByte(Type.enumIndex(b) + 1);
	}

	function writePlaceObject(po:PlaceObject,v3) {
		var f = 0, f2 = 0;
		if( po.move ) f |= 1;
		if( po.cid != null ) f |= 2;
		if( po.matrix != null ) f |= 4;
		if( po.color != null ) f |= 8;
		if( po.ratio != null ) f |= 16;
		if( po.instanceName != null ) f |= 32;
		if( po.clipDepth != null ) f |= 64;
		if( po.events != null ) f |= 128;
		if( po.filters != null ) f2 |= 1;
		if( po.blendMode != null ) f2 |= 2;
		if( po.bitmapCache ) f2 |= 4;
		o.writeByte(f);
		if( v3 )
			o.writeByte(f2);
		else if( f2 != 0 )
			throw "Invalid place object version";
		o.writeUInt16(po.depth);
		if( po.cid != null ) o.writeUInt16(po.cid);
		if( po.matrix != null ) writeMatrix(po.matrix);
		if( po.color != null ) writeCXA(po.color);
		if( po.ratio != null ) o.writeUInt16(po.ratio);
		if( po.instanceName != null ) {
			o.writeString(po.instanceName);
			o.writeByte(0);
		}
		if( po.clipDepth != null ) o.writeUInt16(po.clipDepth);
		if( po.filters != null ) writeFilters(po.filters);
		if( po.blendMode != null ) writeBlendMode(po.blendMode);
		if( po.events != null ) writeClipEvents(po.events);
	}

	function writeTID( id : Int, len : Int ) {
		var h = (id << 6);
		if( len < 63 )
			o.writeUInt16(h|len);
		else {
			o.writeUInt16(h|63);
			o.writeUInt30(len);
		}
	}

	function writeTIDExt( id : Int, len : Int ) {
		o.writeUInt16((id << 6)|63);
		o.writeUInt30(len);
	}

	function writeSymbols( sl : Array<SymData>, tagid : Int ) {
		var len = 2;
		for( s in sl )
			len += 2 + s.className.length + 1;
		writeTID(tagid,len);
		o.writeUInt16(sl.length);
		for( s in sl ) {
			o.writeUInt16(s.cid);
			o.writeString(s.className);
			o.writeByte(0);
		}
	}

	function writeSound( s : Sound ) {
		var len = 7 + switch( s.data ) {
			case SDMp3(_,data): data.length + 2;
			case SDRaw(data): data.length;
			case SDOther(data): data.length;
		};
		writeTIDExt(TagId.DefineSound, len);
		o.writeUInt16(s.sid);
		bits.writeBits(4, switch( s.format ) {
			case SFNativeEndianUncompressed: 0;
			case SFADPCM: 1;
			case SFMP3: 2;
			case SFLittleEndianUncompressed: 3;
			case SFNellymoser16k: 4;
			case SFNellymoser8k: 5;
			case SFNellymoser: 6;
			case SFSpeex: 11;
		});
		bits.writeBits(2, switch( s.rate ) {
			case SR5k: 0;
			case SR11k: 1;
			case SR22k: 2;
			case SR44k: 3;
		});
		bits.writeBit(s.is16bit);
		bits.writeBit(s.isStereo);
		bits.flush();
		o.writeInt32(s.samples);
		switch( s.data ) {
		case SDMp3(seek,data):
			o.writeInt16(seek);
			o.write(data);
		case SDRaw(data):
			o.write(data);
		case SDOther(data):
			o.write(data);
		};
	}

	function writeGradRecord(ver: Int, grad_record: GradRecord) {
		switch(grad_record) {
			case GRRGB(pos, col):
				if(ver > 2)
					throw "Shape versions higher than 2 require alpha channel in gradient control points!";
				o.writeByte(pos);
				writeRGB(col);

			case GRRGBA(pos, col):
				if(ver < 3)
					throw "Shape versions lower than 3 don't support alpha channel in gradient control points!";
				o.writeByte(pos);
				writeRGBA(col);
		}
	}

	function writeGradient(ver: Int, grad: Gradient) {
		var spread_mode = switch(grad.spread) {
			case SMPad: 		0;
			case SMReflect: 	1;
			case SMRepeat:		2;
			case SMReserved:	3;
		};
		var interpolation_mode = switch(grad.interpolate) {
			case IMNormalRGB:	0;
			case IMLinearRGB:	1;
			case IMReserved1:	2;
			case IMReserved2:	3;
		};
		if(ver < 4 && (spread_mode != 0 || interpolation_mode != 0))
			throw "Spread must be Pad and interpolation mode must be Normal RGB in gradient specification when shape version is lower than 4!";
		
		var num_records = grad.data.length;
		
		if(ver < 4) {
			if(num_records > 8)
				throw "Gradient supports at most 8 control points ("+num_records+" has bee given) when shape verison is lower than 4!";
		} else if(num_records > 15)
			throw "Gradient supports at most 15 control points ("+num_records+" has been given) at shape version 4!";

		bits.writeBits(2, spread_mode);
		bits.writeBits(2, interpolation_mode);
		bits.writeBits(4, num_records);
		bits.flush();

		for(grad_record in grad.data) {
			writeGradRecord(ver, grad_record);
		}
	}

	function writeFocalGradient(ver: Int, grad: FocalGradient) {
		if(ver < 4)
			throw "Focal gradient only supported in shape versions higher than 3!";

		writeGradient(ver, grad.data);
		writeFixed8(grad.focalPoint);
	}

	function writeFillStyle(ver: Int, fill_style: FillStyle) {
		switch(fill_style) {
			case FSSolid(rgb):
				if(ver > 2)
					throw "Fill styles with Shape versions higher than 2 reqire alhpa channel!";

				o.writeByte(FillStyleTypeId.Solid);
				writeRGB(rgb);

			case FSSolidAlpha(rgba):
				if(ver < 3)
					throw "Fill styles with Shape versions lower than 3 doesn't support alhpa channel!";
				
				o.writeByte(FillStyleTypeId.Solid);
				writeRGBA(rgba);
			
			case FSLinearGradient(mat, grad):
				o.writeByte(FillStyleTypeId.LinearGradient);
				writeMatrix(mat);
				writeGradient(ver, grad);
			
			case FSRadialGradient(mat, grad):
				o.writeByte(FillStyleTypeId.RadialGradient);
				writeMatrix(mat);
				writeGradient(ver, grad);

			case FSFocalGradient(mat, grad):
				if(ver > 3)
					throw "Focal gradient fill style only supported with Shape versions higher than 3!";

				o.writeByte(FillStyleTypeId.FocalRadialGradient);
				writeMatrix(mat);
				writeFocalGradient(ver, grad);

			case FSBitmap(cid, mat, repeat, smooth):
				o.writeByte( 
					if(repeat) {
						if(smooth)	FillStyleTypeId.RepeatingBitmap
						else			FillStyleTypeId.NonSmoothedRepeatingBitmap;
					} else {
						if(smooth)	FillStyleTypeId.ClippedBitmap
						else			FillStyleTypeId.NonSmoothedClippedBitmap;
					}
				);
				o.writeUInt16(cid);
				writeMatrix(mat);
		}
	}

	function writeFillStyles(ver: Int, fill_styles: Array<FillStyle>) {
		var num_styles = fill_styles.length;

		bits.flush();

		if(num_styles > 254) {
			if(ver >= 2) {
				o.writeByte(0xff);
				o.writeUInt16(num_styles);
			} else if(num_styles == 255)
				o.writeByte(255);
			else
				throw "Too much fill styles ("+num_styles+") for Shape version 1";
		} else
			o.writeByte(num_styles);

		for(style in fill_styles) {
			writeFillStyle(ver, style);
		}
	}

	function writeLineStyle(ver: Int, line_style: LineStyle) {
		o.writeUInt16(line_style.width);
		switch(line_style.data) {
			case LSRGB(rgb):
				if(ver > 2)
					throw "Line styles with Shape versions higher than 2 reqire alhpa channel!";
					writeRGB(rgb);

			case LSRGBA(rgba):
					if(ver < 3)
						throw "Line styles with Shape versions lower than 3 doesn't support alhpa channel!";
					writeRGBA(rgba);

			case LS2(data):
				if(ver < 4)
					throw "LineStyle version 2 only supported in shape versions higher than 3!";

				bits.writeBits(2, switch(data.startCap) {
					case LCRound:	0;
					case LCNone:	1;
					case LCSquare:	2;
				});
				
				bits.writeBits(2, switch(data.join) {
					case LJRound:					0;
					case LJBevel:					1;
					case LJMiter(limitFactor):	2;
				});

				bits.writeBit(switch(data.fill) {
					case LS2FColor(color):	false;
					case LS2FStyle(style):	true;
				});

				bits.writeBit(data.noHScale);
				bits.writeBit(data.noVScale);
				bits.writeBit(data.pixelHinting);
				bits.writeBits(5, 0);
				bits.writeBit(data.noClose);
				
				bits.writeBits(2, switch(data.endCap) {
					case LCRound:	0;
					case LCNone:	1;
					case LCSquare:	2;
				});

				switch(data.join) {
					case LJMiter(limitFactor):
						writeFixed8(limitFactor);
					default:
				}

				switch(data.fill) {
					case LS2FColor(color):	writeRGBA(color);
					case LS2FStyle(style):	writeFillStyle(ver, style);
				}
		} 
	}
	
	function writeLineStyles(ver: Int, line_styles: Array<LineStyle>) {
		var num_styles = line_styles.length;

		bits.flush();

		if(num_styles > 254) {
			if(ver >= 2) {
				o.writeByte(0xff);
				o.writeUInt16(num_styles);
			} else if(num_styles == 255)
				o.writeByte(255);
			else
				throw "Too much line styles ("+num_styles+") for Shape version 1";
		} else
			o.writeByte(num_styles);

		for(style in line_styles) {
			writeLineStyle(ver, style);
		}
	}

	function writeShapeRecord(ver: Int, style_info: ShapeStyleInfo, shape_record: ShapeRecord) {
		switch(shape_record) {
			case SHREnd:
				bits.writeBit(false);
				bits.writeBits(5, 0);

			case SHRChange(data):
				bits.writeBit(false);
				if(data.newStyles != null) {
					if(ver > 1)
						bits.writeBit(true);
					else
						throw "Defining new fill and line style arrays are only supported in shape versions higher than 1!";
				} else
					bits.writeBit(false);
				bits.writeBit(data.lineStyle != null);
				bits.writeBit(data.fillStyle1 != null);
				bits.writeBit(data.fillStyle0 != null);
				bits.writeBit(data.moveTo != null);

				if(data.moveTo != null) {
					var mb = Tools.minBits([data.moveTo.dx, data.moveTo.dy]) + 1;

					bits.writeBits(5, mb);
					bits.writeBits(mb, data.moveTo.dx);
					bits.writeBits(mb, data.moveTo.dy);
				}

				if(data.fillStyle0 != null) {
					bits.writeBits(style_info.fillBits, data.fillStyle0.idx);
				}
				
				if(data.fillStyle1 != null) {
					bits.writeBits(style_info.fillBits, data.fillStyle1.idx);
				}
				
				if(data.lineStyle != null) {
					bits.writeBits(style_info.lineBits, data.lineStyle.idx);
				}

				if(data.newStyles != null) {
					writeFillStyles(ver, data.newStyles.fillStyles);
					writeLineStyles(ver, data.newStyles.lineStyles);
					
					style_info.numFillStyles += data.newStyles.fillStyles.length;
					style_info.numLineStyles += data.newStyles.lineStyles.length;
					style_info.fillBits = Tools.minBits([style_info.numFillStyles]);
					style_info.lineBits = Tools.minBits([style_info.numLineStyles]);
					
					bits.writeBits(4, style_info.fillBits);
					bits.writeBits(4, style_info.lineBits);
				}

			case SHREdge(dx, dy):
				bits.writeBit(true);
				bits.writeBit(true);
				
				var mb = Tools.minBits([dx, dy]) + 1;
				mb = if(mb < 2) 0 else mb - 2;
				bits.writeBits(4, mb);
				mb += 2;

				var is_general = (dx != 0) && (dy != 0);
				bits.writeBit(is_general);

				if(!is_general) {
					var is_vertical = (dx == 0);
					bits.writeBit(is_vertical);
					if(is_vertical)
						bits.writeBits(mb, dy);
					else
						bits.writeBits(mb, dx);
				} else {
					bits.writeBits(mb, dx);
					bits.writeBits(mb, dy);
				}
					
			case SHRCurvedEdge(cdx, cdy, adx, ady):
				bits.writeBit(true);
				bits.writeBit(false);
				
				var mb = Tools.minBits([cdx, cdy, adx, ady]) + 1;
				mb = if(mb < 2) 0 else mb - 2;
				bits.writeBits(4, mb);
				mb += 2;

				bits.writeBits(mb, cdx);
				bits.writeBits(mb, cdy);
				bits.writeBits(mb, adx);
				bits.writeBits(mb, ady);
		}
	}
	
	function writeShapeWithoutStyle(ver: Int, data: ShapeWithoutStyleData) {
		var style_info: ShapeStyleInfo = {
			numFillStyles: 0,
			fillBits: 1,
			numLineStyles: 0,
			lineBits: 1
		};
		
		bits.writeBits(4, style_info.fillBits);
		bits.writeBits(4, style_info.lineBits);
		bits.flush();

		for(shr in data.shapeRecords) {
			writeShapeRecord(ver, style_info, shr);
		}
		bits.flush();
	}

	function writeShapeWithStyle(ver: Int, data: ShapeWithStyleData) {
		writeFillStyles(ver, data.fillStyles);
		writeLineStyles(ver, data.lineStyles);

		var style_info: ShapeStyleInfo = {
			numFillStyles: data.fillStyles.length,
			fillBits: Tools.minBits([data.fillStyles.length]),
			numLineStyles: data.lineStyles.length,
			lineBits: Tools.minBits([data.lineStyles.length]),
		};
		
		bits.writeBits(4, style_info.fillBits);
		bits.writeBits(4, style_info.lineBits);
		bits.flush();

		for(shr in data.shapeRecords) {
			writeShapeRecord(ver, style_info, shr);
		}
		bits.flush();
	}
	
	public function writeShape(id: Int, data: ShapeData) {
		var old = openTMP();

		o.writeUInt16(id);

		switch(data) {
			case SHDShape1(bounds, shapes):
				writeRect(bounds);
				writeShapeWithStyle(1, shapes);

			case SHDShape2(bounds, shapes):
				writeRect(bounds);
				writeShapeWithStyle(2, shapes);

			case SHDShape3(bounds, shapes):
				writeRect(bounds);
				writeShapeWithStyle(3, shapes);

			case SHDShape4(data):
				writeRect(data.shapeBounds);
				writeRect(data.edgeBounds);
				bits.writeBits(5, 0);
				bits.writeBit(data.useWinding);
				bits.writeBit(data.useNonScalingStroke);
				bits.writeBit(data.useScalingStroke);
				bits.flush();
				writeShapeWithStyle(4, data.shapes);
		}

		bits.flush();
		var shape_data = closeTMP(old);

		switch(data) {
			case SHDShape1(bounds, shapes):
				writeTID(TagId.DefineShape, shape_data.length);

			case SHDShape2(bounds, shapes):
				writeTID(TagId.DefineShape2, shape_data.length);

			case SHDShape3(bounds, shapes):
				writeTID(TagId.DefineShape3, shape_data.length);

			case SHDShape4(data):
				writeTID(TagId.DefineShape4, shape_data.length);
		}

		o.write(shape_data);
	}

	function writeMorphGradient(ver: Int, g: MorphGradient) {
		o.writeByte(g.startRatio);
		writeRGBA(g.startColor);
		o.writeByte(g.endRatio);
		writeRGBA(g.endColor);
	}

	function writeMorphGradients(ver: Int, gradients: Array<MorphGradient>) {
		var num = gradients.length;
		if(num < 1 || num > 8)
			throw "Number of specified morph gradients ("+num+") must be in range 1..8";

		for(grad in gradients) {
			writeMorphGradient(ver, grad);
		}
	}

	function writeMorphFillStyle(ver: Int, fill_style: MorphFillStyle) {
		switch(fill_style) {
			case MFSSolid(startColor, endColor):
				o.writeByte(FillStyleTypeId.Solid);
				writeRGBA(startColor);
				writeRGBA(endColor);

			case MFSLinearGradient(startMatrix, endMatrix, gradients):
				o.writeByte(FillStyleTypeId.LinearGradient);
				writeMatrix(startMatrix);
				writeMatrix(endMatrix);
				writeMorphGradients(ver, gradients);
			
			case MFSRadialGradient(startMatrix, endMatrix, gradients):
				o.writeByte(FillStyleTypeId.LinearGradient);
				writeMatrix(startMatrix);
				writeMatrix(endMatrix);
				writeMorphGradients(ver, gradients);

			case MFSBitmap(cid, startMatrix, endMatrix, repeat, smooth):
				o.writeByte( 
					if(repeat) {
						if(smooth)	FillStyleTypeId.RepeatingBitmap
						else			FillStyleTypeId.NonSmoothedRepeatingBitmap;
					} else {
						if(smooth)	FillStyleTypeId.ClippedBitmap
						else			FillStyleTypeId.NonSmoothedClippedBitmap;
					}
				);
				o.writeUInt16(cid);
				writeMatrix(startMatrix);
				writeMatrix(endMatrix);
		}
	}

	function writeMorphFillStyles(ver: Int, fill_styles: Array<MorphFillStyle>) {
		var num_styles = fill_styles.length;

		bits.flush();

		if(num_styles > 254) {
			o.writeByte(0xff);
			o.writeUInt16(num_styles);
		} else
			o.writeByte(num_styles);

		for(style in fill_styles) {
			writeMorphFillStyle(ver, style);
		}
	}

	function writeMorph1LineStyle(s: Morph1LineStyle) {
		o.writeUInt16(s.startWidth);
		o.writeUInt16(s.endWidth);
		writeRGBA(s.startColor);
		writeRGBA(s.endColor);
	}

	function writeMorph1LineStyles(line_styles: Array<Morph1LineStyle>) {
		var num_styles = line_styles.length;

		bits.flush();

		if(num_styles > 254) {
			o.writeByte(0xff);
			o.writeUInt16(num_styles);
		} else
			o.writeByte(num_styles);

		for(style in line_styles) {
			writeMorph1LineStyle(style);
		}
	}

	function writeMorph2LineStyle(style: Morph2LineStyle) {
		var m2data: Morph2LineStyleData;

		switch(style) {
			case M2LSNoFill(startColor, endColor, data):
				m2data = data;

			case M2LSFill(fill, data):
				m2data = data;
		}

		o.writeUInt16(m2data.startWidth);
		o.writeUInt16(m2data.endWidth);
		bits.writeBits(2, switch(m2data.startCapStyle) {
			case LCRound:	0;
			case LCNone:	1;
			case LCSquare:	2;
		});
		
		bits.writeBits(2, switch(m2data.joinStyle) {
			case LJRound:					0;
			case LJBevel:					1;
			case LJMiter(limitFactor):	2;
		});

		switch(style) {
			case M2LSNoFill(startColor, endColor, data):
				bits.writeBit(false);

			case M2LSFill(fill, data):
				bits.writeBit(true);
		}

		bits.writeBit(m2data.noHScale);
		bits.writeBit(m2data.noVScale);
		bits.writeBit(m2data.pixelHinting);
		bits.writeBits(5, 0);
		bits.writeBit(m2data.noClose);
		
		bits.writeBits(2, switch(m2data.endCapStyle) {
			case LCRound:	0;
			case LCNone:	1;
			case LCSquare:	2;
		});

		switch(m2data.joinStyle) {
			case LJMiter(limitFactor):
				writeFixed8(limitFactor);
			default:
		}

		switch(style) {
			case M2LSNoFill(startColor, endColor, data):
				writeRGBA(startColor);
				writeRGBA(endColor);

			case M2LSFill(fill, data):
				writeMorphFillStyle(2, fill);
		}
	}
	
	function writeMorph2LineStyles(line_styles: Array<Morph2LineStyle>) {
		var num_styles = line_styles.length;

		bits.flush();

		if(num_styles > 254) {
			o.writeByte(0xff);
			o.writeUInt16(num_styles);
		} else
			o.writeByte(num_styles);

		for(style in line_styles) {
			writeMorph2LineStyle(style);
		}
	}

	public function writeMorphShape(id: Int, data: MorphShapeData) {
		var old = openTMP();

		o.writeUInt16(id);

		switch(data) {
			case MSDShape1(sh1data):
				writeRect(sh1data.startBounds);
				writeRect(sh1data.endBounds);

				var old = openTMP();

				writeMorphFillStyles(1, sh1data.fillStyles);
				writeMorph1LineStyles(sh1data.lineStyles);
				writeShapeWithoutStyle(3, sh1data.startEdges);
				bits.flush();
				
				var part_data = closeTMP(old);

				o.writeUInt30(part_data.length);
				o.write(part_data);
				writeShapeWithoutStyle(3, sh1data.endEdges);

			case MSDShape2(sh2data):
				writeRect(sh2data.startBounds);
				writeRect(sh2data.endBounds);
				writeRect(sh2data.startEdgeBounds);
				writeRect(sh2data.endEdgeBounds);
				bits.writeBits(6, 0);
				bits.writeBit(sh2data.useNonScalingStrokes);
				bits.writeBit(sh2data.useScalingStrokes);
				bits.flush();

				var old = openTMP();

				writeMorphFillStyles(1, sh2data.fillStyles);
				writeMorph2LineStyles(sh2data.lineStyles);
				writeShapeWithoutStyle(4, sh2data.startEdges);
				bits.flush();
				
				var part_data = closeTMP(old);

				o.writeUInt30(part_data.length);
				o.write(part_data);
				writeShapeWithoutStyle(4, sh2data.endEdges);
		}

		bits.flush();
		var morph_shape_data = closeTMP(old);

		switch(data) {
			case MSDShape1(sh1data):
				writeTID(TagId.DefineMorphShape, morph_shape_data.length);
			
			case MSDShape2(sh2data):
				writeTID(TagId.DefineMorphShape2, morph_shape_data.length);

		}

		o.write(morph_shape_data);
	}

	function writeFontGlyphs(glyphs: Array<ShapeWithoutStyleData>) {
		var old = openTMP();

		var offsets = new Array<Int>();
		var offs: Int = 0;

		for(shape in glyphs) {
			offsets.push(offs);
			
			var old = openTMP();
			writeShapeWithoutStyle(1, shape);
			bits.flush();
			var shape_data = closeTMP(old);

			o.write(shape_data);
			offs += shape_data.length;
		}
		
		var glyph_data = closeTMP(old);

		o.write(glyph_data);

		return offsets;
	}

	function writeFont1(data: Font1Data) {
		var old = openTMP();

		var offset_table = writeFontGlyphs(data.glyphs);
		
		if(offset_table.length * 2 + offset_table[offset_table.length - 1] > 0xffff)
			throw "Font version 1 only supports font sizes up to 64kB!";

		bits.flush();
		var shape_data = closeTMP(old);

		var first_glyph_offset = offset_table.length * 2;
		for(offset in offset_table) {
			o.writeUInt16(first_glyph_offset + offset);
		}

		o.write(shape_data);
	}

	function writeFont2(hasWideChars: Bool, data: Font2Data) {
		var glyphs = new Array<ShapeWithoutStyleData>();
		var num_glyphs: Int = data.glyphs.length;
		for(glyph in data.glyphs)
			glyphs.push(glyph.shape);
		
		var old = openTMP();
		var offset_table = writeFontGlyphs(glyphs);
		bits.flush();
		var shape_data = closeTMP(old);

		// If CodeTableOffset doesn't fit into 16bits then use wide offsets (32bits)
		var hasWideOffsets = offset_table.length * 2 + 2 + shape_data.length > 0xffff;

		bits.writeBit(data.layout != null);
		bits.writeBit(data.shiftJIS);
		bits.writeBit(data.isSmall);
		bits.writeBit(data.isANSI);
		bits.writeBit(hasWideOffsets);
		bits.writeBit(hasWideChars);
		bits.writeBit(data.isItalic);
		bits.writeBit(data.isBold);
		bits.flush();
		o.writeByte(switch(data.language) {
			case LCNone: 0;
			case LCLatin: 1;
			case LCJapanese: 2;
			case LCKorean: 3;
			case LCSimplifiedChinese: 4;
			case LCTraditionalChinese: 5;
		});
		o.writeByte(data.name.length);
		o.writeString(data.name);
		o.writeUInt16(num_glyphs);

		if(hasWideOffsets) {
			// OffsetTable size + CodeTabbleOffset field (32bit version)
			var first_glyph_offset = num_glyphs * 4 + 4;
			
			for(offset in offset_table) {
				o.writeUInt30(first_glyph_offset + offset);
			}
			o.writeUInt30(first_glyph_offset + shape_data.length);

		} else {
			// OffsetTable size + CodeTabbleOffset field (16bit version)
			var first_glyph_offset = num_glyphs * 2 + 2;
			
			for(offset in offset_table) {
				o.writeUInt16(first_glyph_offset + offset);
			}
			o.writeUInt16(first_glyph_offset + shape_data.length);
		}

		o.write(shape_data);

		// CodeTable
		if(hasWideChars) {
			for(glyph in data.glyphs) {
				o.writeUInt16(glyph.charCode);
			}

		} else {
			for(glyph in data.glyphs)
				o.writeByte(glyph.charCode);
		}

		if(data.layout != null) {
			o.writeInt16(data.layout.ascent);
			o.writeInt16(data.layout.descent);
			o.writeInt16(data.layout.leading);

			for(g in data.layout.glyphs)
				o.writeUInt16(g.advance);

			for(g in data.layout.glyphs)
				writeRect(g.bounds);

			o.writeUInt16(data.layout.kerning.length);

			if(hasWideChars) {
				for(k in data.layout.kerning) {
					o.writeUInt16(k.charCode1);
					o.writeUInt16(k.charCode2);
					o.writeInt16(k.adjust);
				}
			} else {
				for(k in data.layout.kerning) {
					o.writeByte(k.charCode1);
					o.writeByte(k.charCode2);
					o.writeInt16(k.adjust);
				}

			}
		}
	}

	public function writeFont(id: Int, data: FontData) {
		var old = openTMP();

		o.writeUInt16(id);

		switch(data) {
			case FDFont1(data):
				writeFont1(data);

			case FDFont2(hasWideChars, data):
				writeFont2(hasWideChars, data);

			case FDFont3(data):
				writeFont2(true, data);
		}

		bits.flush();
		var font_data = closeTMP(old);

		switch(data) {
			case FDFont1(data):
				writeTID(TagId.DefineFont, font_data.length);
				
			case FDFont2(hasWideChars, data):
				writeTID(TagId.DefineFont2, font_data.length);

			case FDFont3(data):
				writeTID(TagId.DefineFont3, font_data.length);
		}

		o.write(font_data);
	}

	public function writeFontInfo(id: Int, data: FontInfoData) {
		switch(data) {
			case FIDFont1(shiftJIS, isANSI, hasWideCodes, data):
				var data_length = if(hasWideCodes)
					4 + data.name.length + data.codeTable.length * 2
				else
					4 + data.name.length + data.codeTable.length;

				writeTID(TagId.DefineFontInfo, data_length);
				o.writeUInt16(id);
				o.writeByte(data.name.length);
				o.writeString(data.name);
				bits.writeBits(2, 0);
				bits.writeBit(data.isSmall);
				bits.writeBit(shiftJIS);
				bits.writeBit(isANSI);
				bits.writeBit(data.isItalic);
				bits.writeBit(data.isBold);
				bits.writeBit(hasWideCodes);

				if(hasWideCodes) {
					for(code in data.codeTable)
						o.writeUInt16(code);

				} else {
					for(code in data.codeTable)
						o.writeByte(code);
				}

			case FIDFont2(language, data):
				writeTID(TagId.DefineFontInfo, 5 + data.name.length + data.codeTable.length * 2);
				o.writeUInt16(id);
				o.writeByte(data.name.length);
				o.writeString(data.name);
				bits.writeBits(2, 0);
				bits.writeBit(data.isSmall);
				bits.writeBit(false);
				bits.writeBit(false);
				bits.writeBit(data.isItalic);
				bits.writeBit(data.isBold);
				bits.writeBit(true);

				o.writeByte(switch(language) {
					case LCNone: 0;
					case LCLatin: 1;
					case LCJapanese: 2;
					case LCKorean: 3;
					case LCSimplifiedChinese: 4;
					case LCTraditionalChinese: 5;
				});

				for(code in data.codeTable)
					o.writeUInt16(code);
		}
	}

	public function writeTag( t : SWFTag ) {
		switch( t ) {
		case TUnknown(id,data):
			writeTID(id,data.length);
			o.write(data);

		case TShowFrame:
			writeTID(TagId.ShowFrame,0);

		case TShape(id, sdata):
			writeShape(id, sdata);

		case TMorphShape(id, data):
			writeMorphShape(id, data);

		case TFont(id, data):
			writeFont(id, data);
		
		case TFontInfo(id, data):
			writeFontInfo(id, data);

		case TBinaryData(id, data):
			writeTID(TagId.DefineBinaryData, data.length + 6);
			o.writeUInt16(id);
			o.writeUInt30(0);
			o.write(data);

		case TBackgroundColor(color):
			writeTID(TagId.SetBackgroundColor,3);
			o.bigEndian = true;
			o.writeUInt24(color);
			o.bigEndian = false;

		case TPlaceObject2(po):
			var t = openTMP();
			writePlaceObject(po,false);
			var bytes = closeTMP(t);
			writeTID(TagId.PlaceObject2,bytes.length);
			o.write(bytes);

		case TPlaceObject3(po):
			var t = openTMP();
			writePlaceObject(po,true);
			var bytes = closeTMP(t);
			writeTID(TagId.PlaceObject3,bytes.length);
			o.write(bytes);

		case TRemoveObject2(depth):
			writeTID(TagId.RemoveObject2,2);
			o.writeUInt16(depth);

		case TFrameLabel(label,anchor):
			var bytes = haxe.io.Bytes.ofString(label);
			writeTID(TagId.FrameLabel,bytes.length + 1 + (anchor?1:0));
			o.write(bytes);
			o.writeByte(0);
			if( anchor ) o.writeByte(1);

		case TClip(id,frames,tags):
			var t = openTMP();
			for( t in tags )
				writeTag(t);
			var bytes = closeTMP(t);
			writeTID(TagId.DefineSprite,bytes.length + 6);
			o.writeUInt16(id);
			o.writeUInt16(frames);
			o.write(bytes);
			o.writeUInt16(0); // end-tag

		case TDoInitActions(id,data):
			writeTID(TagId.DoInitAction,data.length + 2);
			o.writeUInt16(id);
			o.write(data);

		case TActionScript3(data,ctx):
			if( ctx == null )
				writeTID(TagId.RawABC,data.length);
			else {
				var len = data.length + 4 + ctx.label.length + 1;
				writeTID(TagId.DoABC,len);
				o.writeUInt30(ctx.id);
				o.writeString(ctx.label);
				o.writeByte(0);
			}
			o.write(data);

		case TSymbolClass(sl):
			writeSymbols(sl, TagId.SymbolClass);
		case TExportAssets(sl):
			writeSymbols(sl, TagId.ExportAssets);

		case TSandBox(useDirectBlit, useGpu, hasMeta, useAs3, useNetwork):
			writeTID(TagId.FileAttributes,4);
         bits.writeBit(false);
         bits.writeBit(useDirectBlit);
         bits.writeBit(useGpu);
         bits.writeBit(hasMeta);
         bits.writeBit(useAs3);
         bits.writeBits(2, 0);
         bits.writeBit(useNetwork);
         bits.writeBits(24, 0);
         bits.flush();

		case TBitsLossless(l):
			var cbits = switch( l.color ) { case CM8Bits(n): n; default: null; };
			writeTIDExt(TagId.DefineBitsLossless,l.data.length + ((cbits == null)?7:8));
			o.writeUInt16(l.cid);
			switch( l.color ) {
			case CM8Bits(_): o.writeByte(3);
			case CM15Bits: o.writeByte(4);
			case CM24Bits: o.writeByte(5);
			default: throw "assert";
			}
			o.writeUInt16(l.width);
			o.writeUInt16(l.height);
			if( cbits != null ) o.writeByte(cbits);
			o.write(l.data);

		case TBitsLossless2(l):
			var cbits = switch( l.color ) { case CM8Bits(n): n; default: null; };
			writeTIDExt(TagId.DefineBitsLossless2,l.data.length + ((cbits == null)?7:8));
			o.writeUInt16(l.cid);
			switch( l.color ) {
			case CM8Bits(_): o.writeByte(3);
			case CM32Bits: o.writeByte(5);
			default: throw "assert";
			}
			o.writeUInt16(l.width);
			o.writeUInt16(l.height);
			if( cbits != null ) o.writeByte(cbits);
			o.write(l.data);

		case TJPEGTables(data):
			writeTIDExt(TagId.JPEGTables, data.length);
			o.write(data);

		case TBitsJPEG(id, jdata):
			switch (jdata) {
			case JDJPEG1(data):
				writeTIDExt(TagId.DefineBits, data.length + 2);
				o.writeUInt16(id);
				o.write(data);
			case JDJPEG2(data):
				writeTIDExt(TagId.DefineBitsJPEG2, data.length + 2);
				o.writeUInt16(id);
				o.write(data);
			case JDJPEG3(data, mask):	
				writeTIDExt(TagId.DefineBitsJPEG3, data.length + mask.length + 6);
				o.writeUInt16(id);
				o.writeUInt30(data.length);
				o.write(data);
				o.write(mask);
			}

		case TSound(data):
			writeSound(data);

		}
	}

	public function writeEnd() {
		o.writeUInt16(0); // end tag
		var bytes = o.getBytes();
		var size = bytes.length;
		if( compressed ) bytes = format.tools.Deflate.run(bytes);
		output.writeUInt30(size + 8);
		output.write(bytes);
	}

}
