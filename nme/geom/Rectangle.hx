package nme.geom;
#if (cpp || neko)


/*
 * Copyright (c) 2008, Hugh Sanderson, http://gamehaxe.com/
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
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
 *
 */
class Rectangle
{
	
	public var bottom(nmeGetBottom, nmeSetBottom):Float;
	public var bottomRight(nmeGetBottomRight, nmeSetBottomRight) : Point;
	public var height:Float;
	public var left(nmeGetLeft, nmeSetLeft):Float;
	public var right(nmeGetRight, nmeSetRight):Float;
	public var size(nmeGetTopLeft, nmeSetTopLeft) : Point;
	public var top(nmeGetTop, nmeSetTop):Float;
	public var topLeft(nmeGetTopLeft, nmeSetTopLeft) : Point;
	public var width:Float;
	public var x:Float;
	public var y:Float;
	
	
	public function new(?inX:Float, ?inY:Float, ?inWidth:Float, ?inHeight:Float):Void
	{
		x = inX == null ? 0 : inX;
		y = inY == null ? 0 : inY;
		width = inWidth == null ? 0 : inWidth;
		height = inHeight == null ? 0 : inHeight;
	}
	
	
	public function clone():Rectangle
	{
		return new Rectangle(x, y, width, height);
	}
	
	
	public function contains(inX:Float, inY:Float):Bool
	{
		return inX >= x && inY >= y && inX < right && inY < bottom;
	}
	
	
	public function containsPoint(point:Point):Bool
	{
		return contains(point.x, point.y);
	}
	
	
	public function containsRect(rect:Rectangle):Bool
	{
		return contains(rect.x, rect.y) && containsPoint(rect.bottomRight);
	}
	
	
	public function equals(toCompare:Rectangle):Bool
	{
		return x == toCompare.x && y == toCompare.y && width == toCompare.width && height == toCompare.height;
	}
	
	
	public function extendBounds(r:Rectangle)
	{
		var dx = x - r.x;
		if (dx > 0)
		{
			x -= dx;
			width += dx;
		}
		var dy = y - r.y;
		if (dy > 0)
		{
			y -= dy;
			height += dy;
		}
		if (r.right > right)
			right = r.right;
		if (r.bottom > bottom)
			bottom = r.bottom;
	}
	
	
	public function inflate(dx:Float, dy:Float):Void
	{
		x -= dx; width += dx * 2;
		y -= dy; height += dy * 2;
	}
	
	
	public function inflatePoint(point:Point):Void
	{
		inflate(point.x, point.y);
	}
	
	
	public function intersection(toIntersect:Rectangle):Rectangle
	{
		var x0 = x < toIntersect.x ? toIntersect.x : x;
		var x1 = right > toIntersect.right ? toIntersect.right : right;
		if (x1 <= x0)
			return new Rectangle();
		
		var y0 = y < toIntersect.y ? toIntersect.x : y;
		var y1 = bottom > toIntersect.bottom ? toIntersect.bottom : bottom;
		if (y1 <= y0)
			return new Rectangle();
		
		return new Rectangle(x0, y0, x1 - x0, y1 - y0);
	}
	
	
	public function intersects(toIntersect:Rectangle):Bool
	{
		var x0 = x < toIntersect.x ? toIntersect.x : x;
		var x1 = right > toIntersect.right ? toIntersect.right : right;
		if (x1 <= x0)
			return false;
		
		var y0 = y < toIntersect.y ? toIntersect.y : y;
		var y1 = bottom > toIntersect.bottom ? toIntersect.bottom : bottom;
		return y1 > y0;
	}
	
	
	public function isEmpty():Bool
	{
		return width == 0 && height == 0;
	}

	
	public function offset(dx:Float, dy:Float):Void
	{
		x += dx;
		y += dy;
	}
	
	
	public function offsetPoint(point:Point):Void
	{
		x += point.x;
		y += point.y;
	}
	
	
	public function setEmpty():Void
	{
		x = y = width = height = 0;
	}
	
	
	public function transform(m:Matrix)
	{
		var tx0 = m.a * x + m.c * y;
		var tx1 = tx0;
		var ty0 = m.b * x + m.d * y;
		var ty1 = tx0;
		
		var tx = m.a * (x + width) + m.c * y;
		var ty = m.b * (x + width) + m.d * y;
		if (tx < tx0) tx0 = tx;
		if (ty < ty0) ty0 = ty;
		if (tx > tx1) tx1 = tx;
		if (ty > ty1) ty1 = ty;
		
		tx = m.a * (x + width) + m.c * (y + height);
		ty = m.b * (x + width) + m.d * (y + height);
		if (tx < tx0) tx0 = tx;
		if (ty < ty0) ty0 = ty;
		if (tx > tx1) tx1 = tx;
		if (ty > ty1) ty1 = ty;
		
		tx = m.a * x + m.c * (y + height);
		ty = m.b * x + m.d * (y + height);
		if (tx < tx0) tx0 = tx;
		if (ty < ty0) ty0 = ty;
		if (tx > tx1) tx1 = tx;
		if (ty > ty1) ty1 = ty;
		
		return new Rectangle(tx0 + m.tx, ty0 + m.ty, tx1 - tx0, ty1 - ty0);
	}
	
	
	public function union(toUnion:Rectangle):Rectangle
	{
		var x0 = x > toUnion.x ? toUnion.x : x;
		var x1 = right < toUnion.right ? toUnion.right : right;
		var y0 = y > toUnion.y ? toUnion.x : y;
		var y1 = bottom < toUnion.bottom ? toUnion.bottom : bottom;
		return new Rectangle(x0, y0, x1 - x0, y1 - y0);
	}
	
	
	
	// Getters & Setters
	
	
	
	private function nmeGetBottom() { return y + height; }
	private function nmeSetBottom(b:Float) { height = b - y; return b; }
	private function nmeGetBottomRight() { return new Point(x + width, y + height); }
	private function nmeSetBottomRight(p:Point) { width = p.x - x;	height = p.y - y; return p.clone(); }
	private function nmeGetLeft() { return x; }
	private function nmeSetLeft(l:Float) { width -= l - x; x = l; return l; }
	private function nmeGetRight() { return x + width; }
	private function nmeSetRight(r:Float) { width = r - x; return r; }
	private function nmeGetSize() { return new Point(width, height); }
	private function nmeSetSize(p:Point) { width = p.x; height = p.y; return p.clone(); }
	private function nmeGetTop() { return y; }
	private function nmeSetTop(t:Float) { height -= t - y; y = t; return t; }
	private function nmeGetTopLeft() { return new Point(x, y); }
	private function nmeSetTopLeft(p:Point) { x = p.x; y = p.y; return p.clone(); }
	
}


#else
typedef Rectangle = flash.geom.Rectangle;
#end