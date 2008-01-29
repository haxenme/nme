/*
 * Copyright (c) 2008, Hugh Sanderson, http://gamehaxe.com/
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
 *
 */

package nme.geom;

class Point
{
   public var x : Float;
   public var y : Float;

   public function new(?inX : Float, ?inY : Float)
   {
      x = inX==null ? 0.0 : inX;
      y = inY==null ? 0.0 : inY;
   }

   public function add(v : nme.geom.Point) : nme.geom.Point
   {
      return new Point(v.x+x,v.y+y);
   }

   public function clone() : nme.geom.Point
   {
      return new Point(x,y);
   }

   public function equals(toCompare : nme.geom.Point) : Bool
   {
      return toCompare.x==x && toCompare.y==y;
   }

   public var length(get_length,null) : Float;
   function get_length()
   {
      return Math.sqrt(x*x+y*y);
   }
   public function normalize(thickness : Float) : Void
   {
      if (x==0 && y==0)
         x = thickness;
      else
      {
         var norm = thickness / Math.sqrt(x*x+y*y);
         x*=norm;
         y*=norm;
      }
   }

   public function offset(dx : Float, dy : Float) : Void
   {
      x+=dx;
      y+=dy;
   }
   public function subtract(v : nme.geom.Point) : nme.geom.Point
   {
      return new Point(x-v.x,y-v.y);
   }

   public static function distance(pt1 : nme.geom.Point, pt2 : nme.geom.Point) : Float
   {
      var dx = pt1.x-pt2.x;
      var dy = pt1.y-pt2.y;
      return Math.sqrt(dx*dy + dy*dy);
   }

   public static function interpolate(pt1 : nme.geom.Point, pt2 : nme.geom.Point, f : Float) : nme.geom.Point
   {
      return new Point( pt2.x + f*(pt1.x-pt2.x),
                        pt2.y + f*(pt1.y-pt2.y) );
   }

   public static function polar(len : Float, angle : Float) : nme.geom.Point
   {
      return new Point( len*Math.cos(angle), len*Math.sin(angle) );
   }
}
