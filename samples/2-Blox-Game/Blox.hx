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
 
import nme.Manager;
import nme.Surface;
import nme.Sprite;
import nme.Sound;
import nme.Music;
import nme.Rect;
import nme.Point;
import nme.Timer;
import nme.TTF;
import BloxBlock;
import BlockType;
import BlockDirection;
import Reflect;

class Blox
{
	static var mainObject : Blox;
	
	public static var wndWidth = 300;
	public static var wndHeight = 400;
	public static var wndCaption = "Blox";

	// Game related defines //
	public static var fps = 30;
	public static var fRate = 1000 / fps;

	// The game area is the area where the focus block can go. //
	// These values are used to check collisions between the   //
	// game squares and the sides of the game area.            //
	public static var lGameArea = 53;
	public static var rGameArea = 251;
	public static var bGameArea = 298; 

	public static var numLvls = 5;    // number of levels in the game
	public static var pointsPerLine = 525;  // points player receives for completing a line
	public static var pointsPerLvl = 6300; // points player needs to advance a level 

	public static var initialSpd = 60;  // initial interval at which focus block moves down 
	public static var spdChange = 10;  // the above interval is reduced by this much each level

	// Amount of time player has to move the focus block when its bottom collides with something. //
	// Measured in number of frames. At 30 fps, 15 frames will give the player half a second.     //
	public static var slideTime = 15;
	
	public static var squaresPerRow = 10;  // number of squares that fit in a row
	public static var squareMedian = 10;  // distance from the center of a square to its sides
	
	// Starting position of the focus block //
	public static var blockStartX = 151; 
	public static var blockStartY = 59;
	
	// Location on game screen for displaying... //
	public static var lvlRectX = 42;  // current level
	public static var lvlRectY = 320;
	public static var scoreRectX = 42;  // current score
	public static var scoreRectY = 340;
	public static var neededScoreRectX = 42;  // score needed for next level
	public static var neededScoreRectY = 360;
	public static var nextBlockCircleX = 214; // next block in line to be focus block
	public static var nextBlockCircleY = 347;
	
	// Locations within bitmap of background screens //
	public static var bgRects : Array<Dynamic> = [{x:0,y:0},{x:300,y:0},{x:300,y:0},{x:0,y:396},{x:300,y:396}];
	
	var g_Running : Bool;
	var g_Keys : Array<Bool>;
	var g_Timer : Timer;
	var g_CurTime : Float;
	var g_PrevTime : Float;
	var g_Bitmap : Surface;
	var g_FocusBlock : BloxBlock;			// The block the player is controlling
	var g_NextBlock : BloxBlock; 			// The next block to be the focus block
	var g_OldSquares : Array<BloxSquare>;	// The squares that no longer form the focus block
	var g_Score : Int;						// Players current score
	var g_Level : Int;         				// Current level player is on
	var g_FocusBlockSpeed : Int;			// Speed of the focus block
	
	var down_pressed : Bool;
	var left_pressed : Bool;
	var right_pressed : Bool;
	
	var force_down_counter : Int;
	var slide_counter : Int;
	
	var g_Mng : Manager;
	var g_State : Int;
	
	var g_Bang : Sound;
	var g_Boom : Sound;
	
	static function main()
	{
		mainObject = new Blox();
	}
	
	public function new()
	{
		g_Score = 0;
		g_Level = 1;
		g_FocusBlockSpeed = initialSpd;
		g_OldSquares = new Array();
		g_Keys = new Array();
		g_PrevTime = 0;
		g_CurTime = 0;

		g_Mng = new Manager( wndWidth, wndHeight, wndCaption, false, "ico.gif" );

		Sound.setChannels( 2 );
		Music.init( "Data/bubbleb.mid" );
		Music.setVolume( 64 );
		g_Bang = new Sound( "Data/bang.wav" );
		g_Boom = new Sound( "Data/boom.wav" );
		changeState( 1 );
		
		g_Timer = new Timer( 30 );

		g_Bitmap = new Surface( "Data/Blox.gif" );
		
		g_Bitmap.setKey( 255, 255, 255 );
		
		// Initialize blocks and set them to their proper locations. //
		g_FocusBlock = new BloxBlock( blockStartX, blockStartY, g_Bitmap, getBlockTypeFromInt( Std.random( 7 ) ) );
		g_NextBlock  = new BloxBlock( nextBlockCircleX, nextBlockCircleY, g_Bitmap, getBlockTypeFromInt( Std.random( 7 ) ) );
		
		// Every frame we increase this value until it is equal to g_FocusBlockSpeed. //
		// When it reaches that value, we force the focus block down. //
		force_down_counter = 0;

		// Every frame, we check to see if the focus block's bottom has hit something. If it    //
		// has, we decrement this counter. If the counter hits zero, the focus block needs to   //
		// be changed. We use this counter so the player can slide the block before it changes. //
		slide_counter = slideTime;	
		
		var fps : Float;
		g_Running = true;
		while (g_Running)
			if ( g_Timer.isTime() )
				switch g_State
				{
					case 1:
						inGame();
					case 2:
						gameWon();
					case 3:
						gameLost();
				}
		g_Mng.close();
	}
	
