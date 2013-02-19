package native.errors;
#if (cpp || neko)

class TypeError extends Error 
{
   public function new(inMessage:String = "") 
   {
      super(inMessage, 0);
   }
}

#end