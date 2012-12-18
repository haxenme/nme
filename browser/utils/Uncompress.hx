package browser.utils;


class Uncompress {
	
	
	static public function ConvertStream (inStream:IDataInput, ?inSize:Int):IDataInput {
		
		#if flash9
		
		var buffer = new ByteArray ();
		inStream.readBytes (buffer, 0, inSize);
		buffer.uncompress ();
		return buffer;
		
		#elseif (neko||cpp)
		
		var bytes = (inSize == null ? inStream.readAll () : inStream.readBytes (inSize));
		
		#if neko
		return new IDataInput (new haxe.io.BytesInput (neko.zip.Uncompress.run (bytes)));
		#else
		return new IDataInput (new haxe.io.BytesInput (cpp.zip.Uncompress.run (bytes)));
		#end
		
		#else
		// TODO
		return null;
		#end
		
	}
	
	
	#if flash9
	static public function Run (inBytes:haxe.io.Bytes) {
		
		var data = inBytes.getData ();
		data.uncompress ();
		return haxe.io.Bytes.ofData (data);
		
	}
   
	#elseif (neko || cpp)
	
	static public function Run (inBytes:haxe.io.Bytes) {
		
		#if neko
		return neko.zip.Uncompress.run (inBytes);
		#else
		return cpp.zip.Uncompress.run (inBytes);
		#end
		
	}
	
	#else
	
	static public function Run (inBytes:haxe.io.Bytes) {
		
		return null;
		
	}
	
	#end
	
	
}