package nme.format.swf;

import nme.format.swf.Shape;
import nme.format.swf.MorphShape;
import nme.format.swf.Sprite;
import nme.format.swf.Bitmap;
import nme.format.swf.Font;
import nme.format.swf.StaticText;
import nme.format.swf.EditText;

enum Character
{
   charShape(inShape:Shape);
   charMorphShape(inMorphShape:MorphShape);
   charSprite(inSprite:Sprite);
   charBitmap(inBitmap:Bitmap);
   charFont(inFont:Font);
   charStaticText(inText:StaticText);
   charEditText(inText:EditText);
}
