package nme.errors;
#if (cpp || neko || js)


class IOError extends Error
{
	
	public function new(message:String = "")
	{
		super(message);
	}
	
}


#end