package nme.net.http;

import sys.net.Socket;
import haxe.io.Bytes;
#if cpp
import cpp.vm.Thread;
import cpp.vm.Lock;
import cpp.net.Poll;
#elseif neko
import neko.vm.Thread;
import neko.vm.Lock;
import neko.net.Poll;
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
                           // break
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
      while(true)
      {
         var buffer = Bytes.alloc(1024);
         try
         {
            var read = input.readBytes( buffer, 0, 1024 );
            count += read;
            if (read<1024)
            {
               if (read>0)
                  allBytes.push( buffer.sub(0,read) );
               break;
            }
            allBytes.push(buffer);
         }
         catch(e:Dynamic)
         {
            break;
         }
      }

      if (count<1)
         return false;

      var total = Bytes.alloc(count);
      var pos = 0;
      for(s in allBytes)
      {
         total.blit(pos,s,0,s.length);
         pos += s.length;
      }
      var request = new Request(total);
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

