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
 
import BloxSquare;
import nme.Surface;

class BloxBlock
{
	private var m_CenterX : Int;
	private var m_CenterY : Int;
	
	private var m_Type : BlockType;
	
	private var m_Squares : Array<BloxSquare>;
	
	// The constructor just sets the block location and calls SetupSquares //
	public function new( x : Int, y : Int, bitmap : Surface, type : BlockType )
	{
		m_CenterX = x;
		m_CenterY = y;
		m_Type = type;
		m_Squares = new Array();
		for ( i in 0...4 )
			m_Squares[i] = null;
		
		setupSquares( x, y, bitmap );		
	}

	// Setup our block according to its location and type. Note that the squares //
	// are defined according to their distance from the block's center. This     //
	// function takes a surface that gets passed to cSquare's constructor.       //
	public function setupSquares( x : Int, y : Int, bitmap : Surface )
	{
		// This function takes the center location of the block. We set our data //
		// members to these values to make sure our squares don't get defined    //
		// around a new center without our block's center values changing too.   //
		m_CenterX = x;
		m_CenterY = y;

		// Make sure that any current squares are deleted //
		for ( i in 0...4)
			if ( m_Squares[i] != null )
				m_Squares[i] = null;
		
		switch ( m_Type )
		{
			case SQUARE_BLOCK:
				// Upper left //
				m_Squares[0] = new BloxSquare( x - Blox.squareMedian, y - Blox.squareMedian, bitmap, m_Type );
				// Lower Left //
				m_Squares[1] = new BloxSquare( x - Blox.squareMedian, y + Blox.squareMedian, bitmap, m_Type );
				// Upper right //
				m_Squares[2] = new BloxSquare( x + Blox.squareMedian, y - Blox.squareMedian, bitmap, m_Type );
				// Lower right //
				m_Squares[3] = new BloxSquare( x + Blox.squareMedian, y + Blox.squareMedian, bitmap, m_Type );
			case T_BLOCK:
				// Top //
				m_Squares[0] = new BloxSquare( x + Blox.squareMedian, y - Blox.squareMedian, bitmap, m_Type );
				// Middle //
				m_Squares[1] = new BloxSquare( x + Blox.squareMedian, y + Blox.squareMedian, bitmap, m_Type );
				// Left //
				m_Squares[2] = new BloxSquare( x - Blox.squareMedian, y + Blox.squareMedian, bitmap, m_Type );
				// Right //
				m_Squares[3] = new BloxSquare( x + ( Blox.squareMedian * 3 ), y + Blox.squareMedian, bitmap, m_Type );
			case L_BLOCK:
				// |  //
				m_Squares[0] = new BloxSquare( x - Blox.squareMedian, y - Blox.squareMedian, bitmap, m_Type );
				// |  //
				m_Squares[1] = new BloxSquare( x - Blox.squareMedian, y + Blox.squareMedian, bitmap, m_Type );
				// |_ //
				m_Squares[2] = new BloxSquare( x - Blox.squareMedian, y + ( Blox.squareMedian * 3 ), bitmap, m_Type );
				// __ //
				m_Squares[3] = new BloxSquare( x + Blox.squareMedian, y + ( Blox.squareMedian * 3 ), bitmap, m_Type );
			case BACKWARDS_L_BLOCK:
				//  | //
				m_Squares[0] = new BloxSquare( x + Blox.squareMedian, y - Blox.squareMedian, bitmap, m_Type );
				//  | //
				m_Squares[1] = new BloxSquare( x + Blox.squareMedian, y + Blox.squareMedian, bitmap, m_Type );
				// _| //
				m_Squares[2] = new BloxSquare( x + Blox.squareMedian, y + ( Blox.squareMedian * 3 ), bitmap, m_Type );
				// __ //
				m_Squares[3] = new BloxSquare( x - Blox.squareMedian, y + ( Blox.squareMedian * 3 ), bitmap, m_Type );
			case STRAIGHT_BLOCK:
				// Top //
				m_Squares[0] = new BloxSquare( x + Blox.squareMedian, y - ( Blox.squareMedian * 3 ), bitmap, m_Type );
				m_Squares[1] = new BloxSquare( x + Blox.squareMedian, y - Blox.squareMedian, bitmap, m_Type);
				m_Squares[2] = new BloxSquare( x + Blox.squareMedian, y + Blox.squareMedian, bitmap, m_Type);
				m_Squares[3] = new BloxSquare( x + Blox.squareMedian, y + ( Blox.squareMedian * 3 ), bitmap, m_Type );
				// Bottom //
			case S_BLOCK:
				// Top right //       
				m_Squares[0] = new BloxSquare( x + ( Blox.squareMedian * 3 ), y - Blox.squareMedian, bitmap, m_Type );
				// Top middle //
				m_Squares[1] = new BloxSquare( x + Blox.squareMedian, y - Blox.squareMedian, bitmap, m_Type );
				// Bottom middle //
				m_Squares[2] = new BloxSquare( x + Blox.squareMedian, y + Blox.squareMedian, bitmap, m_Type );
				// Bottom left //
				m_Squares[3] = new BloxSquare( x - Blox.squareMedian, y + Blox.squareMedian, bitmap, m_Type );
			case BACKWARDS_S_BLOCK:
				// Top left //       
				m_Squares[0] = new BloxSquare( x - Blox.squareMedian, y - Blox.squareMedian, bitmap, m_Type );
				// Top middle //
				m_Squares[1] = new BloxSquare( x + Blox.squareMedian, y - Blox.squareMedian, bitmap, m_Type );
				// Bottom middle //
				m_Squares[2] = new BloxSquare( x + Blox.squareMedian, y + Blox.squareMedian, bitmap, m_Type );
				// Bottom right //
				m_Squares[3] = new BloxSquare( x + ( Blox.squareMedian * 3 ), y + Blox.squareMedian, bitmap, m_Type );
		}
	}

