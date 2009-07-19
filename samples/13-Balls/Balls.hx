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
 
import nme.Manager;
import nme.Surface;
import nme.geom.Matrix;
import nme.display.Graphics;
import nme.display.BitmapData;
import nme.display.GradientType;
import nme.display.SpreadMethod;
import nme.TileRenderer;

typedef Ball =
{
   var x:Float;
   var y:Float;
   var vx:Float;
   var vy:Float;
};

typedef BallList = Array<Ball>;


class Balls extends nme.GameBase
{
   static var wndWidth = 640;
   static var wndHeight = 480;
   static var wndCaption = "Balls";
   
   static function main() { new Balls(); }

   var mBallTile : TileRenderer;
   var mBalls : BallList;
   var mRand : neko.Random;


   public function new()
   {
      nme.display.Graphics.defaultFontName = "Arial.ttf";

      // Try it both ways !
      var opengl = false;
      var args = nme.Sys.args();
      if (args.length>0 && args[0].substr(0,2)=="-o")
         opengl = true;


      super( wndWidth, wndHeight, wndCaption, false, "ico.gif", opengl );

      var bitmap = new BitmapData(64,64,true,I32.ZERO);
      var gfx = bitmap.graphics;

      var colours = [ 0xffffff, 0xff0000, 0x000000 ];
      var alphas = [ 1.0, 1.0, 1.0 ];
      var ratios = [ 0, 10, 255 ];
      var mtx = new Matrix();

      // Define positive quadrant ...
      mtx.createGradientBox(64,64, 0, 0,0);
      mtx.translate(-32,-32);
      mtx.rotate(0.5);
      mtx.translate(32,32);
      gfx.beginGradientFill(GradientType.RADIAL,
                       colours, alphas, ratios, mtx, SpreadMethod.REPEAT,
                       -0.6 );

      gfx.drawCircle(32,32,30);
      gfx.flush();

      mBallTile = new TileRenderer(bitmap,0,0,64,64,0,0);

      mBalls = new BallList();
      mRand = new neko.Random();

      for(i in 0...1000)
      {
         mBalls.push( {x:Rand()*wndWidth,
                       y:Rand()*wndHeight,
                       vx:Rand()*100 - 50,
                       vy:Rand()*100 - 50} );
      }

      run();
   }

   function Rand() : Float { return mRand.float(); }


   override public function onRender()
   {
      manager.clear( 0xffffff );


      for(b in 1...mBalls.length)
      {
         var ball = mBalls[b];
         mBallTile.Blit(Std.int(ball.x),Std.int(ball.y),0,1);
      }
   }

   override public function onUpdate(inDT:Float)
   {
      var max_w = wndWidth - mBallTile.width;
      var max_h = wndHeight - mBallTile.height;

      var g = -9.8; // pixels per second per second

      for(b in 1...mBalls.length)
      {
         var ball = mBalls[b];
         ball.x += ball.vx * inDT;
         if (ball.x<0)
         {
            ball.vx*=-1;
            ball.x=0;
         }
         if (ball.x>max_w)
         {
            ball.vx*=-1;
            ball.x = max_w;
         }

         ball.vy -= g * inDT;
         ball.y += ball.vy * inDT;
         if (ball.y>max_h)
         {
            ball.y = max_h;
            ball.vy *= -0.99;
         }
     }
   }
}
