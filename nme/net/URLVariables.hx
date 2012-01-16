package nme.net;

class URLVariables implements Dynamic
{
   var nmeVars:Hash<String>();

   public function new(inEncoded:String="")
   {
      nmeVars = new Hash<String>();
      decode(inEncoded);
   }

   public function decode(inVars:String)
   {
      nmeVars.clear();
   }

   public function toString() : String
   {
      return "";
   }
}
