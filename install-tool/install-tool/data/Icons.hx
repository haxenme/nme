package data;

#if REQUIRE_NEKOAPI
import nme.display.BitmapData;
#end


class Icons
{
   var mIcons : Array<Icon>;

   public function new()
   {
      mIcons = [];
   }
   public function add(inIcon:Icon)
   {
      mIcons.push(inIcon);
   }

   public function findIcon(inWidth:Int, inHeight:Int)
   {
      // Look for exact match ...
      for(icon in mIcons)
         if (icon.isSize(inWidth,inHeight))
         {
            var ext =  neko.io.Path.extension(icon.name).toLowerCase();
            if (ext=="png" )
            {
               return icon.name;
            }
         }
      return "";
   }

   public function updateIcon(inWidth:Int, inHeight:Int, inDest:String)
   {
      var bmp = getIconBitmap(inWidth,inHeight,inDest);
      if (bmp==null)
      {
         if (!neko.FileSystem.exists(inDest))
            return false;
      }
      else
      {
         var bytes = bmp.encode("png",0.95);
         bytes.writeFile(inDest);
      }

      return true;
   }


#if REQUIRE_NEKOAPI
   
   
   function getIconBitmap(inWidth:Int, inHeight:Int, inTimedFile:String="", ?inBackgroundColour ) : BitmapData
   {
      var found:Icon = null;

      // Look for exact match ...
      for(icon in mIcons)
         if (icon.isSize(inWidth,inHeight))
         {
            //mContext.HAS_ICON = true;
            if (inTimedFile!="" && !InstallTool.isNewer(icon.name,inTimedFile))
               return null;

            var bmp = nme.display.BitmapData.load(icon.name);
            // TODO: resize if required
            return bmp;
         }

      // Look for possible match ...
      if (found==null)
      {
         for(icon in mIcons)
            if (icon.matches(inWidth,inHeight))
            {
               found = icon;
               //mContext.HAS_ICON = true;
               if (inTimedFile!="" && !InstallTool.isNewer(icon.name,inTimedFile))
                  return null;

               break;
            }
      }

      if (found==null)
         return null;

      var ext =  neko.io.Path.extension(found.name).toLowerCase();

      if (ext=="svg")
      {
         var bytes = nme.utils.ByteArray.readFile(found.name);
         var svg = new gm2d.svg.SVG2Gfx( Xml.parse(bytes.asString()) );

	      var shape = svg.CreateShape();
         var scale = inHeight/32;

         InstallTool.print("Creating " + inWidth + "x" + inHeight + " icon from " + found.name );

         shape.scaleX = scale;
         shape.scaleY = scale;
         shape.x = (inWidth - 32*scale)/2;

         var bmp = new nme.display.BitmapData(inWidth,inHeight, true,
                           inBackgroundColour==null ? {a:0, rgb:0xffffff} : inBackgroundColour );

         bmp.draw(shape);

         return bmp;
      }
      else
      {
          throw "Unknown icon format : " + found.name;
      }
 
      return null;
   }

 function PackBits(data:nme.utils.ByteArray,offset:Int, len:Int) : haxe.io.Bytes
   {
      var out = new haxe.io.BytesOutput();
      var idx = 0;
      while(idx<len)
      {
         var val = data[idx*4+offset];
         var same = 1;
         /*
          Hmmmm...
         while( ((idx+same) < len) && (data[ (idx+same)*4 + offset ]==val) && (same < 2) )
            same++;
         */
         if (same==1)
         {
            var raw = idx+120 < len ? 120 : len-idx;
            out.writeByte(raw-1);
            for(i in 0...raw)
            {
               out.writeByte( data[idx*4+offset] );
               idx++;
            }
         }
         else
         {
            out.writeByte( 257-same );
            out.writeByte(val);
            idx+=same;
         }
      }
      return out.getBytes();
   }
   function ExtractBits(data:nme.utils.ByteArray,offset:Int, len:Int) : haxe.io.Bytes
   {
      var out = new haxe.io.BytesOutput();
      for(i in 0...len)
         out.writeByte( data[i*4+offset] );
      return out.getBytes();
   }



