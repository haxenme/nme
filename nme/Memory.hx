package nme;

import nme.utils.ByteArray;

class Memory
{
   #if neko
   static var ptr:Void
   #else
   static var gcRef:ByteArray;
   #end

   static public function select( b : ByteArray ) : Void
   {
      #if neko
      if (b==null)
         ptr = null;
      else
         ptr = untyped b.getData().__s;
      #else
      gcRef = b;
      if (b==null)
         untyped __global__.__hxcpp_memory_clear();
      else
         untyped __global__.__hxcpp_memory_select(b.getData());
      #end
   }

   #if neko
   // TODO
   static inline public function getByte( addr : Int ) : Int
   static inline public function getDouble( addr : Int ) : Float
   static inline public function getFloat( addr : Int ) : Float
   static inline public function getI32( addr : Int ) : Int
   static inline public function getUI16( addr : Int ) : Int
   static inline public function setByte( addr : Int, v : Int ) : Void
   static inline public function setDouble( addr : Int, v : Float ) : Void
   static inline public function setFloat( addr : Int, v : Float ) : Void
   static inline public function setI16( addr : Int, v : Int ) : Void
   static inline public function setI32( addr : Int, v : Int ) : Void
   #else
   static inline public function getByte( addr : Int ) : Int
      { return untyped __global__.__hxcpp_memory_get_byte(addr); }
   static inline public function getDouble( addr : Int ) : Float
      { return untyped __global__.__hxcpp_memory_get_double(addr); }
   static inline public function getFloat( addr : Int ) : Float
      { return untyped __global__.__hxcpp_memory_get_float(addr); }
   static inline public function getI32( addr : Int ) : Int
      { return untyped __global__.__hxcpp_memory_get_i32(addr); }
   static inline public function getUI16( addr : Int ) : Int
      { return untyped __global__.__hxcpp_memory_get_ui16(addr); }

   static inline public function setByte( addr : Int, v : Int ) : Void
      { untyped __global__.__hxcpp_memory_set_byte(addr,v); }
   static inline public function setDouble( addr : Int, v : Float ) : Void
      { untyped __global__.__hxcpp_memory_set_double(addr,v); }
   static inline public function setFloat( addr : Int, v : Float ) : Void
      { untyped __global__.__hxcpp_memory_set_float(addr,v); }
   static inline public function setI16( addr : Int, v : Int ) : Void
      { untyped __global__.__hxcpp_memory_set_i16(addr,v); }
   static inline public function setI32( addr : Int, v : Int ) : Void
      { untyped __global__.__hxcpp_memory_set_i32(addr,v); }
   #end

   /*
   static inline public function signExtend1( v : Int ) : Int
   static inline public function signExtend16( v : Int ) : Int
   static inline public function signExtend8( v : Int ) : Int
   */
}

