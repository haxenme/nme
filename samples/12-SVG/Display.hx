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
import nme.Graphics;



class Display extends nme.GameBase
{
   static var wndWidth = 800;
   static var wndHeight = 600;
   static var wndCaption = "SVG Display";
   
   static function main() { new Display(); }

   var mShape:nme.Shape;

   public function new()
   {
      // Try it both ways !
      var opengl = false;

      super( wndWidth, wndHeight, wndCaption, false, "ico.gif", opengl );

      var args = neko.Sys.args();
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

      var svg2gfx = new SVG2Gfx(xml);

      mShape = new nme.Shape();

      svg2gfx.Render(mShape,new nme.Matrix(),1.0,1.0);

      run();
   }


   public function onRender()
   {
      manager.clear( 0xffffff );

      mShape.draw();
   }
}
