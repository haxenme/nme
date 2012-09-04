package jeash;


import haxe.io.BytesData;
import jeash.utils.ByteArray;

class Memory
{
	static var gcRef:ByteArray;
	static var len:Int;

	static public function select(inBytes:ByteArray):Void
	{
		gcRef = inBytes;
		len = (inBytes != null) ? inBytes.length : 0;
	}
	
	static private function _setPositionTemporarily<T>(position:Int, action:Void -> T):T {
		var oldPosition:Int = gcRef.position;
		gcRef.position = position;
		var value:T = action();
		gcRef.position = oldPosition;
		return value;
	}
	
	static #if !debug inline #end public function getByte(addr:Int):Int
	{
		#if debug if (addr < 0 || addr + 1 > len) throw("Bad address"); #end
		return gcRef.jeashGet(addr);
	}
	
	static #if !debug inline #end public function getDouble(addr:Int):Float
	{
		#if debug if (addr < 0 || addr + 8 > len) throw("Bad address"); #end
		return _setPositionTemporarily(addr, function() {
			return gcRef.readDouble();
		});
	}
	
	
	static #if !debug inline #end public function getFloat(addr:Int):Float
	{
		#if debug if (addr < 0 || addr + 4 > len) throw("Bad address"); #end
		return _setPositionTemporarily(addr, function() {
			return gcRef.readFloat();
		});
	}
	
	
	static #if !debug inline #end public function getI32(addr:Int):Int
	{
		#if debug if (addr < 0 || addr + 4 > len) throw("Bad address"); #end
		return _setPositionTemporarily(addr, function() {
			return gcRef.readInt();
		});

	}
	
	
	static #if !debug inline #end public function getUI16(addr:Int):Int
	{
		#if debug if (addr < 0 || addr + 2 > len) throw("Bad address"); #end
		return _setPositionTemporarily(addr, function() {
			return gcRef.readUnsignedShort();
		});
	}
	
	
	static #if !debug inline #end public function setByte(addr:Int, v:Int):Void
	{
		#if debug if (addr < 0 || addr + 1 > len) throw("Bad address"); #end
		gcRef.jeashSet(addr, v);
	}
	
	
	static #if !debug inline #end public function setDouble(addr:Int, v:Float):Void
	{
		#if debug if (addr < 0 || addr + 8 > len) throw("Bad address"); #end
		_setPositionTemporarily(addr, function() {
			gcRef.writeDouble(v);
		});
	}
	
	
	static #if !debug inline #end public function setFloat(addr:Int, v:Float):Void
	{
		#if debug if (addr < 0 || addr + 4 > len) throw("Bad address"); #end
		_setPositionTemporarily(addr, function() {
			gcRef.writeFloat(v);
		});
	}
	
	
	static #if !debug inline #end public function setI16(addr:Int, v:Int):Void
	{
		#if debug if (addr < 0 || addr + 2 > len) throw("Bad address"); #end
		_setPositionTemporarily(addr, function() {
			gcRef.writeUnsignedShort(v);
		});
	}
	
	
	static #if !debug inline #end public function setI32(addr:Int, v:Int):Void
	{
		#if debug if (addr < 0 || addr + 4 > len) throw("Bad address"); #end
		_setPositionTemporarily(addr, function() {
			gcRef.writeInt(v);
		});
	}

}