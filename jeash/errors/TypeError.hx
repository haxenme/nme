package jeash.errors;


class TypeError extends Error
{

	public function new(inMessage:String = "")
	{
		super(inMessage, 0);
	}

}