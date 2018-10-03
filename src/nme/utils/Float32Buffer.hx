package nme.utils;

@:nativeProperty
class Float32Buffer extends ByteArray implements ArrayAccess<Float> 
{
   public var count(default,null):Int;

   #if jsprime
   var f32View : js.html.Float32Array;
   var bufferSize:Int;
   #end

   public function new(inCount:Int = 0,inWriteOnly:Bool=false)
   {
      count = inCount;
      super(count<4 ? 16 : (count<<2), inWriteOnly );
      #if jsprime
      bufferSize = alloced>>2;
      #end
   }

   #if jsprime
   override function onBufferChanged()
   {
      bufferSize =  alloced>>2;
      if (ptr>0)
      {
         var offset = ByteArray.nme_buffer_offset(ptr);
         f32View = new js.html.Float32Array(untyped Module.HEAP8.buffer, offset,bufferSize);
      }
      else if (b!=null)
      {
         f32View = new js.html.Float32Array(b.buffer,0,bufferSize);
      }
      else
      {
         f32View = null;
      }
   }
   #end

   public function resize(inSize:Int)
   {
      count = inSize;
      setByteSize((count = inSize)<<2);
      #if jsprime
      bufferSize = alloced>>2;
      #end
   }

   #if (cpp && !cppia)
   @:extern @:native("__hxcpp_memory_set_float")
   extern static function hxcppSetFloat(b:haxe.io.BytesData, pos:Int, val:Float):Void { }
   @:extern @:native("__hxcpp_memory_get_float")
   extern static function hxcppGetFloat(b:haxe.io.BytesData, pos:Int):Float return 0;
   #end

   #if !cppia inline #end
   public function setF32(index:Int,val:Float)
   {
      #if jsprime
         if (index>=count)
         {
            count = index+1;
            if (index>=bufferSize)
               ensureElem((index<<2)+3,true);
         }
         f32View[index]=val;
      #else
         var bpos = index<<2;
         if (index>=count)
         {
            count = index+1;
            ensureElem(bpos+3,true);
         }
         #if cppia
            untyped __global__.__hxcpp_memory_set_float(b,index,val);
         #elseif cpp
            hxcppSetFloat(b,bpos,val);
         #else
            setFloat(bpos,val);
         #end
      #end
   }

   #if !cppia inline #end
   public function getF32(index:Int):Float
   {
      #if jsprime
      return f32View[index];
      #else
         #if cppia
            untyped return __global__.__hxcpp_memory_get_float(b,index);
         #elseif cpp
            return hxcppGetFloat(b,index<<2);
         #else
            return getFloat(index<<2);
         #end
      #end
   }



   #if !cppia inline #end
   public function setF32q(index:Int,val:Float)
   {
      #if jsprime
      f32View[index]=val;
      #else
         #if cppia
            untyped __global__.__hxcpp_memory_set_float(b,index,val);
         #elseif cpp
            hxcppSetFloat(b,index<<2,val);
         #else
            setFloat(index<<2,val);
         #end
      #end
   }

}

