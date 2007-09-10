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
import nme.Timer;
import nme.Surface;

enum AnimType
{
	at_pingpong;
	at_loop;
	at_once;
}

enum Direction
{
	d_forward;
	d_backward;
}

class Sprite
{
	var surface : Surface;
	var groups : Array<Array<Rect>>;
	var currentgroup : Int;
	public var currentframe : Int;
	var animtype : AnimType;
	var direction : Direction;
	public var type : AnimType;
	public var group : Int;
	public var x : Int;
	public var y : Int;
	public var click : Int;
	
	public function new( srf : Surface )
	{
		currentgroup = 0;
		currentframe = 0;
		animtype = at_once;
		direction = d_forward;
		type = animtype;
		groups = new Array();
		group = 0;
		x = 0;
		y = 0;
		click = 0;
		surface = srf;
	}
	
	public function setFrame( rect : Rect, group : Int, loc : Int )
	{
		if ( groups[ loc ] == null ) groups[ loc ] = new Array();
		if ( group >= groups.length || group < 0 )
		{
			neko.Lib.print( "unable to add sprite frame. specified group is out of bounds.\n" );
			return;
		}
		groups[ group ][ loc ] = rect;
	}
	
	public function setFrameRange( xOffset : Int, yOffset : Int, spriteWidth : Int, spriteHeight : Int, cols : Int, count : Int, group : Int )
	{
		for ( loc in 0...count )
		{
			var rect = new Rect( xOffset + ( ( loc % cols ) * spriteWidth ), yOffset + ( Math.floor( loc / cols ) * spriteHeight ), spriteWidth, spriteHeight );
			if ( groups[ loc ] == null ) groups[ loc ] = new Array();
			if ( group >= groups.length || group < 0 )
			{
				neko.Lib.print( "unable to add sprite frame. specified group is out of bounds.\n" );
				return;
			}
			groups[ group ][ loc ] = rect;
		}
	}
	
	public function animate( timer : Timer )
	{
		if ( group != currentgroup || type != animtype )
		{
			currentgroup = group;
			animtype = type;
			currentframe = 0;
			direction = d_forward;
		}
		
		drawFrame();
		
		if ( timer.isTime() )
		{
			if ( animtype == at_pingpong )
			{
				if ( direction == d_forward )
				{
					if ( currentframe + 1 < groups[ group ].length )
					{
						currentframe++;
					}
					else
					{
						direction = d_backward;
						currentframe--;
					}
				}
				else
				{
					if ( currentframe > 0 )
					{
						currentframe--;
					}
					else
					{
						direction = d_forward;
						currentframe++;
					}
				}
			}
			else if ( animtype == at_loop )
			{
				if ( currentframe + 1 >= groups[ group ].length )
					currentframe = 0;
				else
					currentframe++;
			}
			else
			{
				if ( currentframe + 1 != groups[ group ].length )
					currentframe++;
			}
		}
	}
	
	public function drawFrame()
	{
		var point = new Point( x, y );
		surface.draw( Manager.getScreen(), groups[ group ][ currentframe ], point );
	}
	
	public function getCurrentRect() : Rect
	{
		return groups[ currentgroup ][ currentframe ];
	}
	
	public function getSpriteOffset( sprite : Sprite ) : Point
	{
		return new Point( sprite.x - x, sprite.y - y );
	}
}