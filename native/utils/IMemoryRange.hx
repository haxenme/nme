package native.utils;
#if (cpp || neko)

interface IMemoryRange 
{
   public function getByteBuffer():ByteArray;
   public function getStart():Int;
   public function getLength():Int;
}

#end