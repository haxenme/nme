/*
 * Copyright (c) 2008, Hugh Sanderson, gamehaxe.com
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
 
import nme.Manager;
import nme.Surface;
import nme.Graphics;
import nme.BitmapData;
import nme.TileRenderer;

typedef IntArray = Array<Int>;
typedef Grid = Array<IntArray>;
typedef Tiles = Array<TileRenderer>;

class Puzzle extends nme.GameBase
{
   static var SEGMENTS = 4;
   // If you think you are really good ...
   //static var SEGMENTS = 8;
   static var SIZE = Std.int(256/SEGMENTS);

   static var wndWidth = 256 + SEGMENTS - 1;
   static var wndHeight = 256 + SEGMENTS - 1;
   static var wndCaption = "Puzzle";
   
   static function main() { new Puzzle(); }

   var mImage:BitmapData;
   var mRand : neko.Random;
   var mGrid : Grid;
   var mTiles : Tiles;
   var mWon : Bool;

   public function new()
   {
      // Try it both ways !
      var opengl = false;

      super( wndWidth, wndHeight, wndCaption, false, "ico.gif", opengl );

      mImage = BitmapData.Load("image.jpg");
      if (mImage==null)
         throw("Could not load image.jpg ?");

      mTiles = new Tiles();
      mGrid = new Grid();
      mRand = new neko.Random();

      for(i in 0...SEGMENTS*SEGMENTS-1)
      {
         var x = i % SEGMENTS;
         var y = Std.int(i/SEGMENTS);
         mTiles.push( new TileRenderer(mImage,Manager.getScreen(),
                            x*SIZE, y*SIZE, SIZE, SIZE )  );
         if (x==0) mGrid.push( new IntArray() );
         mGrid[y].push(i);
      }
      mGrid[SEGMENTS-1].push(-1);

      Shuffle(SEGMENTS-1,SEGMENTS-1);

      mWon = false;

      run();
   }

   function Shuffle(x:Int, y:Int)
   {
      for(pass in 0...1000)
      {
         var tx = x;
         var ty = y;
         switch(mRand.int(4))
         {
            case 0: tx++;
            case 1: tx--;
            case 2: ty++;
            case 3: ty--;
         }
         if (tx>=0 && tx<SEGMENTS && ty>=0 && ty<SEGMENTS)
         {
            mGrid[y][x] = mGrid[ty][tx];
            mGrid[ty][tx] = -1;
            x = tx;
            y = ty;
         }
      }
   }

   public function onRender()
   {
      manager.clear( 0xffffff );

      for(y in 0...SEGMENTS)
         for(x in 0...SEGMENTS)
         {
            var id = mGrid[y][x];
            if (id>=0)
               mTiles[id].Blit(x*(SIZE+1),y*(SIZE+1));
         }

      if (mWon)
      {
         var gfx = Manager.graphics;

         gfx.moveTo(wndWidth/2, wndHeight/2);
         gfx.text("Well Done!",24,"Times",0xffffff,
             Graphics.CENTER,Graphics.CENTER);
      }

   }

   public function onClick(inEvent:MouseEvent)
   {
      var x = Std.int( inEvent.x / (SIZE+1) );
      var y = Std.int( inEvent.y / (SIZE+1) );
      if (x>=0 && y>=0 && x<SEGMENTS && y<SEGMENTS)
      {
         if (x>0 && mGrid[y][x-1]==-1)
         {
             mGrid[y][x-1]=mGrid[y][x];
             mGrid[y][x] = -1;
         }
         else if (y>0 && mGrid[y-1][x]==-1)
         {
             mGrid[y-1][x]=mGrid[y][x];
             mGrid[y][x] = -1;
         }
         else if (x<SEGMENTS-1 && mGrid[y][x+1]==-1)
         {
             mGrid[y][x+1]=mGrid[y][x];
             mGrid[y][x] = -1;
         }
         else if (y<SEGMENTS-1 && mGrid[y+1][x]==-1)
         {
             mGrid[y+1][x]=mGrid[y][x];
             mGrid[y][x] = -1;
         }
      }
   }




   public function onUpdate()
   {
      mWon = false;

      var i = 0;
      for(y in 0...SEGMENTS)
         for(x in 0...SEGMENTS)
         {
            if (mGrid[y][x]!=i)
               return;

            i++;
            if (i==15)
               mWon = true;
         }
   }
}
