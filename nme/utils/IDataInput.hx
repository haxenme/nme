package nme.utils;


import haxe.io.Input;


class IDataInput
{
   var mInput:Input;
   // not implemented ...
   //var bytesAvailable(default,null) : UInt;
   //var objectEncoding : UInt;

   public function new(inInput:Input)
   {
      mInput = inInput;
   }

   public var endian(getEndian,setEndian) : String;

   inline public function close() : Void { mInput.close(); }

   inline public function readAll( ?bufsize : Int ) : haxe.io.Bytes
      { return mInput.readAll(bufsize); }

   inline public function readBoolean() : Bool { return mInput.readInt8()!=0; }
   inline public function readByte() : Int { return mInput.readByte(); }
   inline public function readBytes(inLen : Int) { return mInput.read(inLen); }
   inline public function readDouble() : Float { return mInput.readDouble(); }
   inline public function readFloat() : Float { return mInput.readFloat(); }
   inline public function readInt() : Int { return haxe.Int32.toInt(mInput.readInt32()); }
   inline public function readUnsignedInt() : Int { return haxe.Int32.toInt(mInput.readInt32()); }
   inline public function readShort() : Int { return mInput.readInt16(); }
   inline public function readUTFBytes(length : Int) : haxe.io.Bytes { return mInput.read(length); }
   public function readUnsignedByte() : Int {
         return mInput.readByte();
   }
   inline public function readUnsignedShort() : Int { return mInput.readUInt16(); }


   private function getEndian() : String { return mInput.bigEndian ? Endian.BIG_ENDIAN : Endian.LITTLE_ENDIAN; }
   private function setEndian(s:String) : String { mInput.bigEndian = (s==Endian.BIG_ENDIAN); return s; }

}


