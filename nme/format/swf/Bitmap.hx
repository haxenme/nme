package nme.format.swf;

import nme.display.BitmapData;
import nme.geom.Rectangle;
import nme.utils.ByteArray;


class Bitmap
{
#if flash
   var mLoader:flash.display.Loader;
   var mAlpha:ByteArray;
#end

   var mBitmap:BitmapData;

   /*
             1 = RGBA index
             2 = 32-bit RGB
      fmt :  3 = RGB index
             4 = 15-bit RGB
             5 = 24-bit RGB
   */


   public function new(inStream:SWFStream,inLossless:Bool,inVersion:Int)
   {
      mBitmap = null;

      #if flash9
      mLoader = null;
      #end

      if (inLossless)
      {
         var fmt = inStream.ReadByte();
         var w = inStream.ReadUI16();
         var h = inStream.ReadUI16();
         var table_size = fmt==3 ? (inStream.ReadByte()+1) : 0;
         
         var buffer:flash.utils.ByteArray = inStream.readFlashBytes(inStream.BytesLeft());
         buffer.uncompress();

         if (inVersion==2)
         {
            if (fmt==4)
               throw("No 15-bit format in DefineBitsLossless2");
            else
               fmt = fmt==3 ? 1 : 2;
         }

         mBitmap = new BitmapData(w,h,fmt<3);

         mBitmap.setPixels(new Rectangle(0,0,w,h), buffer );

         //SetPixelData(buffer.getData(),fmt,table_size);
      }
      else
      {
         var buffer:ByteArray = null;
         var alpha:ByteArray = null;
   
         if (inVersion==2)
         {
            var size = inStream.BytesLeft();
            buffer = inStream.ReadBytes(size);
         }
         else if (inVersion==3)
         {
            var size = inStream.ReadInt();
            buffer = inStream.ReadBytes(size);

            alpha = inStream.readFlashBytes(inStream.BytesLeft());
            alpha.uncompress();
         }
   
   
         #if flash
            mLoader = new flash.display.Loader();
            mAlpha = alpha;
            if (mAlpha!=null)
               mLoader.addEventListener(flash.events.Event.COMPLETE, AddAlpha );
            mLoader.loadBytes(buffer);
         #else
            mBitmap = BitmapData.loadFromHaxeBytes(buffer,alpha);
         #end
      }

   }

   public function GetBitmap()
   {
      #if flash
         if (mBitmap==null && mLoader!=null)
         {
            if (mLoader.content==null)
               return null;
            //trace(mLoader.content);
            var bitmap:flash.display.Bitmap = untyped mLoader.content;
            mBitmap = bitmap.bitmapData;
         }
      #end

      return mBitmap;
   }

   function AddAlpha(inEvt:flash.events.Event)
   {
#if flash
      var bitmap = GetBitmap();
      var w = bitmap.width;
      var h = bitmap.height;
      if (Std.int(mAlpha.length) != Std.int(w*h))
          throw("Alpha size mismatch");
      var idx = 0;
      var a = mAlpha;
      for(y in 0...h)
         for(x in 0...w)
            bitmap.setPixel32(x,y, bitmap.getPixel(x,y) | (a[idx++]<<24) );
#end
   }


#if flash

   function SetPixelData(inData:ByteArray, inFormat:Int, inTableSize:Int )
   {
      mBitmap.lock();
      var w = mBitmap.width;
      var h = mBitmap.height;

      if (inFormat==2)
      {
         for(y in 0...h)
            for(x in 0...w)
            {
                mBitmap.setPixel32(x,y, inData.readUnsignedInt() );
            }
      }
      mBitmap.lock();
   }

#end


}

