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
import nme.Graphics;

class GraphicsTest extends nme.GameBase
{
   static var wndWidth = 640;
   static var wndHeight = 480;
   static var wndCaption = "Graphics Test";
   
   static function main() { new GraphicsTest(); }


   static var x = -40;
   static var rot = 0.0;
   static var phase = 0.0;

   var square : nme.Shape;
   var grad_circle : nme.Shape;
   var lines : nme.Shape;
   var rad_grad : nme.Shape;

   public function new()
   {
      // Try it both ways !
      var opengl = false;
      var args = neko.Sys.args();
      if (args.length>0 && args[0].substr(0,2)=="-o")
         opengl = true;


      super( wndWidth, wndHeight, wndCaption, false, "ico.gif", opengl );

      square = new nme.Shape();
      square.beginFill(0x0000ff);
      square.drawRect(-10,-10,20,20);
      square.moveTo(0,0);
      square.text("Square",12,"Arial",null,Graphics.CENTER,Graphics.CENTER);
      square.matrix.tx = 400;
      square.matrix.ty = 300;

      grad_circle = new nme.Shape();

      var colours = [ 0xff0000, 0x000000 ];
      var alphas = [ 1.0, 1.0 ];
      var ratios = [ 0, 255 ];
      var mtx = new nme.Matrix();
      mtx.createGradientBox(100,100,Math.PI/6,150,100);
      grad_circle.beginGradientFill(nme.GradientType.LINEAR,
                       colours, alphas, ratios, mtx, nme.SpreadMethod.PAD);
      grad_circle.drawCircle(200,150,75);

      lines = new nme.Shape();
      lines.lineStyle(1,0x0000ff);
      lines.moveTo(50,100);
      lines.lineTo(50,400);

      lines.lineStyle(20,0x000000,0.5,false,"normal",
               nme.CapsStyle.ROUND, nme.JointStyle.ROUND );

      lines.moveTo(50,300);
      lines.lineTo(200,300);
      lines.lineTo(250,200);

      lines.lineStyle(20,0x000000,0.5,false,"normal",
               nme.CapsStyle.SQUARE, nme.JointStyle.BEVEL );

      lines.moveTo(50,330);
      lines.lineTo(220,330);
      lines.lineTo(270,230);

      lines.lineStyle(20,0x000000,0.5,false,"normal",
               nme.CapsStyle.NONE, nme.JointStyle.MITER );

      lines.moveTo(50,360);
      lines.lineTo(240,360);
      lines.lineTo(290,260);

      rad_grad = new nme.Shape();
      var mtx = new nme.Matrix();
      // Define positive quadrant ...
      mtx.createGradientBox(50,50, 0, 50,50);
      grad_circle.beginGradientFill(nme.GradientType.RADIAL,
                       colours, alphas, ratios, mtx, nme.SpreadMethod.REPEAT,
                       -0.9 );
      grad_circle.drawRect(0,0,100,100);

      run();
   }

   public function onRender()
   {
      manager.clear( 0xffffff );

      var gfx = Manager.graphics;

      gfx.clear();
      gfx.moveTo(10,10);
      gfx.lineStyle(1,0xff0000);
      gfx.lineTo(100,100);
      gfx.lineStyle(3,0x00ff00);
      gfx.lineTo(200,200);
      gfx.lineStyle(5,0x0000ff);
      gfx.lineTo(300,300);
      // Call flush now to ensure lines drawn before circle etc...
      gfx.flush();

      // This has already been setup.
      grad_circle.draw();
      square.draw();
      lines.draw();
      rad_grad.draw();

      // Drawing to the managers graphics draws immediately.
      // This is not as efficient as building a display object.
      gfx.lineStyle(20,0x007733,1,false,"normal",
               nme.CapsStyle.ROUND, nme.JointStyle.ROUND, 5.0 );
      gfx.moveTo(0,0);
      gfx.curveTo(wndWidth/2,wndHeight,wndWidth,0);
      gfx.flush();

      gfx.lineStyle(3,0x0000ff);
      gfx.beginFill(0xff3030);
      gfx.drawCircle(x,100,60);
      gfx.moveTo(x,100);

      gfx.lineStyle(1,0x00ff80);
      gfx.text("Hello!",24,"Times",0xffffff,Graphics.CENTER,Graphics.CENTER);

      gfx.endFill();
      gfx.moveTo(wndWidth*0.5,wndHeight*0.5);
      gfx.lineTo(x,100);

      gfx.lineStyle(20,0x000000,1,false,"normal",
               nme.CapsStyle.ROUND, nme.JointStyle.MITER, 5.0 );
      gfx.moveTo(wndWidth*0.6,95);
      gfx.lineTo(wndWidth*0.6,100);
      gfx.lineTo(wndWidth*0.6 + 50*Math.cos(phase),
                 100 + 50*Math.sin(phase));

   }

   public function onUpdate()
   {
      // You can set the matrix to move the display object around.
      square.matrix.setRotation(rot, Math.abs(Math.sin(phase)*10.0));

      x = x+1;
      if (x>wndWidth) x = -10;

      rot += 0.01;
      phase += 0.01;
   }
}
