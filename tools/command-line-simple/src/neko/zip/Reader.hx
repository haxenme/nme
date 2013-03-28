/*
 * Copyright(c) 2005, The haXe Project Contributors
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
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package neko.zip;

typedef ZipEntry = 
{
   var fileName : String;
   var fileSize : Int;
   var fileTime : Date;
   var compressed : Bool;
   var compressedSize : Int;
   var data : haxe.io.Bytes;
   var crc32 : Null<haxe.Int32>;
}

// see http://www.pkware.com/documents/casestudies/APPNOTE.TXT
class Reader 
{
   public static function unzip( f : ZipEntry ) : haxe.io.Bytes 
   {
      if ( !f.compressed )
         return f.data;
      var c = new Uncompress(-15);
      var s = haxe.io.Bytes.alloc(f.fileSize);
      var r = c.execute(f.data,0,s,0);
      c.close();
      if ( !r.done || r.read != f.data.length || r.write != f.fileSize )
         throw "Invalid compressed data for "+f.fileName;
      return s;
   }

   static function readZipDate( i : haxe.io.Input ) 
   {
      var t = i.readUInt16();
      var hour = (t >> 11) & 31;
      var min = (t >> 5) & 63;
      var sec = t & 31;
      var d = i.readUInt16();
      var year = d >> 9;
      var month = (d >> 5) & 15;
      var day = d & 31;
      return new Date(year + 1980, month-1, day, hour, min, sec << 1);
   }

   public static function readZipEntry( i : haxe.io.Input ) : ZipEntry 
   {
      var h = i.readInt31();
      if ( h == 0x02014B50 || h == 0x06054B50 )
         return null;
      if ( h != 0x04034B50 )
         throw "Invalid Zip Data";
      var version = i.readUInt16();
      var flags = i.readUInt16();
      //var extraFields = (flags & 8) != 0;
      //if ( (flags & 0xFFF7) != 0 )
         //throw "Unsupported flags "+flags;
      var extraFields = false;
      var compression = i.readUInt16();
      var compressed = (compression != 0);
      if ( compressed && compression != 8 )
         throw "Unsupported compression "+compression;
      var mtime = readZipDate(i);
      var crc32 = i.readInt32();
      var csize = i.readUInt30();
      var usize = i.readUInt30();
      var fnamelen = i.readInt16();
      var elen = i.readInt16();
      var fname = i.readString(fnamelen);
      var ename = i.readString(elen);
      var data;
      if ( extraFields ) 
      {
         // TODO : it is needed to directly read the compressed
         // data streamed from the input(needs additional neko apis)
         // then, we can set "compressed" to false, and then follows
         // 12 bytes with real crc, csize and usize
         throw "Zip format with extrafields is currently not supported";
      }
      else
         data = i.read(csize);
      return 
      {
         fileName : fname,
         fileSize : usize,
         fileTime : mtime,
         compressed : compressed,
         compressedSize : csize,
         data : data,
         crc32 : crc32,
      };
   }

   public static function readZip( i : haxe.io.Input ) : List<ZipEntry> 
   {
      var l = new List();
      while( true ) 
      {
         var e = readZipEntry(i);
         if ( e == null )
            break;
         l.add(e);
      }
      return l;
   }

   public static function readTar( i : haxe.io.Input, ?gz : Bool ) : List<ZipEntry> 
   {
      if ( gz ) 
      {
         var tmp = new haxe.io.BytesOutput();
         readGZHeader(i);
         readGZData(i,tmp);
         i = new haxe.io.BytesInput(tmp.getBytes());
      }
      var l = new List();
      while( true ) 
      {
         var e = readTarEntry(i);
         if ( e == null )
            break;
         var pad = Math.ceil(e.fileSize / 512) * 512 - e.fileSize;
         var data = i.read(e.fileSize);
         i.read(pad);
         l.add(
         {
            fileName : e.fileName,
            fileSize : e.fileSize,
            fileTime : e.fileTime,
            compressed : false,
            compressedSize : e.fileSize,
            data : data,
            crc32 : null,
         });
      }
      return l;
   }

   public static function readGZHeader( i : haxe.io.Input ) : String 
   {
      if ( i.readByte() != 0x1F || i.readByte() != 0x8B )
         throw "Invalid GZ header";
      if ( i.readByte() != 8 )
         throw "Invalid compression method";
      var flags = i.readByte();
      var mtime = i.read(4);
      var xflags = i.readByte();
      var os = i.readByte();
      var fname = null;
      var comments = null;
      if ( flags & 4 != 0 ) 
      {
         var xlen = i.readUInt16();
         var xdata = i.read(xlen);
      }
      if ( flags & 8 != 0 )
         fname = i.readUntil(0);
      if ( flags & 16 != 0 )
         comments = i.readUntil(0);
      if ( flags & 2 != 0 ) 
      {
         var hcrc = i.readUInt16();
         // does not check header crc
      }
      return fname;
   }

   public static function readGZData( i : haxe.io.Input, o : haxe.io.Output, ?bufsize : Int ) : Int 
   {
      if ( bufsize == null ) bufsize = (1 << 16); // 65Ks
      var u = new Uncompress(-15);
      u.setFlushMode(Flush.SYNC);
      var buf = haxe.io.Bytes.alloc(bufsize);
      var out = haxe.io.Bytes.alloc(bufsize);
      var bufpos = bufsize;
      var tsize = 0;
      while( true ) 
      {
         if ( bufpos == buf.length ) 
         {
            buf = refill(i,buf,0);
            bufpos = 0;
         }
         var r = u.execute(buf,bufpos,out,0);
         if ( r.read == 0 ) 
         {
            if ( bufpos == 0 )
               throw new haxe.io.Eof();
            var len = buf.length - bufpos;
            buf.blit(0,buf,bufpos,len);
            buf = refill(i,buf,len);
            bufpos = 0;
         }
         else
         {
            bufpos += r.read;
            tsize += r.read;
            o.writeFullBytes(out,0,r.write);
            if ( r.done )
               break;
         }
      }
      return tsize;
   }

   static function refill( i, buf : haxe.io.Bytes, pos : Int ) 
   {
      try 
      {
         while( pos != buf.length ) 
         {
            var k = i.readBytes(buf,pos,buf.length-pos);
            pos += k;
         }
      } catch( e : haxe.io.Eof ) 
      {
      }
      if ( pos == 0 )
         throw new haxe.io.Eof();
      if ( pos != buf.length )
         buf = buf.sub(0,pos);
      return buf;
   }

   public static function readTarEntry( i : haxe.io.Input ) 
   {
      var fname = i.readUntil(0);
      if ( fname.length == 0 ) 
      {
         for( x in 0...511+512 )
            if ( i.readByte() != 0 )
               throw "Invalid TAR end";
         return null;
      }
      i.read(99 - fname.length); // skip
      var fmod = parseOctal(i.read(8));
      var uid = parseOctal(i.read(8));
      var gid = parseOctal(i.read(8));
      var fsize = parseOctal(i.read(12));
      // read in two parts in order to prevent overflow
      var mtime : Float = parseOctal(i.read(8));
      mtime = mtime * 512.0 + parseOctal(i.read(4));
      var crc = i.read(8);
      var type = i.readByte();
      var lname = i.readUntil(0);
      i.read(99 - lname.length); // skip
      var ustar = i.readString(8);
      if ( ustar != "ustar  \x00" && ustar != "ustar\x00\x00\x00" ) 
      {
         //trace(StringTools.urlEncode(ustar));
         throw "Not an tar ustar file";
      }
      var uname = i.readUntil(0);
      i.read(31 - uname.length);
      var gname = i.readUntil(0);
      i.read(31 - gname.length);
      var devmaj = parseOctal(i.read(8));
      var devmin = parseOctal(i.read(8));
      var prefix = i.readUntil(0);
      i.read(166 - prefix.length);
      return 
      {
         fileName : fname,
         fileSize : fsize,
         fileTime : Date.fromTime(mtime * 1000.0),
      };
   }

   public static function readTarData( i : haxe.io.Input, o : haxe.io.Output, size : Int, ?bufsize ) 
   {
      if ( bufsize == null ) bufsize = (1 << 16); // 65Ks
      var buf = haxe.io.Bytes.alloc(bufsize);
      var pad = Math.ceil(size / 512) * 512 - size;
      while( size > 0 ) 
      {
         var n = i.readBytes(buf,0,if ( size > bufsize ) bufsize else size);
         size -= n;
         o.writeFullBytes(buf,0,n);
      }
      i.read(pad);
   }

   static function parseOctal( n : haxe.io.Bytes ) 
   {
      var i = 0;
      for( p in 0...n.length ) 
      {
         var c = n.get(p);
         if ( c == 0 )
            break;
         if ( c == 32 )
            continue;
         if ( c < 48 || c > 55 )
            throw "Invalid octal char";
         i = (i * 8) + (c - 48);
      }
      return i;
   }
}