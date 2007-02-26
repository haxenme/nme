package neko.nme;

class Timer
{
	var rate : Int;
	var previous : Int;
	
	public function new( r : Int )
	{
		rate = r;
		previous = 0;
	}
	
	public function getPrevious() : Int
	{
		return previous;
	}
	
	public static function getCurrent() : Int
	{
		return nme_gettime();
	}
	
	public function isTime() : Bool
	{
		var cur = getCurrent();
		var rte = 1000 / rate;
		if ( cur - previous >= rte )
		{
			previous = cur;
			return true;
		}
		return false;
	}
	
	static var nme_gettime = neko.Lib.load("nme","nme_gettime",0);
}