package android.app;
class Activity extends android.view.ContextThemeWrapper
{
   static inline public var RESULT_CANCELED:Int = 0;
   static inline public var RESULT_OK:Int = -1;
   static inline public var RESULT_FIRST_USER:Int = 1;
   static inline public var DEFAULT_KEYS_DISABLE:Int = 0;
   static inline public var DEFAULT_KEYS_DIALER:Int = 1;
   static inline public var DEFAULT_KEYS_SHORTCUT:Int = 2;
   static inline public var DEFAULT_KEYS_SEARCH_LOCAL:Int = 3;
   static inline public var DEFAULT_KEYS_SEARCH_GLOBAL:Int = 4;

   static var __create_func:Dynamic;
   public static function _create() : android.app.Activity
   {
      if (__create_func==null)
         __create_func=nme.JNI.createStaticMethod("android.app.Activity","<init>","()V");
      return new android.app.Activity(nme.JNI.callStatic(__create_func,[]));
   }

   public function new(handle:Dynamic) { super(handle); }
   static var _getInstanceCount_func:Dynamic;
   public static function getInstanceCount() : Dynamic
   {
      if (_getInstanceCount_func==null)
         _getInstanceCount_func=nme.JNI.createStaticMethod("android.app.Activity","getInstanceCount","()J");
      return nme.JNI.callStatic(_getInstanceCount_func,[]);
   }

   static var _getIntent_func:Dynamic;
   public function getIntent() : Dynamic
   {
      if (_getIntent_func==null)
         _getIntent_func=nme.JNI.createMemberMethod("android.app.Activity","getIntent","()Landroid/content/Intent;");
      return nme.JNI.callMember(_getIntent_func,__jobject,[]);
   }

   static var _setIntent_func:Dynamic;
   public function setIntent(arg0:Dynamic /*android.content.Intent*/) : Dynamic
   {
      if (_setIntent_func==null)
         _setIntent_func=nme.JNI.createMemberMethod("android.app.Activity","setIntent","(Landroid/content/Intent;)V");
      nme.JNI.callMember(_setIntent_func,__jobject,[arg0]);
   }

   static var _getApplication_func:Dynamic;
   public function getApplication() : Dynamic
   {
      if (_getApplication_func==null)
         _getApplication_func=nme.JNI.createMemberMethod("android.app.Activity","getApplication","()Landroid/app/Application;");
      return nme.JNI.callMember(_getApplication_func,__jobject,[]);
   }

   static var _isChild_func:Dynamic;
   public function isChild() : Dynamic
   {
      if (_isChild_func==null)
         _isChild_func=nme.JNI.createMemberMethod("android.app.Activity","isChild","()Z");
      return nme.JNI.callMember(_isChild_func,__jobject,[]);
   }

   static var _getParent_func:Dynamic;
   public function getParent() : Dynamic
   {
      if (_getParent_func==null)
         _getParent_func=nme.JNI.createMemberMethod("android.app.Activity","getParent","()Landroid/app/Activity;");
      return nme.JNI.callMember(_getParent_func,__jobject,[]);
   }

   static var _getWindowManager_func:Dynamic;
   public function getWindowManager() : Dynamic
   {
      if (_getWindowManager_func==null)
         _getWindowManager_func=nme.JNI.createMemberMethod("android.app.Activity","getWindowManager","()Landroid/view/WindowManager;");
      return nme.JNI.callMember(_getWindowManager_func,__jobject,[]);
   }

   static var _getWindow_func:Dynamic;
   public function getWindow() : Dynamic
   {
      if (_getWindow_func==null)
         _getWindow_func=nme.JNI.createMemberMethod("android.app.Activity","getWindow","()Landroid/view/Window;");
      return nme.JNI.callMember(_getWindow_func,__jobject,[]);
   }

   static var _getCurrentFocus_func:Dynamic;
   public function getCurrentFocus() : Dynamic
   {
      if (_getCurrentFocus_func==null)
         _getCurrentFocus_func=nme.JNI.createMemberMethod("android.app.Activity","getCurrentFocus","()Landroid/view/View;");
      return nme.JNI.callMember(_getCurrentFocus_func,__jobject,[]);
   }

   static var _getWallpaperDesiredMinimumWidth_func:Dynamic;
   public override function getWallpaperDesiredMinimumWidth() : Dynamic
   {
      if (_getWallpaperDesiredMinimumWidth_func==null)
         _getWallpaperDesiredMinimumWidth_func=nme.JNI.createMemberMethod("android.app.Activity","getWallpaperDesiredMinimumWidth","()I");
      return nme.JNI.callMember(_getWallpaperDesiredMinimumWidth_func,__jobject,[]);
   }

   static var _getWallpaperDesiredMinimumHeight_func:Dynamic;
   public override function getWallpaperDesiredMinimumHeight() : Dynamic
   {
      if (_getWallpaperDesiredMinimumHeight_func==null)
         _getWallpaperDesiredMinimumHeight_func=nme.JNI.createMemberMethod("android.app.Activity","getWallpaperDesiredMinimumHeight","()I");
      return nme.JNI.callMember(_getWallpaperDesiredMinimumHeight_func,__jobject,[]);
   }

   static var _onCreateThumbnail_func:Dynamic;
   public function onCreateThumbnail(arg0:Dynamic /*android.graphics.Bitmap*/,arg1:Dynamic /*android.graphics.Canvas*/) : Dynamic
   {
      if (_onCreateThumbnail_func==null)
         _onCreateThumbnail_func=nme.JNI.createMemberMethod("android.app.Activity","onCreateThumbnail","(Landroid/graphics/Bitmap;Landroid/graphics/Canvas;)Z");
      return nme.JNI.callMember(_onCreateThumbnail_func,__jobject,[arg0,arg1]);
   }

   static var _onCreateDescription_func:Dynamic;
   public function onCreateDescription() : Dynamic
   {
      if (_onCreateDescription_func==null)
         _onCreateDescription_func=nme.JNI.createMemberMethod("android.app.Activity","onCreateDescription","()Ljava/lang/CharSequence;");
      return nme.JNI.callMember(_onCreateDescription_func,__jobject,[]);
   }

   static var _onConfigurationChanged_func:Dynamic;
   public function onConfigurationChanged(arg0:Dynamic /*android.content.res.Configuration*/) : Dynamic
   {
      if (_onConfigurationChanged_func==null)
         _onConfigurationChanged_func=nme.JNI.createMemberMethod("android.app.Activity","onConfigurationChanged","(Landroid/content/res/Configuration;)V");
      nme.JNI.callMember(_onConfigurationChanged_func,__jobject,[arg0]);
   }

   static var _getChangingConfigurations_func:Dynamic;
   public function getChangingConfigurations() : Dynamic
   {
      if (_getChangingConfigurations_func==null)
         _getChangingConfigurations_func=nme.JNI.createMemberMethod("android.app.Activity","getChangingConfigurations","()I");
      return nme.JNI.callMember(_getChangingConfigurations_func,__jobject,[]);
   }

