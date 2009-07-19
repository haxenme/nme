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
import nme.geom.Matrix;
import nme.display.Graphics;
import nme.display.Shape;
import nme.KeyCode;




class Display extends nme.GameBase
{
   static var wndWidth = 800;
   static var wndHeight = 600;
   static var wndCaption = "SVG Display";
   
   static function main() { new Display(); }

   var mShape: Shape;
   var mSVG : SVG2Gfx;
   var mOX:Float;
   var mOY:Float;
   var mZoom:Float;
   var mMiddleDrag:Bool;
   var mDownX:Int;
   var mDownY:Int;

   public function new()
   {
      nme.display.Graphics.defaultFontName = "Arial.ttf";

      // Try it both ways !
      var opengl = false;
      var args = nme.Sys.args();
      if (args.length>0 && args[0].substr(0,2)=="-o")
      {
         args.shift();
         opengl = true;
      }

      super( wndWidth, wndHeight, wndCaption, false, "ico.gif", opengl );

      if (args.length!=1)
      {
         neko.Lib.println("Usage : Display file.svg");
         return;
      }

      var xml_data = neko.io.File.getContent(args[0]);
      if (xml_data.length < 1)
      {
         neko.Lib.println("Display, bad file:" + args[0]);
         return;
      }

      var xml = Xml.parse(xml_data);

      mSVG = new SVG2Gfx(xml);

      mShape = new Shape();

      ResetZoom();

      run();
   }

   function ResetZoom()
   {
      var w_scale = wndWidth/mSVG.width * 0.9;
      var h_scale = wndHeight/mSVG.height * 0.9;
      if (w_scale < h_scale)
         mZoom = w_scale;
      else
         mZoom = h_scale;

      mOY = (wndHeight - mSVG.height*mZoom) * 0.5;
      mOX = (wndWidth - mSVG.width*mZoom) * 0.5;

      UpdateGfx();
   }

   function ZoomAbout(inX:Int, inY:Int, inZoom:Float)
   {
      var under_mouse_x = (inX-mOX)/mZoom;
      var under_mouse_y = (inY-mOY)/mZoom;
      mZoom = inZoom;
      mOX = inX - under_mouse_x*mZoom;
      mOY = inY - under_mouse_y*mZoom;
      UpdateGfx();
   }

   override public function onMouse(inEvent:MouseEvent) : Void
   {
      if (inEvent.type == met_MouseWheelUp)
         ZoomAbout(inEvent.x,inEvent.y,mZoom*1.2);
      else if (inEvent.type == met_MouseWheelDown)
         ZoomAbout(inEvent.x,inEvent.y,mZoom/1.2);
      else if (inEvent.type == met_MiddleDown)
      {
         mDownX = inEvent.x;
         mDownY = inEvent.y;
         mMiddleDrag = true;
      }
      else if (inEvent.type == met_MiddleUp)
      {
         mMiddleDrag = false;
      }

      if (mMiddleDrag)
      {
         var dx = (inEvent.x-mDownX);
         var dy = (inEvent.y-mDownY);
         if (dx!=0 || dy!=0)
         {
            mOX += dx;
            mOY += dy;
            UpdateGfx();
         }
         mDownX = inEvent.x;
         mDownY = inEvent.y;
      }
   }

   override public function onKey(inEvent:KeyEvent)
   {
      if (inEvent.code==KeyCode.HOME)
         ResetZoom();
   }


   function UpdateGfx()
   {
      var m = new Matrix(mZoom, 0, 0, mZoom, mOX, mOY);
      mShape.clear();
      mSVG.Render(mShape,m);
   }


   override public function onRender()
   {
      manager.clear( 0x000033 );
      Manager.graphics.beginFill(0xffffff);
      Manager.graphics.drawRect( mOX,mOY, mSVG.width*mZoom, mSVG.height*mZoom );

      mShape.draw();
   }
}
