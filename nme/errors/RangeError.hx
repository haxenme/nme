package nme.errors;
#if (!flash)

@:nativeProperty
class RangeError extends Error 
{
   public function new(inMessage:String = "") 
   {
      super(inMessage, 0);
   }
}

#else
typedef RangeError = flash.errors.RangeError;
#end
