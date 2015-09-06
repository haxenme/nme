package nme;

import nme.utils.ByteArray;
import haxe.io.Bytes;


class Glue
{
   #if flash
   public static inline function toByteArray(bytes:Bytes) return bytes.getData();
   public static inline function toBytes(array:ByteArray) return Bytes.ofData(array);
   #else
   public static inline function toByteArray(bytes:Bytes) return ByteArray.fromBytes(bytes);
   public static inline function toBytes(array:ByteArray) return array;
   #end
}


