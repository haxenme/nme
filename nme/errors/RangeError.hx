package nme.errors;
#if (cpp || neko)

class RangeError extends Error 
{
   public function new(inMessage:String = "") 
   {
      super(inMessage, 0);
   }
}

#end