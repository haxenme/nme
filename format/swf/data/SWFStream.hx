package format.swf.data;


import flash.display.CapsStyle;
import flash.display.InterpolationMethod;
import flash.display.JointStyle;
import flash.display.LineScaleMode;
import flash.display.SpreadMethod;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.text.TextFormatAlign;
import flash.utils.ByteArray;
import flash.utils.Endian;
import flash.utils.IDataInput;


class SWFStream {
	
	
	public var bitPosition:Int;
	public var byteBuffer:Int;
	public var position (getPosition, setPosition):Int;
	public var stream:ByteArray;
	public var tagRead:Int;
	public var tagSize:Int;
	public var version:Int;
	
	private var pushTagRead:Int;
	private var pushTagSize:Int;
	
	
	public function new (bytes:ByteArray) {
		
		stream = bytes;
		
		var signature = "";
		
		signature += String.fromCharCode (stream.readUnsignedByte ());
		signature += String.fromCharCode (stream.readUnsignedByte ());
		signature += String.fromCharCode (stream.readUnsignedByte ());
		
		if (signature != "FWS" && signature != "CWS") {
			
			throw "Invalid signature";
			
		}
		
		version = stream.readUnsignedByte ();
		var length = stream.readInt ();
		
		if (signature == "CWS") {
			
			var buffer = new ByteArray ();
			stream.readBytes (buffer);
			buffer.uncompress ();
			stream = buffer;
			
		}
		
		stream.endian = Endian.LITTLE_ENDIAN;
		
		bitPosition = 0;
		byteBuffer = 0;
		tagRead = 0;
		
	}
	
	
	public function alignBits ():Void {
		
		bitPosition = 0;
		
	}
	
	
	public function beginTag ():Int {
		
		var data = stream.readUnsignedShort ();
		var tag = data >> 6;
		var length = data & 0x3f;
		
		if (tag >= Tags.LAST)
			return 0;
		
		if (length == 0x3F)
			length = stream.readUnsignedInt ();
		
		tagSize = length;
		tagRead = 0;
		
		return tag;
		
	}
	
	
	public function close ():Void {
		
		stream = null;
		
	}
	
	
	public function endTag ():Void {
		
		var read = tagRead;
		var size = tagSize;
		
		if (read > size) {
			
			throw "Tag read overflow";
			
		}
		
		while (read < size) {
			
			stream.readUnsignedByte ();
			read ++;
			
		}
		
	}
	
	
	public function getBytesLeft ():Int { 
		
		return tagSize - tagRead;
		
	}
	
	
	public function getVersion ():Int {
		
		return version;
		
	}
	
	
	public function popTag ():Void {
		
		// should probably count properly ...
		tagRead = pushTagSize;
		tagSize = pushTagSize;
		
	}
	
	
	public function pushTag ():Void {
		
		pushTagRead = tagRead;
		pushTagSize = tagSize;
		
	}
	
	
	public function readAlign () {
		
		switch (readByte ()) {
			
			case 0: return TextFormatAlign.LEFT;
			case 1: return TextFormatAlign.RIGHT;
			case 2: return TextFormatAlign.CENTER;
			case 3: return TextFormatAlign.JUSTIFY;
			
		}
		
		return TextFormatAlign.LEFT;
		
	}
	
	
	public function readArraySize (extended:Bool) {
		
		tagRead++;
		var result = stream.readUnsignedByte ();
		
		if (extended && result == 0xff) {
			
			tagRead += 2;
			result = stream.readUnsignedShort ();
			
		}
		
		return result;
		
	}
	
	
	public function readBits (length:Int, isSigned:Bool = false):Int {
		
		var signBit = length - 1;
		var result = 0;
		var bitsLeft = length;
		
		while (bitsLeft != 0) {
			
			if (bitPosition == 0) {
				
				byteBuffer = stream.readUnsignedByte ();
				tagRead++;
				bitPosition = 8;
				
			}
			
			while (bitPosition > 0 && bitsLeft > 0) {
				
				result = (result << 1) | ((byteBuffer >> 7) & 1);
				bitPosition --;
				bitsLeft --;
				byteBuffer <<= 1;
				
			}
			
		}
		
		if (isSigned) {
			
			var mask = (1 << signBit);
			
			if ((result & mask) != 0) {
				
				result -= (1 << length);
				
			}
			
		}
		
		return result;
		
	}
	
	
	public function readBool ():Bool {
		
		return readBits (1) == 1;
		
	}
	
	
	public function readByte ():Int {
		
		tagRead ++;
		return stream.readUnsignedByte ();
		
	}
	
	
	public function readBytes (length:Int):ByteArray {
		
		var bytes = new ByteArray ();
		stream.readBytes (bytes, 0, length);
		tagRead += length;
		return bytes;
		
	}
	
	
	public function readCapsStyle ():CapsStyle {
		
		switch (readBits (2)) {
			
			case 0: return CapsStyle.ROUND;
			case 1: return CapsStyle.NONE;
			case 2: return CapsStyle.SQUARE;
			
		}
		
		return CapsStyle.ROUND;
		
	}
	
	
	public function readColorTransform (withAlpha:Bool):ColorTransform {
		
		alignBits ();
		
		var result = new ColorTransform ();
		
		var hasOffset = readBool ();
		var hasMultiplier = readBool ();
		
		var length = readBits (4);
		
		if (!hasOffset && !hasMultiplier) {
			
			alignBits ();
			return null;
			
		}
		
		if (hasMultiplier) {
			
			result.redMultiplier = readBits (length, true) / 256.0;
			result.greenMultiplier = readBits (length, true) / 256.0;
			result.blueMultiplier = readBits (length, true) / 256.0;
			
			if (withAlpha) {
				
				result.alphaMultiplier = readBits (length, true) / 256.0;
				
			}
			
		}
		
		if (hasOffset) {
			
			result.redOffset = readBits (length, true);
			result.greenOffset = readBits (length, true);
			result.blueOffset = readBits (length, true);
			
			if (withAlpha) {
				
				result.alphaOffset = readBits (length, true);
				
			}
			
		}
		
		alignBits();
		
		return result;
		
	}
	
	
	public function readDepth ():Int {
		
		tagRead += 2;
		
		return stream.readUnsignedShort ();
		
	}
	
	
	public function readFixed ():Float {
		
		alignBits ();
		
		var frac = readUInt16 () / 65536.0;
		return readUInt16 () + frac;
		
	}
	
	
	public function readFixed8 ():Float {
		
		alignBits ();
		
		var frac = readByte () / 256.0;
		return readByte () + frac;
		
	}
	
	
	public function readFixedBits (length:Int):Float {
		
		return readBits (length, true) / 65536.0;
		
	}
	
	
	public function readFlashBytes (length:Int):ByteArray {
		
		var bytes = new ByteArray ();
		stream.readBytes (bytes, 0, length);
		tagRead += length;
		return bytes;
		
	}
	
	
	public function readFloat ():Float {
		
		tagRead += 4;
		return stream.readInt ();
		
	}
	
	
	public function readFrameRate ():Float {
		
		return stream.readUnsignedShort () / 256.0;
		
	}
	
	
	public function readFrames ():Int {
		
		return stream.readUnsignedShort ();
		
	}
	
	
	public function readID ():Int {
		
		tagRead += 2;
		
		return stream.readUnsignedShort ();
		
	}
	
	
	public function readInt ():Int {
		
		tagRead += 4;
		return stream.readInt ();
		
	}
	
	
	public function readInterpolationMethod ():InterpolationMethod {
		
		switch (readBits (2)) {
			
			case 0: return InterpolationMethod.RGB;
			case 1: return InterpolationMethod.LINEAR_RGB;
			
		}
		
		return InterpolationMethod.RGB;
		
	}
	
	
	public function readJoinStyle ():JointStyle {
		
		switch (readBits (2)) {
			
			case 0: return JointStyle.ROUND;
			case 1: return JointStyle.BEVEL;
			case 2: return JointStyle.MITER;
			
		}
		
		return JointStyle.ROUND;
		
	}
	
	
	public function readMatrix ():Matrix {
		
		var result = new Matrix ();
		
		alignBits ();
		
		var hasScale = readBool ();
		var scaleBits = hasScale ? readBits (5) : 0;
		
		result.a = hasScale ? readFixedBits (scaleBits) : 1.0;
		result.d = hasScale ? readFixedBits (scaleBits) : 1.0;
		
		var hasRotate = readBool ();
		var rotateBits = hasRotate ? readBits (5) : 0;
		
		result.b = hasRotate ? readFixedBits (rotateBits) : 0.0;
		result.c = hasRotate ? readFixedBits (rotateBits) : 0.0;
		
		var transBits = readBits (5);
		
		result.tx = readTwips (transBits);
		result.ty = readTwips (transBits);
		
		return result;
		
	}
	
	
	public function readPascalString ():String {
		
		var length = readByte ();
		var result = "";
		
		for (i in 0...length) {
			
			var code = readByte ();
			
			if (code > 0) {
				
				result += String.fromCharCode (code);
				
			}
			
		}
		
		return result;
		
	}
	
	
	public function readRect ():Rectangle {
		
		alignBits ();
		
		var bits = readBits (5);
		
		var x0 = readTwips (bits);
		var x1 = readTwips (bits);
		var y0 = readTwips (bits);
		var y1 = readTwips (bits);
		
		return new Rectangle (x0, y0, (x1 - x0), (y1 - y0));
		
	}
	
	
	public function readRGB ():Int {
		
		tagRead += 3;
		var r:Int = stream.readUnsignedByte ();
		var g:Int = stream.readUnsignedByte ();
		var b:Int = stream.readUnsignedByte ();
		return (r << 16) | (g << 8) | b;
		
	}
	
	
	public function readScaleMode ():LineScaleMode {
		
		switch (readBits (2)) {
			
			case 0: return LineScaleMode.NORMAL;
			case 1: return LineScaleMode.HORIZONTAL;
			case 2: return LineScaleMode.VERTICAL;
			case 3: return LineScaleMode.NONE;
			
		}
		
		return LineScaleMode.NORMAL;
		
	}
	
	
	public function readSInt16 ():Int {
		
		tagRead += 2;
		return stream.readShort ();
		
	}
	
	
	public function readSTwips ():Float {
		
		return readSInt16 () * 0.05;
		
	}
	
	
	public function readSpreadMethod ():SpreadMethod {
		
		switch (readBits (2)) {
			
			case 0: return SpreadMethod.PAD;
			case 1: return SpreadMethod.REFLECT;
			case 2: return SpreadMethod.REPEAT;
			case 3: return SpreadMethod.PAD;
			
		}
		
		return SpreadMethod.REPEAT;
		
	}
	
	
	public function readString ():String {
		
		var result = "";
		
		while (true) {
			
			var code = readByte ();
			
			if (code == 0) {
				
				return result;
				
			}
			
			result += String.fromCharCode (code);
			
		}
		
		return result;
		
	}
	
	
	public function readTwips (length:Int):Float {
		
		return readBits (length, true) * 0.05;
		
	}
	
	
	public function readUInt16 ():Int {
		
		tagRead += 2;
		return stream.readUnsignedShort ();
		
	}
	
	
	public function readUTwips ():Float {
		
		return readUInt16 () * 0.05;
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function getPosition ():Int {
		
		return stream.position;
		
	}
	
	
	private function setPosition (value:Int):Int {
		
		return stream.position = value;
		
	}
	
	
}