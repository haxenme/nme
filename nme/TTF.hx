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
import nme.Surface;
import nme.Manager;

class TTF
{
        public static var defaultFont = "Times";
        public static var defaultSize = 12;
        public static var defaultFGColor = 0xffffff;
        public static var defaultBGColor = 0x000000;

        public var text:String;
        public var font:String;
        public var size:Int;
        public var position:Point;
        public var alpha:Int;
        public var bgColor:Int;
        public var fgColor:Int;

        public function new( ?str : String, ?in_font : String, ?in_size : Int,?fcolor : Int, ?bcolor : Int, ?in_alpha : Int, ?location:Point )
        {
           text = str==null ? "" : str;
           font = in_font==null ? defaultFont : in_font;
           size = in_size==null ? defaultSize : in_size;
           position = location==null ? new Point(0,0) : location;
           fgColor = fcolor==null ? defaultFGColor : fcolor;
           bgColor = bcolor==null ? defaultBGColor : bcolor;
           alpha = in_alpha==null ? 255 : in_alpha;
        }

        public function moveTo(x:Int, y:Int)
        {
           position.x = x;
           position.y = y;
        }

	public function draw(?inSurface:Void)
	{
                if (inSurface==null)
                   inSurface=Manager.getScreen();
		nme_ttf_shaded( inSurface, untyped text.__s, untyped font.__s, size, position.x, position.y, fgColor, bgColor, alpha );
	}


	public function drawAt( location : Point, ?inSurface:Void )
	{
                if (inSurface==null)
                   inSurface=Manager.getScreen();
		nme_ttf_shaded( inSurface, untyped text.__s, untyped font.__s, size, location.x, location.y, fgColor, bgColor, alpha );
	}
	
	static var nme_ttf_shaded = neko.Lib.load("nme","nme_ttf_shaded",-1);
}
