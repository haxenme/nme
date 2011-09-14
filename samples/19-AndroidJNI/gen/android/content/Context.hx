package android.content;
class Context
{
   var __jobject:Dynamic;

   static inline public var MODE_PRIVATE:Int = 0;
   static inline public var MODE_WORLD_READABLE:Int = 1;
   static inline public var MODE_WORLD_WRITEABLE:Int = 2;
   static inline public var MODE_APPEND:Int = 32768;
   static inline public var BIND_AUTO_CREATE:Int = 1;
   static inline public var BIND_DEBUG_UNBIND:Int = 2;
   static inline public var BIND_NOT_FOREGROUND:Int = 4;
   static inline public var POWER_SERVICE:String = "power";
   static inline public var WINDOW_SERVICE:String = "window";
   static inline public var LAYOUT_INFLATER_SERVICE:String = "layout_inflater";
   static inline public var ACCOUNT_SERVICE:String = "account";
   static inline public var ACTIVITY_SERVICE:String = "activity";
   static inline public var ALARM_SERVICE:String = "alarm";
   static inline public var NOTIFICATION_SERVICE:String = "notification";
   static inline public var ACCESSIBILITY_SERVICE:String = "accessibility";
   static inline public var KEYGUARD_SERVICE:String = "keyguard";
   static inline public var LOCATION_SERVICE:String = "location";
   static inline public var SEARCH_SERVICE:String = "search";
   static inline public var SENSOR_SERVICE:String = "sensor";
   static inline public var WALLPAPER_SERVICE:String = "wallpaper";
   static inline public var VIBRATOR_SERVICE:String = "vibrator";
   static inline public var CONNECTIVITY_SERVICE:String = "connectivity";
   static inline public var WIFI_SERVICE:String = "wifi";
   static inline public var AUDIO_SERVICE:String = "audio";
   static inline public var TELEPHONY_SERVICE:String = "phone";
   static inline public var CLIPBOARD_SERVICE:String = "clipboard";
   static inline public var INPUT_METHOD_SERVICE:String = "input_method";
   static inline public var DROPBOX_SERVICE:String = "dropbox";
   static inline public var DEVICE_POLICY_SERVICE:String = "device_policy";
   static inline public var UI_MODE_SERVICE:String = "uimode";
   static inline public var CONTEXT_INCLUDE_CODE:Int = 1;
   static inline public var CONTEXT_IGNORE_SECURITY:Int = 2;
   static inline public var CONTEXT_RESTRICTED:Int = 4;

   static var __create_func:Dynamic;
   public static function _create() : android.content.Context
   {
      if (__create_func==null)
         __create_func=nme.JNI.createStaticMethod("android.content.Context","<init>","()V");
      return new android.content.Context(nme.JNI.callStatic(__create_func,[]));
   }

   public function new(handle:Dynamic) { __jobject = handle; }
   static var _getAssets_func:Dynamic;
   public function getAssets() : Dynamic
   {
      if (_getAssets_func==null)
         _getAssets_func=nme.JNI.createMemberMethod("android.content.Context","getAssets","()Landroid/content/res/AssetManager;");
      return nme.JNI.callMember(_getAssets_func,__jobject,[]);
   }

   static var _getResources_func:Dynamic;
   public function getResources() : Dynamic
   {
      if (_getResources_func==null)
         _getResources_func=nme.JNI.createMemberMethod("android.content.Context","getResources","()Landroid/content/res/Resources;");
      return nme.JNI.callMember(_getResources_func,__jobject,[]);
   }

   static var _getPackageManager_func:Dynamic;
   public function getPackageManager() : Dynamic
   {
      if (_getPackageManager_func==null)
         _getPackageManager_func=nme.JNI.createMemberMethod("android.content.Context","getPackageManager","()Landroid/content/pm/PackageManager;");
      return nme.JNI.callMember(_getPackageManager_func,__jobject,[]);
   }

   static var _getContentResolver_func:Dynamic;
   public function getContentResolver() : Dynamic
   {
      if (_getContentResolver_func==null)
         _getContentResolver_func=nme.JNI.createMemberMethod("android.content.Context","getContentResolver","()Landroid/content/ContentResolver;");
      return nme.JNI.callMember(_getContentResolver_func,__jobject,[]);
   }

   static var _getMainLooper_func:Dynamic;
   public function getMainLooper() : Dynamic
   {
      if (_getMainLooper_func==null)
         _getMainLooper_func=nme.JNI.createMemberMethod("android.content.Context","getMainLooper","()Landroid/os/Looper;");
      return nme.JNI.callMember(_getMainLooper_func,__jobject,[]);
   }

   static var _getApplicationContext_func:Dynamic;
   public function getApplicationContext() : Dynamic
   {
      if (_getApplicationContext_func==null)
         _getApplicationContext_func=nme.JNI.createMemberMethod("android.content.Context","getApplicationContext","()Landroid/content/Context;");
      return nme.JNI.callMember(_getApplicationContext_func,__jobject,[]);
   }

