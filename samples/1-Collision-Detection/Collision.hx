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
 * 
 * Credit goes to Ari Feldman for the creation of the bat sprite
 */
 
import nme.Manager;
import nme.Surface;
import nme.Sprite;
import nme.Rect;
import nme.Point;
import nme.Timer;
import nme.TTF;
import Reflect;

class Collision
{
	static var mainObject : Collision;
	
	var running : Bool;
	var bat : Sprite;
	var bat2 : Sprite;
	var keys : Array<Bool>;
	var curTime : Float;
	var prevTime : Float;
	
	static function main()
	{
		mainObject = new Collision();
	}
	
	public function new()
	{
		keys = new Array();
		prevTime = 0;
		curTime = 0;
		var mng : Manager = new Manager( 200, 200, "Collision Test", false, "ico.gif" );
		var batSrf : Surface = new Surface( "bat.png" );
		
		bat = new Sprite( batSrf );
		bat2 = new Sprite( batSrf );
		
		batSrf.setKey( 255, 0, 255 );
		
		bat.setFrame( new Rect(24, 63, 65, 44), 0, 0 );
		bat.setFrame( new Rect(156, 63, 65, 44), 0, 1 );
		bat.setFrame( new Rect(288, 63, 65, 44), 0, 2 );
		bat.setFrame( new Rect(420, 63, 65, 44), 0, 3 );
		
		bat2.setFrame( new Rect(24, 63, 65, 44), 0, 0 );
		bat2.setFrame( new Rect(156, 63, 65, 44), 0, 1 );
		bat2.setFrame( new Rect(288, 63, 65, 44), 0, 2 );
		bat2.setFrame( new Rect(420, 63, 65, 44), 0, 3 );
		
		bat.type = at_loop;
		bat.group = 0;
		
		bat2.type = at_pingpong;
		bat2.group = 0;
		bat2.x = 60;
		bat2.y = 60;
		
		var iTimer : Timer = new Timer( 5 );
		var jTimer : Timer = new Timer( 7 );
		var kTimer : Timer = new Timer( 5 );
		var gTimer : Timer = new Timer( 25 );
			
		var fps : Float;
		running = true;
		while (running)
		{
			mng.events();
			switch mng.getEventType()
			{
				case et_keydown:
					processKeys( mng.lastKey(), true );
				case et_keyup:
					processKeys( mng.lastKey(), false );
				case et_mousebutton_down:
					var tmp : Rect = bat.getCurrentRect();
					var batRect : Rect = new Rect( bat.x, bat.y, tmp.w, tmp.h );
					if ( mng.clickRect( mng.mouseX(), mng.mouseY(), batRect ) )
						bat.click = 1;
					else
						bat.click = 0;

				case et_mousebutton_up:
							bat.click = 0;
				case et_mousemove:
					if ( bat.click == 1 )
					{
						bat.x += mng.mouseMoveX();
						bat.y += mng.mouseMoveY();
					}
				case et_quit:
					running = false;
				default:
			}
			
			curTime = Timer.getCurrent();
			if ( kTimer.isTime() )
				fps = 1000.00 / (curTime - prevTime);
			prevTime = curTime;
			
			if (gTimer.isTime())
			{
				if (keys[0]) bat.y -= 1;
				if (keys[1]) bat.y += 1;
				if (keys[2]) bat.x -= 1;
				if (keys[3]) bat.x += 1;
				if( batSrf.collisionPixel( batSrf, bat.getCurrentRect(), bat2.getCurrentRect(), bat.getSpriteOffset( bat2 ) ) )
					mng.clear( 0xFF0000 );
				else if( batSrf.collisionBox( bat.getCurrentRect(), bat2.getCurrentRect(), bat.getSpriteOffset( bat2 ) ) )
					mng.clear( 0xFF9900 );
				else
					mng.clear( 0x00000000 );
				
				bat.animate( iTimer );
				bat2.animate( jTimer );
				
				mng.flip();
			}
		}
		batSrf.free();
		mng.close();
	}
	
	public function processKeys( key, pressed : Bool )
	{
		switch key
		{
			case 27:
				running = false;
			case 273:
				keys[0] = pressed;
			case 274:
				keys[1] = pressed;
			case 275:
				keys[3] = pressed;
			case 276:
				keys[2] = pressed;
			default:
				neko.Lib.print( key );
		}
	}
}
