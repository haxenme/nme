package nme.utils;

class ByteArrayTools
{
   public static function ofLength(inLength:Int) : ByteArray
   {
   #if flash
      var result = new ByteArray();
      result.length = inLength;
      result.endian = Endian.LITTLE_ENDIAN;
   #else
      var result = new ByteArray(inLength);
      result.bigEndian = false;
   #end
      return result;
   }
}
