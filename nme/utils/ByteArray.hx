package nme.utils;

import nme.geom.Rectangle;

/**
* @author   Hugh Sanderson
* @author   Russell Weir
**/

// Ensure that the neko->haxe callbacks are initialized
import nme.Lib;

class ByteArray extends haxe.io.Input, implements ArrayAccess<Int>
{
   public  var position:Int;
   public var endian(nmeGetEndian,nmeSetEndian) : String;
   public var nmeData:Dynamic;

   public var length(nmeGetLength,null):Int;

   public function new(inLen:Int = 0)
   {
      nmeData = nme_byte_array_create(inLen);
      position = 0;
   }

   public function nmeGetData():Dynamic { return nmeData; }

   public function asString() : String
   {
      return nme_byte_array_as_string(nmeData);
   }

   inline function nmeGetLength():Int
   {
      return nme_byte_array_get_length(nmeData);
   }

   // Neko/cpp pseudo array accessors...
   inline public function __get( pos:Int ) : Int
   {
      return nme_byte_array_get(nmeData,pos);
   }

   inline public function __set(pos:Int,v:Int) : Void
   {
      nme_byte_array_set(nmeData,pos,v);
   }

   public function getBytes() : haxe.io.Bytes
   {
		#if cpp
      var bytes = haxe.io.Bytes.alloc(length);
      nme_byte_array_get_bytes(nmeData,bytes.getData());
      return bytes;
      #else
		var str = asString();
      trace(str.length);
		return haxe.io.Bytes.ofString(str);
      #end
   }

   static public function fromHandle(inHandle:Dynamic):ByteArray
	{
      var result = new ByteArray();
      result.nmeData = inHandle;
      return result;
	}

   static public function readFile(inString:String):ByteArray
   {
      var handle = nme_byte_array_read_file(inString);
      var result = new ByteArray();
      result.nmeData = handle;
      return result;
   }

   //[ddc]
   public function writeFile(inString:String):Void
   {
      nme_byte_array_overwrite_file(inString, nmeData , nmeGetLength());
   }

   // does the "work" for haxe.io.Input
   public override function readByte():Int
   {
      return nme_byte_array_get(nmeData,position++);
   }

#if neko
   public function readInt() : haxe.Int32
#else
   public function readInt() : Int
#end
   {
      return cast readInt32();
   }

   public inline function readShort() : Int {
      return readInt16();
   }

   public inline function readUnsignedByte() : Int {
      return readByte();
   }

   public function readUTFBytes(inLen:Int)
   {
      return readString(inLen);
   }

   private function nmeGetEndian() : String {
      return bigEndian ? Endian.BIG_ENDIAN : Endian.LITTLE_ENDIAN;
   }

   private function nmeSetEndian(s:String) : String {
      bigEndian = (s == Endian.BIG_ENDIAN);
      return s;
   }
   
