package nme.errors;
#if (!flash)

@:nativeProperty
class Error 
{
   public var errorID:Int;
   public var message:Dynamic;
   public var name:Dynamic;

   public function new(?inMessage:Dynamic, id:Dynamic = 0) 
   {
      message = inMessage;
      errorID = id;
   }

   private function getStackTrace():String 
   {
      return "";
   }

   public function toString():String 
   {
      return message;
   }
}

#else
typedef Error = flash.errors.Error;
#end
