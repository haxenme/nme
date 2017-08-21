package nme.script;

import sys.net.Host;
import sys.net.Socket;


class Client
{
   static var socket:Socket;
   static var toSocket:haxe.io.Output;
   static var fromSocket:haxe.io.Input;
   public static var log:String->Void;
   public static var error:String->Void;


   public static function sendCommand(inCommand:Array<String>)
   {
      var message = "shell";
      toSocket.writeInt32(message.length);
      toSocket.writeString(message);

      toSocket.writeInt32(inCommand.length);
      for(c in inCommand)
      { 
         toSocket.writeInt32(c.length);
         toSocket.writeString(c);
      }
      var len = fromSocket.readInt32();
      return fromSocket.readString(len);
   }

   public static function parseInput() : Array<String>
   {
      Sys.print("=>");
      try
      {
         var line = Sys.stdin().readLine();
         var word:String;
         var result = new Array<String>();
         var pos = 0;
         while(pos<line.length)
         {
            var ch = line.charAt(pos++);
            if (ch!=" " && ch!="\t")
            {
               var quotes = false;
               var word = "";
               while(true)
               {
                  if (ch=="\\")
                  {
                     if (pos==line.length)
                     {
                        Sys.println("Bad trailing \\");
                        return [];
                     }
                     word += line.charAt(pos++);
                  }
                  else
                  {
                     if (ch=='"')
                        quotes = !quotes;
                     word += ch;
                  }

                  if (pos==line.length)
                  {
                     if (quotes)
                     {
                        Sys.println("Unmatched quotes");
                        return [];
                     }
                     result.push(word);
                     break;
                  }
                  ch = line.charAt(pos++);
                  if ( (ch==" " || ch=="\t") && !quotes)
                  {
                     result.push(word);
                     break;
                  }
               }
            }
         }
         return result;
      }
      catch(e:Dynamic)
      {
         // EOF
      }
      return ["q"];
   }

   public static function shell( inHostName:String, inCommand:Array<String>,?inDefaultPackageName:String)
   {
      try
      {
         var parts = inHostName.split("@");
         var hostName = parts.pop();
         var password = parts.join("@");
         trace("HOST  " + hostName);
         trace("pass  " + password);
         var host = new Host(hostName);
         if (log!=null)
            log("Connect to host " + host);

         socket = new Socket();

         socket.connect(host, 0xacad);
         toSocket = socket.output;
         fromSocket = socket.input;

         if (password!="")
         {
            var len = fromSocket.readInt32();
            var hash = fromSocket.readString(len);
            var response = haxe.crypto.Md5.encode( password + hash );
            toSocket.writeInt32(response.length);
            toSocket.writeString(response);
         }

         if (inDefaultPackageName!=null && inDefaultPackageName!="")
            sendCommand(["set","package",inDefaultPackageName]);

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
                  var response = sendCommand(command);
                  Sys.println(response);
               }
            }

         socket.close();
      }
      catch(e:Dynamic)
      {
         if (error!=null)
            error("No connection to " + inHostName + " : " + e );
      }
   }
}


