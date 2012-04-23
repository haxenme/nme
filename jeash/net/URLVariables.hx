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

package jeash.net;

class URLVariables implements Dynamic
{

   public function new(?inEncoded:String) {
      if (inEncoded!=null)
         decode(inEncoded);
   }

   public function decode(inVars:String) {
      var fields = Reflect.fields(this);

      for(f in fields)
         Reflect.deleteField(this,f);

      var fields = inVars.split(";").join("&").split("&");
      for(f in fields) {
         var eq = f.indexOf("=");
         if (eq>0)
            Reflect.setField(this, StringTools.urlDecode(f.substr(0,eq)),
                                   StringTools.urlDecode(f.substr(eq+1)) );
         else if (eq!=0)
            Reflect.setField(this, StringTools.urlDecode(f),"");
      }
   }

   public function toString() : String
   {
      var result = new Array<String>();
      var fields = Reflect.fields(this);
      for(f in fields)
          result.push( StringTools.urlEncode(f) + "=" + StringTools.urlEncode(Reflect.field(this,f) ) );
 
      return result.join("&");
   }
}