   public function writeUTFBytesToBuffer(str:String) {
   
		// There are many smart ways to do this, but
		// this is simple: we first calculate the required space for
		// the UTF-8 representation of the string alone.
		// If the needed space doesn't require the position
		// to go beyond the buffer size, then we are lucky and
		// just churn out the right byes in the same
		// original buffer.
		// If we are not so lucky and we'd go over the available
		// space instead, then we need to do three things:
		// 1) allocate a newer array that can accomodate the pre-
		//    existing data and the new data
		// 2) we probably have to copy a part of the old data over
		// 3) we put the new bytes from the string in place

		// So, calculate the needed space for the string first
        // P.S. This piece of code curtesy of http://www.google.com/codesearch/p?hl=en#ijOawF65hjs/trunk/std/haxe/io/Bytes.hx&q=ofString%20package:http://haxe%5C.googlecode%5C.com&l=239
		var requiredSpaceForString:Int = 0;
        //trace("calculating how many bytes are needed for the string");
        for (i in 0...str.length) {
            var charValue:Int = str.charCodeAt(i);
            if (charValue > 0 && charValue <= 127) {
                requiredSpaceForString++;
            } else if (charValue <= 2047) {
                requiredSpaceForString += 2;
            } else if (charValue <= 0xFFFF ) {
                requiredSpaceForString += 3;
            }
            else {
                requiredSpaceForString += 4;
            }
           //trace(" > " + str.charAt(i) + " added, now required space for string is " + requiredSpaceForString);
        }
        //trace("required space for string: " + requiredSpaceForString);
        
        // Is there enough space after the pointer to store
        // the bytes from the string?
        
		//trace("position: " + position);        
		//trace("requiredSpaceForString " + requiredSpaceForString);        
		//trace("length " + length);        		
        if ((position + requiredSpaceForString) <= length) {
			// lucky case
			//trace("lucky case");        
        }
        else {
			//trace("unlucky case");        
			// unlucky case
			// 1) allocate new array that can hold all the data
			var requiredSizeForNewBuffer:Int = position + requiredSpaceForString;
			// we keep hold of the old data because we need to copy some of it over
			var originalNmeData:Dynamic = nmeData;
			// brand new buffer for us
		    //trace("allocating new buffer of size " + requiredSizeForNewBuffer);        		
			nmeData = nme_byte_array_create(requiredSizeForNewBuffer);
			
			// 2) ok now we need to copy over the data before the pointer
			for ( i in 0...position) {
				nme_byte_array_set(nmeData,i,nme_byte_array_get(originalNmeData,i));
			}
        }
        
        // 3) lastly, take the bytes from the string and put them in the
        //    buffer        
        // P.S. This piece of code curtesy of http://www.google.com/codesearch/p?hl=en#ijOawF65hjs/trunk/std/haxe/io/Bytes.hx&q=ofString%20package:http://haxe%5C.googlecode%5C.com&l=239
        for ( i in 0...requiredSpaceForString) {
            var charValue:Int = str.charCodeAt(i);
            if (charValue <= 0x7F) {
				nme_byte_array_set(nmeData,position++,charValue);
            } else if (charValue <= 0x7FF ) {
				nme_byte_array_set(nmeData,position++,(0xC0 | (charValue >> 6)) );
				nme_byte_array_set(nmeData,position++,(0x80 | (charValue & 63)) );
            } else if (charValue <= 0xFFFF ) {
				nme_byte_array_set(nmeData,position++,(0xE0 | (charValue >> 12)) );
				nme_byte_array_set(nmeData,position++,(0x80 | ((charValue >> 6) & 63)) );
				nme_byte_array_set(nmeData,position++,(0x80 | (charValue & 63)) );
            }
            else {
				nme_byte_array_set(nmeData,position++,0xF0 | (charValue >> 18) );
				nme_byte_array_set(nmeData,position++,0x80 | ((charValue >> 12) & 63) );
				nme_byte_array_set(nmeData,position++,0x80 | ((charValue >> 6) & 63) );
				nme_byte_array_set(nmeData,position++,0x80 | (charValue & 63) );
            }
        }
        //trace("updated position is now: " + position);        

    }

   static var nme_byte_array_create = nme.Loader.load("nme_byte_array_create",1);
   static var nme_byte_array_as_string = nme.Loader.load("nme_byte_array_as_string",1);
   #if cpp
   static var nme_byte_array_get_bytes = nme.Loader.load("nme_byte_array_get_bytes",2);
   #end
   static var nme_byte_array_read_file = nme.Loader.load("nme_byte_array_read_file",1);
   static var nme_byte_array_overwrite_file = nme.Loader.load("nme_byte_array_overwrite_file",3);
   static var nme_byte_array_get_length = nme.Loader.load("nme_byte_array_get_length",1);
   static var nme_byte_array_get = nme.Loader.load("nme_byte_array_get",2);
   static var nme_byte_array_set = nme.Loader.load("nme_byte_array_set",3);
}


