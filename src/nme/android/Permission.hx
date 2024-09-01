package nme.android;

import nme.JNI;

import nme.android.PermissionType;

@:nativeProperty
class Permission
{
   public static var BLUETOOTH_SCAN = "android.permission.BLUETOOTH_SCAN";
   public static var BLUETOOTH_CONNECT = "android.permission.BLUETOOTH_CONNECT";


   public static function getPermission(permission:String) : PermissionType
   {
      #if android
      var code = sHasPermission(permission);
      switch(code)
      {
         case 0: return PermissionGranted;
         case 1: return PermissionShowRationaleToRequest;
         case 2: return PermissionRequestNeeded;
         default:
            throw "Unknown permission code:" + code;
      }
      #else
      return PermissionDenied;
      #end
   }

   public static function requestPermission(permission:String, onPermission:PermissionType->Void)
   {
      #if android
      sRequestPermission(permission, {
         onGrant: () -> onPermission(PermissionGranted),
         onDeny: () -> onPermission(PermissionDenied),
      });
      #end
   }

   public static function requestPermissions(permissions:Array<String>, onPermission:String->Bool->Void)
   {
      #if android
      sRequestPermissions(permissions, {
         onGrant: (p) -> onPermission(p,true),
         onDeny: (p) -> onPermission(p,false),
      });
      #end
   }


   #if android
   static var sHasPermission = JNI.createStaticMethod("org/haxe/nme/GameActivity", "hasPermission", "(Ljava/lang/String;)I");

   static var sRequestPermission = JNI.createStaticMethod("org/haxe/nme/GameActivity", "requestPermission", "(Ljava/lang/String;Lorg/haxe/nme/HaxeObject;)V");
   static var sRequestPermissions = JNI.createStaticMethod("org/haxe/nme/GameActivity", "requestPermissions", "([Ljava/lang/String;Lorg/haxe/nme/HaxeObject;)V");
   #end
}


