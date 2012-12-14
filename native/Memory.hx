package native;


import haxe.io.BytesData;
import native.utils.ByteArray;

#if neko
import neko.Lib;
#end


class Memory {
	
	
	#if neko
	static var b:BytesData;
	#else
	static var gcRef:ByteArray;
	#end
	static var len:Int;
	
	
	static public function select (inBytes:ByteArray):Void {
		
		#if neko
		if (inBytes == null)
			b = null;
		else
			b = untyped inBytes.getData ();
		#else
		gcRef = inBytes;
		if (inBytes == null)
			untyped __global__.__hxcpp_memory_clear ();
		else
			untyped __global__.__hxcpp_memory_select (inBytes.getData ());
		#end
		
		if (inBytes == null)
			len = 0;
		else
			len = inBytes.length;
		
	}
	
	
	#if neko
		
		
		// TODO
		static inline public function getByte (addr:Int):Int {
			
			return untyped __dollar__sget (b, addr);
			
		}
		
		
		static inline public function getDouble (addr:Int):Float {
			
			return _double_of_bytes (untyped __dollar__ssub (b, addr, 8), false);
			
		}
		
		
		static inline public function getFloat (addr:Int):Float {
			
			return _float_of_bytes (untyped __dollar__ssub (b, addr, 4), false);
			
		}
		
		
		static public function getI32 (addr:Int):Int {
			
			return getByte (addr++) | (getByte (addr++) << 8) | (getByte (addr++) << 16) | (getByte (addr) << 24);
			
		}
		
		
		static inline public function getUI16 (addr:Int):Int {
			
			return getByte (addr++) | (getByte (addr++) << 8);
			
		}
		
		
		static inline public function setByte (addr:Int, v:Int):Void {
			
			untyped __dollar__sset (b, addr, v);
			
		}
		
		
		static inline public function setDouble (addr:Int, v:Float):Void {
			
			untyped __dollar__sblit (b, addr, _double_bytes (v, false), 0, 8);
			
		}
		
		
		static inline public function setFloat (addr:Int, v:Float):Void {
			
			untyped __dollar__sblit (b, addr, _float_bytes (v, false), 0, 4);
			
		}
		
		
		static public function setI16 (addr:Int, v:Int):Void {
			
			setByte (addr++, v & 0xff);
			setByte (addr++, (v >> 8) & 0xff);
			
		}
		
		
		static public function setI32 (addr:Int, v:Int):Void {
			
			setByte (addr++, v & 0xff);
			setByte (addr++, (v >> 8) & 0xff);
			setByte (addr++, (v >> 16) & 0xff);
			setByte (addr++, (v >> 24));
			
		}
		
		
	#else
		
		
		static #if !debug inline #end public function getByte (addr:Int):Int {
			
			#if debug if (addr < 0 || addr >= len) throw("Bad address"); #end
			return untyped __global__.__hxcpp_memory_get_byte (addr);
			
		}
		
		
		static #if !debug inline #end public function getDouble (addr:Int):Float {
			
			#if debug if (addr < 0 || addr >= len) throw("Bad address"); #end
			return untyped __global__.__hxcpp_memory_get_double (addr);
			
		}
		
		
		static #if !debug inline #end public function getFloat (addr:Int):Float {
			
			#if debug if (addr < 0 || addr >= len) throw("Bad address"); #end
			return untyped __global__.__hxcpp_memory_get_float (addr);
			
		}
		
		
		static #if !debug inline #end public function getI32 (addr:Int):Int {
			
			#if debug if (addr < 0 || addr >= len) throw("Bad address"); #end
			return untyped __global__.__hxcpp_memory_get_i32 (addr);
			
		}
		
		
		static #if !debug inline #end public function getUI16 (addr:Int):Int {
			
			#if debug if (addr < 0 || addr >= len) throw("Bad address"); #end
			return untyped __global__.__hxcpp_memory_get_ui16 (addr);
			
		}
		
		
		static #if !debug inline #end public function setByte (addr:Int, v:Int):Void {
			
			#if debug if (addr < 0 || addr >= len) throw("Bad address"); #end
			untyped __global__.__hxcpp_memory_set_byte (addr, v);
			
		}
		
		
		static #if !debug inline #end public function setDouble (addr:Int, v:Float):Void {
			
			#if debug if (addr < 0 || addr >= len) throw("Bad address"); #end
			untyped __global__.__hxcpp_memory_set_double (addr, v);
			
		}
		
		
		static #if !debug inline #end public function setFloat (addr:Int, v:Float):Void {
			
			#if debug if (addr < 0 || addr >= len) throw("Bad address"); #end
			untyped __global__.__hxcpp_memory_set_float (addr, v);
			
		}
		
		
		static #if !debug inline #end public function setI16 (addr:Int, v:Int):Void {
			
			#if debug if (addr < 0 || addr >= len) throw("Bad address"); #end
			untyped __global__.__hxcpp_memory_set_i16 (addr, v);
			
		}
		
		
		static #if !debug inline #end public function setI32 (addr:Int, v:Int):Void {
			
			#if debug if (addr < 0 || addr >= len) throw("Bad address"); #end
			untyped __global__.__hxcpp_memory_set_i32 (addr, v);
			
		}
		
		
	#end
	
	
	/*
	static inline public function signExtend1( v : Int ) : Int
	static inline public function signExtend16( v : Int ) : Int
	static inline public function signExtend8( v : Int ) : Int
	*/
	
	
	
	
	// Native Methods
	
	
	
	
	#if neko
	private static var _float_of_bytes = Lib.load ("std", "float_of_bytes", 2);
	private static var _double_of_bytes = Lib.load ("std", "double_of_bytes", 2);
	private static var _float_bytes = Lib.load ("std", "float_bytes", 2);
	private static var _double_bytes = Lib.load ("std", "double_bytes", 2);
	#end
	
	
}