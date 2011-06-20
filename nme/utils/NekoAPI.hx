package nme.utils;

class NekoAPI
{
   #if neko
   static function __init__()
   {
       var init = neko.Lib.load("nekoapi","neko_api_init2",2);
       init(function(s) return new String(s),
            function(len:Int) { var r=[]; if (len>0) r[len-1]=null; return r; } );
   }
   #end
}

