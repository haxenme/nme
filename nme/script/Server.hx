package nme.script;

import nme.filesystem.File;
import nme.system.System;
import nme.utils.ByteArray;
import nme.events.Event;
import sys.net.Host;
import sys.net.Socket;
import cpp.vm.Thread;
import cpp.vm.Deque;
import Sys;

using StringTools;


class Server
{
   public var connectedHost(default,null):String;
   public var directory(default,null):String;
   public var restartOnScript:Bool;

   var script:String;
   var socket:Socket;
   var connectionStatus:String;
   var doLog:String->Void;
   var deque:Deque<Void->Void>;

   public function new(inEngineName:String, ?inDirectory:String, ?inLog:String->Void)
   {
      doLog = inLog;
      restartOnScript = false;
      connectionStatus = "Not connected";
      connectedHost = null;
      setDir(inEngineName,inDirectory);
      deque = new Deque<Void->Void>();
   }

   public function pollQueue() : Void->Void
   {
      return deque.pop(false);
   }

   function log(inString:String)
   {
      if (doLog!=null)
         doLog(inString);
   }

   function setDir(inEngineName:String, inDirectory:String)
   {
      directory = inDirectory;
      if (directory==null || directory=="")
      {
         directory = null;
         var host = nme.system.System.systemName();
         if (host=="android")
         {
            directory = "/mnt/sdcard/" + inEngineName;
            try
            {
               if (!sys.FileSystem.exists(directory))
                  sys.FileSystem.createDirectory(directory);
            }
            catch(e:Dynamic)
            {
               directory = null;
            }
         }
         if (directory==null)
         {
            var docsDir = nme.filesystem.File.documentsDirectory.nativePath;
            directory = sys.FileSystem.fullPath( docsDir ) +  "/" + inEngineName;
            try
               sys.FileSystem.createDirectory(directory)
            catch(e:Dynamic) {
               directory = null;
            }
         }
      }
   }

   function handleConnection(connection:Socket)
   {
      try
      {
         var fromSocket = connection.input;
         var toSocket = connection.output;

         while(true)
         {
            var len = fromSocket.readInt32();
            if (len==0)
               break;
            var command = fromSocket.readString(len);
            log("command : " + command);
            if (command=="bye")
            {
               break;
            }
            else if (command=="run")
            {
               var len = fromSocket.readInt32();
               var app = fromSocket.readString(len);
               log("Run " + app);
               var message = restartOnScript ? "restart" : "ok";
               toSocket.writeInt32(message.length);
               toSocket.writeString(message);
               var fullPath = directory+"/"+app+"/ScriptMain.cppia";
               log("fullPath " + fullPath);

               if (restartOnScript)
               {
                  connection.close();
                  // Restart
                  #if android
                  nme.system.System.restart();
                  #else
                  var exeName = nme.system.System.exeName;
                  var host = nme.system.System.systemName();
                  log("Restart " + exeName + " on " + host);
                  if (host=="mac")
                  {
                     var parts = exeName.split(".app");
                     if (parts.length>1)
                        exeName = parts[0] + ".app";
                     Sys.command("/usr/bin/open", ["-n", "-a", exeName, "--args", fullPath]);
                  }
                  else if (host=="linux")
                      Sys.command("/usr/bin/xdg-open", [exeName,fullPath]);
                  else
                      Sys.command(exeName,[fullPath]);
                  #end

                  if (socket!=null)
                  {
                     log("Closing socket");
                     try socket.close() catch(e:Dynamic) { }
                  }
                  Sys.exit(0);
               }
               else
               {
                  restartOnScript = true;
                  deque.push( function() Nme.runFile(fullPath) );
               }
            }
            else if (command=="put")
            {
               var len = fromSocket.readInt32();
               var to = fromSocket.readString(len);
               var dataLen = fromSocket.readInt32();
               var bytes = fromSocket.read(dataLen);
               log("Write " + to + " bytes :" + bytes.length);

               try
               {
                  to = to.split("\\").join("/");
                  var parts = to.split("/");
                  if (parts.length>1)
                  {
                     parts.pop();
                     var path = directory;
                     for(part in parts)
                     {
                        path += "/" + part;
                        if (!sys.FileSystem.exists(path))
                           sys.FileSystem.createDirectory(path);
                     }
                  }

                  sys.io.File.saveBytes(directory + "/" + to, bytes);
                  toSocket.writeInt32(2);
                  toSocket.writeString("ok");
               }
               catch(e:Dynamic)
               {
                  var err:String = e.toString();
                  toSocket.writeInt32(err.length);
                  toSocket.writeString(err);
               }
            }
            else if (command=="pull")
            {
               var len = fromSocket.readInt32();
               var from = fromSocket.readString(len);
               trace("Pull " + from );

               try
               {
                  from = from.split("\\").join("/");
                  var parts = from.split("/");

                  var bytes = sys.io.File.getBytes(directory + "/" + from);
                  if (bytes==null)
                     throw "no file";

                  toSocket.writeInt32(bytes.length);
                  toSocket.writeBytes(bytes,0,bytes.length);
                  trace("Sent " + from + " bytes :" + bytes.length);
               }
               catch(e:Dynamic)
               {
                  trace("Missing " + from );
                  toSocket.writeInt32(-1);
               }
            }
            else
            {
               log("Unknown command: " + command);
               break;
            }
         }
      }
      catch(e:Dynamic)
      {
         log("Socket done : " + e);
      }
      try
      {
         connection.close();
      }
      catch(e:Dynamic)
      {
         log("Socket closed : " + e);
      }
   }

   public function start()
   {
      var hostName = nme.system.System.getLocalIpAddress();
      var host = new sys.net.Host(hostName);
      log(" Listening on " + host + " (" + hostName + ")");
      connectionStatus = "Create socket";
      socket = new Socket();
      try
      {
         socket.bind(host,0xacad);
         socket.listen(1);
         connectionStatus = "Connected";
         connectedHost = host.toString();
      }
      catch(e:Dynamic)
      {
         socket.close();
         socket = null;
            connectionStatus = "Could not bind " + host.toString();
      }

      if (socket!=null)
      {
         Thread.create( function() {
            while(true)
            {
               log("Wait connection...");
               var connection = socket.accept();
               log("got connection");
               connection.setBlocking(true);
               handleConnection(connection);
            }
         });
      }
   }
}

