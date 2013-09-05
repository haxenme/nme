package nme.utils;
#if (cpp || neko)

interface IDataOutput 
{
   public var endian(get_endian, set_endian):String;

   public function writeBoolean(value:Bool):Void;
   public function writeByte(value:Int):Void;
   public function writeBytes(bytes:ByteArray, offset:Int = 0, length:Int = 0):Void;
   public function writeDouble(value:Float):Void;
   public function writeFloat(value:Float):Void;
   public function writeInt(value:Int):Void;
   public function writeShort(value:Int):Void;
   public function writeUnsignedInt(value:Int):Void;
   public function writeUTF(value:String):Void;
   public function writeUTFBytes(value:String):Void;

   // Not implmented...
   //public function writeMultiByte(value:String, charSet:String):Void;
   //public function writeObject(object:*):Void;

   private function get_endian():String;
   private function set_endian(s:String):String;
}

#else
typedef IDataInput = flash.utils.IDataInput;
#end

