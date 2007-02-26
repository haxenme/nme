package neko.nme;

import neko.nme.Rect;
import neko.nme.Point;
import neko.nme.Surface;
import neko.nme.Manager;

class TTF
{
	var surface : Void;
	
	public function new( str : String, font : String, size : Int, fcolor : Int, bcolor : Int )
	{
		surface = nme_ttf_shaded( untyped str.__s, untyped font.__s, size, fcolor, bcolor );
	}
	
	public function draw( loc : Point )
	{
		nme_ttf_draw( Manager.getScreen(), surface, loc );
	}
	
	public function close()
	{
		nme_surface_free( surface );
	}
	
	static var nme_ttf_shaded = neko.Lib.load("nme","nme_ttf_shaded",5);
	static var nme_ttf_draw = neko.Lib.load("nme","nme_ttf_draw",3);
	static var nme_surface_free = neko.Lib.load("nme","nme_surface_free",1);
}