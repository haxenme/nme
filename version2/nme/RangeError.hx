class RangeError
{
   var mString:String;

   public function new(inMessage:String = "")
   {
      mString = inMessage;
   }
   public function toString() : String { return mString; }
}
