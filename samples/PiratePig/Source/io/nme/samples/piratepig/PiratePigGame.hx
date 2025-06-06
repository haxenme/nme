package io.nme.samples.piratepig;


import motion.Actuate;
import motion.easing.Quad;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.display.Shape;
import nme.events.Event;
import nme.events.MouseEvent;
import nme.events.KeyboardEvent;
import nme.filters.BlurFilter;
import nme.filters.DropShadowFilter;
import nme.geom.Point;
import nme.media.Sound;
import nme.text.TextField;
import nme.text.TextFormat;
import nme.text.TextFormatAlign;
import nme.Assets;
import nme.ui.Keyboard;
import nme.Lib;


class PiratePigGame extends Sprite {
	
	
	private static var NUM_COLUMNS:Int = 8;
	private static var NUM_ROWS:Int = 8;
	
	private static var tileImages:Array <String> = [ "images/game_bear.png", "images/game_bunny_02.png", "images/game_carrot.png", "images/game_lemon.png", "images/game_panda.png", "images/game_piratePig.png" ];
	
	private var Background:Sprite;
	private var IntroSound:Sound;
	private var Logo:Bitmap;
	private var Score:TextField;
	private var Sound3:Sound;
	private var Sound4:Sound;
	private var Sound5:Sound;
	private var TileContainer:Sprite;
	private var SelectionContainer:Shape;
	
	public var currentScale:Float;
	public var currentScore:Int;
	
	private var cacheMouse:Point;
	private var needToCheckMatches:Bool;
	private var selectedTile:Tile;
	private var tiles:Array <Array <Tile>>;
	private var usedTiles:Array <Tile>;
	private var cursorRow:Int;
	private var cursorCol:Int;
	private var cursorActive:Bool;
	private var seenMouse:Bool;
	private var seenKey:Bool;
	
	
	public function new () {
		
		super ();

      Dbg.game = this;
      seenMouse = seenKey = false;
		
      cursorActive = true;
		initialize ();
		construct ();
		
		newGame ();
		
	}
	
	
	private function addTile (row:Int, column:Int, animate:Bool = true):Void {
	
		var tile = null;
		var type = Math.round (Math.random () * (tileImages.length - 1));
		
		for (usedTile in usedTiles) {
			
			if (usedTile.removed && usedTile.parent == null && usedTile.type == type) {
				
				tile = usedTile;
				
			}
			
		}
		
		if (tile == null) {
			
			tile = new Tile (tileImages[type]);
			
		}
		
		tile.initialize ();
		
		tile.type = type;
		tile.row = row;
		tile.column = column;
		tiles[row][column] = tile;
		
		var position = getPosition (row, column);
		
		if (animate) {
			
			var firstPosition = getPosition (-1, column);
			
			tile.alpha = 0;
			tile.x = firstPosition.x;
			tile.y = firstPosition.y;
			
			tile.moveTo (0.15 * (row + 1), position.x, position.y);
			Actuate.tween (tile, 0.3, { alpha: 1 } ).delay (0.15 * (row - 2)).ease (Quad.easeOut);
			
		} else {
			
			tile.x = position.x;
			tile.y = position.y;
			
		}
		
		TileContainer.addChild (tile);
		needToCheckMatches = true;
		
	}
	
	
	private function construct ():Void {
		
		Logo.smoothing = true;
		addChild (Logo);
		
		var font = Assets.getFont ("fonts/FreebooterUpdated.ttf");
		var defaultFormat = new TextFormat (font.fontName, 60, 0x000000);
		defaultFormat.align = TextFormatAlign.RIGHT;
		
		
		var contentWidth = 75 * NUM_COLUMNS;
		
		Score.x = contentWidth - 200;
		Score.width = 200;
		Score.y = 12;
		Score.selectable = false;
		Score.defaultTextFormat = defaultFormat;
		
		Score.filters = [ new BlurFilter (1.5, 1.5), new DropShadowFilter (1, 45, 0, 0.2, 5, 5) ];
		
		Score.embedFonts = true;
		addChild (Score);
		
		Background.y = 85;
		Background.graphics.beginFill (0xFFFFFF, 0.4);
		Background.graphics.drawRect (0, 0, contentWidth, 75 * NUM_ROWS);
		
		Background.filters = [ new BlurFilter (10, 10) ];
		addChild (Background);
		
		TileContainer.x = 14;
		TileContainer.y = Background.y + 14;
		TileContainer.addEventListener (MouseEvent.MOUSE_DOWN, TileContainer_onMouseDown);
		Lib.current.stage.addEventListener (MouseEvent.MOUSE_MOVE, onMouseMove);
		Lib.current.stage.addEventListener (MouseEvent.MOUSE_UP, stage_onMouseUp);
		Lib.current.stage.addEventListener (KeyboardEvent.KEY_DOWN, onKey);
		addChild (TileContainer);
		TileContainer.addChild (SelectionContainer);
		
		IntroSound = Assets.getMusic ("soundTheme");
		Sound3 = Assets.getSound ("sound3");
		Sound4 = Assets.getSound ("sound4");
		Sound5 = Assets.getSound ("sound5");
		
	}