   static var _getText_func:Dynamic;
   public function getText(arg0:Int) : Dynamic
   {
      if (_getText_func==null)
         _getText_func=nme.JNI.createMemberMethod("android.content.Context","getText","(I)Ljava/lang/CharSequence;");
      return nme.JNI.callMember(_getText_func,__jobject,[arg0]);
   }

   static var _getString_func:Dynamic;
   public function getString(arg0:Int) : Dynamic
   {
      if (_getString_func==null)
         _getString_func=nme.JNI.createMemberMethod("android.content.Context","getString","(I)Ljava/lang/String;");
      return nme.JNI.callMember(_getString_func,__jobject,[arg0]);
   }

   static var _getString1_func:Dynamic;
   public function getString1(arg0:Int,arg1:Array< Dynamic /*java.lang.Object*/ >,arg2:Dynamic /*java.lang.Object*/) : Dynamic
   {
      if (_getString1_func==null)
         _getString1_func=nme.JNI.createMemberMethod("android.content.Context","getString","(I[Ljava/lang/Object;)Ljava/lang/String;");
      return nme.JNI.callMember(_getString1_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _setTheme_func:Dynamic;
   public function setTheme(arg0:Int) : Dynamic
   {
      if (_setTheme_func==null)
         _setTheme_func=nme.JNI.createMemberMethod("android.content.Context","setTheme","(I)V");
      nme.JNI.callMember(_setTheme_func,__jobject,[arg0]);
   }

   static var _getTheme_func:Dynamic;
   public function getTheme() : Dynamic
   {
      if (_getTheme_func==null)
         _getTheme_func=nme.JNI.createMemberMethod("android.content.Context","getTheme","()Landroid/content/res/Resources$Theme;");
      return nme.JNI.callMember(_getTheme_func,__jobject,[]);
   }

   static var _obtainStyledAttributes_func:Dynamic;
   public function obtainStyledAttributes(arg0:Array< Int >,arg1:Int) : Dynamic
   {
      if (_obtainStyledAttributes_func==null)
         _obtainStyledAttributes_func=nme.JNI.createMemberMethod("android.content.Context","obtainStyledAttributes","([I)Landroid/content/res/TypedArray;");
      return nme.JNI.callMember(_obtainStyledAttributes_func,__jobject,[arg0,arg1]);
   }

   static var _obtainStyledAttributes1_func:Dynamic;
   public function obtainStyledAttributes1(arg0:Int,arg1:Array< Int >,arg2:Int) : Dynamic
   {
      if (_obtainStyledAttributes1_func==null)
         _obtainStyledAttributes1_func=nme.JNI.createMemberMethod("android.content.Context","obtainStyledAttributes","(I[I)Landroid/content/res/TypedArray;");
      return nme.JNI.callMember(_obtainStyledAttributes1_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _obtainStyledAttributes2_func:Dynamic;
   public function obtainStyledAttributes2(arg0:Dynamic /*android.util.AttributeSet*/,arg1:Array< Int >,arg2:Int) : Dynamic
   {
      if (_obtainStyledAttributes2_func==null)
         _obtainStyledAttributes2_func=nme.JNI.createMemberMethod("android.content.Context","obtainStyledAttributes","(Landroid/util/AttributeSet;[I)Landroid/content/res/TypedArray;");
      return nme.JNI.callMember(_obtainStyledAttributes2_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _obtainStyledAttributes3_func:Dynamic;
   public function obtainStyledAttributes3(arg0:Dynamic /*android.util.AttributeSet*/,arg1:Array< Int >,arg2:Int,arg3:Int,arg4:Int,arg5:Int,arg6:Int) : Dynamic
   {
      if (_obtainStyledAttributes3_func==null)
         _obtainStyledAttributes3_func=nme.JNI.createMemberMethod("android.content.Context","obtainStyledAttributes","(Landroid/util/AttributeSet;[III)Landroid/content/res/TypedArray;");
      return nme.JNI.callMember(_obtainStyledAttributes3_func,__jobject,[arg0,arg1,arg2,arg3,arg4,arg5,arg6]);
   }

   static var _getClassLoader_func:Dynamic;
   public function getClassLoader() : Dynamic
   {
      if (_getClassLoader_func==null)
         _getClassLoader_func=nme.JNI.createMemberMethod("android.content.Context","getClassLoader","()Ljava/lang/ClassLoader;");
      return nme.JNI.callMember(_getClassLoader_func,__jobject,[]);
   }

   static var _getPackageName_func:Dynamic;
   public function getPackageName() : Dynamic
   {
      if (_getPackageName_func==null)
         _getPackageName_func=nme.JNI.createMemberMethod("android.content.Context","getPackageName","()Ljava/lang/String;");
      return nme.JNI.callMember(_getPackageName_func,__jobject,[]);
   }

   static var _getApplicationInfo_func:Dynamic;
   public function getApplicationInfo() : Dynamic
   {
      if (_getApplicationInfo_func==null)
         _getApplicationInfo_func=nme.JNI.createMemberMethod("android.content.Context","getApplicationInfo","()Landroid/content/pm/ApplicationInfo;");
      return nme.JNI.callMember(_getApplicationInfo_func,__jobject,[]);
   }

   static var _getPackageResourcePath_func:Dynamic;
   public function getPackageResourcePath() : Dynamic
   {
      if (_getPackageResourcePath_func==null)
         _getPackageResourcePath_func=nme.JNI.createMemberMethod("android.content.Context","getPackageResourcePath","()Ljava/lang/String;");
      return nme.JNI.callMember(_getPackageResourcePath_func,__jobject,[]);
   }

   static var _getPackageCodePath_func:Dynamic;
   public function getPackageCodePath() : Dynamic
   {
      if (_getPackageCodePath_func==null)
         _getPackageCodePath_func=nme.JNI.createMemberMethod("android.content.Context","getPackageCodePath","()Ljava/lang/String;");
      return nme.JNI.callMember(_getPackageCodePath_func,__jobject,[]);
   }

   static var _getSharedPreferences_func:Dynamic;
   public function getSharedPreferences(arg0:String,arg1:Int) : Dynamic
   {
      if (_getSharedPreferences_func==null)
         _getSharedPreferences_func=nme.JNI.createMemberMethod("android.content.Context","getSharedPreferences","(Ljava/lang/String;I)Landroid/content/SharedPreferences;");
      return nme.JNI.callMember(_getSharedPreferences_func,__jobject,[arg0,arg1]);
   }

   static var _openFileInput_func:Dynamic;
   public function openFileInput(arg0:String) : Dynamic
   {
      if (_openFileInput_func==null)
         _openFileInput_func=nme.JNI.createMemberMethod("android.content.Context","openFileInput","(Ljava/lang/String;)Ljava/io/FileInputStream;");
      return nme.JNI.callMember(_openFileInput_func,__jobject,[arg0]);
   }

   static var _openFileOutput_func:Dynamic;
   public function openFileOutput(arg0:String,arg1:Int) : Dynamic
   {
      if (_openFileOutput_func==null)
         _openFileOutput_func=nme.JNI.createMemberMethod("android.content.Context","openFileOutput","(Ljava/lang/String;I)Ljava/io/FileOutputStream;");
      return nme.JNI.callMember(_openFileOutput_func,__jobject,[arg0,arg1]);
   }

   static var _deleteFile_func:Dynamic;
   public function deleteFile(arg0:String) : Dynamic
   {
      if (_deleteFile_func==null)
         _deleteFile_func=nme.JNI.createMemberMethod("android.content.Context","deleteFile","(Ljava/lang/String;)Z");
      return nme.JNI.callMember(_deleteFile_func,__jobject,[arg0]);
   }

   static var _getFileStreamPath_func:Dynamic;
   public function getFileStreamPath(arg0:String) : Dynamic
   {
      if (_getFileStreamPath_func==null)
         _getFileStreamPath_func=nme.JNI.createMemberMethod("android.content.Context","getFileStreamPath","(Ljava/lang/String;)Ljava/io/File;");
      return nme.JNI.callMember(_getFileStreamPath_func,__jobject,[arg0]);
   }

   static var _getFilesDir_func:Dynamic;
   public function getFilesDir() : Dynamic
   {
      if (_getFilesDir_func==null)
         _getFilesDir_func=nme.JNI.createMemberMethod("android.content.Context","getFilesDir","()Ljava/io/File;");
      return nme.JNI.callMember(_getFilesDir_func,__jobject,[]);
   }

   static var _getExternalFilesDir_func:Dynamic;
   public function getExternalFilesDir(arg0:String) : Dynamic
   {
      if (_getExternalFilesDir_func==null)
         _getExternalFilesDir_func=nme.JNI.createMemberMethod("android.content.Context","getExternalFilesDir","(Ljava/lang/String;)Ljava/io/File;");
      return nme.JNI.callMember(_getExternalFilesDir_func,__jobject,[arg0]);
   }

   static var _getCacheDir_func:Dynamic;
   public function getCacheDir() : Dynamic
   {
      if (_getCacheDir_func==null)
         _getCacheDir_func=nme.JNI.createMemberMethod("android.content.Context","getCacheDir","()Ljava/io/File;");
      return nme.JNI.callMember(_getCacheDir_func,__jobject,[]);
   }

   static var _getExternalCacheDir_func:Dynamic;
   public function getExternalCacheDir() : Dynamic
   {
      if (_getExternalCacheDir_func==null)
         _getExternalCacheDir_func=nme.JNI.createMemberMethod("android.content.Context","getExternalCacheDir","()Ljava/io/File;");
      return nme.JNI.callMember(_getExternalCacheDir_func,__jobject,[]);
   }

   static var _fileList_func:Dynamic;
   public function fileList() : Dynamic
   {
      if (_fileList_func==null)
         _fileList_func=nme.JNI.createMemberMethod("android.content.Context","fileList","()[Ljava/lang/String;");
      return nme.JNI.callMember(_fileList_func,__jobject,[]);
   }

   static var _getDir_func:Dynamic;
   public function getDir(arg0:String,arg1:Int) : Dynamic
   {
      if (_getDir_func==null)
         _getDir_func=nme.JNI.createMemberMethod("android.content.Context","getDir","(Ljava/lang/String;I)Ljava/io/File;");
      return nme.JNI.callMember(_getDir_func,__jobject,[arg0,arg1]);
   }

   static var _openOrCreateDatabase_func:Dynamic;
   public function openOrCreateDatabase(arg0:String,arg1:Int,arg2:Dynamic /*android.database.sqlite.SQLiteDatabase$CursorFactory*/) : Dynamic
   {
      if (_openOrCreateDatabase_func==null)
         _openOrCreateDatabase_func=nme.JNI.createMemberMethod("android.content.Context","openOrCreateDatabase","(Ljava/lang/String;ILandroid/database/sqlite/SQLiteDatabase$CursorFactory;)Landroid/database/sqlite/SQLiteDatabase;");
      return nme.JNI.callMember(_openOrCreateDatabase_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _deleteDatabase_func:Dynamic;
   public function deleteDatabase(arg0:String) : Dynamic
   {
      if (_deleteDatabase_func==null)
         _deleteDatabase_func=nme.JNI.createMemberMethod("android.content.Context","deleteDatabase","(Ljava/lang/String;)Z");
      return nme.JNI.callMember(_deleteDatabase_func,__jobject,[arg0]);
   }

   static var _getDatabasePath_func:Dynamic;
   public function getDatabasePath(arg0:String) : Dynamic
   {
      if (_getDatabasePath_func==null)
         _getDatabasePath_func=nme.JNI.createMemberMethod("android.content.Context","getDatabasePath","(Ljava/lang/String;)Ljava/io/File;");
      return nme.JNI.callMember(_getDatabasePath_func,__jobject,[arg0]);
   }

   static var _databaseList_func:Dynamic;
   public function databaseList() : Dynamic
   {
      if (_databaseList_func==null)
         _databaseList_func=nme.JNI.createMemberMethod("android.content.Context","databaseList","()[Ljava/lang/String;");
      return nme.JNI.callMember(_databaseList_func,__jobject,[]);
   }

   static var _getWallpaper_func:Dynamic;
   public function getWallpaper() : Dynamic
   {
      if (_getWallpaper_func==null)
         _getWallpaper_func=nme.JNI.createMemberMethod("android.content.Context","getWallpaper","()Landroid/graphics/drawable/Drawable;");
      return nme.JNI.callMember(_getWallpaper_func,__jobject,[]);
   }

   static var _peekWallpaper_func:Dynamic;
   public function peekWallpaper() : Dynamic
   {
      if (_peekWallpaper_func==null)
         _peekWallpaper_func=nme.JNI.createMemberMethod("android.content.Context","peekWallpaper","()Landroid/graphics/drawable/Drawable;");
      return nme.JNI.callMember(_peekWallpaper_func,__jobject,[]);
   }

   static var _getWallpaperDesiredMinimumWidth_func:Dynamic;
   public function getWallpaperDesiredMinimumWidth() : Dynamic
   {
      if (_getWallpaperDesiredMinimumWidth_func==null)
         _getWallpaperDesiredMinimumWidth_func=nme.JNI.createMemberMethod("android.content.Context","getWallpaperDesiredMinimumWidth","()I");
      return nme.JNI.callMember(_getWallpaperDesiredMinimumWidth_func,__jobject,[]);
   }

   static var _getWallpaperDesiredMinimumHeight_func:Dynamic;
   public function getWallpaperDesiredMinimumHeight() : Dynamic
   {
      if (_getWallpaperDesiredMinimumHeight_func==null)
         _getWallpaperDesiredMinimumHeight_func=nme.JNI.createMemberMethod("android.content.Context","getWallpaperDesiredMinimumHeight","()I");
      return nme.JNI.callMember(_getWallpaperDesiredMinimumHeight_func,__jobject,[]);
   }

   static var _setWallpaper_func:Dynamic;
   public function setWallpaper(arg0:Dynamic /*android.graphics.Bitmap*/) : Dynamic
   {
      if (_setWallpaper_func==null)
         _setWallpaper_func=nme.JNI.createMemberMethod("android.content.Context","setWallpaper","(Landroid/graphics/Bitmap;)V");
      nme.JNI.callMember(_setWallpaper_func,__jobject,[arg0]);
   }

   static var _setWallpaper1_func:Dynamic;
   public function setWallpaper1(arg0:Dynamic /*java.io.InputStream*/) : Dynamic
   {
      if (_setWallpaper1_func==null)
         _setWallpaper1_func=nme.JNI.createMemberMethod("android.content.Context","setWallpaper","(Ljava/io/InputStream;)V");
      nme.JNI.callMember(_setWallpaper1_func,__jobject,[arg0]);
   }

   static var _clearWallpaper_func:Dynamic;
   public function clearWallpaper() : Dynamic
   {
      if (_clearWallpaper_func==null)
         _clearWallpaper_func=nme.JNI.createMemberMethod("android.content.Context","clearWallpaper","()V");
      nme.JNI.callMember(_clearWallpaper_func,__jobject,[]);
   }

   static var _startActivity_func:Dynamic;
   public function startActivity(arg0:Dynamic /*android.content.Intent*/) : Dynamic
   {
      if (_startActivity_func==null)
         _startActivity_func=nme.JNI.createMemberMethod("android.content.Context","startActivity","(Landroid/content/Intent;)V");
      nme.JNI.callMember(_startActivity_func,__jobject,[arg0]);
   }

   static var _startIntentSender_func:Dynamic;
   public function startIntentSender(arg0:Dynamic /*android.content.IntentSender*/,arg1:Dynamic /*android.content.Intent*/,arg2:Int,arg3:Int,arg4:Int) : Dynamic
   {
      if (_startIntentSender_func==null)
         _startIntentSender_func=nme.JNI.createMemberMethod("android.content.Context","startIntentSender","(Landroid/content/IntentSender;Landroid/content/Intent;III)V");
      nme.JNI.callMember(_startIntentSender_func,__jobject,[arg0,arg1,arg2,arg3,arg4]);
   }

   static var _sendBroadcast_func:Dynamic;
   public function sendBroadcast(arg0:Dynamic /*android.content.Intent*/) : Dynamic
   {
      if (_sendBroadcast_func==null)
         _sendBroadcast_func=nme.JNI.createMemberMethod("android.content.Context","sendBroadcast","(Landroid/content/Intent;)V");
      nme.JNI.callMember(_sendBroadcast_func,__jobject,[arg0]);
   }

   static var _sendBroadcast1_func:Dynamic;
   public function sendBroadcast1(arg0:Dynamic /*android.content.Intent*/,arg1:String) : Dynamic
   {
      if (_sendBroadcast1_func==null)
         _sendBroadcast1_func=nme.JNI.createMemberMethod("android.content.Context","sendBroadcast","(Landroid/content/Intent;Ljava/lang/String;)V");
      nme.JNI.callMember(_sendBroadcast1_func,__jobject,[arg0,arg1]);
   }

   static var _sendOrderedBroadcast_func:Dynamic;
   public function sendOrderedBroadcast(arg0:Dynamic /*android.content.Intent*/,arg1:String) : Dynamic
   {
      if (_sendOrderedBroadcast_func==null)
         _sendOrderedBroadcast_func=nme.JNI.createMemberMethod("android.content.Context","sendOrderedBroadcast","(Landroid/content/Intent;Ljava/lang/String;)V");
      nme.JNI.callMember(_sendOrderedBroadcast_func,__jobject,[arg0,arg1]);
   }

   static var _sendOrderedBroadcast1_func:Dynamic;
   public function sendOrderedBroadcast1(arg0:Dynamic /*android.content.Intent*/,arg1:String,arg2:Dynamic /*android.content.BroadcastReceiver*/,arg3:Dynamic /*android.os.Handler*/,arg4:Int,arg5:String,arg6:Dynamic /*android.os.Bundle*/) : Dynamic
   {
      if (_sendOrderedBroadcast1_func==null)
         _sendOrderedBroadcast1_func=nme.JNI.createMemberMethod("android.content.Context","sendOrderedBroadcast","(Landroid/content/Intent;Ljava/lang/String;Landroid/content/BroadcastReceiver;Landroid/os/Handler;ILjava/lang/String;Landroid/os/Bundle;)V");
      nme.JNI.callMember(_sendOrderedBroadcast1_func,__jobject,[arg0,arg1,arg2,arg3,arg4,arg5,arg6]);
   }

   static var _sendStickyBroadcast_func:Dynamic;
   public function sendStickyBroadcast(arg0:Dynamic /*android.content.Intent*/) : Dynamic
   {
      if (_sendStickyBroadcast_func==null)
         _sendStickyBroadcast_func=nme.JNI.createMemberMethod("android.content.Context","sendStickyBroadcast","(Landroid/content/Intent;)V");
      nme.JNI.callMember(_sendStickyBroadcast_func,__jobject,[arg0]);
   }

   static var _sendStickyOrderedBroadcast_func:Dynamic;
   public function sendStickyOrderedBroadcast(arg0:Dynamic /*android.content.Intent*/,arg1:Dynamic /*android.content.BroadcastReceiver*/,arg2:Dynamic /*android.os.Handler*/,arg3:Int,arg4:String,arg5:Dynamic /*android.os.Bundle*/) : Dynamic
   {
      if (_sendStickyOrderedBroadcast_func==null)
         _sendStickyOrderedBroadcast_func=nme.JNI.createMemberMethod("android.content.Context","sendStickyOrderedBroadcast","(Landroid/content/Intent;Landroid/content/BroadcastReceiver;Landroid/os/Handler;ILjava/lang/String;Landroid/os/Bundle;)V");
      nme.JNI.callMember(_sendStickyOrderedBroadcast_func,__jobject,[arg0,arg1,arg2,arg3,arg4,arg5]);
   }

   static var _removeStickyBroadcast_func:Dynamic;
   public function removeStickyBroadcast(arg0:Dynamic /*android.content.Intent*/) : Dynamic
   {
      if (_removeStickyBroadcast_func==null)
         _removeStickyBroadcast_func=nme.JNI.createMemberMethod("android.content.Context","removeStickyBroadcast","(Landroid/content/Intent;)V");
      nme.JNI.callMember(_removeStickyBroadcast_func,__jobject,[arg0]);
   }

   static var _registerReceiver_func:Dynamic;
   public function registerReceiver(arg0:Dynamic /*android.content.BroadcastReceiver*/,arg1:Dynamic /*android.content.IntentFilter*/) : Dynamic
   {
      if (_registerReceiver_func==null)
         _registerReceiver_func=nme.JNI.createMemberMethod("android.content.Context","registerReceiver","(Landroid/content/BroadcastReceiver;Landroid/content/IntentFilter;)Landroid/content/Intent;");
      return nme.JNI.callMember(_registerReceiver_func,__jobject,[arg0,arg1]);
   }

   static var _registerReceiver1_func:Dynamic;
   public function registerReceiver1(arg0:Dynamic /*android.content.BroadcastReceiver*/,arg1:Dynamic /*android.content.IntentFilter*/,arg2:String,arg3:Dynamic /*android.os.Handler*/) : Dynamic
   {
      if (_registerReceiver1_func==null)
         _registerReceiver1_func=nme.JNI.createMemberMethod("android.content.Context","registerReceiver","(Landroid/content/BroadcastReceiver;Landroid/content/IntentFilter;Ljava/lang/String;Landroid/os/Handler;)Landroid/content/Intent;");
      return nme.JNI.callMember(_registerReceiver1_func,__jobject,[arg0,arg1,arg2,arg3]);
   }

   static var _unregisterReceiver_func:Dynamic;
   public function unregisterReceiver(arg0:Dynamic /*android.content.BroadcastReceiver*/) : Dynamic
   {
      if (_unregisterReceiver_func==null)
         _unregisterReceiver_func=nme.JNI.createMemberMethod("android.content.Context","unregisterReceiver","(Landroid/content/BroadcastReceiver;)V");
      nme.JNI.callMember(_unregisterReceiver_func,__jobject,[arg0]);
   }

   static var _startService_func:Dynamic;
   public function startService(arg0:Dynamic /*android.content.Intent*/) : Dynamic
   {
      if (_startService_func==null)
         _startService_func=nme.JNI.createMemberMethod("android.content.Context","startService","(Landroid/content/Intent;)Landroid/content/ComponentName;");
      return nme.JNI.callMember(_startService_func,__jobject,[arg0]);
   }

   static var _stopService_func:Dynamic;
   public function stopService(arg0:Dynamic /*android.content.Intent*/) : Dynamic
   {
      if (_stopService_func==null)
         _stopService_func=nme.JNI.createMemberMethod("android.content.Context","stopService","(Landroid/content/Intent;)Z");
      return nme.JNI.callMember(_stopService_func,__jobject,[arg0]);
   }

   static var _bindService_func:Dynamic;
   public function bindService(arg0:Dynamic /*android.content.Intent*/,arg1:Dynamic /*android.content.ServiceConnection*/,arg2:Int) : Dynamic
   {
      if (_bindService_func==null)
         _bindService_func=nme.JNI.createMemberMethod("android.content.Context","bindService","(Landroid/content/Intent;Landroid/content/ServiceConnection;I)Z");
      return nme.JNI.callMember(_bindService_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _unbindService_func:Dynamic;
   public function unbindService(arg0:Dynamic /*android.content.ServiceConnection*/) : Dynamic
   {
      if (_unbindService_func==null)
         _unbindService_func=nme.JNI.createMemberMethod("android.content.Context","unbindService","(Landroid/content/ServiceConnection;)V");
      nme.JNI.callMember(_unbindService_func,__jobject,[arg0]);
   }

   static var _startInstrumentation_func:Dynamic;
   public function startInstrumentation(arg0:Dynamic /*android.content.ComponentName*/,arg1:String,arg2:Dynamic /*android.os.Bundle*/) : Dynamic
   {
      if (_startInstrumentation_func==null)
         _startInstrumentation_func=nme.JNI.createMemberMethod("android.content.Context","startInstrumentation","(Landroid/content/ComponentName;Ljava/lang/String;Landroid/os/Bundle;)Z");
      return nme.JNI.callMember(_startInstrumentation_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _getSystemService_func:Dynamic;
   public function getSystemService(arg0:String) : Dynamic
   {
      if (_getSystemService_func==null)
         _getSystemService_func=nme.JNI.createMemberMethod("android.content.Context","getSystemService","(Ljava/lang/String;)Ljava/lang/Object;");
      return nme.JNI.callMember(_getSystemService_func,__jobject,[arg0]);
   }

   static var _checkPermission_func:Dynamic;
   public function checkPermission(arg0:String,arg1:Int,arg2:Int) : Dynamic
   {
      if (_checkPermission_func==null)
         _checkPermission_func=nme.JNI.createMemberMethod("android.content.Context","checkPermission","(Ljava/lang/String;II)I");
      return nme.JNI.callMember(_checkPermission_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _checkCallingPermission_func:Dynamic;
   public function checkCallingPermission(arg0:String) : Dynamic
   {
      if (_checkCallingPermission_func==null)
         _checkCallingPermission_func=nme.JNI.createMemberMethod("android.content.Context","checkCallingPermission","(Ljava/lang/String;)I");
      return nme.JNI.callMember(_checkCallingPermission_func,__jobject,[arg0]);
   }

   static var _checkCallingOrSelfPermission_func:Dynamic;
   public function checkCallingOrSelfPermission(arg0:String) : Dynamic
   {
      if (_checkCallingOrSelfPermission_func==null)
         _checkCallingOrSelfPermission_func=nme.JNI.createMemberMethod("android.content.Context","checkCallingOrSelfPermission","(Ljava/lang/String;)I");
      return nme.JNI.callMember(_checkCallingOrSelfPermission_func,__jobject,[arg0]);
   }

   static var _enforcePermission_func:Dynamic;
   public function enforcePermission(arg0:String,arg1:Int,arg2:Int,arg3:String) : Dynamic
   {
      if (_enforcePermission_func==null)
         _enforcePermission_func=nme.JNI.createMemberMethod("android.content.Context","enforcePermission","(Ljava/lang/String;IILjava/lang/String;)V");
      nme.JNI.callMember(_enforcePermission_func,__jobject,[arg0,arg1,arg2,arg3]);
   }

   static var _enforceCallingPermission_func:Dynamic;
   public function enforceCallingPermission(arg0:String,arg1:String) : Dynamic
   {
      if (_enforceCallingPermission_func==null)
         _enforceCallingPermission_func=nme.JNI.createMemberMethod("android.content.Context","enforceCallingPermission","(Ljava/lang/String;Ljava/lang/String;)V");
      nme.JNI.callMember(_enforceCallingPermission_func,__jobject,[arg0,arg1]);
   }

   static var _enforceCallingOrSelfPermission_func:Dynamic;
   public function enforceCallingOrSelfPermission(arg0:String,arg1:String) : Dynamic
   {
      if (_enforceCallingOrSelfPermission_func==null)
         _enforceCallingOrSelfPermission_func=nme.JNI.createMemberMethod("android.content.Context","enforceCallingOrSelfPermission","(Ljava/lang/String;Ljava/lang/String;)V");
      nme.JNI.callMember(_enforceCallingOrSelfPermission_func,__jobject,[arg0,arg1]);
   }

   static var _grantUriPermission_func:Dynamic;
   public function grantUriPermission(arg0:String,arg1:Dynamic /*android.net.Uri*/,arg2:Int) : Dynamic
   {
      if (_grantUriPermission_func==null)
         _grantUriPermission_func=nme.JNI.createMemberMethod("android.content.Context","grantUriPermission","(Ljava/lang/String;Landroid/net/Uri;I)V");
      nme.JNI.callMember(_grantUriPermission_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _revokeUriPermission_func:Dynamic;
   public function revokeUriPermission(arg0:Dynamic /*android.net.Uri*/,arg1:Int) : Dynamic
   {
      if (_revokeUriPermission_func==null)
         _revokeUriPermission_func=nme.JNI.createMemberMethod("android.content.Context","revokeUriPermission","(Landroid/net/Uri;I)V");
      nme.JNI.callMember(_revokeUriPermission_func,__jobject,[arg0,arg1]);
   }

   static var _checkUriPermission_func:Dynamic;
   public function checkUriPermission(arg0:Dynamic /*android.net.Uri*/,arg1:Int,arg2:Int,arg3:Int) : Dynamic
   {
      if (_checkUriPermission_func==null)
         _checkUriPermission_func=nme.JNI.createMemberMethod("android.content.Context","checkUriPermission","(Landroid/net/Uri;III)I");
      return nme.JNI.callMember(_checkUriPermission_func,__jobject,[arg0,arg1,arg2,arg3]);
   }

   static var _checkCallingUriPermission_func:Dynamic;
   public function checkCallingUriPermission(arg0:Dynamic /*android.net.Uri*/,arg1:Int) : Dynamic
   {
      if (_checkCallingUriPermission_func==null)
         _checkCallingUriPermission_func=nme.JNI.createMemberMethod("android.content.Context","checkCallingUriPermission","(Landroid/net/Uri;I)I");
      return nme.JNI.callMember(_checkCallingUriPermission_func,__jobject,[arg0,arg1]);
   }

   static var _checkCallingOrSelfUriPermission_func:Dynamic;
   public function checkCallingOrSelfUriPermission(arg0:Dynamic /*android.net.Uri*/,arg1:Int) : Dynamic
   {
      if (_checkCallingOrSelfUriPermission_func==null)
         _checkCallingOrSelfUriPermission_func=nme.JNI.createMemberMethod("android.content.Context","checkCallingOrSelfUriPermission","(Landroid/net/Uri;I)I");
      return nme.JNI.callMember(_checkCallingOrSelfUriPermission_func,__jobject,[arg0,arg1]);
   }

   static var _checkUriPermission1_func:Dynamic;
   public function checkUriPermission1(arg0:Dynamic /*android.net.Uri*/,arg1:String,arg2:String,arg3:Int,arg4:Int,arg5:Int) : Dynamic
   {
      if (_checkUriPermission1_func==null)
         _checkUriPermission1_func=nme.JNI.createMemberMethod("android.content.Context","checkUriPermission","(Landroid/net/Uri;Ljava/lang/String;Ljava/lang/String;III)I");
      return nme.JNI.callMember(_checkUriPermission1_func,__jobject,[arg0,arg1,arg2,arg3,arg4,arg5]);
   }

   static var _enforceUriPermission_func:Dynamic;
   public function enforceUriPermission(arg0:Dynamic /*android.net.Uri*/,arg1:Int,arg2:Int,arg3:Int,arg4:String) : Dynamic
   {
      if (_enforceUriPermission_func==null)
         _enforceUriPermission_func=nme.JNI.createMemberMethod("android.content.Context","enforceUriPermission","(Landroid/net/Uri;IIILjava/lang/String;)V");
      nme.JNI.callMember(_enforceUriPermission_func,__jobject,[arg0,arg1,arg2,arg3,arg4]);
   }

   static var _enforceCallingUriPermission_func:Dynamic;
   public function enforceCallingUriPermission(arg0:Dynamic /*android.net.Uri*/,arg1:Int,arg2:String) : Dynamic
   {
      if (_enforceCallingUriPermission_func==null)
         _enforceCallingUriPermission_func=nme.JNI.createMemberMethod("android.content.Context","enforceCallingUriPermission","(Landroid/net/Uri;ILjava/lang/String;)V");
      nme.JNI.callMember(_enforceCallingUriPermission_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _enforceCallingOrSelfUriPermission_func:Dynamic;
   public function enforceCallingOrSelfUriPermission(arg0:Dynamic /*android.net.Uri*/,arg1:Int,arg2:String) : Dynamic
   {
      if (_enforceCallingOrSelfUriPermission_func==null)
         _enforceCallingOrSelfUriPermission_func=nme.JNI.createMemberMethod("android.content.Context","enforceCallingOrSelfUriPermission","(Landroid/net/Uri;ILjava/lang/String;)V");
      nme.JNI.callMember(_enforceCallingOrSelfUriPermission_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _enforceUriPermission1_func:Dynamic;
   public function enforceUriPermission1(arg0:Dynamic /*android.net.Uri*/,arg1:String,arg2:String,arg3:Int,arg4:Int,arg5:Int,arg6:String) : Dynamic
   {
      if (_enforceUriPermission1_func==null)
         _enforceUriPermission1_func=nme.JNI.createMemberMethod("android.content.Context","enforceUriPermission","(Landroid/net/Uri;Ljava/lang/String;Ljava/lang/String;IIILjava/lang/String;)V");
      nme.JNI.callMember(_enforceUriPermission1_func,__jobject,[arg0,arg1,arg2,arg3,arg4,arg5,arg6]);
   }

   static var _createPackageContext_func:Dynamic;
   public function createPackageContext(arg0:String,arg1:Int) : Dynamic
   {
      if (_createPackageContext_func==null)
         _createPackageContext_func=nme.JNI.createMemberMethod("android.content.Context","createPackageContext","(Ljava/lang/String;I)Landroid/content/Context;");
      return nme.JNI.callMember(_createPackageContext_func,__jobject,[arg0,arg1]);
   }

   static var _isRestricted_func:Dynamic;
   public function isRestricted() : Dynamic
   {
      if (_isRestricted_func==null)
         _isRestricted_func=nme.JNI.createMemberMethod("android.content.Context","isRestricted","()Z");
      return nme.JNI.callMember(_isRestricted_func,__jobject,[]);
   }

}
