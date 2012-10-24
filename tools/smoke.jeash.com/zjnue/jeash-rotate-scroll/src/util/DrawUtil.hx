package util;

import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;

#if js
typedef UInt = Int
#end

enum Orientation {
	l;
	t;
	r;
	b;
}

class DrawUtil {
	
	public static function drawRect( s : Sprite, x : Float, y : Float, w : Float, h : Float, col : UInt = 0xff0000, alpha : Float = 1.0 ) {
		var gfx = s.graphics;
		gfx.beginFill( col, alpha );
		gfx.drawRect( x, y, w, h );
		gfx.endFill();
		return s;
	}
	
	public static function drawTriangle( s : Sprite, x : Float, y : Float, side : Float, w : Float, h : Float, orientation : Orientation, col : UInt = 0xff0000, alpha : Float = 1.0 ) {
		var gfx = s.graphics;
		gfx.beginFill( col, alpha );
		switch( orientation ) {
		case l:
			var offset = (side - w) / 2;
			gfx.moveTo( x + offset, y + h/2 );
			gfx.lineTo( x + offset + w, y );
			gfx.lineTo( x + offset + w, y + h );
			gfx.lineTo( x + offset, y + h/2 );
		case r:
			var offset = (side - w) / 2;
			gfx.moveTo( x + offset, y );
			gfx.lineTo( x + offset + w, y + h/2 );
			gfx.lineTo( x + offset, y + h );
			gfx.lineTo( x + offset, y );
		case b:
			var offset = (side - w) / 2;
			gfx.moveTo( x, y + offset );
			gfx.lineTo( x + side, y + offset );
			gfx.lineTo( x + side/2, y + w );
			gfx.lineTo( x, y + offset);
		default:
		}
		/*
		gfx.moveTo( x - side/2, y - side/2 );
		gfx.lineTo( x + side/2, y );
		gfx.lineTo( x - side/2, y + side/2 );
		gfx.lineTo( x - side/2, y - side/2 );
		*/
		gfx.endFill();
		return s;
	}
	
	public static function drawDot( s : Sprite, x : Float, y : Float, r : Float, col : Int = 0xff0000, alpha : Float = 1.0 ) {
		var gfx = s.graphics;
		gfx.beginFill( col, alpha );
		gfx.drawCircle( x, y, r );
		gfx.endFill();
		return s;
	}
	
	public static function setFont( t : TextField, str : String ) {
		var fmt = new TextFormat( str );
		t.defaultTextFormat = fmt;
		return t;
	}
	
	public static function correct( t : TextField ) {
		#if js
		t.y += 2.5;
		t.x += 2;
		#end
		#if embedfonts
		t.embedFonts = true;
		#end
	}
	
}
