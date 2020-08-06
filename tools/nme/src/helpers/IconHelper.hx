package;

import gm2d.svg.Svg;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.Path;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.Shape;
import nme.geom.Rectangle;
import nme.utils.ByteArray;
import sys.io.File;
import sys.FileSystem;

import haxe.ds.IntMap;

class IconHelper 
{
   public static function createIcon(icons:Array<Icon>, width:Int, height:Int, targetPath:String, ?onFile:String->Void):Bool 
   {
      var dir = Path.directory(targetPath);
      PathHelper.mkdir(Path.directory(targetPath));
      var icon = findMatch(icons, width, height);

      try
      {
         if (icon!=null && Path.extension(icon.path) == "png")
         {
            var bitmapData = BitmapData.load(icon.path);
            if (bitmapData==null)
               throw "Could not find " + icon.path;
            if (bitmapData.width==width && bitmapData.height==height)
            {
               FileHelper.copyFile(icon.path, targetPath, onFile);
               return true;
            }
         }

         var bitmapData = getIconBitmap(icons, width, height);
         if (bitmapData != null) 
         {
            File.saveBytes(targetPath, bitmapData.encode("png"));
            if (onFile!=null)
               onFile(targetPath);
            return true;
         }
      }
      catch(e:Dynamic)
      {
         Log.error("Could not save icon " + targetPath + " : " + e);
      }

      return false;
   }

   public static function getSvgIcon(icons:Array<Icon>) : String
   {
      // Last in, best dressed
      var result:String = null;
      for(icon in icons)
         if (Path.extension(icon.path)=="svg")
            result = icon.path;
      return result;
   }

   public static function createMacIcon(icons:Array<Icon>, targetPath:String):Bool 
   {
      var out = new BytesOutput();
      out.bigEndian = true;

      // Not sure why the 128x128 icon is not saving properly. Disabling for now
      for(i in 0...3) 
      {
         var s =  ([ 16, 32, 48, 128 ])[i];
         var code =  ([ "is32", "il32", "ih32", "it32" ])[i];
         var bmp = getIconBitmap(icons, s, s);

         if (bmp != null) 
         {
            for(c in 0...4) out.writeByte(code.charCodeAt(c));

            var n = s * s;
            var pixels = bmp.getPixels(new Rectangle(0, 0, s, s));

            var bytes_r = packBits(pixels, 1, s * s);
            var bytes_g = packBits(pixels, 2, s * s);
            var bytes_b = packBits(pixels, 3, s * s);

            out.writeInt32 (bytes_r.length + bytes_g.length + bytes_b.length + 8);
            out.writeBytes(bytes_r, 0, bytes_r.length);
            out.writeBytes(bytes_g, 0, bytes_g.length);
            out.writeBytes(bytes_b, 0, bytes_b.length);

            var code =  ([ "s8mk", "l8mk", "h8mk", "t8mk" ])[i];

            for(c in 0...4) out.writeByte(code.charCodeAt(c));

            var bytes_a = extractBits(pixels, 0, s * s);
            out.writeInt32 (bytes_a.length + 8);
            out.writeBytes(bytes_a, 0, bytes_a.length);
         }
      }

      for(i in 0...5) 
      {
         var s =  ([ 32, 64, 256, 512, 1024 ])[i];
         var code =  ([ "ic11", "ic12", "ic08", "ic09", "ic10" ])[i];
         var bmp = getIconBitmap(icons, s, s);

         if (bmp != null) 
         {
            for(c in 0...4) out.writeByte(code.charCodeAt(c));

            var bytes = bmp.encode("png");

            out.writeInt32 (bytes.length + 8);
            out.writeBytes(bytes, 0, bytes.length);
         }
      }

      var bytes = out.getBytes();

      if (bytes.length > 0) 
      {
         PathHelper.mkdir(Path.directory(targetPath));
         var file = File.write(targetPath, true);
         file.bigEndian = true;

         for(c in 0...4) file.writeByte("icns".charCodeAt(c));

         file.writeInt32 (bytes.length + 8);
         file.writeBytes(bytes, 0, bytes.length);
         file.close();

         return true;
      }

      return false;
   }
   