   public function createMacIcon(resource_dest:String)
   {
         var out = new haxe.io.BytesOutput();
         out.bigEndian = true;
         for(i in 0...2)
         {
            var s =  ([ 32, 48 ])[i];
            var code =  (["il32","ih32"])[i];
            var bmp = getIconBitmap(s,s);
            if (bmp!=null)
            {
               for(c in 0...4)
                  out.writeByte(code.charCodeAt(c));
               var n = s*s;
               var pixels = bmp.getPixels(new nme.geom.Rectangle(0,0,s,s));

               var bytes_r = PackBits(pixels,1,s*s);
               var bytes_g = PackBits(pixels,2,s*s);
               var bytes_b = PackBits(pixels,3,s*s);

               out.writeInt31(bytes_r.length + bytes_g.length + bytes_b.length + 8);
               out.writeBytes(bytes_r,0,bytes_r.length);
               out.writeBytes(bytes_g,0,bytes_g.length);
               out.writeBytes(bytes_b,0,bytes_b.length);

               var code =  (["l8mk","h8mk" ])[i];
               for(c in 0...4)
                  out.writeByte(code.charCodeAt(c));
               var bytes_a = ExtractBits(pixels,0,s*s);
               out.writeInt31(bytes_a.length + 8);
               out.writeBytes(bytes_a,0,bytes_a.length);
            }
         }
         var bytes = out.getBytes();
         if (bytes.length>0)
         {
            var filename = resource_dest + "/icon.icns";
            var file = neko.io.File.write( filename,true);
            file.bigEndian = true;
            for(c in 0...4)
               file.writeByte("icns".charCodeAt(c));
            file.writeInt31(bytes.length+8);
            file.writeBytes(bytes,0,bytes.length);
            file.close();
            return filename;
         }
 
      return "";
   }

   function setWindowsIcon(inAppIcon:String, inTmp:String, inExeName:String)
   {
      var name:String="";
      if (inAppIcon!=null && inAppIcon!="")
         name = inAppIcon;
      else
      {
         // Not quite working yet....
         return;

         var ico = new nme.utils.ByteArray();
         ico.bigEndian = false;
         ico.writeShort(0);
         ico.writeShort(1);
         ico.writeShort(1);

         for(size in [ 32 ])
         {
            var bmp = getIconBitmap(size,size);
            if (bmp==null)
               break;
            ico.writeByte(size);
            ico.writeByte(size);
            ico.writeByte(0); // palette
            ico.writeByte(0); // reserved
            ico.writeShort(1); // planes
            ico.writeShort(32); // bits per pixel
            ico.writeInt(108 + 4*size*size); // Data size
            var here = ico.length;
            ico.writeInt(here + 4); // Data offset

            ico.writeInt(108); // size (bytes)
            ico.writeInt(size);
            ico.writeInt(size);
            ico.writeShort(1);
            ico.writeShort(32);
            ico.writeInt(3); // Bit fields...
            ico.writeInt(size*size*4); // SIze...
            ico.writeInt(0); // res-x
            ico.writeInt(0); // res-y
            ico.writeInt(0); // cols
            ico.writeInt(0); // important
            // Red
            ico.writeByte(0); 
            ico.writeByte(0);
            ico.writeByte(0xff);
            ico.writeByte(0);
            // Green
            ico.writeByte(0); 
            ico.writeByte(0xff);
            ico.writeByte(0);
            ico.writeByte(0);
            // Blue
            ico.writeByte(0xff);
            ico.writeByte(0); 
            ico.writeByte(0);
            ico.writeByte(0);
            // Alpha
            ico.writeByte(0); 
            ico.writeByte(0);
            ico.writeByte(0);
            ico.writeByte(0xff);

            //LCS_WINDOWS_COLOR_SPACE
            ico.writeByte(0x20); 
            ico.writeByte(0x6e);
            ico.writeByte(0x69);
            ico.writeByte(0x57);

            for(j in 0...36)
               ico.writeByte(0);
            ico.writeInt(0);
            ico.writeInt(0);
            ico.writeInt(0);

            var bits = bmp.getPixels( new nme.geom.Rectangle(0,0,size,size) );
            ico.writeBytes(bits);
         }

         name = inTmp + "/icon.ico";
         neko.io.File.write(name,true);

         var file = neko.io.File.write( name,true);
         file.writeBytes(ico,0,ico.length);
         file.close();
      }

      InstallTool.runCommand(".", InstallTool.nme + "\\ndll\\Windows\\ReplaceVistaIcon.exe", [ inExeName, name] );
   }


#else


	public function createMacIcon(resource_dest:String) {
		
		return "";
		
	}
	

	function getIconBitmap(inWidth:Int, inHeight:Int, inTimedFile:String="", ?inBackgroundColour ) : Dynamic {
		
		return null;
		
	}


	function setWindowsIcon(inAppIcon:String, inTmp:String, inExeName:String) {
		
		return "";
		
	}

#end


}