   function onMouseMove(_)
   {
      if (!seenMouse && !seenKey)
      {
         seenMouse = true;
         SelectionContainer.visible = false;
      }
   }

   function onKey(event:KeyboardEvent)
   {
      var code = event.keyCode;
      var dx = 0;
      var dy = 0;

      if (!SelectionContainer.visible)
      {
         SelectionContainer.visible = true;
         return;
      }

      if (code==Keyboard.LEFT)
         dx = -1;
      else if (code==Keyboard.RIGHT)
         dx = 1;
      else if (code==Keyboard.UP)
         dy = -1;
      else if (code==Keyboard.DOWN)
         dy = 1;
      else if (code==Keyboard.ENTER)
      {
         seenKey = true;
         setSelection( cursorRow, cursorCol, !cursorActive);
      }
      else
      {
         SelectionContainer.visible = false;
         return;
      }


      if (dx!=0 || dy!=0)
      {
         seenKey = true;
         if (cursorActive)
         {
            if (swapTile (tiles[cursorRow][cursorCol], cursorRow+dy, cursorCol+dx ))
            {
               setSelection( cursorRow+dy, cursorCol+dx, false);
            }
         }
         else
            setSelection( cursorRow+dy, cursorCol+dx, cursorActive);
      }
   }
	
	
	private function dropTiles ():Void {
		
		for (column in 0...NUM_COLUMNS) {
			
			var spaces = 0;
			
			for (row in 0...NUM_ROWS) {
				
				var index = (NUM_ROWS - 1) - row;
				var tile = tiles[index][column];
				
				if (tile == null) {
					
					spaces++;
					
				} else {
					
					if (spaces > 0) {
						
						var position = getPosition (index + spaces, column);
						tile.moveTo (0.15 * spaces, position.x,position.y);
						
						tile.row = index + spaces;
						tiles[index + spaces][column] = tile;
						tiles[index][column] = null;
						
						needToCheckMatches = true;
						
					}
					
				}
				
			}
			
			for (i in 0...spaces) {
				
				var row = (spaces - 1) - i;
				addTile (row, column);
				
			}
			
		}
		
	}
	
	
	private function findMatches (byRow:Bool, accumulateScore:Bool = true):Array <Tile> {
		
		var matchedTiles = new Array <Tile> ();
		
		var max:Int;
		var secondMax:Int;
		
		if (byRow) {
			
			max = NUM_ROWS;
			secondMax = NUM_COLUMNS;
			
		} else {
			
			max = NUM_COLUMNS;
			secondMax = NUM_ROWS;
			
		}
		
		for (index in 0...max) {
			
			var matches = 0;
			var foundTiles = new Array <Tile> ();
			var previousType = -1;
			
			for (secondIndex in 0...secondMax) {
				
				var tile:Tile;
				
				if (byRow) {
					
					tile = tiles[index][secondIndex];
					
				} else {
					
					tile = tiles[secondIndex][index];
					
				}
				
				if (tile != null && !tile.moving) {
					
					if (previousType == -1) {
						
						previousType = tile.type;
						foundTiles.push (tile);
						continue;
						
					} else if (tile.type == previousType) {
						
						foundTiles.push (tile);
						matches++;
						
					}
					
				}
				
				if (tile == null || tile.moving || tile.type != previousType || secondIndex == secondMax - 1) {
					
					if (matches >= 2 && previousType != -1) {
						
						if (accumulateScore) {
							
							if (matches > 3) {
								
								Sound5.play ();
								
							} else if (matches > 2) {
								
								Sound4.play ();
								
							} else {
								
								Sound3.play ();
								
							}
							
							currentScore += Std.int (Math.pow (matches, 2) * 50);
							
						}
						
						matchedTiles = matchedTiles.concat (foundTiles);
						
					}
					
					matches = 0;
					foundTiles = new Array <Tile> ();
					
					if (tile == null || tile.moving) {
						
						needToCheckMatches = true;
						previousType = -1;
						
					} else {
						
						previousType = tile.type;
						foundTiles.push (tile);
						
					}
					
				}
				
			}
			
		}
		
		return matchedTiles;
		
	}
	
	
	private function getPosition (row:Int, column:Int):Point {
		
		return new Point (column * (57 + 16), row * (57 + 16));
		
	}

