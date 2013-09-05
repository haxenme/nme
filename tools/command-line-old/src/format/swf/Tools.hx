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

class Tools {

	public static function signExtend( v : Int, nbits : Int ) {
		var max = 1 << nbits;
		// sign bit is set
		if( v & (max >> 1) != 0 )
			return v - max;
		return v;
	}

	public inline static function floatFixedBits( i : Int, nbits ) {
		i = signExtend(i,nbits);
		return (i >> 16) + (i & 0xFFFF) / 65536.0;
	}

	public inline static function floatFixed( i : haxe.Int32 ) {
		return haxe.Int32.toInt(haxe.Int32.shr(i,16)) + haxe.Int32.toInt(haxe.Int32.and(i,haxe.Int32.ofInt(0xFFFF))) / 65536.0;
	}

	public inline static function floatFixed8( i : Int ) {
		return (i >> 8) + (i & 0xFF) / 256.0;
	}
	
	public inline static function toFixed8( f : Float ) {
		var i = Std.int(f);
		if( ((i>0)?i:-i) >= 128 )
			throw haxe.io.Error.Overflow;
		if( i < 0 ) i = 256-i;
		return (i << 8) | Std.int((f-i)*256.0);
	}
	
	public inline static function toFixed16( f : Float ) {
		var i = Std.int(f);
		if( ((i>0)?i:-i) >= 32768 )
			throw haxe.io.Error.Overflow;
		if( i < 0 ) i = 65536-i;
		return (i << 16) | Std.int((f-i)*65536.0);
	}

	// All values are treated as unsigned! 
	public inline static function minBits(values: Array<Int>): Int {
		// Accumulate bits in x
		var x: Int = 0;
		for(v in values) {
			// Make sure v is positive!
			if(v < 0) v = -v;
			x |= v;
		}

		// Compute most significant 1 bit
		x |= (x >> 1);
		x |= (x >> 2);
		x |= (x >> 4);
		x |= (x >> 8);
		x |= (x >> 16);

		// Compute ones count (equals the number of bits to represent original value)
		x -= ((x >> 1) & 0x15555555);
		x = (((x >> 2) & 0x33333333) + (x & 0x33333333));
		x = (((x >> 4) + x) & 0x0f0f0f0f);
		x += (x >> 8);
		x += (x >> 16);
		x &= 0x0000003f;

		return x;
	}

	public static function hex( b : haxe.io.Bytes, ?max : Int ) {
		var hex = ["0".code,"1".code,"2".code,"3".code,"4".code,"5".code,"6".code,"7".code,"8".code,"9".code,"A".code,"B".code,"C".code,"D".code,"E".code,"F".code];
		var count = if( max == null || b.length <= max ) b.length else max;
		var buf = new StringBuf();
		for( i in 0...count ) {
			var v = b.get(i);
			buf.addChar(hex[v>>4]);
			buf.addChar(hex[v&15]);
		}
		if( count < b.length )
			buf.add("...");
		return buf.toString();
	}

	public static function bin( b: haxe.io.Bytes, ?maxBytes : Int ) {
		var buf = new StringBuf();
		var cnt = (maxBytes == null) ? b.length : (maxBytes > b.length ? b.length : maxBytes);

		for (i in 0...cnt) {
			var v = b.get(i);
			for (j in 0...8) {
				buf.add(((v >> (7-j)) & 1 == 1) ? "1" : "0");
				if (j == 3)
					buf.add(" ");
			}
			buf.add("  ");
		}
		return buf.toString();
	}

	public static function dumpTag( t : SWFTag, ?max : Int ) {
		var infos:Array<Dynamic> = switch( t ) {
		case TShowFrame: [];
		case TBackgroundColor(color): [StringTools.hex(color,6)];
		case TShape(id,sdata): ["id",id]; // TODO write when TShape final
		case TMorphShape(id,data): ["id",id]; // TODO
		case TFont(id,data): ["id",id]; // TODO
		case TFontInfo(id,data): ["id",id]; // TODO
		case TBinaryData(id,data): ["id",id,"data",hex(data,max)];
		case TClip(id,frames,tags): ["id",id,"frames",frames];
		case TPlaceObject2(po): [Std.string(po)];
		case TPlaceObject3(po): [Std.string(po)];
		case TRemoveObject2(d): ["depth",d];
		case TFrameLabel(label,anchor): ["label",label,"anchor",anchor];
		case TDoInitActions(id,data): ["id",id,"data",hex(data,max)];
		case TActionScript3(data,context): ["context",context,"data",hex(data,max)];
		case TSymbolClass(symbols): [Std.string(symbols)];
		case TExportAssets(symbols): [Std.string(symbols)];
	   case TSandBox(useDirectBlit, useGpu, hasMeta, useAs3, useNetwork): [
         "directBlit", useDirectBlit,
         "gpu", useGpu,
         "meta/symbols", hasMeta,
         "as3", useAs3,
         "net", useNetwork
      ];
		case TBitsLossless(l),TBitsLossless2(l): ["id",l.cid,"color",l.color,"width",l.width,"height",l.height,"data",hex(l.data,max)];
		case TJPEGTables(data): ["data", hex(data,max)];
		case TBitsJPEG(id, jdata): 
			switch (jdata) {
			case JDJPEG1(data): ["id", id, "ver", 1, "data", hex(data,max)];
			case JDJPEG2(data): ["id", id, "ver", 2, "data", hex(data,max)];
			case JDJPEG3(data, mask): ["id", id, "ver", 3, "data", hex(data,max), "mask", hex(mask,max)];
			}
		case TSound(data): ["sid", data.sid, "format", data.format, "rate", data.rate ];
		case TUnknown(id,data): ["id",id,"data",hex(data,max)];
		}
		var b = new StringBuf();
		b.add(Type.enumConstructor(t));
		b.add("(");
		while( infos.length > 0 ) {
			b.add(infos.shift());
			if( infos.length == 0 )
				break;
			b.add(":");
			b.add(infos.shift());
			if( infos.length == 0 )
				break;
			b.add(",");
		}
		b.add(")");
		return b.toString();
	}

}
