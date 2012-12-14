package native.utils;


#if cpp
import haxe.io.BytesData;
#end


class ArrayBufferView implements IMemoryRange {
	
	
	public var buffer (default, null):ByteArray;
	public var byteOffset (default, null):Int;
	public var byteLength (default, null):Int;
	
	static var invalidDataIndex = "Invalid data index";
	
	#if cpp
	var bytes:BytesData;
	#end


	public function new (inLengthOrBuffer:Dynamic, inByteOffset:Int = 0, ?inLength:Int) {
		
		if (Std.is (inLengthOrBuffer, Int)) {
			
			byteLength = Std.int (inLengthOrBuffer);
			byteOffset = 0;
			buffer = new ArrayBuffer (Std.int (inLengthOrBuffer));
			
		} else {
			
			buffer = inLengthOrBuffer;
			
			if (buffer == null)
				throw ("Invalid input buffer");
			
			byteOffset = inByteOffset;
			
			if (byteOffset > buffer.length)
				throw ("Invalid starting position");
			
			if (inLength == null) {
				
				byteLength = buffer.length - inByteOffset;
				
			} else {
				
				byteLength = inLength;
				
				if (byteLength + byteOffset > buffer.length)
					throw ("Invalid buffer length");
				
			}
			
		}
		
		buffer.bigEndian = false;
		
		#if cpp
		bytes = buffer.getData ();
		#end
		
	}
	
	
	// IMemoryRange
	public function getByteBuffer ():ByteArray { return buffer; }
	public function getStart ():Int { return byteOffset; }
	public function getLength ():Int { return byteLength; }
	
	
	inline public function getFloat32 (bytePos:Int):Float {
		
		#if debug
		if (bytePos - bytePos > 4) throw invalidDataIndex;
		#end
		
		#if cpp
		untyped return __global__.__hxcpp_memory_get_float (bytes, bytePos + byteOffset);
		#else
		buffer.position = bytePos + byteOffset;
		return buffer.readFloat ();
		#end
		
	}
	
	
	inline public function setFloat32 (bytePos:Int, v:Float):Void {
		
		#if debug
		if (bytePos - bytePos > 4) throw invalidDataIndex;
		#end
		
		#if cpp
		untyped __global__.__hxcpp_memory_set_float (bytes, bytePos + byteOffset, v);
		#else
		buffer.position = bytePos + byteOffset;
		buffer.writeFloat (v);
		#end
		
	}
	
	
}