// import nme.Assets;

::foreach ndlls::::importStatic::::end::



@:cppFileCode("
::foreach ndlls:: ::if (registerPrim!=null):: extern \"C\" int ::registerPrim::();
::end::::end::
")
class ApplicationMain
{
   public static function main()
   {
      // nme.AssetData.create();

      ::if REDIRECT_TRACE::
      //nme.Lib.redirectTrace();
      ::end::

      //nme.app.Application.setPackage("::APP_COMPANY::", "::APP_FILE::", "::APP_PACKAGE::", "::APP_VERSION::");

      new ::APP_MAIN::();
   }

   @:keep function keepMe() return Reflect.callMethod;

   public static function __init__ ()
   {
      ::foreach ndlls:: ::if (registerPrim!=null):: untyped __cpp__("::registerPrim::()");
::end:: ::end::
   }
}

