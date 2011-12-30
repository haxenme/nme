package nme.format.swf;

import nme.format.swf.SWFStream;
import nme.format.swf.SWF;
import nme.display.Graphics;

import nme.geom.Rectangle;
import nme.geom.Matrix;

typedef TextRecord =
{
   var mSWFFont:Font;

   var mOffsetX:Int;
   var mOffsetY:Int;
   var mHeight:Float;

   var mColour:Int;
   var mAlpha:Float;

   var mGlyphs:Array<Int>;
   var mAdvances:Array<Int>;
}

typedef TextRecords = Array<TextRecord>;

class StaticText
{
   var mBounds:Rectangle;
   var mTextMatrix:Matrix;
   var mRecords:TextRecords;


   public function new(inSWF:SWF, inStream:SWFStream, inVersion:Int)
   {
      inStream.AlignBits();

      mRecords = new TextRecords();
      mBounds = inStream.ReadRect();
      //trace("StaticText " + mBounds);

      mTextMatrix = inStream.ReadMatrix();

      var glyph_bits = inStream.ReadByte();
      var advance_bits = inStream.ReadByte();
      var font:Font = null;
      var height = 32.0;
      var colour = 0;
      var alpha = 1.0;

      inStream.AlignBits();
      while(inStream.ReadBool())
      {
         inStream.Bits(3);
         var has_font = inStream.ReadBool();
         var has_colour = inStream.ReadBool();
         var has_y = inStream.ReadBool();
         var has_x = inStream.ReadBool();
         if (has_font)
         {
            var font_id = inStream.ReadID();
            var ch = inSWF.GetCharacter(font_id);
            switch(ch)
            {
               case charFont(f):
                  font = f;
               default:
                  throw "Not font character";
            }
         }
         else if (font==null)
            throw "No font - not implemented";

         if (has_colour)
         {
            colour = inStream.ReadRGB();
            if (inVersion>=2)
               alpha = inStream.ReadByte()/255.0;
         }

         var x_off = has_x ? inStream.ReadSI16() : 0;
         var y_off = has_y ? inStream.ReadSI16() : 0;
         if (has_font)
            height = inStream.ReadUI16() * 0.05;
         var count = inStream.ReadByte();

         //trace("Glyphs : " + count);

         var glyphs = new Array<Int>();
         var advances = new Array<Int>();

         for(i in 0...count)
         {
            glyphs.push( inStream.Bits(glyph_bits) );
            advances.push( inStream.Bits(advance_bits,true) );
         }

         mRecords.push( {  mSWFFont:font,
                           mOffsetX : x_off,
                           mOffsetY : y_off,
                           mGlyphs : glyphs,
                           mColour : colour,
                           mAlpha : alpha,
                           mHeight : height,
                           mAdvances : advances } );


         inStream.AlignBits();
      }
   }

   public function Render(inGfx:Graphics)
   {
      for(rec in mRecords)
      {
         var scale = rec.mHeight/1024;
         var m = mTextMatrix.clone();
         m.scale(scale,scale);
         m.tx += rec.mOffsetX * 0.05;
         m.ty +=  rec.mOffsetY * 0.05;
         inGfx.lineStyle();
         for(i in 0...rec.mGlyphs.length)
         {
            var tx = m.tx;
            inGfx.beginFill(rec.mColour,rec.mAlpha);
            rec.mSWFFont.RenderGlyph(inGfx,rec.mGlyphs[i], m );
            inGfx.endFill();
            m.tx += rec.mAdvances[i] * 0.05;
         }
      }
   }

}
