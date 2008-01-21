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

typedef Star =
{
   var x:Float;
   var y:Float;
   var vx:Float;
   var vy:Float;
};

typedef Stars = Array<Star>;

class BitmapTest extends nme.GameBase
{
   static var wndWidth = 640;
   static var wndHeight = 480;
   static var wndCaption = "Bitmap Test";
   
   static function main() { new BitmapTest(); }

   var mBang:BitmapData;
   var mStars : Stars;
   var mRand : neko.Random;

   public function new()
   {
      // Try it both ways !
      var opengl = false;
      var args = neko.Sys.args();
      if (args.length>0 && args[0].substr(0,2)=="-o")
         opengl = true;


      super( wndWidth, wndHeight, wndCaption, false, "ico.gif", opengl );

      mBang = BitmapData.Load("bang.png");
      if (mBang==null)
         neko.Lib.print("Could not load bang.png ?");
      else
         neko.Lib.print("Loaded bang " + mBang.width + "x" + mBang.height + "\n");

      mRand = new neko.Random();
      mStars = new Stars();
      for(i in 0...1000)
      {
         mStars.push( {x:Rand()*wndWidth,
                       y:Rand()*wndHeight,
                       vx:Rand()*100 - 50,
                       vy:Rand()*100 - 50} );
      }

      run();
   }

   function Rand() : Float { return mRand.float(); }

   public function onRender()
   {
      manager.clear( 0xffffff );

      var gfx = Manager.graphics;
      var bang = mBang;

      for(i in 0...mStars.length)
      {
         var star = mStars[i];
         gfx.moveTo(star.x,star.y);
         gfx.blit(bang);
      }
   }

   public function onUpdate(inDT:Float)
   {
      for(i in 0...mStars.length)
      {
         var star = mStars[i];
         star.x+=(star.vx*inDT);
         star.y+=(star.vy*inDT);
         if (star.x<-10) star.x = wndWidth;
         if (star.x>wndWidth) star.x = -9;
         if (star.y<-10) star.y = wndHeight;
         if (star.y>wndHeight) star.y = -9;
      }
   }
}
