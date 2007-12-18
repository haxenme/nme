/*
 * Copyright (c) 2007, Lee McColl Sylvester - www.designrealm.co.uk
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
 *  This code test the image and sound formats that are not tested in the
 *   Blox demo.
 *
 *   mp3 music
 *   ogg,aiff,wav sounds
 *   png,jpg images
 *
 */
 
import nme.Manager;
import nme.Surface;

class GraphicsTest
{
   static var wndWidth = 640;
   static var wndHeight = 480;
   static var wndCaption = "Graphics Test";
   
   static function main() { new GraphicsTest(); }

   public function new()
   {
      // Try it both ways !
      var opengl = false;

      var manager  = new Manager( wndWidth, wndHeight, wndCaption, false,
                             "ico.gif", opengl );

      var square = new nme.Shape();
      square.beginFill(0x0000ff);
      square.drawRect(-10,-10,20,20);
      square.matrix.tx = 400;
      square.matrix.ty = 300;


      var running = true;
      var x = 0;
      var rot = 0.0;
      var phase = 0.0;

      while (running)
      {
         var type:nme.EventType;
         do
         {
            type = manager.nextEvent();
            switch type
            {
               case et_quit:
                  running = false;
               case et_keydown:
                  running =  manager.lastKey() != 27;
               default:
            }
         } while(type!=et_noevent && running);

         manager.clear( 0xffffff );

         var gfx = Manager.graphics;

         gfx.beginFill(0xff3030);
         gfx.drawCircle(x,100,60);

         square.matrix.setRotation(rot, Math.abs(Math.sin(phase)*5.0));
         square.draw();

         x = (x+1) % wndWidth;
         rot += 0.01;
         phase += 0.01;

         manager.flip();
      }


      manager.close();
   }
}
