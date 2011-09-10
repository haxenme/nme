package nme.errors;


#if flash
@:native ("flash.errors.EOFError")
extern class EOFError extends IOError {
	function new(?message : String, id : Int = 0) : Void;
}
#else


class EOFError extends Error
{
	public function new()
	{
     super("End of file was encountered",2030);
	}
}
#end