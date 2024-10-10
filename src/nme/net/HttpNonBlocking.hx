/*
 * Copyright (C)2005-2019 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package nme.net;

import haxe.io.BytesOutput;
import haxe.io.BytesBuffer;
import haxe.io.Bytes;
import haxe.io.Input;
import sys.net.Host;
import sys.net.Socket;
import sys.Http;

import haxe.io.Bytes;
import haxe.io.Output;
import haxe.io.Error;

typedef IntRef = Array<Int>;

private enum AsyncJob
{
   WriteBytes(b:Bytes, len:Int, doneRef:IntRef);
   ReadHeaders(n:BytesBuffer, k:IntRef, s:Bytes, p:IntRef);
   ParseHeaders(b:BytesBuffer, api:BytesOutput);
   ReadChunk(api:BytesOutput, chunk_re:EReg, buf:Bytes, bufRead:IntRef);
   ReadEof(api:BytesOutput, buf:Bytes);
   ReadBytes(api:BytesOutput, buf:Bytes, remain:IntRef);
}

class HttpNonBlocking extends sys.Http {
   var sock:sys.net.Socket;
   var asyncJobs:Array<AsyncJob>;

   public var onComplete:Void->Void;

   public function new(url:String) {
      super(url);
   }

   public function nonblockingRequest(post:Bool, api:BytesOutput, ?inSock:sys.net.Socket, ?method:String) {
      this.responseAsString = null;
      this.responseBytes = null;
      sock = inSock;
      var url_regexp = ~/^(https?:\/\/)?([a-zA-Z\.0-9_-]+)(:[0-9]+)?(.*)$/;
      if (!url_regexp.match(url)) {
         asyncError("Invalid URL");
         return;
      }
      var secure = (url_regexp.matched(1) == "https://");
      if (sock == null) {
         if (secure) {
            #if php
            sock = new php.net.SslSocket();
            #elseif java
            sock = new java.net.SslSocket();
            #elseif python
            sock = new python.net.SslSocket();
            #elseif (!no_ssl && (hxssl || hl || cpp || (neko && !(macro || interp) || eval) || (lua && !lua_vanilla)))
            sock = new sys.ssl.Socket();
            #elseif (neko || cpp)
            throw "Https is only supported with -lib hxssl";
            #else
            throw new haxe.exceptions.NotImplementedException("Https support in haxe.Http is not implemented for this target");
            #end
         } else {
            sock = new Socket();
         }
         sock.setTimeout(cnxTimeout);
      }
      var host = url_regexp.matched(2);
      var portString = url_regexp.matched(3);
      var request = url_regexp.matched(4);
      // ensure path begins with a forward slash
      // this is required by original URL specifications and many servers have issues if it's not supplied
      // see https://stackoverflow.com/questions/1617058/ok-to-skip-slash-before-query-string
      if (request.charAt(0) != "/") {
         request = "/" + request;
      }
      var port = if (portString == null || portString == "") secure ? 443 : 80 else Std.parseInt(portString.substr(1, portString.length - 1));

      var multipart = (file != null);
      var boundary = null;
      var uri = null;
      if (multipart) {
         post = true;
         boundary = Std.string(Std.random(1000))
            + Std.string(Std.random(1000))
            + Std.string(Std.random(1000))
            + Std.string(Std.random(1000));
         while (boundary.length < 38)
            boundary = "-" + boundary;
         var b = new StringBuf();
         for (p in params) {
            b.add("--");
            b.add(boundary);
            b.add("\r\n");
            b.add('Content-Disposition: form-data; name="');
            b.add(p.name);
            b.add('"');
            b.add("\r\n");
            b.add("\r\n");
            b.add(p.value);
            b.add("\r\n");
         }
         b.add("--");
         b.add(boundary);
         b.add("\r\n");
         b.add('Content-Disposition: form-data; name="');
         b.add(file.param);
         b.add('"; filename="');
         b.add(file.filename);
         b.add('"');
         b.add("\r\n");
         b.add("Content-Type: " + file.mimeType + "\r\n" + "\r\n");
         uri = b.toString();
      } else {
         for (p in params) {
            if (uri == null)
               uri = "";
            else
               uri += "&";
            uri += StringTools.urlEncode(p.name) + "=" + StringTools.urlEncode('${p.value}');
         }
      }

      var b = new BytesOutput();
      if (method != null) {
         b.writeString(method);
         b.writeString(" ");
      } else if (post)
         b.writeString("POST ");
      else
         b.writeString("GET ");

      if (Http.PROXY != null) {
         b.writeString("http://");
         b.writeString(host);
         if (port != 80) {
            b.writeString(":");
            b.writeString('$port');
         }
      }
      b.writeString(request);

      if (!post && uri != null) {
         if (request.indexOf("?", 0) >= 0)
            b.writeString("&");
         else
            b.writeString("?");
         b.writeString(uri);
      }
      b.writeString(" HTTP/1.1\r\nHost: " + host + "\r\n");
      if (postData != null) {
         postBytes = Bytes.ofString(postData);
         postData = null;
      }
      if (postBytes != null)
         b.writeString("Content-Length: " + postBytes.length + "\r\n");
      else if (post && uri != null) {
         if (multipart || !Lambda.exists(headers, function(h) return h.name == "Content-Type")) {
            b.writeString("Content-Type: ");
            if (multipart) {
               b.writeString("multipart/form-data");
               b.writeString("; boundary=");
               b.writeString(boundary);
            } else
               b.writeString("application/x-www-form-urlencoded");
            b.writeString("\r\n");
         }
         if (multipart)
            b.writeString("Content-Length: " + (uri.length + file.size + boundary.length + 6) + "\r\n");
         else
            b.writeString("Content-Length: " + uri.length + "\r\n");
      }
      if( !Lambda.exists(headers, function(h) return h.name == "Connection") )
         b.writeString("Connection: close\r\n");
      for (h in headers) {
         b.writeString(h.name);
         b.writeString(": ");
         b.writeString(h.value);
         b.writeString("\r\n");
      }
      b.writeString("\r\n");
      if (postBytes != null)
         b.writeFullBytes(postBytes, 0, postBytes.length);
      else if (post && uri != null)
         b.writeString(uri);


      try
      {
         if (Http.PROXY != null)
            sock.connect(new Host(Http.PROXY.host), Http.PROXY.port);
         else
            sock.connect(new Host(host), port);

         var jobs = new Array<AsyncJob>();

         if (multipart)
            pushBody(b, file.io, file.size, boundary, jobs)
         else
            pushBody(b, null, 0, null, jobs);

         var headerBytes = new haxe.io.BytesBuffer();
         jobs.push( ReadHeaders( headerBytes, [4], haxe.io.Bytes.alloc(4), [0])  );
         jobs.push( ParseHeaders(headerBytes, api) );
         //jobs.push( SockClose );

         sock.setBlocking(false);
         asyncJobs = jobs;

         update();
      }
      catch (e:Dynamic)
      {
         asyncError(Std.string(e));
      }
   }

   function closeSocket()
   {
      asyncJobs = null;
      if (sock!=null)
      {
         try {
            sock.close();
         } catch(e:Dynamic) { }
         sock = null;
      }
   }

   public function asyncError(e:String)
   {
      closeSocket();
      onError(e);
   }


   public function asyncComplete(output:BytesOutput)
   {
      closeSocket();
      success(output.getBytes());
   }

   public function isPending() return asyncJobs!=null && asyncJobs.length>0;

   public function update()
   {
      while(asyncJobs!=null && asyncJobs[0]!=null)
      {
         var job = asyncJobs[0];
         switch(job)
         {

            case WriteBytes(bytes, len, done):
               try
               {
                  while( done[0]<len )
                  {
                     var remain = len-done[0];
                     var wrote = sock.output.writeBytes( bytes, done[0], remain );
                     if (wrote<1)
                        return;
                     done[0] += wrote;
                  }
                  asyncJobs.shift();
               }
               catch(e:haxe.io.Eof)
               {
                  asyncError("Eof");
                  return;
               }
               catch(e:haxe.io.Error)
               {
                  if (e!=Blocked)
                     asyncError("Error writing bytes " + e);
                  return;
               }
               catch(e:Dynamic)
               {
                  asyncError("error writing bytes:"+e);
                  return;
               }


            case ReadHeaders(b, k, s, p):
               while (true)
               {
                  while (p[0] != k[0])
                  {
                     try
                     {
                        var read = sock.input.readBytes(s, p[0], k[0] - p[0]);
                        if (read<1)
                           return;
                        p[0] += read;
                     }
                     catch (e:haxe.io.Eof)
                     {
                        asyncError("EOF reading header");
                        return;
                     }
                     catch(e:haxe.io.Error)
                     {
                        if (e!=Blocked)
                           asyncError("Error reading header " + e);
                        return;
                     }
                     catch (e:Dynamic)
                     {
                        asyncError("Error reading header:" + e);
                        return;
                     }
                  }
                  p[0] = 0;
                  b.addBytes(s, 0, k[0]);
                  switch (k[0])
                  {
                     case 1:
                        var c = s.get(0);
                        if (c == 10)
                           break;
                        if (c == 13)
                           k[0] = 3;
                        else
                           k[0] = 4;
                     case 2:
                        var c = s.get(1);
                        if (c == 10) {
                           if (s.get(0) == 13)
                              break;
                           k[0] = 4;
                        } else if (c == 13)
                           k[0] = 3;
                        else
                           k[0] = 4;
                     case 3:
                        var c = s.get(2);
                        if (c == 10) {
                           if (s.get(1) != 13)
                              k[0] = 4;
                           else if (s.get(0) != 10)
                              k[0] = 2;
                           else
                              break;
                        } else if (c == 13) {
                           if (s.get(1) != 10 || s.get(0) != 13)
                              k[0] = 1;
                           else
                              k[0] = 3;
                        } else
                           k[0] = 4;
                     case 4:
                        var c = s.get(3);
                        if (c == 10) {
                           if (s.get(2) != 13)
                              continue;
                           else if (s.get(1) != 10 || s.get(0) != 13)
                              k[0] = 2;
                           else
                              break;
                        } else if (c == 13){
                           if (s.get(2) != 10 || s.get(1) != 13)
                              k[0] = 3;
                           else
                              k[0] = 1;
                        }
                  }
               }
               // Header is read
               asyncJobs.shift();

          case ParseHeaders(b,api):
               var headers = b.getBytes().toString().split("\r\n");
               var response = headers.shift();
               var rp = response.split(" ");
               var status = Std.parseInt(rp[1]);
               if (status == 0 || status == null)
               {
                  asyncError("Invalid status:" + status );
                  return;
               }
 
               // remove the two lasts \r\n\r\n
               headers.pop();
               headers.pop();
               responseHeaders = new haxe.ds.StringMap();
               var size = null;
               var chunked = false;
               for (hline in headers)
               {
                  var a = hline.split(": ");
                  var hname = a.shift();
                  var hval = if (a.length == 1) a[0] else a.join(": ");
                  hval = StringTools.ltrim(StringTools.rtrim(hval));
                  {
                     var previousValue = responseHeaders.get(hname);
                     if (previousValue != null) {
                        if (responseHeadersSameKey == null) {
                           responseHeadersSameKey = new haxe.ds.Map<String, Array<String>>();
                        }
                        var array = responseHeadersSameKey.get(hname);
                        if (array == null) {
                           array = new Array<String>();
                           array.push(previousValue);
                           responseHeadersSameKey.set(hname, array);
                        }
                        array.push(hval);
                     }
                  }
                  responseHeaders.set(hname, hval);
                  switch (hname.toLowerCase()) {
                     case "content-length":
                        size = Std.parseInt(hval);
                     case "transfer-encoding":
                        chunked = (hval.toLowerCase() == "chunked");
                  }
               }
               onStatus(status);
               asyncJobs.shift();

               if (status < 200 || status >= 400)
               {
                  asyncError("Http Error #" + status);
                  return;
               }

               if (chunked)
               {
                  //if ((chunk_size != null || chunk_buf != null))
                  //  throw "Invalid chunk";
                  var chunk_re = ~/^([0-9A-Fa-f]+)[ ]*\r\n/m;
                  var buf = haxe.io.Bytes.alloc(1024);
                  chunk_size = null;
                  chunk_buf = null;
                  asyncJobs.push( ReadChunk(api, chunk_re, buf, [0]) );
               }
               else if (size==null)
               {
                  if (!noShutdown)
                      sock.shutdown(false, true);
                  var buf = haxe.io.Bytes.alloc(1024);
                  asyncJobs.push( ReadEof(api,buf) );
               }
               else
               {
                  api.prepare(size);
                  var s:Int = size;
                  var buf = haxe.io.Bytes.alloc(s>4096 ? 4096 : s);
                  asyncJobs.push( ReadBytes(api,buf,[s]) );
               }


         case ReadChunk(api, chunk_re, buf, bufRead):
            try
            {
               while (true)
               {
                  var bufsize = buf.length;
                  var remain = bufsize - bufRead[0];
                  var len = sock.input.readBytes(buf, bufRead[0], remain);
                  if (len<1)
                     return;
                  bufRead[0] += len;
                  if (bufRead[0]==bufsize)
                  {
                     if (!readChunk(chunk_re, api, buf, bufRead[0]))
                        break;
                     bufRead[0] = 0;
                  }
               }
            }
            catch (e:haxe.io.Error)
            {
               if (e!=Blocked)
                  asyncError("Error reading chunk " + e);
               return;
            }
            catch (e:haxe.io.Eof)
            {
               var chunksDone = false;
               if (bufRead[0]>0)
                  chunksDone = !readChunk(chunk_re, api, buf, bufRead[0]);

               if (!chunksDone)
                  asyncError( "Transfer aborted" );
            }
            if (chunk_size != null || chunk_buf != null)
            {
               asyncError("Invalid chunk");
            }
            else
            {
               asyncComplete(api);
            }


         case ReadEof(api, buf):
            try
            {
               while (true)
               {
                  var len = sock.input.readBytes(buf, 0, buf.length);
                  if (len == 0)
                     return;
                  api.writeBytes(buf, 0, len);
               }
            }
            catch (e:haxe.io.Eof)
            {
               asyncComplete(api);
            }
            catch (e:haxe.io.Error)
            {
               if (e!=Blocked)
                   asyncError("Error reading data " + e);
               return;
            }
            catch (e:Dynamic)
            {
               asyncError("Error reading data " + e);
            }

         case ReadBytes(api, buf, remain):
            try
            {
               while (true)
               {
                  var l = remain[0];
                  if (l>buf.length)
                     l = buf.length;
                  var read = sock.input.readBytes(buf, 0, l);
                  if (read == 0)
                     return;
                  api.writeBytes(buf, 0, read);
                  remain[0] -= read;
                  if (remain[0]==0)
                  {
                     asyncComplete(api);
                     return;
                  }
               }
            }
            catch (e:haxe.io.Eof)
            {
               asyncError("EOF while reading bytes");
               return;
            }
            catch (e:haxe.io.Error)
            {
               if (e!=Blocked)
                  asyncError("Error reading data " + e);
               return;
            }
            catch (e:Dynamic)
            {
               asyncError("Error reading bytes " + e);
               return;
            }
         }
      }
   }



   function pushBody(body:Null<BytesOutput>, fileInput:Null<Input>, fileSize:Int, boundary:Null<String>, jobs: Array<AsyncJob>) {
      if (body != null) {
         var bytes = body.getBytes();
         jobs.push( WriteBytes(bytes,bytes.length,[0]) );
         //sock.output.writeFullBytes(bytes, 0, bytes.length);
      }
      if (boundary != null) {
         var bufsize = 4096;
         var buf = haxe.io.Bytes.alloc(bufsize);
         while (fileSize > 0) {
            var size = if (fileSize > bufsize) bufsize else fileSize;
            var len = 0;
            try {
               len = fileInput.readBytes(buf, 0, size);
            } catch (e:haxe.io.Eof)
               break;
            jobs.push( WriteBytes(buf,len,[0]) );
            //sock.output.writeFullBytes(buf, 0, len);
            fileSize -= len;
         }
         var str = "\r\n" + "--" + boundary + "--";
         var bytes = Bytes.ofString(str);
         jobs.push( WriteBytes(bytes,bytes.length,[0]) );

         //sock.output.writeString("\r\n");
         //sock.output.writeString("--");
         //sock.output.writeString(boundary);
         //sock.output.writeString("--");
      }
   }

}

