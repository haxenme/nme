package nme.errors;


#if flash
@:native("TypeError") extern class TypeError extends Error {
}
#else



class TypeError extends Error
{
   public function new(inMessage:String = "")
   {
	   super(inMessage,0);
   }
}
#end