   private static inline function alignTo(val:Int, align:Int):Int
   {
        return ((val + align - 1) & ~(align - 1));
   }

   public static function createWindowsIcon(icons:Array<Icon>, targetPath:String, favicon = false):Bool 
   {
      var sizes = [ 256, 128, 64, 48, 40, 32, 24, 16 ];
      var sizes_8bit = [ 48, 32, 16 ];
      var bmps = new Array<BitmapData>();
      var bmps_8bit = new Array<BitmapData>();

      var data_pos = 6;

      if (favicon)
      {
         for(size in sizes_8bit) 
         {
            var bmp = getIconBitmap(icons, size, size);
            if (bmp != null) 
            {
               bmps_8bit.push(bmp);
               data_pos += 16;
            }
         }
      }
      else
      {
         for(size in sizes) 
         {
            var bmp = getIconBitmap(icons, size, size);
            if (bmp != null) 
            {
               bmps.push(bmp);
               data_pos += 16;
            }
         }
      }

      var ico = new ByteArray();
      var bmpsLength = bmps.length+bmps_8bit.length;
      ico.bigEndian = false;
      ico.writeShort(0);
      ico.writeShort(1);
      ico.writeShort(bmpsLength);

      for(bmp in bmps_8bit) 
      {
         var size = bmp.width;
         var xor_size = size * size;
         var and_size = size * alignTo(size >> 3, 4);
         var palette_size = 256 * 4;
         ico.writeByte(size);
         ico.writeByte(size);
         ico.writeByte(0); // palette
         ico.writeByte(0); // reserved
         ico.writeShort(1); // planes
         ico.writeShort(8); // bits per pixel
         ico.writeInt(40 + xor_size + and_size + palette_size);
         ico.writeInt(data_pos); // Data offset
         data_pos += 40 + xor_size + and_size + palette_size;
      }

      for(bmp in bmps) 
      {
         var size = bmp.width;
         var xor_size = size * size * 4;
         var and_size = size * alignTo(size >> 3, 4);
         ico.writeByte(size);
         ico.writeByte(size);
         ico.writeByte(0); // palette
         ico.writeByte(0); // reserved
         ico.writeShort(1); // planes
         ico.writeShort(32); // bits per pixel
         ico.writeInt(40 + xor_size + and_size); // Data size
         ico.writeInt(data_pos); // Data offset
         data_pos += 40 + xor_size + and_size;
      }

      for(bmp in bmps_8bit) 
      {
         var size = bmp.width;
         var xor_size = size * size;
         var and_size = size * alignTo(size >> 3, 4);
         ico.writeInt(40); // size(bytes)
         ico.writeInt(size);
         ico.writeInt(size * 2);
         ico.writeShort(1);
         ico.writeShort(8);
         ico.writeInt(0); // Bit fields...
         ico.writeInt(xor_size + and_size); // Size...
         ico.writeInt(0); // res-x
         ico.writeInt(0); // res-y
         ico.writeInt(256); // cols
         ico.writeInt(0); // important

         var bits = BitmapData.getRGBAPixels(bmp);
         var and_mask = new ByteArray();
         var colourCounter:IntMap<Int> = new IntMap<Int>(); //key: color, value: slot
         var allCols = new Array<Int>();

         //calculate palette & and mask
         for(y in 0...size) 
         {
            var mask = 0;
            var bit = 128;
            bits.position = (size-1 - y) * 4 * size;

            for(i in 0...alignTo(size,32)) 
            {
               if(i<size)
               {
                  var r:Int = 0xFF & bits.readByte();
                  var g:Int = 0xFF & bits.readByte();
                  var b:Int = 0xFF & bits.readByte();
                  var color:Int = ((b << 16) | (g << 8) | (r));

                  var a = bits.readByte();

                  if ((a&0x80) == 0)
                  {
                     mask |= bit;
                     color = 0;
                  }

                  var val = colourCounter.get(color);
                  if (val==null)
                     colourCounter.set(color,1);
                  else
                     colourCounter.set(color, val+1);

                  allCols.push(color);
               }

               bit = bit >> 1;
               if (bit == 0) 
               {
                  and_mask.writeByte(mask);
                  bit = 128;
                  mask = 0;
               }
            }
         }

         var cols = new Array<Int>();
         var count = new Array<Int>();
         var paletteMap = new Map<Int,Int>();
         var idx = 0;
         for(k in colourCounter.keys())
         {
            cols[idx] = k;
            count[idx] = colourCounter.get(k);
            paletteMap.set(k,idx);
            idx++;
         }

         var palSize = idx;
         var paletteRemap = [for(i in 0...palSize) i];

         while(palSize>255)
         {
            palSize--;
            var where = -1;
            var smallest = size*size;
            for(i in 0...idx)
            {
                if (cols[i]>=0 && count[i]<smallest)
                {
                   smallest = count[i];
                   where = i;
                   if (smallest==1)
                      break;
                }
            }
            var match = -1;
            var err = 255.0*255.0*3;
            var col = cols[where];
            var r = col & 0xff;
            var g = (col>>8) & 0xff;
            var b = (col>>16) & 0xff;
            for(j in 0...idx)
            {
               if (j!=where)
               {
                  col = cols[j];
                  if (col>0 && col>=0)
                  {
                     var dr = r - (col&0xff);
                     var dg = g - ((col>>8)&0xff);
                     var db = b - ((col>>16)&0xff);
                     var diff = dr*dr + dg*dg + db*db;
                     if (diff<err)
                     {
                        err = diff;
                        match = j;
                     }
                  }
               }
            }
            paletteRemap[where] = match;
            count[match] += count[where];
            cols[where] = -1;
         }

         var palette = new Array<Int>();
         var paletteIdx = new Array<Int>();
         var idx = 0;
         for(j in 0...paletteRemap.length)
         {
            if (paletteRemap[j]==j)
            {
               paletteIdx[j] = palette.length;
               palette.push( cols[j] );
            }
         }

         var colorIndexes:Array<Int> = new Array<Int>(); //bmp
         for(col in allCols)
         {
            var idx = paletteMap.get(col);
            while(true)
            {
               var remap = paletteRemap[idx];
               if (remap==idx)
                  break;
               idx = remap;
            }
            colorIndexes.push( paletteIdx[idx] );
         }

         //write palette
         for (color in palette) 
         {
            ico.writeByte((color & 0xFF0000) >> 16);
            ico.writeByte((color & 0xFF00) >> 8);
            ico.writeByte((color & 0xFF));
            ico.writeByte(0x00);
         }
         for(i in palette.length...256)
         {
            ico.writeByte(0x00);
            ico.writeByte(0x00);
            ico.writeByte(0x00);
            ico.writeByte(0x00);
         }

         //write bmp (color indexes)
         for( slot in colorIndexes )
         {
            ico.writeByte(slot);
         }
         //write and mask
         ico.writeBytes(and_mask, 0, and_mask.length);
      }

      for(bmp in bmps) 
      {
         var size = bmp.width;
         var xor_size = size * size * 4;
         var and_size = size * alignTo(size >> 3, 4);

         ico.writeInt(40); // size(bytes)
         ico.writeInt(size);
         ico.writeInt(size * 2);
         ico.writeShort(1);
         ico.writeShort(32);
         ico.writeInt(0); // Bit fields...
         ico.writeInt(xor_size + and_size); // Size...
         ico.writeInt(0); // res-x
         ico.writeInt(0); // res-y
         ico.writeInt(0); // cols
         ico.writeInt(0); // important

         var bits = BitmapData.getRGBAPixels(bmp);
         var and_mask = new ByteArray();

         for(y in 0...size) 
         {
            var mask = 0;
            var bit = 128;
            bits.position = (size-1 - y) * 4 * size;

            for(i in 0...alignTo(size,32)) 
            {
               if(i<size)
               {
                  var r = bits.readByte();
                  var g = bits.readByte();
                  var b = bits.readByte();
                  var a = bits.readByte();
                  ico.writeByte(b);
                  ico.writeByte(g);
                  ico.writeByte(r);
                  ico.writeByte(a);

                  if ((a&0x80) == 0)
                     mask |= bit;
               }

               bit = bit >> 1;
               if (bit == 0) 
               {
                  and_mask.writeByte(mask);
                  bit = 128;
                  mask = 0;
               }
            }
         }
         ico.writeBytes(and_mask, 0, and_mask.length);
      }

      if (bmpsLength > 0) 
      {
         var file = File.write(targetPath, true);
         file.writeBytes(ico, 0, ico.length);
         file.close();

         return true;
      }

      return false;
   }

