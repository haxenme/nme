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

typedef Callback = Request -> Response -> Void;

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
            trace("listen...");
            try
            {
               var connection = sock.accept();
               Thread.create( function()
                  {
                     try{
                        process(connection);
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

   function process(connection:Socket)
   {
      var allBytes = [];
      var input = connection.input;

      while(true)
      {
         var buffer = Bytes.alloc(1024);
         var read = 0;
         try {
            read = input.readBytes( buffer, 0, 1024 );
            if (read<1024)
            {
               allBytes.push( buffer.sub(0,read) );
               break;
            }
            allBytes.push(buffer);
         } catch(e:Dynamic) {
            break;
         }
         trace(read);
      }
      trace("Done " + allBytes.length);
      trace(allBytes);
   }

   public function untilDeath()
   {
      while(alive)
         Sys.sleep(1);
   }
   #end
}

