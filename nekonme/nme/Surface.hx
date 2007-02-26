package neko.nme;

import neko.nme.Rect;
import neko.nme.Point;

class Surface
{
	var __srf : Void;
	
	public function new( file : String )
	{
		__srf = nme_sprite_init( untyped file.__s );
	}
	
	public function draw( screen : Void, rect : Rect, point : Point )
	{
		nme_sprite_draw( __srf, screen, rect, point );
	}
	
	public function clear( color : Int )
	{
		nme_surface_clear( __srf, color );
	}
	
	public function free()
	{
		nme_surface_free( __srf );
	}
	
	public function setKey( r : Int, g : Int, b : Int )
	{
		var valid : Bool = true;
		if ( r < 0 || r > 255 ) valid = false;
		if ( g < 0 || g > 255 ) valid = false;
		if ( b < 0 || b > 255 ) valid = false;
		if ( ! valid )
			neko.Lib.print( "unable to set colour key. invalid colour value.\n" );
		else
			nme_surface_colourkey( __srf, r, g, b );
	}
	
	public function setAlpha( percentage : Int )
	{
		if ( percentage < 0 || percentage > 100 ) return;
		nme_sprite_alpha( __srf, percentage );
	}
	
	public function collisionPixel( srfb : Surface, rect : Rect, rectb : Rect, offsetPoint : Point ) : Bool
	{
		return nme_collision_pixel( __srf, rect, srfb.__srf, rectb, offsetPoint );
	}
	
	public function collisionBox( rect : Rect, rectb : Rect, offsetPoint : Point ) : Bool
	{
		return nme_collision_boundingbox( rect, rectb, offsetPoint );
	}
	
	static var nme_surface_clear = neko.Lib.load("nme","nme_surface_clear",2);
	static var nme_surface_free = neko.Lib.load("nme","nme_surface_free",1);
	static var nme_surface_colourkey = neko.Lib.load("nme", "nme_surface_colourkey",4);
	static var nme_sprite_alpha = neko.Lib.load("nme","nme_sprite_alpha",2);
	
	static var nme_sprite_init = neko.Lib.load("nme","nme_sprite_init",1);
	static var nme_sprite_draw = neko.Lib.load("nme","nme_sprite_draw",4);
	
	static var nme_collision_pixel = neko.Lib.load("nme","nme_collision_pixel",5);
	static var nme_collision_boundingbox = neko.Lib.load("nme","nme_collision_boundingbox",3);
}