package nme.ui;
#if (cpp || neko)


enum MultitouchInputMode
{
   NONE;
   TOUCH_POINT;
   GESTURE;
}


#else
typedef MultitouchInputMode = flash.ui.MultitouchInputMode;
#end