#if flash


package nme.media;


@:native ("flash.media.ID3Info")
@:final extern class ID3Info implements Dynamic {
	var album : String;
	var artist : String;
	var comment : String;
	var genre : String;
	var songName : String;
	var track : String;
	var year : String;
	function new() : Void;
}



#else


package nme.media;

class ID3Info
{
	public var album : String;
	public var artist : String;
	public var comment : String;
	public var genre : String;
	public var songName : String;
	public var track : String;
	public var year : String;


   public function new() { }
}


#end