   private static function extractBits(data:ByteArray, offset:Int, len:Int):Bytes 
   {
      var out = new BytesOutput();

      for(i in 0...len) 
      {
         out.writeByte(data[i * 4 + offset]);
      }

      return out.getBytes();
   }

   public static function findMatch(icons:Array<Icon>, width:Int, height:Int):Icon 
   {
      var match = null;

      for(icon in icons) 
      {
         if (match == null && icon.width == 0 && icon.height == 0) 
         {
            match = icon;
         }
         else if (icon.width == width && icon.height == height) 
         {
            match = icon;
         }
      }

      // Only the default icon...
      if (match==null && icons.length==1 && icons[0].width==-1)
         return icons[0];

      return match;
   }

   public static function findNearestMatch(icons:Array<Icon>, width:Int, height:Int):Icon 
   {
      var match = null;

      for(icon in icons) 
      {
         if (icon.width > width / 2 && icon.height > height / 2) 
         {
            if (match == null) 
            {
               match = icon;
            }
            else
            {
               if (icon.width > match.width && icon.height > match.height) 
               {
                  if (match.width < width || match.height < height) 
                  {
                     match = icon;
                  }
               }
               else
               {
                  if (icon.width > width && icon.height > height) 
                  {
                     match = icon;
                  }
               }
            }
         }
      }

      return match;
   }

