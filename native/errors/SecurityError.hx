package native.errors;
#if (cpp || neko)

class SecurityError extends Error 
{
   public function new(inMessage:String = "") 
   {
      super(inMessage, 0);
   }
}

#end