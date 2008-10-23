/*
 * Copyright (c) 2006, Lee McColl Sylvester - www.designrealm.co.uk
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
 
package nme;

import nme.Rect;
import nme.Point;

class Surface
{
	var __srf : Dynamic;
        public var width(getWidth,null):Int;
        public var height(getHeight,null):Int;
	
	public function new( ?file : String )
	{
		if ( file != null && file != "" )
      #if neko
			__srf = nme_sprite_init( untyped file.__s );
      #else
			__srf = nme_sprite_init( file );
      #end
	}

        public function handle() { return __srf; }
	
	public function draw( screen : Dynamic, ?rect : Rect, ?point : Point )
	{
                if (rect==null) rect = new Rect(0,0,width,height);
                if (point==null) point = new Point(0,0);
		nme_sprite_draw( __srf, screen, rect, point );
	}
	
	public function clear( color : Int )
	{
		nme_surface_clear( __srf, color );
	}
	
	public function free()
	{
                __srf = null;
		//nme_surface_free( __srf );
	}

        public function getWidth() : Int { return nme_surface_width(__srf); }
        public function getHeight()  : Int { return nme_surface_height(__srf); }
	
	public function setKey( r : Int, g : Int, b : Int )
	{
		var valid : Bool = true;
		if ( r < 0 || r > 255 ) valid = false;
		if ( g < 0 || g > 255 ) valid = false;
		if ( b < 0 || b > 255 ) valid = false;
		if ( ! valid )
			nme.Manager.warn( "unable to set colour key. invalid colour value.\n" );
		else
			nme_surface_colourkey( __srf, r, g, b );
	}
	
	public static var DEFAULT : Int = 0x00;
	public static var TAA : Int = 0x01;
	public static var TSAFE : Int = 0x02;
	public static var TTMAP : Int = 0x04;
	/*
		FLAGS
		=================
		* DEFAULT - Default.
		* TAA - Use the interpolating renderer. Much slower but can look better.
		* TSAFE - Don't asume that the src and dst surfaces has the same pixel format. This is the default when the two surfaces don't have the same BPP. This is slower but will render weird pixel formats right.
		* TTMAP - Use texture mapping. This is a bit faster but the result isn't as nice as in the normal mode. This mode will also ignore the px/py coordinates and the other flags. 

		To get optimal performance PLEASE make sure that the two surfaces has the same pixel format (color depth) and doesn't use 24-bpp.
	*/
	public function transform( screen : Dynamic, angle : Float, scale : Point, pivot : Point, destination : Point, flags : Int ) : Rect
	{
		var r = nme_sprite_transform( __srf, screen, angle, scale.x, scale.y, pivot.x, pivot.y, destination.x, destination.y, flags );
		return new Rect( r.x, r.y, r.w, r.h );
	}

	public function transformSurface( bgColor : Int, angle : Float, scale : Point, flags : Int )
	{
		var srf = new Surface();
		untyped srf.__srf = nme_sprite_transform_surface( __srf, bgColor, angle, scale.x, scale.y, flags );
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
	
	static var nme_surface_clear = nme.Loader.load("nme_surface_clear",2);
	static var nme_surface_width = nme.Loader.load("nme_surface_width",1);
	static var nme_surface_height = nme.Loader.load("nme_surface_height",1);
	static var nme_surface_free = nme.Loader.load("nme_surface_free",1);
	static var nme_surface_colourkey = nme.Loader.load( "nme_surface_colourkey",4);
	static var nme_sprite_alpha = nme.Loader.load("nme_sprite_alpha",2);
	
	static var nme_sprite_init = nme.Loader.load("nme_sprite_init",1);
	static var nme_sprite_draw = nme.Loader.load("nme_sprite_draw",4);
	
	static var nme_sprite_transform = nme.Loader.load("nme_sprite_transform",-1);
	static var nme_sprite_transform_surface = nme.Loader.load("nme_sprite_transform_surface",-1);
	
	static var nme_collision_pixel = nme.Loader.load("nme_collision_pixel",5);
	static var nme_collision_boundingbox = nme.Loader.load("nme_collision_boundingbox",3);
}
