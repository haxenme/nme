package native.utils;


import native.geom.Matrix3D;


class Float32Array extends ArrayBufferView, implements ArrayAccess<Float> {
	
	
	static public inline var SBYTES_PER_ELEMENT = 4;
	
	public var BYTES_PER_ELEMENT (default, null):Int;
	public var length (default, null):Int;
	
	
	// Constrctor: length, array, float[], ArrayBuffer + start + len
	public function new (inBufferOrArray:Dynamic, inStart:Int = 0, ?inLen:Null<Int>) {
		
		BYTES_PER_ELEMENT = 4;
		var floats:Array<Float> = inBufferOrArray;
		
		if (floats != null) {
			
			length = floats.length;
			
			super (length << 2);
			
			#if !cpp
			buffer.position = 0;
			#end
			
			for (i in 0...length) {
				
				#if cpp
				untyped __global__.__hxcpp_memory_set_float (bytes, (i << 2), floats[i]);
				#else
				buffer.writeFloat (floats[i]);
				#end
				
			}
			
		} else {
			
			super (inBufferOrArray, inStart, inLen);
			
			if ((byteLength & 0x03) > 0)
				throw ("Invalid array size");
			
			length = byteLength >> 2;
			if (length != (byteLength << 2))
				throw "Invalid length multiple";
			
		}
		
	}
	
	
	public static function fromMatrix (inMatrix:Matrix3D) {
		
		return new Float32Array (inMatrix.rawData);
		
	}
	
	
	inline public function __get (index:Int):Float { return getFloat32 (index << 2); }
	inline public function __set (index:Int, v:Float):Void { setFloat32 (index << 2, v); }
	
	
}