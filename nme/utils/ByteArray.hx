package nme.utils;
import nme.geom.Rectangle;
import StdTypes;

class ByteArray implements ArrayAccess<Int>
{
   private var mArray:Dynamic;

   public var length(get_length,null):Int;

   public function new(?inHandle:Dynamic)
   {
      if (inHandle==null)
         mArray = nme_create_byte_array();
      else
         mArray = inHandle;
   }

   public function get_handle():Dynamic { return mArray; }

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


   static var nme_create_byte_array = nme.Loader.load("nme_create_byte_array",0);
   static var nme_byte_array_length = nme.Loader.load("nme_byte_array_length",1);
   static var nme_byte_array_get = nme.Loader.load("nme_byte_array_get",2);
   static var nme_byte_array_set = nme.Loader.load("nme_byte_array_set",3);

}


