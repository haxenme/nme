package nme.utils;
#if (!flash)

interface IMemoryRange 
{
   public function getByteBuffer():ByteArray;
   public function getStart():Int;
   public function getLength():Int;
}

#end
