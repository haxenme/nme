import nme.Manager;
import nme.Surface;
import nme.Rect;
import nme.Point;
import nme.TTF;

class SimpleCollision
{
  static var mainObject : SimpleCollision;
	
  var running : Bool;
  var click : Int;
  var batR : Rect;
  var bat : Point;
  var bat2 : Point;
  var batSrf : Surface;
  var curTime : Float;
  var prevTime : Float;
	
  static function main()
  {
    mainObject = new SimpleCollision();
  }
	
  public function new()
  {
    prevTime = 0;
    curTime = 0;
    click = 0;
    var mng = new Manager( 200, 200, "Collision Test", false, "ico.gif" );
		
    batSrf = new Surface( "bat.PNG" );
		
    batR = new Rect(24, 63, 65, 44);
    bat = new Point( 0, 0 );
	bat2 = new Point( 50, 50 );
		
    batSrf.setKey( 255, 0, 255 );
			
    var fps : Float;
    running = true;
    while (running)
    {
      mng.events();
      switch mng.getEventType()
      {
        case et_mousebutton_down:
            if ( mng.clickRect( mng.mouseX(), mng.mouseY(), new Rect( bat.x, bat.y, batR.w - bat.x, batR.h - bat.y ) ) )
              click = 1;
            else
              click = 0;
        case et_mousebutton_up:
            click = 0;

        case et_mousemove:
          if ( click == 1 )
          {
            bat.x += mng.mouseMoveX();
            bat.y += mng.mouseMoveY();
          }
        case et_quit:
          running = false;
        default:
      }

      if( batSrf.collisionPixel( batSrf, batR, batR, new Point( bat.x - bat2.x, bat.y - bat2.y ) ) )
        mng.clear( 0xFF0000 );
      else if( batSrf.collisionBox( batR, batR, new Point( bat.x - bat2.x, bat.y - bat2.y ) ) )
        mng.clear( 0xFF9900 );
      else
        mng.clear( 0x00000000 );
	
      batSrf.draw(Manager.getScreen(), batR, bat );
      batSrf.draw(Manager.getScreen(), batR, bat2 );
		
      mng.flip();
    }
    batSrf.free();
    mng.close();
  }
}
