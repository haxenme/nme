package nme.net;

class URLRequest
{
   public var url(default,null):String;

   public function new(?inURL:String)
   {
      if (inURL!=null)
         url = inURL;
   }
}


