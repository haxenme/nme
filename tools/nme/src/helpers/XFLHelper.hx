package;

class XFLHelper
{
   public static function preprocess(project:NMEProject):Void
   {
      for(library in project.libraries)
         if (library.type == LibraryType.XFL)
            throw "XFL not supported";
   }
}
