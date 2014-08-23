package nme.android;

import nme.JNI;

class Bluetooth
{
   static var adapter:Dynamic;
   var handle:Dynamic;


   public var portName(default,null):String;
   public var baud(default,null):Int;
   public var isSetup(default,null):Bool;

	   
   public function new(inPortName:String, ?baud:Int = 9600, ?setupImmediately:Bool = false)
   {
      portName = inPortName;
      baud = 57600;

      trace("JNI...");
      trace(adapter);

      isSetup = true;
   }

   static public function getDeviceList():Array<String>
   {
      if (adapter==null && create!=null)
         adapter = create();

      if (adapter!=null)
      {
         getDevices(adapter);
      }
      return [];
   }

   public function setup():Bool  return adapter!=null;

   public function writeBytes(buffer:String):Int
   {
      return 0;
   }

   public function readBytes(length:Int):String return "";

   public function writeByte(byte:Int):Bool return false;

   public function readByte():Int return 0;

   public function flush(?flushIn:Bool = false, ?flushOut = false):Void return;

   public function available():Int return 0;

   public function close():Int
   {
      return 0;
   }

   static var create = JNI.createStaticMethod("org.haxe.nme.Bluetooth", "create", "()Lorg/haxe/nme/Bluetooth;");
   static var getDevices = JNI.createMemberMethod("org.haxe.nme.Bluetooth", "getDevices", "()V");
}

