package nme.format.swf;

import nme.geom.Rectangle;
import nme.text.TextField;
import nme.text.TextFieldType;
import nme.text.TextFormat;
import nme.text.TextFieldAutoSize;

import nme.format.SWF;
import nme.format.swf.SWFStream;

class EditText
{
   var mRect:Rectangle;
   var mWordWrap:Bool;
   var mMultiLine:Bool;
   var mPassword:Bool;
   var mReadOnly:Bool;
   var mAutoSize:Bool;
   var mNoSelect:Bool;
   var mBorder:Bool;
   var mWasStatic:Bool;
   var mHTML:Bool;
   var mUseOutlines:Bool;
   var mAlpha:Float;
   var mMaxLen:Int;
   var mInitialText:String;
   var mTextFormat:TextFormat;

   public function new(inSWF:SWF,inStream:SWFStream, inVersion:Int)
   {
      mRect = inStream.ReadRect();
      mTextFormat = new TextFormat();
      inStream.AlignBits();
      //trace(mRect);
      var has_text = inStream.ReadBool();
      mWordWrap = inStream.ReadBool();
      mMultiLine = inStream.ReadBool();
      //trace(mMultiLine);
      mPassword = inStream.ReadBool();
      mReadOnly = inStream.ReadBool();
      var has_colour = inStream.ReadBool();
      //trace(has_colour);
      var has_max_len = inStream.ReadBool();
      //trace(has_max_len);
      var has_font = inStream.ReadBool();
      //trace("has font:" + has_font);
      var has_font_class = inStream.ReadBool();
      //trace("has font class:" + has_font_class);
      mAutoSize = inStream.ReadBool();
      var has_layout = inStream.ReadBool();
      mNoSelect = inStream.ReadBool();
      mBorder = inStream.ReadBool();
      mWasStatic = inStream.ReadBool();
      mHTML = inStream.ReadBool();
      mUseOutlines = inStream.ReadBool();
      //trace("Use outlines:" + mUseOutlines);

      if (has_font)
      {
         var font_id = inStream.ReadID();
         switch(inSWF.getCharacter(font_id))
         {
            case charFont(font):
               mTextFormat.font = font.GetName();

               //trace("Font :" + mFont.GetName());
            default:
               throw("Specified font is incorrect type");
         }
         mTextFormat.size = inStream.ReadUTwips();
      }
      else if (has_font_class)
      {
         var font_name = inStream.ReadString();
         throw("Can't reference external font :" + font_name);
      }
      
      if (has_colour)
      {
         mTextFormat.color = inStream.ReadRGB();
         mAlpha = inStream.ReadByte() / 255.0;
      }

      mMaxLen = has_max_len ? inStream.ReadUI16() : 0;
      //trace("MaxLen : " + mMaxLen );
      if (has_layout)
      {
         mTextFormat.align = inStream.ReadAlign();
         mTextFormat.leftMargin = inStream.ReadUTwips();
         mTextFormat.rightMargin = inStream.ReadUTwips();
         mTextFormat.indent = inStream.ReadUTwips();
         mTextFormat.leading = inStream.ReadSTwips();
      }

      var var_name = inStream.ReadString();
      mInitialText = has_text ? inStream.ReadString() : "";
      //trace(mInitialText);
      
   }
   
   public function Apply(inText:TextField)
   {
      inText.wordWrap = mWordWrap;
      inText.multiline = mMultiLine;
      inText.width = mRect.width;
      inText.height = mRect.height;
      inText.displayAsPassword = mPassword;
      if (mMaxLen > 0)
         inText.maxChars = mMaxLen;
      inText.border = mBorder;
      inText.borderColor = 0x000000;
      inText.type = mReadOnly ? TextFieldType.DYNAMIC : TextFieldType.INPUT;
      inText.autoSize = mAutoSize ? TextFieldAutoSize.CENTER : TextFieldAutoSize.NONE;
      inText.setTextFormat(mTextFormat);

      
      //inText.embedFonts = mUseOutlines;

      
      if (mHTML)
         inText.htmlText = mInitialText;
      else
         inText.text = mInitialText;

      // if (!mReadOnly) inText.stage.focus = inText;
   }
   
   

}
