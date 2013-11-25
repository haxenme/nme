package android.content;
class ContextWrapper extends android.content.Context
{

   static var __create_func:Dynamic;
   public static function _create(arg0:Dynamic /*android.content.Context*/) : android.content.ContextWrapper
   {
      if (__create_func==null)
         __create_func=nme.JNI.createStaticMethod("android.content.ContextWrapper","<init>","(Landroid/content/Context;)V");
      return new android.content.ContextWrapper(nme.JNI.callStatic(__create_func,[arg0]));
   }

   public function new(handle:Dynamic) { super(handle); }
   static var _getBaseContext_func:Dynamic;
   public function getBaseContext() : Dynamic
   {
      if (_getBaseContext_func==null)
         _getBaseContext_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getBaseContext","()Landroid/content/Context;");
      return nme.JNI.callMember(_getBaseContext_func,__jobject,[]);
   }

   static var _getAssets_func:Dynamic;
   public override function getAssets() : Dynamic
   {
      if (_getAssets_func==null)
         _getAssets_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getAssets","()Landroid/content/res/AssetManager;");
      return nme.JNI.callMember(_getAssets_func,__jobject,[]);
   }

   static var _getResources_func:Dynamic;
   public override function getResources() : Dynamic
   {
      if (_getResources_func==null)
         _getResources_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getResources","()Landroid/content/res/Resources;");
      return nme.JNI.callMember(_getResources_func,__jobject,[]);
   }

   static var _getPackageManager_func:Dynamic;
   public override function getPackageManager() : Dynamic
   {
      if (_getPackageManager_func==null)
         _getPackageManager_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getPackageManager","()Landroid/content/pm/PackageManager;");
      return nme.JNI.callMember(_getPackageManager_func,__jobject,[]);
   }

   static var _getContentResolver_func:Dynamic;
   public override function getContentResolver() : Dynamic
   {
      if (_getContentResolver_func==null)
         _getContentResolver_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getContentResolver","()Landroid/content/ContentResolver;");
      return nme.JNI.callMember(_getContentResolver_func,__jobject,[]);
   }

   static var _getMainLooper_func:Dynamic;
   public override function getMainLooper() : Dynamic
   {
      if (_getMainLooper_func==null)
         _getMainLooper_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getMainLooper","()Landroid/os/Looper;");
      return nme.JNI.callMember(_getMainLooper_func,__jobject,[]);
   }

   static var _getApplicationContext_func:Dynamic;
   public override function getApplicationContext() : Dynamic
   {
      if (_getApplicationContext_func==null)
         _getApplicationContext_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getApplicationContext","()Landroid/content/Context;");
      return nme.JNI.callMember(_getApplicationContext_func,__jobject,[]);
   }

   static var _setTheme_func:Dynamic;
   public override function setTheme(arg0:Int) : Dynamic
   {
      if (_setTheme_func==null)
         _setTheme_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","setTheme","(I)V");
      nme.JNI.callMember(_setTheme_func,__jobject,[arg0]);
   }

   static var _getTheme_func:Dynamic;
   public override function getTheme() : Dynamic
   {
      if (_getTheme_func==null)
         _getTheme_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getTheme","()Landroid/content/res/Resources$Theme;");
      return nme.JNI.callMember(_getTheme_func,__jobject,[]);
   }

   static var _getClassLoader_func:Dynamic;
   public override function getClassLoader() : Dynamic
   {
      if (_getClassLoader_func==null)
         _getClassLoader_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getClassLoader","()Ljava/lang/ClassLoader;");
      return nme.JNI.callMember(_getClassLoader_func,__jobject,[]);
   }

   static var _getPackageName_func:Dynamic;
   public override function getPackageName() : Dynamic
   {
      if (_getPackageName_func==null)
         _getPackageName_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getPackageName","()Ljava/lang/String;");
      return nme.JNI.callMember(_getPackageName_func,__jobject,[]);
   }

   static var _getApplicationInfo_func:Dynamic;
   public override function getApplicationInfo() : Dynamic
   {
      if (_getApplicationInfo_func==null)
         _getApplicationInfo_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getApplicationInfo","()Landroid/content/pm/ApplicationInfo;");
      return nme.JNI.callMember(_getApplicationInfo_func,__jobject,[]);
   }