	// draw() simply iterates through the squares and calls their draw() functions. //
	public function draw()
	{
		for ( i in 0...4 )
			m_Squares[i].draw();
	}

	// move() simply changes the block's center and calls the squares' move functions. //
	public function move( dir : BlockDirection )
	{
		switch ( dir )
		{
			case LEFT:
				m_CenterX -= Blox.squareMedian * 2;
			case RIGHT:
				m_CenterX += Blox.squareMedian * 2;
			case DOWN:
				m_CenterY += Blox.squareMedian * 2;
		}

		for ( i in 0...4 )
		{
			m_Squares[i].move( dir );
		}
	}

	// This function is explained in the tutorial. //
	public function rotate()
	{
		var x1 : Int;
		var y1 : Int;
		var x2 : Int;
		var y2 : Int;

		for ( i in 0...4 )
		{
			x1 = m_Squares[i].getCenterX(); 
			y1 = m_Squares[i].getCenterY();

			x1 -= m_CenterX;
			y1 -= m_CenterY;

			x2 = - y1;
			y2 = x1;

			x2 += m_CenterX;
			y2 += m_CenterY;

			m_Squares[i].setCenterX( x2 );
			m_Squares[i].setCenterY( y2 );
		}
	}

	// This function gets the locations of the squares after //
	// a rotation and returns an array of those values.      //
	public function getRotatedSquares() : Array<Int>
	{
		var temp_array : Array<Int> = new Array();
		var x1 : Int;
		var y1 : Int;
		var x2 : Int;
		var y2 : Int;
		
		for ( i in 0...4 )
		{
			x1 = m_Squares[i].getCenterX(); 
			y1 = m_Squares[i].getCenterY();

			x1 -= m_CenterX;
			y1 -= m_CenterY;

			x2 = - y1;
			y2 = x1;

			x2 += m_CenterX;
			y2 += m_CenterY;

			temp_array[i*2] = x2;
			temp_array[i*2+1] = y2;
		}

		return temp_array;
	}

	// This returns an array of pointers to the squares of the block. //
	public function getSquares() : Array<BloxSquare>
	{
		return m_Squares;
	}
}