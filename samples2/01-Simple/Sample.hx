import nme2.Manager;

class Sample
{

public static function main()
{
   Manager.init(320,480, Manager.OPENGL | Manager.RESIZABLE);
   Manager.mainLoop();
}

}
