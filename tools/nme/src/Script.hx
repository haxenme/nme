import sys.net.Host;
import sys.net.Socket;


class Script
{
   static var socket:Socket;
   static var toSocket:haxe.io.Output;
   static var fromSocket:haxe.io.Input;

   public static function sendCommand(inCommand:Array<String>)
   {
      var message = "command";
      toSocket.writeInt32(message.length);
      toSocket.writeString(message);

      toSocket.writeInt32(inCommand.length);
      for(c in inCommand)
      { 
         toSocket.writeInt32(c.length);
         toSocket.writeString(c);
      }
      var len = fromSocket.readInt32();
      var message = fromSocket.readString(len);
      Sys.println(message);
   }

   public static function parseInput() : Array<String>
   {
      return ["q"];
   }

   public static function shell(inPackageName:String, inHost:String, inCommand:Array<String>)
   {
      var host = new Host(inHost);
      Log.verbose("Connect to host " + inHost);
      try
      {
         socket = new Socket();

         socket.connect(host, 0xacad);
         toSocket = socket.output;
         fromSocket = socket.input;

         if (inCommand!=null && inCommand.length>0)
            sendCommand(inCommand);
         else
            while(true)
            {
               var command = parseInput();
               if (command.length>0)
               {
                  if (command[0]=="exit" || command[0]=="quit" || command[0]=="q")
                     break;
                  sendCommand(inCommand);
               }
            }

         socket.close();
      }
      catch(e:Dynamic)
      {
         Log.error("Could not connect to " + host + " : " + e );
      }
   }
}