	// This function receives player input and //
	// handles it for the main game state.     //
	public function handleGameInput() 
	{
		// These variables allow the user to hold the arrow keys down //
		down_pressed  = false;
		left_pressed  = false;
		right_pressed = false;

		// Fill our event structure with event information. //
		g_Mng.events();
		switch g_Mng.getEventType()
		{
			case et_keydown:
				processKeys( g_Mng.lastKey(), true );
			case et_keyup:
				processKeys( g_Mng.lastKey(), false );
			case et_quit:
				g_Running = false;
			default:
		}

		// Now we handle the arrow keys, making sure to check for collisions //
		if ( down_pressed )
			if ( !CheckWallCollisions( g_FocusBlock, DOWN ) && !checkEntityCollisions( g_FocusBlock, DOWN ) )
				g_FocusBlock.move( DOWN );
		if ( left_pressed )
			if ( !CheckWallCollisions( g_FocusBlock, LEFT ) && !checkEntityCollisions( g_FocusBlock, LEFT ) )
				g_FocusBlock.move( LEFT );
		if ( right_pressed )
			if ( !CheckWallCollisions( g_FocusBlock, RIGHT ) && !checkEntityCollisions( g_FocusBlock, RIGHT ) )
				g_FocusBlock.move( RIGHT );
	}
	
	public function changeState( state )
	{
		g_State = state;
		if ( state == 1 )
			Music.play( -1 );
		else
			Music.stop();
	}
	
	// This function receives player input and //
	// handles it for the main game state.     //
	public function handleWinLoseInput() 
	{
		// Fill our event structure with event information. //
		g_Mng.events();
		switch g_Mng.getEventType()
		{
			case et_keydown:
				switch g_Mng.lastKey()
				{
					case 121:
						g_Running = false;
					case 110:
						changeState( 1 );
				}
			case et_quit:
				g_Running = false;
			default:
		}
	}
	
	public function processKeys( key, pressed : Bool )
	{
		switch key
		{
			case 27:
				g_Running = false;
			case 273:
				if ( !pressed )
					if ( ! checkRotationCollisions( g_FocusBlock ) )
						g_FocusBlock.rotate();
			case 274:
				down_pressed = pressed;
			case 275:
				right_pressed = pressed;
			case 276:
				left_pressed = pressed;
			case 109:
				toggleMusic();
			default:
				neko.Lib.print( key );
		}
	}
	
	public function toggleMusic()
	{
		
	}
	
	public function getBlockTypeFromInt( i : Int )
	{
		switch i
		{
			case 0:
				return SQUARE_BLOCK;
			case 1:
				return T_BLOCK;
			case 2:
				return L_BLOCK;
			case 3:
				return BACKWARDS_L_BLOCK;
			case 4:
				return STRAIGHT_BLOCK;
			case 5:
				return S_BLOCK;
			default:
				return BACKWARDS_S_BLOCK;
		}
	}
	
