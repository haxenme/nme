package nme.net.http;

import sys.net.Socket;
import haxe.io.Bytes;
#if haxe4
import sys.thread.Thread;
import sys.thread.Lock;
#elseif cpp
import cpp.vm.Thread;
import cpp.vm.Lock;
#elseif neko
import neko.vm.Thread;
import neko.vm.Lock;
#end

typedef Callback = Request -> haxe.io.Bytes;

class Server
{
   #if !flash
   var alive = true;

   public var handler : Callback;
   public function new( inHandler: Callback )
   {
      handler = inHandler;
   }

   public function listen(port:Int, hostname:String="localhost")
   {
      var sock = new Socket();
      sock.bind( new sys.net.Host( hostname ), port );
      sock.listen( 5 );
      Thread.create( function()
      {
         while( alive )
         {
            try
            {
               var connection = sock.accept();
               Thread.create( function()
                  {
                     try{
                        while( process(connection) )
                        {
                           // Can't re-use connection because we rely on reading all the data.
                           break;
                        }
                        connection.close();
                     }
                     catch(e:Dynamic)
                     {
                        trace("Error processing event:" + e);
                        connection.close();
                     }
                  }
               );
            }
            catch(e:Dynamic)
               trace(e);
         }
      } );
   }

   function process(connection:Socket) : Bool
   {
      var allBytes = [];
      var input = connection.input;
      var output = connection.output;

      var count = 0;
      var buffer = Bytes.alloc(1024);
      var partialLine = "";
      var headers = new haxe.ds.StringMap<String>();
      var body:String = null;
      var contentLength = 0;
      var url:String=null;
      var method:String=null;
      var version:String=null;

      while(true)
      {
         try
         {
            var read = input.readBytes( buffer, 0, 1024 );
            if (read==0)
               break;
            count += read;
            if (read<1024)
               partialLine +=  buffer.sub(0,read).toString();
            else
               partialLine += buffer.toString();

            var parts = partialLine.split("\r\n");
            if (parts.length>1)
            {
               partialLine = parts.pop();
               for(i in 0...parts.length)
               {
                  var line = parts[i];
                  if (line=="")
                  {
                     body = parts.slice(i+1).join("\r\n") + partialLine;
                     partialLine = null;
                     var remaining = contentLength-body.length;
                     if (remaining>0)
                     {
                        if (remaining>1024)
                           buffer = Bytes.alloc(remaining);

                        var read = input.readBytes( buffer, 0, remaining );
                        if (remaining>=1024)
                           body += buffer.toString();
                        else
                           body += buffer.sub(0,remaining).toString();
                     }
                     break;
                  }
                  else
                  {
                     if (url==null)
                     {
                        var reqs = parts[i].split(" ");
                        method = reqs[0];
                        url = StringTools.urlDecode(reqs[1]);
                        version = reqs[2];
                     }
                     else
                     {
                        var col = line.indexOf(':');
                        if (col>0)
                        {
                           var key = line.substr(0,col);
                           var value = line.substr(col+2);
                           if (key=="Content-Length")
                              contentLength = Std.parseInt(value);
                           headers.set(key,value);
                        }
                    }
                  }
               }
               if (body!=null)
                  break;
            }
         }
         catch(e:Dynamic)
         {
            break;
         }
      }

      if (url==null)
         return false;

      var request = new Request(headers, body);
      request.url = url;
      request.version = version;
      request.method = method;

      var bytes = handler(request);
      var len = output.writeBytes(bytes, 0, bytes.length);

      return request.isKeepAlive();
   }

   public function untilDeath()
   {
      while(alive)
         Sys.sleep(1);
   }
   #end
}