   static var _getLastNonConfigurationInstance_func:Dynamic;
   public function getLastNonConfigurationInstance() : Dynamic
   {
      if (_getLastNonConfigurationInstance_func==null)
         _getLastNonConfigurationInstance_func=nme.JNI.createMemberMethod("android.app.Activity","getLastNonConfigurationInstance","()Ljava/lang/Object;");
      return nme.JNI.callMember(_getLastNonConfigurationInstance_func,__jobject,[]);
   }

   static var _onRetainNonConfigurationInstance_func:Dynamic;
   public function onRetainNonConfigurationInstance() : Dynamic
   {
      if (_onRetainNonConfigurationInstance_func==null)
         _onRetainNonConfigurationInstance_func=nme.JNI.createMemberMethod("android.app.Activity","onRetainNonConfigurationInstance","()Ljava/lang/Object;");
      return nme.JNI.callMember(_onRetainNonConfigurationInstance_func,__jobject,[]);
   }

   static var _onLowMemory_func:Dynamic;
   public function onLowMemory() : Dynamic
   {
      if (_onLowMemory_func==null)
         _onLowMemory_func=nme.JNI.createMemberMethod("android.app.Activity","onLowMemory","()V");
      nme.JNI.callMember(_onLowMemory_func,__jobject,[]);
   }

   static var _managedQuery_func:Dynamic;
   public function managedQuery(arg0:Dynamic /*android.net.Uri*/,arg1:Array< String >,arg2:String,arg3:Array< String >,arg4:String,arg5:String,arg6:String,arg7:String,arg8:String,arg9:Array< String >,arg10:String,arg11:String,arg12:String) : Dynamic
   {
      if (_managedQuery_func==null)
         _managedQuery_func=nme.JNI.createMemberMethod("android.app.Activity","managedQuery","(Landroid/net/Uri;[Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;)Landroid/database/Cursor;");
      return nme.JNI.callMember(_managedQuery_func,__jobject,[arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10,arg11,arg12]);
   }

   static var _startManagingCursor_func:Dynamic;
   public function startManagingCursor(arg0:Dynamic /*android.database.Cursor*/) : Dynamic
   {
      if (_startManagingCursor_func==null)
         _startManagingCursor_func=nme.JNI.createMemberMethod("android.app.Activity","startManagingCursor","(Landroid/database/Cursor;)V");
      nme.JNI.callMember(_startManagingCursor_func,__jobject,[arg0]);
   }

   static var _stopManagingCursor_func:Dynamic;
   public function stopManagingCursor(arg0:Dynamic /*android.database.Cursor*/) : Dynamic
   {
      if (_stopManagingCursor_func==null)
         _stopManagingCursor_func=nme.JNI.createMemberMethod("android.app.Activity","stopManagingCursor","(Landroid/database/Cursor;)V");
      nme.JNI.callMember(_stopManagingCursor_func,__jobject,[arg0]);
   }

   static var _setPersistent_func:Dynamic;
   public function setPersistent(arg0:Bool) : Dynamic
   {
      if (_setPersistent_func==null)
         _setPersistent_func=nme.JNI.createMemberMethod("android.app.Activity","setPersistent","(Z)V");
      nme.JNI.callMember(_setPersistent_func,__jobject,[arg0]);
   }

   static var _findViewById_func:Dynamic;
   public function findViewById(arg0:Int) : Dynamic
   {
      if (_findViewById_func==null)
         _findViewById_func=nme.JNI.createMemberMethod("android.app.Activity","findViewById","(I)Landroid/view/View;");
      return nme.JNI.callMember(_findViewById_func,__jobject,[arg0]);
   }

   static var _setContentView_func:Dynamic;
   public function setContentView(arg0:Int) : Dynamic
   {
      if (_setContentView_func==null)
         _setContentView_func=nme.JNI.createMemberMethod("android.app.Activity","setContentView","(I)V");
      nme.JNI.callMember(_setContentView_func,__jobject,[arg0]);
   }

   static var _setContentView1_func:Dynamic;
   public function setContentView1(arg0:Dynamic /*android.view.View*/) : Dynamic
   {
      if (_setContentView1_func==null)
         _setContentView1_func=nme.JNI.createMemberMethod("android.app.Activity","setContentView","(Landroid/view/View;)V");
      nme.JNI.callMember(_setContentView1_func,__jobject,[arg0]);
   }

   static var _setContentView2_func:Dynamic;
   public function setContentView2(arg0:Dynamic /*android.view.View*/,arg1:Dynamic /*android.view.ViewGroup$LayoutParams*/) : Dynamic
   {
      if (_setContentView2_func==null)
         _setContentView2_func=nme.JNI.createMemberMethod("android.app.Activity","setContentView","(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V");
      nme.JNI.callMember(_setContentView2_func,__jobject,[arg0,arg1]);
   }

   static var _addContentView_func:Dynamic;
   public function addContentView(arg0:Dynamic /*android.view.View*/,arg1:Dynamic /*android.view.ViewGroup$LayoutParams*/) : Dynamic
   {
      if (_addContentView_func==null)
         _addContentView_func=nme.JNI.createMemberMethod("android.app.Activity","addContentView","(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V");
      nme.JNI.callMember(_addContentView_func,__jobject,[arg0,arg1]);
   }

   static var _setDefaultKeyMode_func:Dynamic;
   public function setDefaultKeyMode(arg0:Int) : Dynamic
   {
      if (_setDefaultKeyMode_func==null)
         _setDefaultKeyMode_func=nme.JNI.createMemberMethod("android.app.Activity","setDefaultKeyMode","(I)V");
      nme.JNI.callMember(_setDefaultKeyMode_func,__jobject,[arg0]);
   }

   static var _onKeyDown_func:Dynamic;
   public function onKeyDown(arg0:Int,arg1:Dynamic /*android.view.KeyEvent*/) : Dynamic
   {
      if (_onKeyDown_func==null)
         _onKeyDown_func=nme.JNI.createMemberMethod("android.app.Activity","onKeyDown","(ILandroid/view/KeyEvent;)Z");
      return nme.JNI.callMember(_onKeyDown_func,__jobject,[arg0,arg1]);
   }

   static var _onKeyLongPress_func:Dynamic;
   public function onKeyLongPress(arg0:Int,arg1:Dynamic /*android.view.KeyEvent*/) : Dynamic
   {
      if (_onKeyLongPress_func==null)
         _onKeyLongPress_func=nme.JNI.createMemberMethod("android.app.Activity","onKeyLongPress","(ILandroid/view/KeyEvent;)Z");
      return nme.JNI.callMember(_onKeyLongPress_func,__jobject,[arg0,arg1]);
   }

