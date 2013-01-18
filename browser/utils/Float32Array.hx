package browser.utils;
#if js


import browser.Html5Dom;

typedef Float32Array = browser.Float32Array;

/*import browser.geom.Matrix3D;


class Float32Array extends ArrayBufferView, implements ArrayAccess<Float> {
	
	
	static public inline var SBYTES_PER_ELEMENT = 4;
	
	public var BYTES_PER_ELEMENT(default, null):Int;
	public var length(default, null):Int;
	
	
	// Constrctor: length, array, float[], ArrayBuffer + start + len
	public function new(inBufferOrArray:Dynamic, inStart:Int = 0, ?inLen:Null<Int>) {
		
		BYTES_PER_ELEMENT = 4;
		var floats:Array<Float> = inBufferOrArray;
		
		if (floats != null) {

            if(inLen != null){
                length = inLen;
            }else{
                length = floats.length - inStart;
            }

            // 4 bytes per element -> shift it by two bits to get the lenght in bytes
			super (length << 2);
			
			buffer.position = 0;
			
			for (i in 0...length) {
				
				buffer.writeFloat (floats[i + inStart]);
				
			}
			
		} else {
			
			super(inBufferOrArray, inStart, inLen);
			
			if ((byteLength & 0x03) > 0)
				throw("Invalid array size");
			
			length = byteLength >> 2;
			if (length !=(byteLength << 2))
				throw "Invalid length multiple";
			
		}
		
	}
	
	
	public static function fromMatrix(inMatrix:Matrix3D) {
		
		return new Float32Array(inMatrix.rawData);
		
	}
	
	
	inline public function __get(index:Int):Float { return getFloat32(index << 2); }
	inline public function __set(index:Int, v:Float):Void { setFloat32(index << 2, v); }
	
	
}*/


#end