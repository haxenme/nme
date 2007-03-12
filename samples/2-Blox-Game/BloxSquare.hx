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
 * Credit goes to Andy ? who created the original Blox game in C for which this
 * example is based
 */
 
import nme.Surface;
import nme.Manager;
import nme.Point;
import nme.Rect;
import BlockType;

class BloxSquare
{	
	// Location within bitmap of colored squares //
	public static var blockRects : Array<Dynamic> = [{x:600,y:400},{x:620,y:400},{x:640,y:400},{x:660,y:400},{x:680,y:400},{x:700,y:400},{x:720,y:400}];
	
	// Location of the center of the square //
	private var m_CenterX : Int;
	private var m_CenterY : Int;

	// Type of block. Needed to locate the correct square in our bitmap //
	private var m_BlockType : BlockType;
	
	// A pointer to our bitmap surface from "Main.cpp" //
	private var m_Bitmap : Surface;

	// Main constructor takes location and type of block, //
	// and pointer to our bitmap surface. //
	public function new( x : Int, y : Int, bitmap : Surface, type : BlockType )
	{
		m_CenterX = x;
		m_CenterY = y; 
		m_Bitmap = bitmap;
		m_BlockType = type;
	}

	public function draw()
	{
        var source : Rect;
		
		// switch statement to determine the location of the square within our bitmap //
		switch m_BlockType
		{
			case SQUARE_BLOCK:
				source = new Rect( blockRects[0].x, blockRects[0].y, Blox.squareMedian * 2, Blox.squareMedian * 2 );
			case T_BLOCK:
				source = new Rect( blockRects[1].x, blockRects[1].y, Blox.squareMedian * 2, Blox.squareMedian * 2 );
			case L_BLOCK:
				source = new Rect( blockRects[2].x, blockRects[2].y, Blox.squareMedian * 2, Blox.squareMedian * 2 );
			case BACKWARDS_L_BLOCK:
				source = new Rect( blockRects[3].x, blockRects[3].y, Blox.squareMedian * 2, Blox.squareMedian * 2 );
			case STRAIGHT_BLOCK:
				source = new Rect( blockRects[4].x, blockRects[4].y, Blox.squareMedian * 2, Blox.squareMedian * 2 );
			case S_BLOCK:
				source = new Rect( blockRects[5].x, blockRects[5].y, Blox.squareMedian * 2, Blox.squareMedian * 2 );
			case BACKWARDS_S_BLOCK:
				source = new Rect( blockRects[6].x, blockRects[6].y, Blox.squareMedian * 2, Blox.squareMedian * 2 );
		}
		
		// draw at square's current location. remember that m_X and m_Y store the center of the square. //
		var destination : Point = new Point( m_CenterX - Blox.squareMedian, m_CenterY - Blox.squareMedian );

		m_Bitmap.draw( Manager.getScreen(), source, destination );
	}

	// Remember, squareMedian represents the distance from the square's center to //
	// its sides. squareMedian*2 gives us the width and height of our squares.    //
	public function move( dir : BlockDirection )
	{
		switch (dir)
		{
			case LEFT:
				m_CenterX -= Blox.squareMedian * 2;
			case RIGHT:
				m_CenterX += Blox.squareMedian * 2;
			case DOWN:
				m_CenterY += Blox.squareMedian * 2;
		}
	}

	// Accessors //
	public function getCenterX() { return m_CenterX; }
	public function getCenterY() { return m_CenterY; }

	// Mutators //
	public function setCenterX( x : Int ) { m_CenterX = x; }
	public function setCenterY( y : Int ) { m_CenterY = y; }
}