class ApplicationMain
{
   public static function main()
   {
      nme.Lib.create(
           function(){ ::APP_MAIN::.main(); },
           ::WIN_WIDTH::, ::WIN_HEIGHT::,
           ::WIN_FPS::,
           ::WIN_BACKGROUND::,
             ( ::WIN_HARDWARE::   ? nme.Lib.HARDWARE  : 0) |
             ( ::WIN_RESIZEABLE:: ? nme.Lib.RESIZABLE : 0),
          "::APP_TITLE::",
          "::APP_ICON::"
          );
   }
}