   static var _getPackageResourcePath_func:Dynamic;
   public override function getPackageResourcePath() : Dynamic
   {
      if (_getPackageResourcePath_func==null)
         _getPackageResourcePath_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getPackageResourcePath","()Ljava/lang/String;");
      return nme.JNI.callMember(_getPackageResourcePath_func,__jobject,[]);
   }

   static var _getPackageCodePath_func:Dynamic;
   public override function getPackageCodePath() : Dynamic
   {
      if (_getPackageCodePath_func==null)
         _getPackageCodePath_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getPackageCodePath","()Ljava/lang/String;");
      return nme.JNI.callMember(_getPackageCodePath_func,__jobject,[]);
   }

   static var _getSharedPreferences_func:Dynamic;
   public override function getSharedPreferences(arg0:String,arg1:Int) : Dynamic
   {
      if (_getSharedPreferences_func==null)
         _getSharedPreferences_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getSharedPreferences","(Ljava/lang/String;I)Landroid/content/SharedPreferences;");
      return nme.JNI.callMember(_getSharedPreferences_func,__jobject,[arg0,arg1]);
   }

   static var _openFileInput_func:Dynamic;
   public override function openFileInput(arg0:String) : Dynamic
   {
      if (_openFileInput_func==null)
         _openFileInput_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","openFileInput","(Ljava/lang/String;)Ljava/io/FileInputStream;");
      return nme.JNI.callMember(_openFileInput_func,__jobject,[arg0]);
   }

   static var _openFileOutput_func:Dynamic;
   public override function openFileOutput(arg0:String,arg1:Int) : Dynamic
   {
      if (_openFileOutput_func==null)
         _openFileOutput_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","openFileOutput","(Ljava/lang/String;I)Ljava/io/FileOutputStream;");
      return nme.JNI.callMember(_openFileOutput_func,__jobject,[arg0,arg1]);
   }

   static var _deleteFile_func:Dynamic;
   public override function deleteFile(arg0:String) : Dynamic
   {
      if (_deleteFile_func==null)
         _deleteFile_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","deleteFile","(Ljava/lang/String;)Z");
      return nme.JNI.callMember(_deleteFile_func,__jobject,[arg0]);
   }

   static var _getFileStreamPath_func:Dynamic;
   public override function getFileStreamPath(arg0:String) : Dynamic
   {
      if (_getFileStreamPath_func==null)
         _getFileStreamPath_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getFileStreamPath","(Ljava/lang/String;)Ljava/io/File;");
      return nme.JNI.callMember(_getFileStreamPath_func,__jobject,[arg0]);
   }