   private static function getIconBitmap(icons:Array<Icon>, width:Int, height:Int, backgroundColor:Int = null):BitmapData 
   {
      if (width<1 || height<1)
         Log.error("Bad icon size request");
      var icon = findMatch(icons, width, height);
      var exactMatch = icon!=null && icon.width==width && icon.height==height;

      if (icon == null) 
      {
         icon = findNearestMatch(icons, width, height);
         exactMatch = false;
      }

      if (icon == null) 
      {
         return null;
      }

      if (!FileSystem.exists(icon.path)) 
      {
         LogHelper.warn("Could not find icon path: " + icon.path);
         return null;
      }

      var extension = Path.extension(icon.path);
      var bitmapData = null;

      switch(extension) 
      {
         case "png", "jpg", "jpeg":

            if (exactMatch ) 
            {
               bitmapData = BitmapData.load(icon.path);
               if (bitmapData.width==0 || bitmapData.height==0)
                   Log.error("Invalid icon image " + icon.path );
            }
            else
            {
               bitmapData = ImageHelper.resizeBitmapData(BitmapData.load(icon.path), width, height);
               if (bitmapData.width==0 || bitmapData.height==0)
                   Log.error("Invalid icon image resize " + icon.path );
            }

         case "svg":

            var content  = File.getContent(icon.path);
            if (content==null || content.length<1)
               Log.error("Invalid svg getContent " + icon.path );
            var svg = new Svg(Xml.parse(content));
            if (svg.width==0 || svg.height==0)
               Log.error("Invalid svg data " + icon.path );

            bitmapData = ImageHelper.rasterizeSVG(svg, width, height, backgroundColor);
            if (bitmapData.width<1 || bitmapData.height<1)
               Log.error("Invalid svg resterize " + width + "x" + height );
      }

      return bitmapData;
   }

   private static function packBits(data:ByteArray, offset:Int, len:Int):Bytes 
   {
      var out = new BytesOutput();
      var idx = 0;

      while(idx < len) 
      {
         var val = data[idx * 4 + offset];
         var same = 1;

         /*
         Hmmmm...
         while( ((idx+same) < len) && (data[ (idx+same)*4 + offset ]==val) && (same < 2) )
         same++;
         */

         if (same == 1) 
         {
            var raw = idx + 120 < len ? 120 : len - idx;
            out.writeByte(raw - 1);

            for(i in 0...raw) 
            {
               out.writeByte(data[idx * 4 + offset]);
               idx++;
            }
         }
         else
         {
            out.writeByte(257 - same);
            out.writeByte(val);
            idx += same;
         }
      }

      return out.getBytes();
   }
}
