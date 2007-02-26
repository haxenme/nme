package neko.nme;

import neko.nme.Rect;
import neko.nme.Point;
import neko.nme.Timer;
import neko.nme.Surface;

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
	var currentframe : Int;
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
	
	public function animate( timer : Timer )
	{
		if ( group != currentgroup || type != animtype )
		{
			currentgroup = group;
			animtype = type;
			currentframe = 0;
			direction = d_forward;
		}
		
		var point = new Point( x, y );
		surface.draw( Manager.getScreen(), groups[ group ][ currentframe ], point );
		
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
	
	public function getCurrentRect() : Rect
	{
		return groups[ currentgroup ][ currentframe ];
	}
	
	public function getSpriteOffset( sprite : Sprite ) : Point
	{
		return new Point( sprite.x - x, sprite.y - y );
	}
}