   static var _onKeyUp_func:Dynamic;
   public function onKeyUp(arg0:Int,arg1:Dynamic /*android.view.KeyEvent*/) : Dynamic
   {
      if (_onKeyUp_func==null)
         _onKeyUp_func=nme.JNI.createMemberMethod("android.app.Activity","onKeyUp","(ILandroid/view/KeyEvent;)Z");
      return nme.JNI.callMember(_onKeyUp_func,__jobject,[arg0,arg1]);
   }

   static var _onKeyMultiple_func:Dynamic;
   public function onKeyMultiple(arg0:Int,arg1:Int,arg2:Dynamic /*android.view.KeyEvent*/) : Dynamic
   {
      if (_onKeyMultiple_func==null)
         _onKeyMultiple_func=nme.JNI.createMemberMethod("android.app.Activity","onKeyMultiple","(IILandroid/view/KeyEvent;)Z");
      return nme.JNI.callMember(_onKeyMultiple_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _onBackPressed_func:Dynamic;
   public function onBackPressed() : Dynamic
   {
      if (_onBackPressed_func==null)
         _onBackPressed_func=nme.JNI.createMemberMethod("android.app.Activity","onBackPressed","()V");
      nme.JNI.callMember(_onBackPressed_func,__jobject,[]);
   }

   static var _onTouchEvent_func:Dynamic;
   public function onTouchEvent(arg0:Dynamic /*android.view.MotionEvent*/) : Dynamic
   {
      if (_onTouchEvent_func==null)
         _onTouchEvent_func=nme.JNI.createMemberMethod("android.app.Activity","onTouchEvent","(Landroid/view/MotionEvent;)Z");
      return nme.JNI.callMember(_onTouchEvent_func,__jobject,[arg0]);
   }

   static var _onTrackballEvent_func:Dynamic;
   public function onTrackballEvent(arg0:Dynamic /*android.view.MotionEvent*/) : Dynamic
   {
      if (_onTrackballEvent_func==null)
         _onTrackballEvent_func=nme.JNI.createMemberMethod("android.app.Activity","onTrackballEvent","(Landroid/view/MotionEvent;)Z");
      return nme.JNI.callMember(_onTrackballEvent_func,__jobject,[arg0]);
   }

   static var _onUserInteraction_func:Dynamic;
   public function onUserInteraction() : Dynamic
   {
      if (_onUserInteraction_func==null)
         _onUserInteraction_func=nme.JNI.createMemberMethod("android.app.Activity","onUserInteraction","()V");
      nme.JNI.callMember(_onUserInteraction_func,__jobject,[]);
   }

   static var _onWindowAttributesChanged_func:Dynamic;
   public function onWindowAttributesChanged(arg0:Dynamic /*android.view.WindowManager$LayoutParams*/) : Dynamic
   {
      if (_onWindowAttributesChanged_func==null)
         _onWindowAttributesChanged_func=nme.JNI.createMemberMethod("android.app.Activity","onWindowAttributesChanged","(Landroid/view/WindowManager$LayoutParams;)V");
      nme.JNI.callMember(_onWindowAttributesChanged_func,__jobject,[arg0]);
   }

   static var _onContentChanged_func:Dynamic;
   public function onContentChanged() : Dynamic
   {
      if (_onContentChanged_func==null)
         _onContentChanged_func=nme.JNI.createMemberMethod("android.app.Activity","onContentChanged","()V");
      nme.JNI.callMember(_onContentChanged_func,__jobject,[]);
   }

   static var _onWindowFocusChanged_func:Dynamic;
   public function onWindowFocusChanged(arg0:Bool) : Dynamic
   {
      if (_onWindowFocusChanged_func==null)
         _onWindowFocusChanged_func=nme.JNI.createMemberMethod("android.app.Activity","onWindowFocusChanged","(Z)V");
      nme.JNI.callMember(_onWindowFocusChanged_func,__jobject,[arg0]);
   }

   static var _onAttachedToWindow_func:Dynamic;
   public function onAttachedToWindow() : Dynamic
   {
      if (_onAttachedToWindow_func==null)
         _onAttachedToWindow_func=nme.JNI.createMemberMethod("android.app.Activity","onAttachedToWindow","()V");
      nme.JNI.callMember(_onAttachedToWindow_func,__jobject,[]);
   }

   static var _onDetachedFromWindow_func:Dynamic;
   public function onDetachedFromWindow() : Dynamic
   {
      if (_onDetachedFromWindow_func==null)
         _onDetachedFromWindow_func=nme.JNI.createMemberMethod("android.app.Activity","onDetachedFromWindow","()V");
      nme.JNI.callMember(_onDetachedFromWindow_func,__jobject,[]);
   }

   static var _hasWindowFocus_func:Dynamic;
   public function hasWindowFocus() : Dynamic
   {
      if (_hasWindowFocus_func==null)
         _hasWindowFocus_func=nme.JNI.createMemberMethod("android.app.Activity","hasWindowFocus","()Z");
      return nme.JNI.callMember(_hasWindowFocus_func,__jobject,[]);
   }

   static var _dispatchKeyEvent_func:Dynamic;
   public function dispatchKeyEvent(arg0:Dynamic /*android.view.KeyEvent*/) : Dynamic
   {
      if (_dispatchKeyEvent_func==null)
         _dispatchKeyEvent_func=nme.JNI.createMemberMethod("android.app.Activity","dispatchKeyEvent","(Landroid/view/KeyEvent;)Z");
      return nme.JNI.callMember(_dispatchKeyEvent_func,__jobject,[arg0]);
   }

   static var _dispatchTouchEvent_func:Dynamic;
   public function dispatchTouchEvent(arg0:Dynamic /*android.view.MotionEvent*/) : Dynamic
   {
      if (_dispatchTouchEvent_func==null)
         _dispatchTouchEvent_func=nme.JNI.createMemberMethod("android.app.Activity","dispatchTouchEvent","(Landroid/view/MotionEvent;)Z");
      return nme.JNI.callMember(_dispatchTouchEvent_func,__jobject,[arg0]);
   }

   static var _dispatchTrackballEvent_func:Dynamic;
   public function dispatchTrackballEvent(arg0:Dynamic /*android.view.MotionEvent*/) : Dynamic
   {
      if (_dispatchTrackballEvent_func==null)
         _dispatchTrackballEvent_func=nme.JNI.createMemberMethod("android.app.Activity","dispatchTrackballEvent","(Landroid/view/MotionEvent;)Z");
      return nme.JNI.callMember(_dispatchTrackballEvent_func,__jobject,[arg0]);
   }

   static var _dispatchPopulateAccessibilityEvent_func:Dynamic;
   public function dispatchPopulateAccessibilityEvent(arg0:Dynamic /*android.view.accessibility.AccessibilityEvent*/) : Dynamic
   {
      if (_dispatchPopulateAccessibilityEvent_func==null)
         _dispatchPopulateAccessibilityEvent_func=nme.JNI.createMemberMethod("android.app.Activity","dispatchPopulateAccessibilityEvent","(Landroid/view/accessibility/AccessibilityEvent;)Z");
      return nme.JNI.callMember(_dispatchPopulateAccessibilityEvent_func,__jobject,[arg0]);
   }

   static var _onCreatePanelView_func:Dynamic;
   public function onCreatePanelView(arg0:Int) : Dynamic
   {
      if (_onCreatePanelView_func==null)
         _onCreatePanelView_func=nme.JNI.createMemberMethod("android.app.Activity","onCreatePanelView","(I)Landroid/view/View;");
      return nme.JNI.callMember(_onCreatePanelView_func,__jobject,[arg0]);
   }

   static var _onCreatePanelMenu_func:Dynamic;
   public function onCreatePanelMenu(arg0:Int,arg1:Dynamic /*android.view.Menu*/) : Dynamic
   {
      if (_onCreatePanelMenu_func==null)
         _onCreatePanelMenu_func=nme.JNI.createMemberMethod("android.app.Activity","onCreatePanelMenu","(ILandroid/view/Menu;)Z");
      return nme.JNI.callMember(_onCreatePanelMenu_func,__jobject,[arg0,arg1]);
   }

   static var _onPreparePanel_func:Dynamic;
   public function onPreparePanel(arg0:Int,arg1:Dynamic /*android.view.View*/,arg2:Dynamic /*android.view.Menu*/) : Dynamic
   {
      if (_onPreparePanel_func==null)
         _onPreparePanel_func=nme.JNI.createMemberMethod("android.app.Activity","onPreparePanel","(ILandroid/view/View;Landroid/view/Menu;)Z");
      return nme.JNI.callMember(_onPreparePanel_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _onMenuOpened_func:Dynamic;
   public function onMenuOpened(arg0:Int,arg1:Dynamic /*android.view.Menu*/) : Dynamic
   {
      if (_onMenuOpened_func==null)
         _onMenuOpened_func=nme.JNI.createMemberMethod("android.app.Activity","onMenuOpened","(ILandroid/view/Menu;)Z");
      return nme.JNI.callMember(_onMenuOpened_func,__jobject,[arg0,arg1]);
   }

   static var _onMenuItemSelected_func:Dynamic;
   public function onMenuItemSelected(arg0:Int,arg1:Dynamic /*android.view.MenuItem*/) : Dynamic
   {
      if (_onMenuItemSelected_func==null)
         _onMenuItemSelected_func=nme.JNI.createMemberMethod("android.app.Activity","onMenuItemSelected","(ILandroid/view/MenuItem;)Z");
      return nme.JNI.callMember(_onMenuItemSelected_func,__jobject,[arg0,arg1]);
   }

   static var _onPanelClosed_func:Dynamic;
   public function onPanelClosed(arg0:Int,arg1:Dynamic /*android.view.Menu*/) : Dynamic
   {
      if (_onPanelClosed_func==null)
         _onPanelClosed_func=nme.JNI.createMemberMethod("android.app.Activity","onPanelClosed","(ILandroid/view/Menu;)V");
      nme.JNI.callMember(_onPanelClosed_func,__jobject,[arg0,arg1]);
   }

   static var _onCreateOptionsMenu_func:Dynamic;
   public function onCreateOptionsMenu(arg0:Dynamic /*android.view.Menu*/) : Dynamic
   {
      if (_onCreateOptionsMenu_func==null)
         _onCreateOptionsMenu_func=nme.JNI.createMemberMethod("android.app.Activity","onCreateOptionsMenu","(Landroid/view/Menu;)Z");
      return nme.JNI.callMember(_onCreateOptionsMenu_func,__jobject,[arg0]);
   }

   static var _onPrepareOptionsMenu_func:Dynamic;
   public function onPrepareOptionsMenu(arg0:Dynamic /*android.view.Menu*/) : Dynamic
   {
      if (_onPrepareOptionsMenu_func==null)
         _onPrepareOptionsMenu_func=nme.JNI.createMemberMethod("android.app.Activity","onPrepareOptionsMenu","(Landroid/view/Menu;)Z");
      return nme.JNI.callMember(_onPrepareOptionsMenu_func,__jobject,[arg0]);
   }

   static var _onOptionsItemSelected_func:Dynamic;
   public function onOptionsItemSelected(arg0:Dynamic /*android.view.MenuItem*/) : Dynamic
   {
      if (_onOptionsItemSelected_func==null)
         _onOptionsItemSelected_func=nme.JNI.createMemberMethod("android.app.Activity","onOptionsItemSelected","(Landroid/view/MenuItem;)Z");
      return nme.JNI.callMember(_onOptionsItemSelected_func,__jobject,[arg0]);
   }

   static var _onOptionsMenuClosed_func:Dynamic;
   public function onOptionsMenuClosed(arg0:Dynamic /*android.view.Menu*/) : Dynamic
   {
      if (_onOptionsMenuClosed_func==null)
         _onOptionsMenuClosed_func=nme.JNI.createMemberMethod("android.app.Activity","onOptionsMenuClosed","(Landroid/view/Menu;)V");
      nme.JNI.callMember(_onOptionsMenuClosed_func,__jobject,[arg0]);
   }

   static var _openOptionsMenu_func:Dynamic;
   public function openOptionsMenu() : Dynamic
   {
      if (_openOptionsMenu_func==null)
         _openOptionsMenu_func=nme.JNI.createMemberMethod("android.app.Activity","openOptionsMenu","()V");
      nme.JNI.callMember(_openOptionsMenu_func,__jobject,[]);
   }

   static var _closeOptionsMenu_func:Dynamic;
   public function closeOptionsMenu() : Dynamic
   {
      if (_closeOptionsMenu_func==null)
         _closeOptionsMenu_func=nme.JNI.createMemberMethod("android.app.Activity","closeOptionsMenu","()V");
      nme.JNI.callMember(_closeOptionsMenu_func,__jobject,[]);
   }

   static var _onCreateContextMenu_func:Dynamic;
   public function onCreateContextMenu(arg0:Dynamic /*android.view.ContextMenu*/,arg1:Dynamic /*android.view.View*/,arg2:Dynamic /*android.view.ContextMenu$ContextMenuInfo*/) : Dynamic
   {
      if (_onCreateContextMenu_func==null)
         _onCreateContextMenu_func=nme.JNI.createMemberMethod("android.app.Activity","onCreateContextMenu","(Landroid/view/ContextMenu;Landroid/view/View;Landroid/view/ContextMenu$ContextMenuInfo;)V");
      nme.JNI.callMember(_onCreateContextMenu_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _registerForContextMenu_func:Dynamic;
   public function registerForContextMenu(arg0:Dynamic /*android.view.View*/) : Dynamic
   {
      if (_registerForContextMenu_func==null)
         _registerForContextMenu_func=nme.JNI.createMemberMethod("android.app.Activity","registerForContextMenu","(Landroid/view/View;)V");
      nme.JNI.callMember(_registerForContextMenu_func,__jobject,[arg0]);
   }

   static var _unregisterForContextMenu_func:Dynamic;
   public function unregisterForContextMenu(arg0:Dynamic /*android.view.View*/) : Dynamic
   {
      if (_unregisterForContextMenu_func==null)
         _unregisterForContextMenu_func=nme.JNI.createMemberMethod("android.app.Activity","unregisterForContextMenu","(Landroid/view/View;)V");
      nme.JNI.callMember(_unregisterForContextMenu_func,__jobject,[arg0]);
   }

   static var _openContextMenu_func:Dynamic;
   public function openContextMenu(arg0:Dynamic /*android.view.View*/) : Dynamic
   {
      if (_openContextMenu_func==null)
         _openContextMenu_func=nme.JNI.createMemberMethod("android.app.Activity","openContextMenu","(Landroid/view/View;)V");
      nme.JNI.callMember(_openContextMenu_func,__jobject,[arg0]);
   }

   static var _closeContextMenu_func:Dynamic;
   public function closeContextMenu() : Dynamic
   {
      if (_closeContextMenu_func==null)
         _closeContextMenu_func=nme.JNI.createMemberMethod("android.app.Activity","closeContextMenu","()V");
      nme.JNI.callMember(_closeContextMenu_func,__jobject,[]);
   }

   static var _onContextItemSelected_func:Dynamic;
   public function onContextItemSelected(arg0:Dynamic /*android.view.MenuItem*/) : Dynamic
   {
      if (_onContextItemSelected_func==null)
         _onContextItemSelected_func=nme.JNI.createMemberMethod("android.app.Activity","onContextItemSelected","(Landroid/view/MenuItem;)Z");
      return nme.JNI.callMember(_onContextItemSelected_func,__jobject,[arg0]);
   }

   static var _onContextMenuClosed_func:Dynamic;
   public function onContextMenuClosed(arg0:Dynamic /*android.view.Menu*/) : Dynamic
   {
      if (_onContextMenuClosed_func==null)
         _onContextMenuClosed_func=nme.JNI.createMemberMethod("android.app.Activity","onContextMenuClosed","(Landroid/view/Menu;)V");
      nme.JNI.callMember(_onContextMenuClosed_func,__jobject,[arg0]);
   }

   static var _showDialog_func:Dynamic;
   public function showDialog(arg0:Int) : Dynamic
   {
      if (_showDialog_func==null)
         _showDialog_func=nme.JNI.createMemberMethod("android.app.Activity","showDialog","(I)V");
      nme.JNI.callMember(_showDialog_func,__jobject,[arg0]);
   }

   static var _showDialog1_func:Dynamic;
   public function showDialog1(arg0:Int,arg1:Dynamic /*android.os.Bundle*/) : Dynamic
   {
      if (_showDialog1_func==null)
         _showDialog1_func=nme.JNI.createMemberMethod("android.app.Activity","showDialog","(ILandroid/os/Bundle;)Z");
      return nme.JNI.callMember(_showDialog1_func,__jobject,[arg0,arg1]);
   }

   static var _dismissDialog_func:Dynamic;
   public function dismissDialog(arg0:Int) : Dynamic
   {
      if (_dismissDialog_func==null)
         _dismissDialog_func=nme.JNI.createMemberMethod("android.app.Activity","dismissDialog","(I)V");
      nme.JNI.callMember(_dismissDialog_func,__jobject,[arg0]);
   }

   static var _removeDialog_func:Dynamic;
   public function removeDialog(arg0:Int) : Dynamic
   {
      if (_removeDialog_func==null)
         _removeDialog_func=nme.JNI.createMemberMethod("android.app.Activity","removeDialog","(I)V");
      nme.JNI.callMember(_removeDialog_func,__jobject,[arg0]);
   }

   static var _onSearchRequested_func:Dynamic;
   public function onSearchRequested() : Dynamic
   {
      if (_onSearchRequested_func==null)
         _onSearchRequested_func=nme.JNI.createMemberMethod("android.app.Activity","onSearchRequested","()Z");
      return nme.JNI.callMember(_onSearchRequested_func,__jobject,[]);
   }

   static var _startSearch_func:Dynamic;
   public function startSearch(arg0:String,arg1:Bool,arg2:Dynamic /*android.os.Bundle*/,arg3:Bool) : Dynamic
   {
      if (_startSearch_func==null)
         _startSearch_func=nme.JNI.createMemberMethod("android.app.Activity","startSearch","(Ljava/lang/String;ZLandroid/os/Bundle;Z)V");
      nme.JNI.callMember(_startSearch_func,__jobject,[arg0,arg1,arg2,arg3]);
   }

   static var _triggerSearch_func:Dynamic;
   public function triggerSearch(arg0:String,arg1:Dynamic /*android.os.Bundle*/) : Dynamic
   {
      if (_triggerSearch_func==null)
         _triggerSearch_func=nme.JNI.createMemberMethod("android.app.Activity","triggerSearch","(Ljava/lang/String;Landroid/os/Bundle;)V");
      nme.JNI.callMember(_triggerSearch_func,__jobject,[arg0,arg1]);
   }

   static var _takeKeyEvents_func:Dynamic;
   public function takeKeyEvents(arg0:Bool) : Dynamic
   {
      if (_takeKeyEvents_func==null)
         _takeKeyEvents_func=nme.JNI.createMemberMethod("android.app.Activity","takeKeyEvents","(Z)V");
      nme.JNI.callMember(_takeKeyEvents_func,__jobject,[arg0]);
   }

   static var _requestWindowFeature_func:Dynamic;
   public function requestWindowFeature(arg0:Int) : Dynamic
   {
      if (_requestWindowFeature_func==null)
         _requestWindowFeature_func=nme.JNI.createMemberMethod("android.app.Activity","requestWindowFeature","(I)Z");
      return nme.JNI.callMember(_requestWindowFeature_func,__jobject,[arg0]);
   }

   static var _setFeatureDrawableResource_func:Dynamic;
   public function setFeatureDrawableResource(arg0:Int,arg1:Int) : Dynamic
   {
      if (_setFeatureDrawableResource_func==null)
         _setFeatureDrawableResource_func=nme.JNI.createMemberMethod("android.app.Activity","setFeatureDrawableResource","(II)V");
      nme.JNI.callMember(_setFeatureDrawableResource_func,__jobject,[arg0,arg1]);
   }

   static var _setFeatureDrawableUri_func:Dynamic;
   public function setFeatureDrawableUri(arg0:Int,arg1:Dynamic /*android.net.Uri*/) : Dynamic
   {
      if (_setFeatureDrawableUri_func==null)
         _setFeatureDrawableUri_func=nme.JNI.createMemberMethod("android.app.Activity","setFeatureDrawableUri","(ILandroid/net/Uri;)V");
      nme.JNI.callMember(_setFeatureDrawableUri_func,__jobject,[arg0,arg1]);
   }

   static var _setFeatureDrawable_func:Dynamic;
   public function setFeatureDrawable(arg0:Int,arg1:Dynamic /*android.graphics.drawable.Drawable*/) : Dynamic
   {
      if (_setFeatureDrawable_func==null)
         _setFeatureDrawable_func=nme.JNI.createMemberMethod("android.app.Activity","setFeatureDrawable","(ILandroid/graphics/drawable/Drawable;)V");
      nme.JNI.callMember(_setFeatureDrawable_func,__jobject,[arg0,arg1]);
   }

   static var _setFeatureDrawableAlpha_func:Dynamic;
   public function setFeatureDrawableAlpha(arg0:Int,arg1:Int) : Dynamic
   {
      if (_setFeatureDrawableAlpha_func==null)
         _setFeatureDrawableAlpha_func=nme.JNI.createMemberMethod("android.app.Activity","setFeatureDrawableAlpha","(II)V");
      nme.JNI.callMember(_setFeatureDrawableAlpha_func,__jobject,[arg0,arg1]);
   }

   static var _getLayoutInflater_func:Dynamic;
   public function getLayoutInflater() : Dynamic
   {
      if (_getLayoutInflater_func==null)
         _getLayoutInflater_func=nme.JNI.createMemberMethod("android.app.Activity","getLayoutInflater","()Landroid/view/LayoutInflater;");
      return nme.JNI.callMember(_getLayoutInflater_func,__jobject,[]);
   }

   static var _getMenuInflater_func:Dynamic;
   public function getMenuInflater() : Dynamic
   {
      if (_getMenuInflater_func==null)
         _getMenuInflater_func=nme.JNI.createMemberMethod("android.app.Activity","getMenuInflater","()Landroid/view/MenuInflater;");
      return nme.JNI.callMember(_getMenuInflater_func,__jobject,[]);
   }

   static var _startActivityForResult_func:Dynamic;
   public function startActivityForResult(arg0:Dynamic /*android.content.Intent*/,arg1:Int) : Dynamic
   {
      if (_startActivityForResult_func==null)
         _startActivityForResult_func=nme.JNI.createMemberMethod("android.app.Activity","startActivityForResult","(Landroid/content/Intent;I)V");
      nme.JNI.callMember(_startActivityForResult_func,__jobject,[arg0,arg1]);
   }

   static var _startIntentSenderForResult_func:Dynamic;
   public function startIntentSenderForResult(arg0:Dynamic /*android.content.IntentSender*/,arg1:Int,arg2:Dynamic /*android.content.Intent*/,arg3:Int,arg4:Int,arg5:Int) : Dynamic
   {
      if (_startIntentSenderForResult_func==null)
         _startIntentSenderForResult_func=nme.JNI.createMemberMethod("android.app.Activity","startIntentSenderForResult","(Landroid/content/IntentSender;ILandroid/content/Intent;III)V");
      nme.JNI.callMember(_startIntentSenderForResult_func,__jobject,[arg0,arg1,arg2,arg3,arg4,arg5]);
   }

   static var _startActivity_func:Dynamic;
   public override function startActivity(arg0:Dynamic /*android.content.Intent*/) : Dynamic
   {
      if (_startActivity_func==null)
         _startActivity_func=nme.JNI.createMemberMethod("android.app.Activity","startActivity","(Landroid/content/Intent;)V");
      nme.JNI.callMember(_startActivity_func,__jobject,[arg0]);
   }

   static var _startIntentSender_func:Dynamic;
   public override function startIntentSender(arg0:Dynamic /*android.content.IntentSender*/,arg1:Dynamic /*android.content.Intent*/,arg2:Int,arg3:Int,arg4:Int) : Dynamic
   {
      if (_startIntentSender_func==null)
         _startIntentSender_func=nme.JNI.createMemberMethod("android.app.Activity","startIntentSender","(Landroid/content/IntentSender;Landroid/content/Intent;III)V");
      nme.JNI.callMember(_startIntentSender_func,__jobject,[arg0,arg1,arg2,arg3,arg4]);
   }

   static var _startActivityIfNeeded_func:Dynamic;
   public function startActivityIfNeeded(arg0:Dynamic /*android.content.Intent*/,arg1:Int) : Dynamic
   {
      if (_startActivityIfNeeded_func==null)
         _startActivityIfNeeded_func=nme.JNI.createMemberMethod("android.app.Activity","startActivityIfNeeded","(Landroid/content/Intent;I)Z");
      return nme.JNI.callMember(_startActivityIfNeeded_func,__jobject,[arg0,arg1]);
   }

   static var _startNextMatchingActivity_func:Dynamic;
   public function startNextMatchingActivity(arg0:Dynamic /*android.content.Intent*/) : Dynamic
   {
      if (_startNextMatchingActivity_func==null)
         _startNextMatchingActivity_func=nme.JNI.createMemberMethod("android.app.Activity","startNextMatchingActivity","(Landroid/content/Intent;)Z");
      return nme.JNI.callMember(_startNextMatchingActivity_func,__jobject,[arg0]);
   }

   static var _startActivityFromChild_func:Dynamic;
   public function startActivityFromChild(arg0:android.app.Activity,arg1:Dynamic /*android.content.Intent*/,arg2:Int) : Dynamic
   {
      if (_startActivityFromChild_func==null)
         _startActivityFromChild_func=nme.JNI.createMemberMethod("android.app.Activity","startActivityFromChild","(Landroid/app/Activity;Landroid/content/Intent;I)V");
      nme.JNI.callMember(_startActivityFromChild_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _startIntentSenderFromChild_func:Dynamic;
   public function startIntentSenderFromChild(arg0:android.app.Activity,arg1:Dynamic /*android.content.IntentSender*/,arg2:Int,arg3:Dynamic /*android.content.Intent*/,arg4:Int,arg5:Int,arg6:Int) : Dynamic
   {
      if (_startIntentSenderFromChild_func==null)
         _startIntentSenderFromChild_func=nme.JNI.createMemberMethod("android.app.Activity","startIntentSenderFromChild","(Landroid/app/Activity;Landroid/content/IntentSender;ILandroid/content/Intent;III)V");
      nme.JNI.callMember(_startIntentSenderFromChild_func,__jobject,[arg0,arg1,arg2,arg3,arg4,arg5,arg6]);
   }

   static var _overridePendingTransition_func:Dynamic;
   public function overridePendingTransition(arg0:Int,arg1:Int) : Dynamic
   {
      if (_overridePendingTransition_func==null)
         _overridePendingTransition_func=nme.JNI.createMemberMethod("android.app.Activity","overridePendingTransition","(II)V");
      nme.JNI.callMember(_overridePendingTransition_func,__jobject,[arg0,arg1]);
   }

   static var _setResult_func:Dynamic;
   public function setResult(arg0:Int) : Dynamic
   {
      if (_setResult_func==null)
         _setResult_func=nme.JNI.createMemberMethod("android.app.Activity","setResult","(I)V");
      nme.JNI.callMember(_setResult_func,__jobject,[arg0]);
   }

   static var _setResult1_func:Dynamic;
   public function setResult1(arg0:Int,arg1:Dynamic /*android.content.Intent*/) : Dynamic
   {
      if (_setResult1_func==null)
         _setResult1_func=nme.JNI.createMemberMethod("android.app.Activity","setResult","(ILandroid/content/Intent;)V");
      nme.JNI.callMember(_setResult1_func,__jobject,[arg0,arg1]);
   }

   static var _getCallingPackage_func:Dynamic;
   public function getCallingPackage() : Dynamic
   {
      if (_getCallingPackage_func==null)
         _getCallingPackage_func=nme.JNI.createMemberMethod("android.app.Activity","getCallingPackage","()Ljava/lang/String;");
      return nme.JNI.callMember(_getCallingPackage_func,__jobject,[]);
   }

   static var _getCallingActivity_func:Dynamic;
   public function getCallingActivity() : Dynamic
   {
      if (_getCallingActivity_func==null)
         _getCallingActivity_func=nme.JNI.createMemberMethod("android.app.Activity","getCallingActivity","()Landroid/content/ComponentName;");
      return nme.JNI.callMember(_getCallingActivity_func,__jobject,[]);
   }

   static var _setVisible_func:Dynamic;
   public function setVisible(arg0:Bool) : Dynamic
   {
      if (_setVisible_func==null)
         _setVisible_func=nme.JNI.createMemberMethod("android.app.Activity","setVisible","(Z)V");
      nme.JNI.callMember(_setVisible_func,__jobject,[arg0]);
   }

   static var _isFinishing_func:Dynamic;
   public function isFinishing() : Dynamic
   {
      if (_isFinishing_func==null)
         _isFinishing_func=nme.JNI.createMemberMethod("android.app.Activity","isFinishing","()Z");
      return nme.JNI.callMember(_isFinishing_func,__jobject,[]);
   }

   static var _finish_func:Dynamic;
   public function finish() : Dynamic
   {
      if (_finish_func==null)
         _finish_func=nme.JNI.createMemberMethod("android.app.Activity","finish","()V");
      nme.JNI.callMember(_finish_func,__jobject,[]);
   }

   static var _finishFromChild_func:Dynamic;
   public function finishFromChild(arg0:android.app.Activity) : Dynamic
   {
      if (_finishFromChild_func==null)
         _finishFromChild_func=nme.JNI.createMemberMethod("android.app.Activity","finishFromChild","(Landroid/app/Activity;)V");
      nme.JNI.callMember(_finishFromChild_func,__jobject,[arg0]);
   }

   static var _finishActivity_func:Dynamic;
   public function finishActivity(arg0:Int) : Dynamic
   {
      if (_finishActivity_func==null)
         _finishActivity_func=nme.JNI.createMemberMethod("android.app.Activity","finishActivity","(I)V");
      nme.JNI.callMember(_finishActivity_func,__jobject,[arg0]);
   }

   static var _finishActivityFromChild_func:Dynamic;
   public function finishActivityFromChild(arg0:android.app.Activity,arg1:Int) : Dynamic
   {
      if (_finishActivityFromChild_func==null)
         _finishActivityFromChild_func=nme.JNI.createMemberMethod("android.app.Activity","finishActivityFromChild","(Landroid/app/Activity;I)V");
      nme.JNI.callMember(_finishActivityFromChild_func,__jobject,[arg0,arg1]);
   }

   static var _createPendingResult_func:Dynamic;
   public function createPendingResult(arg0:Int,arg1:Dynamic /*android.content.Intent*/,arg2:Int) : Dynamic
   {
      if (_createPendingResult_func==null)
         _createPendingResult_func=nme.JNI.createMemberMethod("android.app.Activity","createPendingResult","(ILandroid/content/Intent;I)Landroid/app/PendingIntent;");
      return nme.JNI.callMember(_createPendingResult_func,__jobject,[arg0,arg1,arg2]);
   }

   static var _setRequestedOrientation_func:Dynamic;
   public function setRequestedOrientation(arg0:Int) : Dynamic
   {
      if (_setRequestedOrientation_func==null)
         _setRequestedOrientation_func=nme.JNI.createMemberMethod("android.app.Activity","setRequestedOrientation","(I)V");
      nme.JNI.callMember(_setRequestedOrientation_func,__jobject,[arg0]);
   }

   static var _getRequestedOrientation_func:Dynamic;
   public function getRequestedOrientation() : Dynamic
   {
      if (_getRequestedOrientation_func==null)
         _getRequestedOrientation_func=nme.JNI.createMemberMethod("android.app.Activity","getRequestedOrientation","()I");
      return nme.JNI.callMember(_getRequestedOrientation_func,__jobject,[]);
   }

   static var _getTaskId_func:Dynamic;
   public function getTaskId() : Dynamic
   {
      if (_getTaskId_func==null)
         _getTaskId_func=nme.JNI.createMemberMethod("android.app.Activity","getTaskId","()I");
      return nme.JNI.callMember(_getTaskId_func,__jobject,[]);
   }

   static var _isTaskRoot_func:Dynamic;
   public function isTaskRoot() : Dynamic
   {
      if (_isTaskRoot_func==null)
         _isTaskRoot_func=nme.JNI.createMemberMethod("android.app.Activity","isTaskRoot","()Z");
      return nme.JNI.callMember(_isTaskRoot_func,__jobject,[]);
   }

   static var _moveTaskToBack_func:Dynamic;
   public function moveTaskToBack(arg0:Bool) : Dynamic
   {
      if (_moveTaskToBack_func==null)
         _moveTaskToBack_func=nme.JNI.createMemberMethod("android.app.Activity","moveTaskToBack","(Z)Z");
      return nme.JNI.callMember(_moveTaskToBack_func,__jobject,[arg0]);
   }

   static var _getLocalClassName_func:Dynamic;
   public function getLocalClassName() : Dynamic
   {
      if (_getLocalClassName_func==null)
         _getLocalClassName_func=nme.JNI.createMemberMethod("android.app.Activity","getLocalClassName","()Ljava/lang/String;");
      return nme.JNI.callMember(_getLocalClassName_func,__jobject,[]);
   }

   static var _getComponentName_func:Dynamic;
   public function getComponentName() : Dynamic
   {
      if (_getComponentName_func==null)
         _getComponentName_func=nme.JNI.createMemberMethod("android.app.Activity","getComponentName","()Landroid/content/ComponentName;");
      return nme.JNI.callMember(_getComponentName_func,__jobject,[]);
   }

   static var _getPreferences_func:Dynamic;
   public function getPreferences(arg0:Int) : Dynamic
   {
      if (_getPreferences_func==null)
         _getPreferences_func=nme.JNI.createMemberMethod("android.app.Activity","getPreferences","(I)Landroid/content/SharedPreferences;");
      return nme.JNI.callMember(_getPreferences_func,__jobject,[arg0]);
   }

   static var _getSystemService_func:Dynamic;
   public override function getSystemService(arg0:String) : Dynamic
   {
      if (_getSystemService_func==null)
         _getSystemService_func=nme.JNI.createMemberMethod("android.app.Activity","getSystemService","(Ljava/lang/String;)Ljava/lang/Object;");
      return nme.JNI.callMember(_getSystemService_func,__jobject,[arg0]);
   }

   static var _setTitle_func:Dynamic;
   public function setTitle(arg0:String) : Dynamic
   {
      if (_setTitle_func==null)
         _setTitle_func=nme.JNI.createMemberMethod("android.app.Activity","setTitle","(Ljava/lang/CharSequence;)V");
      nme.JNI.callMember(_setTitle_func,__jobject,[arg0]);
   }

   static var _setTitle1_func:Dynamic;
   public function setTitle1(arg0:Int) : Dynamic
   {
      if (_setTitle1_func==null)
         _setTitle1_func=nme.JNI.createMemberMethod("android.app.Activity","setTitle","(I)V");
      nme.JNI.callMember(_setTitle1_func,__jobject,[arg0]);
   }

   static var _setTitleColor_func:Dynamic;
   public function setTitleColor(arg0:Int) : Dynamic
   {
      if (_setTitleColor_func==null)
         _setTitleColor_func=nme.JNI.createMemberMethod("android.app.Activity","setTitleColor","(I)V");
      nme.JNI.callMember(_setTitleColor_func,__jobject,[arg0]);
   }

   static var _getTitle_func:Dynamic;
   public function getTitle() : Dynamic
   {
      if (_getTitle_func==null)
         _getTitle_func=nme.JNI.createMemberMethod("android.app.Activity","getTitle","()Ljava/lang/CharSequence;");
      return nme.JNI.callMember(_getTitle_func,__jobject,[]);
   }

   static var _getTitleColor_func:Dynamic;
   public function getTitleColor() : Dynamic
   {
      if (_getTitleColor_func==null)
         _getTitleColor_func=nme.JNI.createMemberMethod("android.app.Activity","getTitleColor","()I");
      return nme.JNI.callMember(_getTitleColor_func,__jobject,[]);
   }

   static var _setProgressBarVisibility_func:Dynamic;
   public function setProgressBarVisibility(arg0:Bool) : Dynamic
   {
      if (_setProgressBarVisibility_func==null)
         _setProgressBarVisibility_func=nme.JNI.createMemberMethod("android.app.Activity","setProgressBarVisibility","(Z)V");
      nme.JNI.callMember(_setProgressBarVisibility_func,__jobject,[arg0]);
   }

   static var _setProgressBarIndeterminateVisibility_func:Dynamic;
   public function setProgressBarIndeterminateVisibility(arg0:Bool) : Dynamic
   {
      if (_setProgressBarIndeterminateVisibility_func==null)
         _setProgressBarIndeterminateVisibility_func=nme.JNI.createMemberMethod("android.app.Activity","setProgressBarIndeterminateVisibility","(Z)V");
      nme.JNI.callMember(_setProgressBarIndeterminateVisibility_func,__jobject,[arg0]);
   }

   static var _setProgressBarIndeterminate_func:Dynamic;
   public function setProgressBarIndeterminate(arg0:Bool) : Dynamic
   {
      if (_setProgressBarIndeterminate_func==null)
         _setProgressBarIndeterminate_func=nme.JNI.createMemberMethod("android.app.Activity","setProgressBarIndeterminate","(Z)V");
      nme.JNI.callMember(_setProgressBarIndeterminate_func,__jobject,[arg0]);
   }

   static var _setProgress_func:Dynamic;
   public function setProgress(arg0:Int) : Dynamic
   {
      if (_setProgress_func==null)
         _setProgress_func=nme.JNI.createMemberMethod("android.app.Activity","setProgress","(I)V");
      nme.JNI.callMember(_setProgress_func,__jobject,[arg0]);
   }

   static var _setSecondaryProgress_func:Dynamic;
   public function setSecondaryProgress(arg0:Int) : Dynamic
   {
      if (_setSecondaryProgress_func==null)
         _setSecondaryProgress_func=nme.JNI.createMemberMethod("android.app.Activity","setSecondaryProgress","(I)V");
      nme.JNI.callMember(_setSecondaryProgress_func,__jobject,[arg0]);
   }

   static var _setVolumeControlStream_func:Dynamic;
   public function setVolumeControlStream(arg0:Int) : Dynamic
   {
      if (_setVolumeControlStream_func==null)
         _setVolumeControlStream_func=nme.JNI.createMemberMethod("android.app.Activity","setVolumeControlStream","(I)V");
      nme.JNI.callMember(_setVolumeControlStream_func,__jobject,[arg0]);
   }

   static var _getVolumeControlStream_func:Dynamic;
   public function getVolumeControlStream() : Dynamic
   {
      if (_getVolumeControlStream_func==null)
         _getVolumeControlStream_func=nme.JNI.createMemberMethod("android.app.Activity","getVolumeControlStream","()I");
      return nme.JNI.callMember(_getVolumeControlStream_func,__jobject,[]);
   }

   static var _runOnUiThread_func:Dynamic;
   public function runOnUiThread(arg0:Dynamic /*java.lang.Runnable*/) : Dynamic
   {
      if (_runOnUiThread_func==null)
         _runOnUiThread_func=nme.JNI.createMemberMethod("android.app.Activity","runOnUiThread","(Ljava/lang/Runnable;)V");
      nme.JNI.callMember(_runOnUiThread_func,__jobject,[arg0]);
   }

   static var _onCreateView_func:Dynamic;
   public function onCreateView(arg0:String,arg1:Dynamic /*android.content.Context*/,arg2:Dynamic /*android.util.AttributeSet*/) : Dynamic
   {
      if (_onCreateView_func==null)
         _onCreateView_func=nme.JNI.createMemberMethod("android.app.Activity","onCreateView","(Ljava/lang/String;Landroid/content/Context;Landroid/util/AttributeSet;)Landroid/view/View;");
      return nme.JNI.callMember(_onCreateView_func,__jobject,[arg0,arg1,arg2]);
   }

}