	public function checkEntityCollisionsSquare( square : BloxSquare, dir : BlockDirection ) : Bool
	{ 
		// Width/height of a square. Also the distance //
		// between two squares if they've collided.    //
		var distance : Int = squareMedian * 2; 

		// Center of the given square //
		var centerX : Int = square.getCenterX();  
		var centerY : Int = square.getCenterY();

		// Determine the location of the square after moving //
		switch ( dir )
		{
			case DOWN:
				centerY += distance;
			case LEFT:
				centerX -= distance;
			case RIGHT:
				centerX += distance;
		}
		
		// Iterate through the old squares vector, checking for collisions //
		for ( i in 0...g_OldSquares.length )
			if ( ( Math.abs(centerX - g_OldSquares[i].getCenterX() ) < distance ) && ( Math.abs(centerY - g_OldSquares[i].getCenterY() ) < distance ) )
				return true;

		return false;
	}

	// Check collisions between a given block and the squares in g_OldSquares //
	public function checkEntityCollisions( block : BloxBlock, dir : BlockDirection ) : Bool 
	{ 
		// Get an array of the squares that make up the given block //
		var temp_array : Array<BloxSquare> = block.getSquares();

		// Now just call the other checkEntityCollisions() on each square //
		for ( i in 0...4 )
			if ( checkEntityCollisionsSquare( temp_array[i], dir ) )
				return true;

		return false;
	}

	// Check collisions between a given square and the sides of the game area //
	public function checkWallCollisionsSquare( square : BloxSquare, dir : BlockDirection ) : Bool
	{
		// Get the center of the square //
		var x : Int = square.getCenterX();
		var y : Int = square.getCenterY();

		// Get the location of the square after moving and see if its out of bounds //
		switch ( dir )
		{
			case DOWN:
				if ( ( y + ( squareMedian * 2 ) ) > bGameArea )
					return true;
				else
					return false;
			case LEFT:
				if ( ( x - ( squareMedian * 2 ) ) < lGameArea )
					return true;
				else
					return false;
			case RIGHT:
				if ( ( x + ( squareMedian * 2 ) ) > rGameArea )
					return true;
				else
					return false;
		}
		return false;
	}

	// Check for collisions between a given block a the sides of the game area //
	public function CheckWallCollisions( block : BloxBlock, dir : BlockDirection ) : Bool
	{
		// Get an array of squares that make up the given block //
		var temp_array : Array<BloxSquare> = block.getSquares();

		// Call other CheckWallCollisions() on each square //
		for ( i in 0...4 )
			if ( checkWallCollisionsSquare( temp_array[i], dir ) )
				return true;
		return false;
	}

	// Check for collisions when a block is rotated //
	public function checkRotationCollisions( block : BloxBlock ) 
	{
		// Get an array of values for the locations of the rotated block's squares //
		var temp_array : Array<Int> = block.getRotatedSquares();

		// Distance between two touching squares //
		var distance : Int = squareMedian * 2;

		for ( i in 0...4 )
		{
			// Check to see if the block will go out of bounds //
	        if ( ( temp_array[i*2] < lGameArea ) || ( temp_array[i*2] > rGameArea ) )
			{
				temp_array = null;
				return true;
			}

			if ( temp_array[i*2+1] > bGameArea )
			{
				temp_array = null;
				return true;
			}

			// Check to see if the block will collide with any squares //
			for ( index in 0...g_OldSquares.length )
				if ( ( Math.abs( temp_array[i*2]   - g_OldSquares[index].getCenterX() ) < distance ) && ( Math.abs( temp_array[i*2+1] - g_OldSquares[index].getCenterY() ) < distance ) )
				{
					temp_array = null;
					return true;
				}
		}

		temp_array = null;
		return false;
	}

	// This function handles all of the events that   //
	// occur when the focus block can no longer move. //
	public function handleBottomCollision() : Bool
	{	
		changeFocusBlock();

		// Check for completed lines and store the number of lines completed //
		var num_lines : Int = checkCompletedLines();

		var rslt : Bool = false;
		if ( num_lines > 0 )
		{
			rslt = true;
			// Increase player's score according to number of lines completed //
			g_Score += pointsPerLine * num_lines;

			// Check to see if it's time for a new level //
			if ( g_Score >= g_Level * pointsPerLvl )
			{
				g_Level++;
				checkWin(); // check for a win after increasing the level 
				g_FocusBlockSpeed -= spdChange; // shorten the focus blocks movement interval
			}
		}

		// Now would be a good time to check to see if the player has lost //
		checkLoss();
		
		return rslt;
	}

