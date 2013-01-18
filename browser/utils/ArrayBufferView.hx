package browser.utils;
#if js


import browser.Html5Dom;

typedef ArrayBufferView = browser.ArrayBufferView;

/*class ArrayBufferView implements IMemoryRange {
	
	
	public var buffer(default, null):ByteArray;
	public var byteOffset(default, null):Int;
	public var byteLength(default, null):Int;
	
	static var invalidDataIndex = "Invalid data index";
	
	//var bytes:BytesData;


	public function new(inLengthOrBuffer:Dynamic, inByteOffset:Int = 0, ?inLength:Int) {
		
		if (Std.is(inLengthOrBuffer, Int)) {
			
			byteLength = Std.int(inLengthOrBuffer);
			byteOffset = 0;
			buffer = new ArrayBuffer(Std.int(inLengthOrBuffer));
			
		} else {
			
			buffer = inLengthOrBuffer;
			
			if (buffer == null)
				throw("Invalid input buffer");
			
			byteOffset = inByteOffset;
			
			if (byteOffset > buffer.length)
				throw("Invalid starting position");
			
			if (inLength == null) {
				
				byteLength = buffer.length - inByteOffset;
				
			} else {
				
				byteLength = inLength;
				
				if (byteLength + byteOffset > buffer.length)
					throw("Invalid buffer length");
				
			}
			
		}
		
		buffer.bigEndian = false;
		
		//bytes = buffer.getData();
		
	}
	
	
	// IMemoryRange
	public function getByteBuffer():ByteArray { return buffer; }
	public function getStart():Int { return byteOffset; }
	public function getLength():Int { return byteLength; }
	
	
	inline public function getFloat32(bytePos:Int):Float {
		
		#if debug
		if (bytePos - bytePos > 4) throw invalidDataIndex;
		#end
		
		buffer.position = bytePos + byteOffset;
		return buffer.readFloat();
		
	}
	
	
	inline public function setFloat32(bytePos:Int, v:Float):Void {
		
		#if debug
		if (bytePos - bytePos > 4) throw invalidDataIndex;
		#end
		
		buffer.position = bytePos + byteOffset;
		buffer.writeFloat(v);
		
	}
	
	
}*/


#end