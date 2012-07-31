/**
 * Copyright (c) 2010, Jeash contributors.
 * 
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
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

package jeash.display;


class MovieClip extends Sprite, implements Dynamic<Dynamic>
{
   public var enabled:Bool;
   public var currentFrame(GetCurrentFrame,null):Int;
   public var framesLoaded(GetTotalFrames,null):Int;
   public var totalFrames(GetTotalFrames,null):Int;

   var mCurrentFrame:Int;
   var mTotalFrames:Int;

   function GetTotalFrames() { return mTotalFrames; }
   function GetCurrentFrame() { return mCurrentFrame; }

   public function new() {
      super();
      enabled = true;
      mCurrentFrame = 0;
      mTotalFrames = 0;
      this.loaderInfo = LoaderInfo.create(null);
      name = "MovieClip " + jeash.display.DisplayObject.mNameID++;
   }

   public function gotoAndPlay(frame:Dynamic, ?scene:String):Void { }
   public function gotoAndStop(frame:Dynamic, ?scene:String):Void { }
   public function play():Void { }
   public function stop():Void { }
}