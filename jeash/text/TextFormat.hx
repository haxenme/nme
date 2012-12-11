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

package jeash.text;
import jeash.Html5Dom;

class TextFormat
{
   public var font : String;
   public var size : Float;
   public var color : UInt;
   public var bold : Bool;
   public var italic : Bool;
   public var underline : Bool;
   public var url : String;
   public var target : String;
   public var align : TextFormatAlign;
   public var leftMargin : Float;
   public var rightMargin : Float;
   public var indent : Float;
   public var leading : Float;

   public var blockIndent : Float;
   public var bullet : Bool;
   public var display : String;
   public var kerning : Bool;
   public var letterSpacing : Float;
   public var tabStops : UInt;

  public function new(?in_font : String,
                      ?in_size : Float,
                      ?in_color : UInt,
                      ?in_bold : Bool,
                      ?in_italic : Bool,
                      ?in_underline : Bool,
                      ?in_url : String,
                      ?in_target : String,
                      ?in_align : TextFormatAlign,
                      ?in_leftMargin : Int,
                      ?in_rightMargin : Int,
                      ?in_indent : Int,
                      ?in_leading : Int)
   {
      font = in_font;
      size = in_size;
      color = in_color;
      bold = in_bold;
      italic = in_italic;
      underline = in_underline;
      url = in_url;
      target = in_target;
      align = in_align;
      leftMargin = in_leftMargin;
      rightMargin = in_rightMargin;
      indent = in_indent;
      leading = in_leading;
   }

   public function clone():TextFormat {
      var newFormat = new TextFormat(font, size, color, bold, italic, underline, url, target);
      newFormat.align = align;
      newFormat.leftMargin = leftMargin;
      newFormat.rightMargin = rightMargin;
      newFormat.indent = indent;
      newFormat.leading = leading;

      newFormat.blockIndent = blockIndent;
      newFormat.bullet = bullet;
      newFormat.display = display;
      newFormat.kerning = kerning;
      newFormat.letterSpacing = letterSpacing;
      newFormat.tabStops = tabStops;
      return newFormat;
   }
}