   function setSelection(inRow:Int, inCol:Int, inActive:Bool)
   {
      if (inRow<0) inRow = 0;
      if (inRow>=NUM_ROWS) inRow = NUM_ROWS-1;
      if (inCol<0) inCol = 0;
      if (inCol>=NUM_COLUMNS) inCol = NUM_COLUMNS-1;

      if (inActive!=cursorActive)
      {
         cursorActive = inActive;
         var gfx = SelectionContainer.graphics;
         gfx.lineStyle( 3, cursorActive ? 0xff0000 : 0x0000ff );
         gfx.drawRect( 0, 0, 57, 57 );
      }
      cursorRow = inRow;
      cursorCol = inCol;
      var pos = getPosition(cursorRow, cursorCol);
      SelectionContainer.x = pos.x;
      SelectionContainer.y = pos.y;
   }
	
	
	private function initialize ():Void {
		
		currentScale = 1;
		currentScore = 0;

		
		tiles = new Array <Array <Tile>> ();
		usedTiles = new Array <Tile> ();
		
		for (row in 0...NUM_ROWS) {
			
			tiles[row] = new Array <Tile> ();
			
			for (column in 0...NUM_COLUMNS) {
				
				tiles[row][column] = null;
				
			}
			
		}
		
		Background = new Sprite ();
		Logo = new Bitmap (Assets.getBitmapData ("images/logo.png"));
		Score = new TextField ();
		TileContainer = new Sprite ();
		SelectionContainer = new Shape ();
      SelectionContainer.visible = true;
		
      setSelection((NUM_ROWS>>1) -1,(NUM_COLUMNS>>1) -1,false);
	}
	
	
	public function newGame ():Void {
		
		currentScore = 0;
		Score.text = "0";
		
		for (row in 0...NUM_ROWS) {
			
			for (column in 0...NUM_COLUMNS) {
				
				removeTile (row, column, false);
				
			}
			
		}
		
		for (row in 0...NUM_ROWS) {
			
			for (column in 0...NUM_COLUMNS) {
				
				addTile (row, column, false);
				
			}
			
		}
		
		IntroSound.play ();
		
		removeEventListener (Event.ENTER_FRAME, this_onEnterFrame);
		addEventListener (Event.ENTER_FRAME, this_onEnterFrame);
		
	}
	
	
	public function removeTile (row:Int, column:Int, animate:Bool = true):Void {
		
		var tile = tiles[row][column];
		
		if (tile != null) {
			
			tile.remove (animate);
			usedTiles.push (tile);
			
		}
		
		tiles[row][column] = null;
		
	}
	
	
	public function resize (newWidth:Int, newHeight:Int):Void {
		
		var maxWidth = newWidth * 0.90;
		var maxHeight = newHeight * 0.86;
		
		currentScale = 1;
		scaleX = 1;
		scaleY = 1;
		
		var currentWidth = width;
		var currentHeight = height;
		
		var maxScaleX = maxWidth / currentWidth;
		var maxScaleY = maxHeight / currentHeight;

      currentScale = Math.min(maxScaleX,maxScaleY);

		scaleX = currentScale;
		scaleY = currentScale;
			
		x = newWidth / 2 - (currentWidth * currentScale) / 2;
		
	}
	
	
	private function swapTile (tile:Tile, targetRow:Int, targetColumn:Int):Bool {
		
		if (targetColumn >= 0 && targetColumn < NUM_COLUMNS && targetRow >= 0 && targetRow < NUM_ROWS) {
			
			var targetTile = tiles[targetRow][targetColumn];
			
			if (targetTile != null && !targetTile.moving) {
				
				tiles[targetRow][targetColumn] = tile;
				tiles[tile.row][tile.column] = targetTile;
				
				if (findMatches (true, false).length > 0 || findMatches (false, false).length > 0) {
					
					targetTile.row = tile.row;
					targetTile.column = tile.column;
					tile.row = targetRow;
					tile.column = targetColumn;
					var targetTilePosition = getPosition (targetTile.row, targetTile.column);
					var tilePosition = getPosition (tile.row, tile.column);
					
					targetTile.moveTo (0.3, targetTilePosition.x, targetTilePosition.y);
					tile.moveTo (0.3, tilePosition.x, tilePosition.y);
					
					needToCheckMatches = true;
               return true;
					
				} else {
					
					tiles[targetRow][targetColumn] = targetTile;
					tiles[tile.row][tile.column] = tile;
					
				}
				
			}
			
		}
      return false;
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function stage_onMouseUp (event:MouseEvent):Void {
		
		if (cacheMouse != null && selectedTile != null && !selectedTile.moving) {
			
			var differenceX = event.stageX - cacheMouse.x;
			var differenceY = event.stageY - cacheMouse.y;
			
			if (Math.abs (differenceX) > 10 || Math.abs (differenceY) > 10) {
				
				var swapToRow = selectedTile.row;
				var swapToColumn = selectedTile.column;
				
				if (Math.abs (differenceX) > Math.abs (differenceY)) {
					
					if (differenceX < 0) {
						
						swapToColumn --;
						
					} else {
						
						swapToColumn ++;
						
					}
					
				} else {
					
					if (differenceY < 0) {
						
						swapToRow --;
						
					} else {
						
						swapToRow ++;
						
					}
					
				}
				
				swapTile (selectedTile, swapToRow, swapToColumn);
				
			}
			
		}
		
		selectedTile = null;
		cacheMouse = null;
		
	}
	
	
	private function this_onEnterFrame (event:Event):Void {
		
		if (needToCheckMatches) {
			
			var matchedTiles = new Array <Tile> ();
			
			matchedTiles = matchedTiles.concat (findMatches (true));
			matchedTiles = matchedTiles.concat (findMatches (false));
			
			for (tile in matchedTiles) {
				
				removeTile (tile.row, tile.column);
				
			}
			
			if (matchedTiles.length > 0) {
				
				Score.text = Std.string (currentScore);
				dropTiles ();
				
			}
			
		}
		
	}
	
	
	private function TileContainer_onMouseDown (event:MouseEvent):Void {
		
		if (Std.isOfType(event.target, Tile)) {
			
			selectedTile = cast event.target;
			cacheMouse = new Point (event.stageX, event.stageY);
			
		} else {
			
			cacheMouse = null;
			selectedTile = null;
			
		}
		
	}
	
	
}