   static var _fileList_func:Dynamic;
   public override function fileList() : Dynamic
   {
      if (_fileList_func==null)
         _fileList_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","fileList","()[Ljava/lang/String;");
      return nme.JNI.callMember(_fileList_func,__jobject,[]);
   }

   static var _getFilesDir_func:Dynamic;
   public override function getFilesDir() : Dynamic
   {
      if (_getFilesDir_func==null)
         _getFilesDir_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getFilesDir","()Ljava/io/File;");
      return nme.JNI.callMember(_getFilesDir_func,__jobject,[]);
   }

   static var _getExternalFilesDir_func:Dynamic;
   public override function getExternalFilesDir(arg0:String) : Dynamic
   {
      if (_getExternalFilesDir_func==null)
         _getExternalFilesDir_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getExternalFilesDir","(Ljava/lang/String;)Ljava/io/File;");
      return nme.JNI.callMember(_getExternalFilesDir_func,__jobject,[arg0]);
   }

   static var _getCacheDir_func:Dynamic;
   public override function getCacheDir() : Dynamic
   {
      if (_getCacheDir_func==null)
         _getCacheDir_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getCacheDir","()Ljava/io/File;");
      return nme.JNI.callMember(_getCacheDir_func,__jobject,[]);
   }

   static var _getExternalCacheDir_func:Dynamic;
   public override function getExternalCacheDir() : Dynamic
   {
      if (_getExternalCacheDir_func==null)
         _getExternalCacheDir_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getExternalCacheDir","()Ljava/io/File;");
      return nme.JNI.callMember(_getExternalCacheDir_func,__jobject,[]);
   }

   static var _getDir_func:Dynamic;
   public override function getDir(arg0:String,arg1:Int) : Dynamic
   {
      if (_getDir_func==null)
         _getDir_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getDir","(Ljava/lang/String;I)Ljava/io/File;");
      return nme.JNI.callMember(_getDir_func,__jobject,[arg0,arg1]);
   }

   static var _openOrCreateDatabase_func:Dynamic;
   public override function openOrCreateDatabase(arg0:String,arg1:Int,arg2:Dynamic /*android.database.sqlite.SQLiteDatabase$CursorFactory*/) : Dynamic
   {
      if (_openOrCreateDatabase_func==null)
         _openOrCreateDatabase_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","openOrCreateDatabase","(Ljava/lang/String;ILandroid/database/sqlite/SQLiteDatabase$CursorFactory;)Landroid/database/sqlite/SQLiteDatabase;");
      return nme.JNI.callMember(_openOrCreateDatabase_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _deleteDatabase_func:Dynamic;
   public override function deleteDatabase(arg0:String) : Dynamic
   {
      if (_deleteDatabase_func==null)
         _deleteDatabase_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","deleteDatabase","(Ljava/lang/String;)Z");
      return nme.JNI.callMember(_deleteDatabase_func,__jobject,[arg0]);
   }

   static var _getDatabasePath_func:Dynamic;
   public override function getDatabasePath(arg0:String) : Dynamic
   {
      if (_getDatabasePath_func==null)
         _getDatabasePath_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getDatabasePath","(Ljava/lang/String;)Ljava/io/File;");
      return nme.JNI.callMember(_getDatabasePath_func,__jobject,[arg0]);
   }

   static var _databaseList_func:Dynamic;
   public override function databaseList() : Dynamic
   {
      if (_databaseList_func==null)
         _databaseList_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","databaseList","()[Ljava/lang/String;");
      return nme.JNI.callMember(_databaseList_func,__jobject,[]);
   }

   static var _getWallpaper_func:Dynamic;
   public override function getWallpaper() : Dynamic
   {
      if (_getWallpaper_func==null)
         _getWallpaper_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getWallpaper","()Landroid/graphics/drawable/Drawable;");
      return nme.JNI.callMember(_getWallpaper_func,__jobject,[]);
   }

   static var _peekWallpaper_func:Dynamic;
   public override function peekWallpaper() : Dynamic
   {
      if (_peekWallpaper_func==null)
         _peekWallpaper_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","peekWallpaper","()Landroid/graphics/drawable/Drawable;");
      return nme.JNI.callMember(_peekWallpaper_func,__jobject,[]);
   }

   static var _getWallpaperDesiredMinimumWidth_func:Dynamic;
   public override function getWallpaperDesiredMinimumWidth() : Dynamic
   {
      if (_getWallpaperDesiredMinimumWidth_func==null)
         _getWallpaperDesiredMinimumWidth_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getWallpaperDesiredMinimumWidth","()I");
      return nme.JNI.callMember(_getWallpaperDesiredMinimumWidth_func,__jobject,[]);
   }

   static var _getWallpaperDesiredMinimumHeight_func:Dynamic;
   public override function getWallpaperDesiredMinimumHeight() : Dynamic
   {
      if (_getWallpaperDesiredMinimumHeight_func==null)
         _getWallpaperDesiredMinimumHeight_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getWallpaperDesiredMinimumHeight","()I");
      return nme.JNI.callMember(_getWallpaperDesiredMinimumHeight_func,__jobject,[]);
   }

   static var _setWallpaper_func:Dynamic;
   public override function setWallpaper(arg0:Dynamic /*android.graphics.Bitmap*/) : Dynamic
   {
      if (_setWallpaper_func==null)
         _setWallpaper_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","setWallpaper","(Landroid/graphics/Bitmap;)V");
      nme.JNI.callMember(_setWallpaper_func,__jobject,[arg0]);
   }

   static var _setWallpaper1_func:Dynamic;
   public override function setWallpaper1(arg0:Dynamic /*java.io.InputStream*/) : Dynamic
   {
      if (_setWallpaper1_func==null)
         _setWallpaper1_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","setWallpaper","(Ljava/io/InputStream;)V");
      nme.JNI.callMember(_setWallpaper1_func,__jobject,[arg0]);
   }

   static var _clearWallpaper_func:Dynamic;
   public override function clearWallpaper() : Dynamic
   {
      if (_clearWallpaper_func==null)
         _clearWallpaper_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","clearWallpaper","()V");
      nme.JNI.callMember(_clearWallpaper_func,__jobject,[]);
   }

   static var _startActivity_func:Dynamic;
   public override function startActivity(arg0:Dynamic /*android.content.Intent*/) : Dynamic
   {
      if (_startActivity_func==null)
         _startActivity_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","startActivity","(Landroid/content/Intent;)V");
      nme.JNI.callMember(_startActivity_func,__jobject,[arg0]);
   }

   static var _startIntentSender_func:Dynamic;
   public override function startIntentSender(arg0:Dynamic /*android.content.IntentSender*/,arg1:Dynamic /*android.content.Intent*/,arg2:Int,arg3:Int,arg4:Int) : Dynamic
   {
      if (_startIntentSender_func==null)
         _startIntentSender_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","startIntentSender","(Landroid/content/IntentSender;Landroid/content/Intent;III)V");
      nme.JNI.callMember(_startIntentSender_func,__jobject,[arg0,arg1,arg2,arg3,arg4]);
   }

   static var _sendBroadcast_func:Dynamic;
   public override function sendBroadcast(arg0:Dynamic /*android.content.Intent*/) : Dynamic
   {
      if (_sendBroadcast_func==null)
         _sendBroadcast_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","sendBroadcast","(Landroid/content/Intent;)V");
      nme.JNI.callMember(_sendBroadcast_func,__jobject,[arg0]);
   }

   static var _sendBroadcast1_func:Dynamic;
   public override function sendBroadcast1(arg0:Dynamic /*android.content.Intent*/,arg1:String) : Dynamic
   {
      if (_sendBroadcast1_func==null)
         _sendBroadcast1_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","sendBroadcast","(Landroid/content/Intent;Ljava/lang/String;)V");
      nme.JNI.callMember(_sendBroadcast1_func,__jobject,[arg0,arg1]);
   }

   static var _sendOrderedBroadcast_func:Dynamic;
   public override function sendOrderedBroadcast(arg0:Dynamic /*android.content.Intent*/,arg1:String) : Dynamic
   {
      if (_sendOrderedBroadcast_func==null)
         _sendOrderedBroadcast_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","sendOrderedBroadcast","(Landroid/content/Intent;Ljava/lang/String;)V");
      nme.JNI.callMember(_sendOrderedBroadcast_func,__jobject,[arg0,arg1]);
   }

   static var _sendOrderedBroadcast1_func:Dynamic;
   public override function sendOrderedBroadcast1(arg0:Dynamic /*android.content.Intent*/,arg1:String,arg2:Dynamic /*android.content.BroadcastReceiver*/,arg3:Dynamic /*android.os.Handler*/,arg4:Int,arg5:String,arg6:Dynamic /*android.os.Bundle*/) : Dynamic
   {
      if (_sendOrderedBroadcast1_func==null)
         _sendOrderedBroadcast1_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","sendOrderedBroadcast","(Landroid/content/Intent;Ljava/lang/String;Landroid/content/BroadcastReceiver;Landroid/os/Handler;ILjava/lang/String;Landroid/os/Bundle;)V");
      nme.JNI.callMember(_sendOrderedBroadcast1_func,__jobject,[arg0,arg1,arg2,arg3,arg4,arg5,arg6]);
   }

   static var _sendStickyBroadcast_func:Dynamic;
   public override function sendStickyBroadcast(arg0:Dynamic /*android.content.Intent*/) : Dynamic
   {
      if (_sendStickyBroadcast_func==null)
         _sendStickyBroadcast_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","sendStickyBroadcast","(Landroid/content/Intent;)V");
      nme.JNI.callMember(_sendStickyBroadcast_func,__jobject,[arg0]);
   }

   static var _sendStickyOrderedBroadcast_func:Dynamic;
   public override function sendStickyOrderedBroadcast(arg0:Dynamic /*android.content.Intent*/,arg1:Dynamic /*android.content.BroadcastReceiver*/,arg2:Dynamic /*android.os.Handler*/,arg3:Int,arg4:String,arg5:Dynamic /*android.os.Bundle*/) : Dynamic
   {
      if (_sendStickyOrderedBroadcast_func==null)
         _sendStickyOrderedBroadcast_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","sendStickyOrderedBroadcast","(Landroid/content/Intent;Landroid/content/BroadcastReceiver;Landroid/os/Handler;ILjava/lang/String;Landroid/os/Bundle;)V");
      nme.JNI.callMember(_sendStickyOrderedBroadcast_func,__jobject,[arg0,arg1,arg2,arg3,arg4,arg5]);
   }

   static var _removeStickyBroadcast_func:Dynamic;
   public override function removeStickyBroadcast(arg0:Dynamic /*android.content.Intent*/) : Dynamic
   {
      if (_removeStickyBroadcast_func==null)
         _removeStickyBroadcast_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","removeStickyBroadcast","(Landroid/content/Intent;)V");
      nme.JNI.callMember(_removeStickyBroadcast_func,__jobject,[arg0]);
   }

   static var _registerReceiver_func:Dynamic;
   public override function registerReceiver(arg0:Dynamic /*android.content.BroadcastReceiver*/,arg1:Dynamic /*android.content.IntentFilter*/) : Dynamic
   {
      if (_registerReceiver_func==null)
         _registerReceiver_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","registerReceiver","(Landroid/content/BroadcastReceiver;Landroid/content/IntentFilter;)Landroid/content/Intent;");
      return nme.JNI.callMember(_registerReceiver_func,__jobject,[arg0,arg1]);
   }

   static var _registerReceiver1_func:Dynamic;
   public override function registerReceiver1(arg0:Dynamic /*android.content.BroadcastReceiver*/,arg1:Dynamic /*android.content.IntentFilter*/,arg2:String,arg3:Dynamic /*android.os.Handler*/) : Dynamic
   {
      if (_registerReceiver1_func==null)
         _registerReceiver1_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","registerReceiver","(Landroid/content/BroadcastReceiver;Landroid/content/IntentFilter;Ljava/lang/String;Landroid/os/Handler;)Landroid/content/Intent;");
      return nme.JNI.callMember(_registerReceiver1_func,__jobject,[arg0,arg1,arg2,arg3]);
   }

   static var _unregisterReceiver_func:Dynamic;
   public override function unregisterReceiver(arg0:Dynamic /*android.content.BroadcastReceiver*/) : Dynamic
   {
      if (_unregisterReceiver_func==null)
         _unregisterReceiver_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","unregisterReceiver","(Landroid/content/BroadcastReceiver;)V");
      nme.JNI.callMember(_unregisterReceiver_func,__jobject,[arg0]);
   }

   static var _startService_func:Dynamic;
   public override function startService(arg0:Dynamic /*android.content.Intent*/) : Dynamic
   {
      if (_startService_func==null)
         _startService_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","startService","(Landroid/content/Intent;)Landroid/content/ComponentName;");
      return nme.JNI.callMember(_startService_func,__jobject,[arg0]);
   }

   static var _stopService_func:Dynamic;
   public override function stopService(arg0:Dynamic /*android.content.Intent*/) : Dynamic
   {
      if (_stopService_func==null)
         _stopService_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","stopService","(Landroid/content/Intent;)Z");
      return nme.JNI.callMember(_stopService_func,__jobject,[arg0]);
   }

   static var _bindService_func:Dynamic;
   public override function bindService(arg0:Dynamic /*android.content.Intent*/,arg1:Dynamic /*android.content.ServiceConnection*/,arg2:Int) : Dynamic
   {
      if (_bindService_func==null)
         _bindService_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","bindService","(Landroid/content/Intent;Landroid/content/ServiceConnection;I)Z");
      return nme.JNI.callMember(_bindService_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _unbindService_func:Dynamic;
   public override function unbindService(arg0:Dynamic /*android.content.ServiceConnection*/) : Dynamic
   {
      if (_unbindService_func==null)
         _unbindService_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","unbindService","(Landroid/content/ServiceConnection;)V");
      nme.JNI.callMember(_unbindService_func,__jobject,[arg0]);
   }

   static var _startInstrumentation_func:Dynamic;
   public override function startInstrumentation(arg0:Dynamic /*android.content.ComponentName*/,arg1:String,arg2:Dynamic /*android.os.Bundle*/) : Dynamic
   {
      if (_startInstrumentation_func==null)
         _startInstrumentation_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","startInstrumentation","(Landroid/content/ComponentName;Ljava/lang/String;Landroid/os/Bundle;)Z");
      return nme.JNI.callMember(_startInstrumentation_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _getSystemService_func:Dynamic;
   public override function getSystemService(arg0:String) : Dynamic
   {
      if (_getSystemService_func==null)
         _getSystemService_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","getSystemService","(Ljava/lang/String;)Ljava/lang/Object;");
      return nme.JNI.callMember(_getSystemService_func,__jobject,[arg0]);
   }

   static var _checkPermission_func:Dynamic;
   public override function checkPermission(arg0:String,arg1:Int,arg2:Int) : Dynamic
   {
      if (_checkPermission_func==null)
         _checkPermission_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","checkPermission","(Ljava/lang/String;II)I");
      return nme.JNI.callMember(_checkPermission_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _checkCallingPermission_func:Dynamic;
   public override function checkCallingPermission(arg0:String) : Dynamic
   {
      if (_checkCallingPermission_func==null)
         _checkCallingPermission_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","checkCallingPermission","(Ljava/lang/String;)I");
      return nme.JNI.callMember(_checkCallingPermission_func,__jobject,[arg0]);
   }

   static var _checkCallingOrSelfPermission_func:Dynamic;
   public override function checkCallingOrSelfPermission(arg0:String) : Dynamic
   {
      if (_checkCallingOrSelfPermission_func==null)
         _checkCallingOrSelfPermission_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","checkCallingOrSelfPermission","(Ljava/lang/String;)I");
      return nme.JNI.callMember(_checkCallingOrSelfPermission_func,__jobject,[arg0]);
   }

   static var _enforcePermission_func:Dynamic;
   public override function enforcePermission(arg0:String,arg1:Int,arg2:Int,arg3:String) : Dynamic
   {
      if (_enforcePermission_func==null)
         _enforcePermission_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","enforcePermission","(Ljava/lang/String;IILjava/lang/String;)V");
      nme.JNI.callMember(_enforcePermission_func,__jobject,[arg0,arg1,arg2,arg3]);
   }

   static var _enforceCallingPermission_func:Dynamic;
   public override function enforceCallingPermission(arg0:String,arg1:String) : Dynamic
   {
      if (_enforceCallingPermission_func==null)
         _enforceCallingPermission_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","enforceCallingPermission","(Ljava/lang/String;Ljava/lang/String;)V");
      nme.JNI.callMember(_enforceCallingPermission_func,__jobject,[arg0,arg1]);
   }

   static var _enforceCallingOrSelfPermission_func:Dynamic;
   public override function enforceCallingOrSelfPermission(arg0:String,arg1:String) : Dynamic
   {
      if (_enforceCallingOrSelfPermission_func==null)
         _enforceCallingOrSelfPermission_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","enforceCallingOrSelfPermission","(Ljava/lang/String;Ljava/lang/String;)V");
      nme.JNI.callMember(_enforceCallingOrSelfPermission_func,__jobject,[arg0,arg1]);
   }

   static var _grantUriPermission_func:Dynamic;
   public override function grantUriPermission(arg0:String,arg1:Dynamic /*android.net.Uri*/,arg2:Int) : Dynamic
   {
      if (_grantUriPermission_func==null)
         _grantUriPermission_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","grantUriPermission","(Ljava/lang/String;Landroid/net/Uri;I)V");
      nme.JNI.callMember(_grantUriPermission_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _revokeUriPermission_func:Dynamic;
   public override function revokeUriPermission(arg0:Dynamic /*android.net.Uri*/,arg1:Int) : Dynamic
   {
      if (_revokeUriPermission_func==null)
         _revokeUriPermission_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","revokeUriPermission","(Landroid/net/Uri;I)V");
      nme.JNI.callMember(_revokeUriPermission_func,__jobject,[arg0,arg1]);
   }

   static var _checkUriPermission_func:Dynamic;
   public override function checkUriPermission(arg0:Dynamic /*android.net.Uri*/,arg1:Int,arg2:Int,arg3:Int) : Dynamic
   {
      if (_checkUriPermission_func==null)
         _checkUriPermission_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","checkUriPermission","(Landroid/net/Uri;III)I");
      return nme.JNI.callMember(_checkUriPermission_func,__jobject,[arg0,arg1,arg2,arg3]);
   }

   static var _checkCallingUriPermission_func:Dynamic;
   public override function checkCallingUriPermission(arg0:Dynamic /*android.net.Uri*/,arg1:Int) : Dynamic
   {
      if (_checkCallingUriPermission_func==null)
         _checkCallingUriPermission_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","checkCallingUriPermission","(Landroid/net/Uri;I)I");
      return nme.JNI.callMember(_checkCallingUriPermission_func,__jobject,[arg0,arg1]);
   }

   static var _checkCallingOrSelfUriPermission_func:Dynamic;
   public override function checkCallingOrSelfUriPermission(arg0:Dynamic /*android.net.Uri*/,arg1:Int) : Dynamic
   {
      if (_checkCallingOrSelfUriPermission_func==null)
         _checkCallingOrSelfUriPermission_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","checkCallingOrSelfUriPermission","(Landroid/net/Uri;I)I");
      return nme.JNI.callMember(_checkCallingOrSelfUriPermission_func,__jobject,[arg0,arg1]);
   }

   static var _checkUriPermission1_func:Dynamic;
   public override function checkUriPermission1(arg0:Dynamic /*android.net.Uri*/,arg1:String,arg2:String,arg3:Int,arg4:Int,arg5:Int) : Dynamic
   {
      if (_checkUriPermission1_func==null)
         _checkUriPermission1_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","checkUriPermission","(Landroid/net/Uri;Ljava/lang/String;Ljava/lang/String;III)I");
      return nme.JNI.callMember(_checkUriPermission1_func,__jobject,[arg0,arg1,arg2,arg3,arg4,arg5]);
   }

   static var _enforceUriPermission_func:Dynamic;
   public override function enforceUriPermission(arg0:Dynamic /*android.net.Uri*/,arg1:Int,arg2:Int,arg3:Int,arg4:String) : Dynamic
   {
      if (_enforceUriPermission_func==null)
         _enforceUriPermission_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","enforceUriPermission","(Landroid/net/Uri;IIILjava/lang/String;)V");
      nme.JNI.callMember(_enforceUriPermission_func,__jobject,[arg0,arg1,arg2,arg3,arg4]);
   }

   static var _enforceCallingUriPermission_func:Dynamic;
   public override function enforceCallingUriPermission(arg0:Dynamic /*android.net.Uri*/,arg1:Int,arg2:String) : Dynamic
   {
      if (_enforceCallingUriPermission_func==null)
         _enforceCallingUriPermission_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","enforceCallingUriPermission","(Landroid/net/Uri;ILjava/lang/String;)V");
      nme.JNI.callMember(_enforceCallingUriPermission_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _enforceCallingOrSelfUriPermission_func:Dynamic;
   public override function enforceCallingOrSelfUriPermission(arg0:Dynamic /*android.net.Uri*/,arg1:Int,arg2:String) : Dynamic
   {
      if (_enforceCallingOrSelfUriPermission_func==null)
         _enforceCallingOrSelfUriPermission_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","enforceCallingOrSelfUriPermission","(Landroid/net/Uri;ILjava/lang/String;)V");
      nme.JNI.callMember(_enforceCallingOrSelfUriPermission_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _enforceUriPermission1_func:Dynamic;
   public override function enforceUriPermission1(arg0:Dynamic /*android.net.Uri*/,arg1:String,arg2:String,arg3:Int,arg4:Int,arg5:Int,arg6:String) : Dynamic
   {
      if (_enforceUriPermission1_func==null)
         _enforceUriPermission1_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","enforceUriPermission","(Landroid/net/Uri;Ljava/lang/String;Ljava/lang/String;IIILjava/lang/String;)V");
      nme.JNI.callMember(_enforceUriPermission1_func,__jobject,[arg0,arg1,arg2,arg3,arg4,arg5,arg6]);
   }

   static var _createPackageContext_func:Dynamic;
   public override function createPackageContext(arg0:String,arg1:Int) : Dynamic
   {
      if (_createPackageContext_func==null)
         _createPackageContext_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","createPackageContext","(Ljava/lang/String;I)Landroid/content/Context;");
      return nme.JNI.callMember(_createPackageContext_func,__jobject,[arg0,arg1]);
   }

   static var _isRestricted_func:Dynamic;
   public override function isRestricted() : Dynamic
   {
      if (_isRestricted_func==null)
         _isRestricted_func=nme.JNI.createMemberMethod("android.content.ContextWrapper","isRestricted","()Z");
      return nme.JNI.callMember(_isRestricted_func,__jobject,[]);
   }

}
