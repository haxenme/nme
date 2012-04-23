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

package jeash.events;

class KeyboardEvent extends Event
{
   public var keyCode : Int;
   public var charCode : Int;
   public var keyLocation : Int;

   public var ctrlKey : Bool;
   public var altKey : Bool;
   public var shiftKey : Bool;


   public function new(type : String, ?bubbles : Bool, ?cancelable : Bool,
         ?inCharCode : Int, ?inKeyCode : Int, ?inKeyLocation : Int,
         ?inCtrlKey : Bool, ?inAltKey : Bool, ?inShiftKey : Bool)
   {
      super(type,bubbles,cancelable);

      keyCode = inKeyCode;
      keyLocation = inKeyLocation==null ? 0 : inKeyLocation;
      charCode = inCharCode==null ? 0 : inCharCode;

      shiftKey = inShiftKey==null ? false : inShiftKey;
      altKey = inAltKey==null ? false : inAltKey;
      ctrlKey = inCtrlKey==null ? false : inCtrlKey;
   }


   public static var KEY_DOWN = "KEY_DOWN";
   public static var KEY_UP = "KEY_UP";

}

