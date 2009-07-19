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
import nme.display.Shape;
import nme.FontHandle;

import nme.display.CapsStyle;
import nme.display.GradientType;
import nme.display.JointStyle;
import nme.display.SpreadMethod;

/*
  This example shows how the flash-like stroke api can be used to
   render fonts with outlines, gradients and bounding boxes etc.
*/

class FontTest extends nme.GameBase
{
   static var wndWidth = 640;
   static var wndHeight = 480;
   static var wndCaption = "Font Test";
   
   static function main() { new FontTest(); }

   var mFont:FontHandle;
   var mFM:FontMetrics;
   var mBmp:BitmapData;


   public function new()
   {
      nme.display.Graphics.defaultFontName = "Arial.ttf";

      // Try it both ways !
      var opengl = false;
      var args = nme.Sys.args();
      if (args.length>0 && args[0].substr(0,2)=="-o")
         opengl = true;


      super( wndWidth, wndHeight, wndCaption, false, "ico.gif", opengl );

      mFont = new nme.FontHandle("Arial.ttf",48);
      mFM = mFont.GetFontMetrics();

      mBmp = new BitmapData(32,32,false,I32.make(0xffff,0xffff));
      mBmp.graphics.beginFill(0xff5050);
      mBmp.graphics.drawCircle(6,6,5);
      mBmp.graphics.drawCircle(22,22,5);
      mBmp.graphics.flush();


      run();
   }

   public override function onRender()
   {
      manager.clear( 0x000000 );

      var gfx = Manager.graphics;

      var colours = [ 0xffff00, 0xff00ff ];
      var alphas = [ 1.0, 1.0 ];
      var ratios = [  128, 200 ];
      var mtx = new Matrix();
      mtx.a = 0; mtx.d = 0.0;
      mtx.b = 1.0/mFM.height;


      var c0 = ("a").charCodeAt(0);
      for(y in 0...6)
         for(x in 0...5)
         {
            var c = c0+y*5+x;
            var x0 = x*mFM.max_x_advance;
            var y0 = y*mFM.height+40;

            // Translate gradient to new position...
            mtx.tx = -y0*mtx.b;

            gfx.lineStyle(2,0xff0000);
            gfx.lineGradientStyle(GradientType.LINEAR,
                       colours, alphas, ratios, mtx, SpreadMethod.PAD);


            gfx.beginBitmapFill(mBmp,null,true,true);

            // gfx.text( String.fromCharCode(c), 48, "Times" );
            gfx.RenderGlyph(mFont,c,x0,y0);
            gfx.endFill();

            gfx.lineStyle(1,0x00ff00);
            var mtx = mFont.GetGlyphMetrics(c);
            gfx.drawRect(x0+mtx.min_x,y0,mtx.width,mFM.height);
            gfx.drawRect(x0,y0,mtx.x_advance,mFM.ascent);
         }


      gfx.flush();

   }

   override public function onUpdate(inDT:Float)
   {
      // You can set the matrix to move the display object around.
   }
}
