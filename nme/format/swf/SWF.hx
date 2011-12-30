package nme.format.swf;

import nme.format.swf.SWFStream;
import nme.format.swf.Tags;
import nme.format.swf.Character;
import nme.format.swf.Shape;
import nme.format.swf.MorphShape;
import nme.format.swf.Frame;
import nme.format.swf.StaticText;
import nme.format.swf.Font;

import nme.display.BitmapData;
import nme.utils.ByteArray;

import nme.geom.Rectangle;



class SWF
{
   var mStream:SWFStream;
   var mRect : Rectangle;
   var mFrameRate : Float;
   var mBackground : Int;
   var mDictionary:Array<Character>;
   var mSymbols:Hash<Int>;
   var mMain:Sprite;
   var mVersion:Int;


   public function new(inStream:ByteArray)
   {
      mStream = new SWFStream(inStream);

      mRect= mStream.ReadRect();
      mFrameRate = mStream.FrameRate();
      var count = mStream.Frames();
      mDictionary = [];
      mSymbols = new Hash<Int>();

      mMain = new Sprite(this,0,count);


      var count:Array<Int> = [];
      for(i in 0...Tags.LAST)
        count.push(0);

 

      var tag = 0;
      while( (tag=mStream.BeginTag())!=0 )
      {
         //trace( Tags.string(tag) + "  x  " + mStream.mTagSize );
         count[tag]++;
         switch(tag)
         {
            case Tags.SetBackgroundColor:
               mBackground = mStream.ReadRGB();

            case Tags.DefineShape:
               DefineShape(1);
            case Tags.DefineShape2:
               DefineShape(2);
            case Tags.DefineShape3:
               DefineShape(3);
            case Tags.DefineShape4:
               DefineShape(4);

            case Tags.DefineMorphShape:
               DefineMorphShape(1);
            case Tags.DefineMorphShape2:
               DefineMorphShape(2);

            case Tags.DefineSprite:
               DefineSprite();

            case Tags.PlaceObject:
               mMain.PlaceObject(mStream,1);
            case Tags.PlaceObject2:
               mMain.PlaceObject(mStream,2);
            case Tags.PlaceObject3:
               mMain.PlaceObject(mStream,3);

            case Tags.RemoveObject:
               mMain.RemoveObject(mStream,1);
            case Tags.RemoveObject2:
               mMain.RemoveObject(mStream,2);

            case Tags.DefineBits:
               throw("DefineBits not implemented");
            case Tags.JPEGTables:
               throw("JPEGTables not implemented");

            case Tags.DefineBitsJPEG2:
               DefineBitmap(false,2);
            case Tags.DefineBitsJPEG3:
               DefineBitmap(false,3);

            case Tags.DefineBitsLossless:
               DefineBitmap(true,1);
            case Tags.DefineBitsLossless2:
               DefineBitmap(true,2);


            case Tags.DefineFont:
               DefineFont(1);
            case Tags.DefineFont2:
               DefineFont(2);
            case Tags.DefineFont3:
               DefineFont(3);

            case Tags.DefineText:
               DefineText(1);

            case Tags.ShowFrame:
               mMain.ShowFrame();

            case Tags.DefineFontName:
               // safely ignore

            case Tags.DefineFontAlignZones:
               // todo:

            case Tags.CSMTextSettings:
               // todo:

            case Tags.DoAction:
               // todo:

            case Tags.DoABC2:
               // todo:


            case Tags.FileAttributes:
               ReadFileAttributes();
               // Do nothing

            case Tags.DefineEditText:
               DefineEditText(1);

            case Tags.SymbolClass:
               SymbolClass();
			
			case Tags.DefineSceneAndFrameLabelData:
				//ignored
			
			case Tags.MetaData:
				//ignored

            default:
               trace("Unknown tag:" + Tags.string(tag));
         }
         mStream.EndTag();
      }

       //This is quite good for debug
       /*
       for(i in 0...Tags.LAST)
         if (count[i]!=0)
            trace( Tags.string(i) + " = " + count[i] );
       */

      mStream.close();
      mStream = null;
      //trace(this);
   }

   public function createInstance() : nme.format.swf.MovieClip
   {
      var result = new nme.format.swf.MovieClip();
      result.CreateFromSWF(mMain);
      return result;
   }

   public function createSymbolInstance(inName:String) : Dynamic
   {
      if (!mSymbols.exists(inName))
         return null;
      switch( GetCharacter(mSymbols.get(inName)) )
      {
         case charSprite(sprite) :
            var result = new nme.format.swf.MovieClip();
            result.CreateFromSWF(sprite);
            return result;

         case charBitmap(bits) :
            return bits.GetBitmap();

         default:
            return null;
      }

      return null;
   }


