package nme.utils;
import nme.geom.Rectangle;
import StdTypes;

class ByteArray implements ArrayAccess<Int>
{
   private var mArray:Void;

   public var length(get_length,null):Int;

   public function new(?inHandle:Void)
   {
      if (inHandle==null)
         mArray = nme_create_byte_array();
      else
         mArray = inHandle;
   }

   public function get_handle():Void { return mArray; }

   public function get_length():Int
   {
      return nme_byte_array_length(mArray);
   }

   private function __get( pos:Int ) : Int
   {
      return nme_byte_array_get(mArray,pos);
   }

   private function __set(pos:Int,v:Int) : Void
   {
      nme_byte_array_set(mArray,pos,v);
   }


   static var nme_create_byte_array = neko.Lib.load("nme","nme_create_byte_array",0);
   static var nme_byte_array_length = neko.Lib.load("nme","nme_byte_array_length",1);
   static var nme_byte_array_get = neko.Lib.load("nme","nme_byte_array_get",2);
   static var nme_byte_array_set = neko.Lib.load("nme","nme_byte_array_set",3);

}


