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

import nme.Surface;
import nme.Point;
import nme.Rect;

class BitmapFont
{
	var __b;
	
	public function new()
	{
	
	}
	
	public static var SGE_BFTRANSP = 0x01;
	public static var SGE_BFNOCONVERT = 0x04;
	public static var SGE_BFSFONT = 0x02;
	public static var SGE_BFPALETTE = 0x08;
	
	/*
	FLAGS
	=================
	* SGE_BFTRANSP - Transparent (should usually be set).
	* SGE_BFNOCONVERT - Don't convert font surface to display format for faster blits.
	* SGE_BFSFONT - If you enabled support for SDL_img when compiling SGE you can also set the SGE_BFSFONT flag, this enables you to load Karl Bartel's SFont files.
	* SGE_BFPALETTE - Converts the font surface to a palette surface (8bit). Don't do this on color fonts or SFonts! Blits from the font surface will be a bit slower but sge_BF_SetColor() will be faster (O(1) instead of O(n^2)).
	*/
	public function open( file : String, flags : Int )
	{
		__b = nme_bf_open_font( untyped file.__s, flags );
	}
	
	public function fromSurface( surface : Void, flags : Int )
	{
		__b = nme_bf_font_from_surface( surface, flags );
	}
	
	public function dispose()
	{
		nme_bf_close_font( __b );
	}
	
	public function setColor( r : Int, g : Int, b : Int )
	{
		var valid : Bool = true;
		if ( r < 0 || r > 255 ) valid = false;
		if ( g < 0 || g > 255 ) valid = false;
		if ( b < 0 || b > 255 ) valid = false;
		if ( ! valid )
			neko.Lib.print( "unable to set colour. invalid colour value.\n" );
		else
			nme_bf_set_font_color( __b, r, g, b );
	}
	
	public function setAlpha( alpha : Int )
	{
		nme_bf_set_font_alpha( __b, alpha );
	}
	
	/*
	returns the height of a single character
	*/
	public function getHeight() : Int
	{
		nme_bf_get_font_height( __b );
	}
	
	/*
	returns the width of a single character
	*/
	public function getWidth() : Int
	{
		nme_bf_get_font_width( __b );
	}
	
	/*
	returns the rect dimensions of a string written using the bitmap font
	*/
	public function getTextSize( text : String ) : Rect
	{
		var r = nme_bf_text_size( __b, untyped text.__s );
		return new Rect( r.x, r.y, r.w, r.h );
	}
	
	public function draw( surface : Void, text : String, location : Point ) : Rect
	{
		var r = nme_bf_text_out( surface, __b, untyped text.__s, location.x, location.y );
		return new Rect( r.x, r.y, r.w, r.h );
	}
	
	public static var nme_bf_open_font = neko.Lib.load("nme","nme_bf_open_font",2);
	public static var nme_bf_font_from_surface = neko.Lib.load("nme","nme_bf_font_from_surface",2);
	public static var nme_bf_close_font = neko.Lib.load("nme","nme_bf_close_font",1);
	public static var nme_bf_set_font_color = neko.Lib.load("nme","nme_bf_set_font_color",4);
	public static var nme_bf_set_font_alpha = neko.Lib.load("nme","nme_bf_set_font_alpha",2);
	public static var nme_bf_get_font_height = neko.Lib.load("nme","nme_bf_get_font_height",1);
	public static var nme_bf_get_font_width = neko.Lib.load("nme","nme_bf_get_font_width",1);
	public static var nme_bf_text_size = neko.Lib.load("nme","nme_bf_text_size",2);
	public static var nme_bf_text_out = neko.Lib.load("nme","nme_bf_text_out",5);
}