   public function GetBackground() { return mBackground; }
   public function GetFrameRate() { return mFrameRate; }
   public function Width() { return Std.int(mRect.width); }
   public function Height() { return Std.int(mRect.height); }

   public function GetCharacter(inID:Int)
   {
      var result = mDictionary[inID];
      if (result==null)
         throw "Invalid character ID (" + inID + ")";
      return result;
   }

   function ReadFileAttributes()
   {
      var flags = mStream.ReadByte();
      var zero = mStream.ReadByte();
      zero = mStream.ReadByte();
      zero = mStream.ReadByte();
   }

   function SymbolClass()
   {
      var n = mStream.ReadUI16();
      for(i in 0...n)
      {
         var id = mStream.ReadUI16();
         var str = mStream.ReadString();
         mSymbols.set(str,id);
      }
   }


   function CreatePlaceholderBitmap(inID:Int)
   {
      var bmp = new nme.display.BitmapData(32,32);
      var render = new nme.display.Shape();
      var gfx = render.graphics;
      gfx.lineStyle(1,0xff0000);
      gfx.moveTo(0,0);
      gfx.lineTo(32,32);
      gfx.moveTo(32,0);
      gfx.lineTo(0,32);
      bmp.draw(render);
      return bmp;
   }

   public function GetBitmap(inID:Int) : nme.display.BitmapData
   {
      if (inID==0xffff)
         return null;

      if (mDictionary[inID]==null)
         throw("Bitmap not defined: " + inID);

      //if (mDictionary[inID]==null)
         //return CreatePlaceholderBitmap(inID);

      switch( GetCharacter(inID) )
      {
         case charBitmap(bits) : return bits.GetBitmap();
         default: throw "Non-bitmap character";
      }
      return null;
   }

   function DefineShape(inVersion:Int)
   {
      var shape_id = mStream.ReadID();
      //trace("Define shape " + shape_id);
      mDictionary[shape_id] = charShape(
          new Shape(this,mStream,inVersion) );
   }

   function DefineText(inVersion:Int)
   {
      var text_id = mStream.ReadID();
      mDictionary[text_id] = charStaticText(
          new StaticText(this,mStream,inVersion) );
   }
   
   function DefineEditText(inVersion:Int)
   {
      var text_id = mStream.ReadID();
      mDictionary[text_id] = charEditText(
          new EditText(this,mStream,inVersion) );
   }



   function DefineMorphShape(inVersion:Int)
   {
      var shape_id = mStream.ReadID();
      mDictionary[shape_id] = charMorphShape(
          new MorphShape(this,mStream,inVersion) );
   }


   function DefineBitmap(inLossless:Bool,inVersion:Int)
   {
      var shape_id = mStream.ReadID();
      //trace("Define bitmap : " + shape_id);
      mDictionary[shape_id] = charBitmap(
         new Bitmap(mStream,inLossless,inVersion) );
   }

   function DefineFont(inVersion:Int)
   {
      var shape_id = mStream.ReadID();
      mDictionary[shape_id] = charFont( new Font(mStream,inVersion) );
   }



   public function DefineSprite()
   {
      var id = mStream.ReadID();
      //trace("Define sprite " + id);
      var frames = mStream.Frames();
      mStream.PushTag();

      var sprite = new Sprite(this,id,frames);

      var tag=0;
      var fid = 1;
      while( (tag=mStream.BeginTag())!=0 )
      {
         //trace("sub tag:" + Tags.string(tag) );
         switch(tag)
         {
            case Tags.FrameLabel:
               sprite.LabelFrame(mStream.ReadString());
            case Tags.ShowFrame:
               //trace(" frame:" + (fid++));
               sprite.ShowFrame();

            case Tags.PlaceObject:
               sprite.PlaceObject(mStream,1);
            case Tags.PlaceObject2:
               sprite.PlaceObject(mStream,2);
            case Tags.PlaceObject3:
               sprite.PlaceObject(mStream,3);

            case Tags.RemoveObject:
               sprite.RemoveObject(mStream,1);
            case Tags.RemoveObject2:
               sprite.RemoveObject(mStream,2);
            case Tags.DoAction:
               // not implemented
            default:
               trace("Unknown sub tag: " +  Tags.string(tag) );
         }
         mStream.EndTag();
      }

      mDictionary[id] = charSprite(sprite);


      mStream.PopTag();
   }


}

