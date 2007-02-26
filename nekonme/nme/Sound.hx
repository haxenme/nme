package neko.nme;

class Sound
{
	static var __s;
	
	public function new ( file : String )
	{
		__s = nme_sound_loadwav( untyped file.__s );
	}
	
	public function free()
	{
		nme_sound_free( __s );
	}
	
	public function playChannel( channel : Int, loops : Int )
	{
		if ( loops < -1 ) loops = -1;
		nme_sound_playchannel( __s, channel, loops );
	}
	
	public static function setChannels( num : Int )
	{
		if ( num < 1 ) num = 1;
		nme_sound_setchannels( num );
	}
	
	static var nme_sound_loadwav = neko.Lib.load("nme","nme_sound_loadwav", 1);
	static var nme_sound_free = neko.Lib.load("nme","nme_sound_free", 1);
	static var nme_sound_setchannels = neko.Lib.load("nme","nme_sound_setchannels", 1);
	static var nme_sound_volume = neko.Lib.load("nme","nme_sound_volume", 2);
	static var nme_sound_playchannel = neko.Lib.load("nme","nme_sound_playchannel", 3);
	static var nme_sound_playchanneltimed = neko.Lib.load("nme","nme_sound_playchanneltimed", 4);
	static var nme_sound_fadeinchannel = neko.Lib.load("nme","nme_sound_fadeinchannel", 4);
	static var nme_sound_fadeinchanneltimed = neko.Lib.load("nme","nme_sound_fadeinchanneltimed", 5);
	static var nme_sound_fadeoutchannel = neko.Lib.load("nme","nme_sound_fadeoutchannel", 2);
	static var nme_sound_pause = neko.Lib.load("nme","nme_sound_pause", 1);
	static var nme_sound_resume = neko.Lib.load("nme","nme_sound_resume", 1);
	static var nme_sound_stop = neko.Lib.load("nme","nme_sound_stop", 1);
	static var nme_sound_stoptimed = neko.Lib.load("nme","nme_sound_stoptimed", 2);
	static var nme_sound_isplaying = neko.Lib.load("nme","nme_sound_isplaying", 1);
	static var nme_sound_ispaused = neko.Lib.load("nme","nme_sound_ispaused", 1);
	static var nme_sound_isfading = neko.Lib.load("nme","nme_sound_isfading", 1);
	static var nme_sound_reservechannels = neko.Lib.load("nme","nme_sound_reservechannels", 1);
	static var nme_sound_groupchannel = neko.Lib.load("nme","nme_sound_groupchannel", 2);
	static var nme_sound_groupchannels = neko.Lib.load("nme","nme_sound_groupchannels", 3);
	static var nme_sound_groupcount = neko.Lib.load("nme","nme_sound_groupcount", 1);
	static var nme_sound_groupavailable = neko.Lib.load("nme","nme_sound_groupavailable", 1);
	static var nme_sound_fadeoutgroup = neko.Lib.load("nme","nme_sound_fadeoutgroup", 2);
	static var nme_sound_stopgroup = neko.Lib.load("nme","nme_sound_stopgroup", 1);
}