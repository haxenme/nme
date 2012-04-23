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

package jeash.utils;

class Uncompress
{
   static public function ConvertStream(inStream:jeash.utils.IDataInput,?inSize:Int) : 
      jeash.utils.IDataInput
   {
#if flash9
      var buffer = new jeash.utils.ByteArray();
      inStream.readBytes(buffer,0,inSize);
      buffer.uncompress();
      return buffer;
#elseif (neko||cpp)
      var bytes = inSize==null ? inStream.readAll() : inStream.readBytes(inSize);
      #if neko
      return new IDataInput( new haxe.io.BytesInput( neko.zip.Uncompress.run(bytes) ) );
      #else
      return new IDataInput( new haxe.io.BytesInput( cpp.zip.Uncompress.run(bytes) ) );
      #end
#else
    // TODO
   return null;
#end
   }


#if flash9
   static public function Run(inBytes:haxe.io.Bytes)
   {
      var data = inBytes.getData();
      data.uncompress();
      return haxe.io.Bytes.ofData(data);
   }
#elseif (neko||cpp)
   static public function Run(inBytes:haxe.io.Bytes)
   {
#if neko
      return neko.zip.Uncompress.run(inBytes);
#else
      return cpp.zip.Uncompress.run(inBytes);
#end
   }
#else
   static public function Run(inBytes:haxe.io.Bytes)
   {
      return null;
   }
#end
}
