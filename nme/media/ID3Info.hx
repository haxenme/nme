package nme.media;
#if display


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


#elseif (cpp || neko)
typedef ID3Info = native.media.ID3Info;
#elseif js
typedef ID3Info = browser.media.ID3Info;
#else
typedef ID3Info = flash.media.ID3Info;
#end