	// Add the squares of the focus block to g_OldSquares //
	// and set the next block as the focus block. //
	public function changeFocusBlock()
	{
		// Get an array of pointers to the focus block squares //
		var square_array : Array<BloxSquare> = g_FocusBlock.getSquares();

		// Add focus block squares to g_OldSquares //
		for ( i in 0...4 )
			g_OldSquares.push( square_array[i] );
		
		g_FocusBlock = null;        // delete the current focus block
		g_FocusBlock = g_NextBlock; // set the focus block to the next block
		g_FocusBlock.setupSquares( blockStartX, blockStartY, g_Bitmap );
		
		// Set the next block to a new block of random type //
		g_NextBlock = new BloxBlock( nextBlockCircleX, nextBlockCircleY, g_Bitmap, getBlockTypeFromInt( Std.random( 7 ) ) );
	}

	// Return amount of lines cleared or zero if no lines were cleared //
	public function checkCompletedLines() : Int
	{
		// Store the amount of squares in each row in an array //
		var squares_per_row : Array<Int> = new Array();

		// The compiler will fill the array with junk values if we don't do this //
		for ( index in 0...13 )
			squares_per_row[index] = 0;

		var row_size : Int   = squareMedian * 2;                // pixel size of one row
		var bottom : Int     = bGameArea - squareMedian; // center of bottom row
		var top : Int        = bottom - 12 * row_size;		   // center of top row
		
		var num_lines : Int = 0; // number of lines cleared                               
		var row : Int;           // multipurpose variable 


		// Check for full lines //
		for ( i in 0...g_OldSquares.length )
		{
			// Get the row the current square is in //
			row = Math.round( ( g_OldSquares[i].getCenterY() - top ) / row_size );

			// Increment the appropriate row counter //
			squares_per_row[row]++; 
		}

		// Erase any full lines //
		for ( line in 0...13 )
			// Check for completed lines //
			if ( squares_per_row[line] == squaresPerRow )
			{
				// Keep track of how many lines have been completed //
				num_lines++;

				var tmp : Array<BloxSquare> = new Array();	
				// Find any squares in current row and remove them //
				for ( index in 0...g_OldSquares.length )
					if ( Math.floor( ( g_OldSquares[index].getCenterY() - top ) / row_size ) != line )
						tmp.push( g_OldSquares[index] );
				g_OldSquares = tmp;
			}

		// Move squares above cleared line down //
		for ( index in 0...g_OldSquares.length )
			for ( line in 0...13 )
				// Determine if this row was filled //
				if ( squares_per_row[line] == squaresPerRow )
				{
					// If it was, get the location of it within the game area //
					row = Math.floor( ( g_OldSquares[index].getCenterY() - top ) / row_size );

					// Now move any squares above that row down one //
					if ( row < line )
						g_OldSquares[index].move( DOWN );
				}
				
		return num_lines;
	}

	// Check to see if player has won. Handle winning condition if needed. //
	public function checkWin() 
	{
		// If current level is greater than number of levels, player has won //
		if ( g_Level > numLvls )
		{
			// Clear the old squares vector //
			for ( i in 0...g_OldSquares.length )
				g_OldSquares[i] = null;
			g_OldSquares = new Array();

			// Reset score and level //
			g_Score = 0;
			g_Level = 1;

			changeState( 2 );
		}
	}

	// Check to see if player has lost. Handle losing condition if needed. //
	public function checkLoss() 
	{
		// We call this function when the focus block is at the top of that //
		// game area. If the focus block is stuck now, the game is over.    //
		if ( checkEntityCollisions( g_FocusBlock, DOWN ) )
		{
			// Clear the old squares vector //
			for ( i in 0...g_OldSquares.length )
				g_OldSquares[i] = null;
			g_OldSquares = new Array();

			// Reset score and level //
			g_Score = 0;
			g_Level = 1;
			
			changeState( 3 );
		}
	}	

