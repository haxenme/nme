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
import nme.Sprite;
import nme.Sound;
import nme.Music;
import nme.Rect;
import nme.Point;
import nme.Timer;



class Bang
{
   static var mImage : Surface = null;
   static var mSound1 : Sound = null;
   static var mSound2 : Sound = null;
   static var mSound3 : Sound = null;

   static var mOffX = 0;
   static var mOffY = 0;
   var mPos : Point;
   var mTimeStart : Float;

   public function new(manager:Manager)
   {
      if (mImage==null)
      {
         mImage = new Surface("Data/bang.png");
         mOffX = -Math.round(mImage.width/2);
         mOffY = -Math.round(mImage.height/2);

         // Can't use mp3 as "sound", only "music"
         mSound1 = new Sound("Data/drum.ogg");
         mSound2 = new Sound("Data/drums.aiff");
         mSound3 = new Sound("Data/bass.wav");
      }

      mPos = new Point( manager.mouseX()+mOffX, manager.mouseY()+mOffY );
      mTimeStart = haxe.Timer.stamp();
      if (manager.mouseY()<100)
         mSound2.playChannel(-1,0);
      else if (manager.mouseY()>200)
         mSound3.playChannel(-1,0);
      else
         mSound1.playChannel(-1,0);
   }

   public function alive()
   {
      return (haxe.Timer.stamp()-mTimeStart) < 0.2;
   }

   public function draw()
   {
       mImage.draw(Manager.getScreen(),null,mPos);
   }

}

typedef BangList = Array<Bang>;

class Drums extends nme.GameBase
{
   var mRunning : Bool;
   var mDrumPicture : Surface;
   var mBangs : BangList;
   var mScreen : Void;
   static var wndWidth = 375;
   static var wndHeight = 322;
   static var wndCaption = "Drum test";
   
   static function main() { new Drums(); }

   public function new()
   {
      super( wndWidth, wndHeight, wndCaption, false, "Data/ico.gif" );

      Sound.setChannels( 8 );
      Music.init( "Data/Party_Gu-Jeremy_S-8250_hifi.mp3" );
      // -1 = loop
      Music.play( -1 );

      mBangs = new BangList();
      
      mDrumPicture = new Surface( "Data/drum_kit.jpg" );

      run();
   }

   public function onUpdate(inDT:Float)
   {
      // Remove old graphics ...
      var remove = -1;
      for(i in 0...mBangs.length)
      {
         if (mBangs[i].alive())
            break;
         remove = i;
      }
      if (remove>=0)
         mBangs.splice(0,remove+1);
   }

   public function onClick(inEvent:MouseEvent)
   {
      mBangs.push( new Bang(manager) );
   }

   public function onRender()
   {
      manager.clear( 0xFFFFFF );

      mDrumPicture.draw( Manager.getScreen() );

      // Remove old graphics ...
      var remove = -1;
      for(i in 0...mBangs.length)
      {
         if (mBangs[i].alive())
            break;
         remove = i;
      }
      if (remove>=0)
         mBangs.splice(0,remove+1);

      // Draw them ..
      for(b in mBangs)
         b.draw();
   }

   public function onKey(inEvent:KeyEvent)
   {
      // test/debug
      neko.Lib.print(inEvent);
      neko.Lib.print("\n");
   }

}