	// This function draws the background //
	public function drawBackground() 
	{
		var source : Rect;

		// Set our source rectangle to the current level's background //
		switch ( g_Level )
		{
			case 1:
				source = new Rect( bgRects[0].x, bgRects[0].y, wndWidth, wndHeight );
			case 2:
				source = new Rect( bgRects[1].x, bgRects[1].y, wndWidth, wndHeight );
			case 3:
				source = new Rect( bgRects[2].x, bgRects[2].y, wndWidth, wndHeight );
			case 4:
				source = new Rect( bgRects[3].x, bgRects[3].y, wndWidth, wndHeight );
			case 5:
				source = new Rect( bgRects[4].x, bgRects[4].y, wndWidth, wndHeight );
		}
		
		var destination = new Point( 0, 0 );

		g_Bitmap.draw( Manager.getScreen(), source, destination );
	}
	
	public function inGame()
	{
		handleGameInput();
				
		force_down_counter++;

		if ( force_down_counter >= g_FocusBlockSpeed )
			// Always check for collisions before moving anything //
			if ( !CheckWallCollisions( g_FocusBlock, DOWN ) && !checkEntityCollisions( g_FocusBlock, DOWN ) )
			{
				g_FocusBlock.move( DOWN ); // move the focus block
				force_down_counter = 0;   // reset our counter
			}
		
		// Check to see if focus block's bottom has hit something. If it has, we decrement our counter. //
		if ( CheckWallCollisions( g_FocusBlock, DOWN ) || checkEntityCollisions( g_FocusBlock, DOWN ) )
			slide_counter--;
		// If there isn't a collision, we reset our counter.    //
		// This is in case the player moves out of a collision. //
		else 
			slide_counter = slideTime;
		// If the counter hits zero, we reset it and call our //
		// function that handles changing the focus block.    //
		if ( slide_counter == 0 )
		{
			slide_counter = slideTime;
			handleBottomCollision();
		}
		
		// Make sure nothing from the last frame is still drawn. //
		g_Mng.clear( 0xFFFFFF );

		// Draw the background //
		drawBackground();

		// Draw the focus block and next block. //
		g_FocusBlock.draw();
		g_NextBlock.draw();

		// Draw the old squares. //
		for ( i in 0...g_OldSquares.length )
			g_OldSquares[i].draw();
		
		// Draw the text for the current level, score, and needed score. //

		// We need to display the text ("Score:", "Level:", "Needed Score:") as well as the //
		// associated value. To do this, we use the string function append(). This function //
		// takes a char string so we call itoa() and store the char string in temp.         //
		var score : String = "Score: " + g_Score;
		var nextscore : String = "Needed Score: " + (g_Level*pointsPerLvl);
		var level : String = "Level: " + g_Level;
		
		var text : TTF = new TTF( score, "../common/ARIAL.TTF", 8, 0x000000, 0xFFFFFF );
		text.drawAt( new Point( scoreRectX, scoreRectY ) );
		
		text = new TTF( nextscore, "../common/ARIAL.TTF", 8, 0x000000, 0xFFFFFF );
		text.drawAt( new Point( neededScoreRectX, neededScoreRectY ) );
		
		text = new TTF( level, "../common/ARIAL.TTF", 8, 0x000000, 0xFFFFFF );
		text.drawAt( new Point( lvlRectX, lvlRectY ) );
		

		// Tell SDL to display our backbuffer. The four 0's will make //
		// SDL display the whole screen. //
		g_Mng.flip();
	}

	// Display a victory message. //
	public function gameWon()
	{
		handleWinLoseInput();

		g_Mng.clear( 0x000000);
		
		var text : TTF = new TTF( "You Win!!!", "../common/ARIAL.TTF", 12, 0xFFFFFF, 0x000000 );
		text.drawAt( new Point( 100, 120 ) );
		
		text = new TTF( "Quit Game (Y or N)?", "../common/ARIAL.TTF", 12, 0xFFFFFF, 0x000000 );
		text.drawAt( new Point( 100, 140 ) );
		
		g_Mng.flip();
	}

	// Display a game over message. //
	public function gameLost()
	{	
		handleWinLoseInput();
		
		g_Mng.clear( 0x000000);

		var text : TTF = new TTF( "You Lose.", "../common/ARIAL.TTF", 12, 0xFFFFFF, 0x000000 );
		text.drawAt( new Point( 100, 120 ) );
		
		text = new TTF( "Quit Game (Y or N)?", "../common/ARIAL.TTF", 12, 0xFFFFFF, 0x000000 );
		text.drawAt( new Point( 100, 140 ) );
		
		g_Mng.flip();
	}
}
