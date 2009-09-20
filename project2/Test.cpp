#include <Graphics.h>
#include <TextField.h>
#include <Display.h>
#include <Utils.h>
#include <Surface.h>

DisplayObject *gWin = 0;

void Handler(Event &ioEvent,void *inStage)
{
   if (ioEvent.mType==etClose)
      TerminateMainLoop();
   else
   {
   Stage *stage = (Stage *)inStage;

      DisplayObject *shape = stage->getChildAt(0);
	   double x = shape->getX();
	   double rot = shape->getRotation();
      rot += 1;
	   x += 1;
      if (x>800) x = 0;
      shape->setX(x);
      shape->setRotation(rot);
      gWin->setScrollRect( DRect(0,x/2,200,200) );

   if (ioEvent.mType==etNextFrame)
      stage->RenderStage();
   }
}


int main(int inargc,char **arvg)
{
   Frame *frame = CreateMainFrame(640,400,wfResizable,L"Hello");


   // Render to bitmap ...
   Surface *bg = new SimpleSurface(32,32, pfXRGB);
   {
      Graphics gfx;
      gfx.lineStyle(1,0x0000ff);
      gfx.moveTo(0,0);
      gfx.lineTo(32,32);
      gfx.moveTo(0,32);
      gfx.lineTo(32,0);
      bg->Clear(0x002020);
      AutoSurfaceRender render(bg);
      gfx.Render(render.Target(),RenderState(bg,4));
   }



   Stage *stage = frame->GetStage();
   stage->IncRef();
   stage->SetEventHandler(Handler,stage);

   GraphicsGradientFill *fill = new GraphicsGradientFill(true,
                                 Matrix().createGradientBox(200,200,45,-100,-100), smPad );
   fill->AddStop( 0xffffff, 1, 0 );
   fill->AddStop( 0xff0000, 1, 0.25 );
   fill->AddStop( 0x00ff00, 1, 0.5 );
   fill->AddStop( 0x0000ff, 1, 0.75 );
   fill->AddStop( 0xff00ff, 1, 1 );

   DisplayObject *shape = new DisplayObject();
   Graphics &gfx = shape->GetGraphics();
   gfx.addData(fill);
   //gfx.beginBitmapFill(bg, Matrix().createGradientBox(32,32), true,true );
   gfx.lineStyle(5,0x202040,0.75,true,ssmNormal,scRound,sjMiter);
   gfx.moveTo(-100,-100);
   gfx.lineTo(-100,100);
   gfx.curveTo(0,180,100,100);
   gfx.lineTo(100,-100);
   gfx.lineTo(-100,-100);
   shape->setY(200);
   stage->addChild(shape);

   DisplayObjectContainer *win = new DisplayObjectContainer(true);
   Graphics &g = win->GetGraphics();
   g.lineStyle(5,0x404080);
   g.beginFill(0x8080f0);
   //g.drawRect(0,0,200,100);
   //g.drawEllipse(0,0,200,100);
   g.drawRoundRect(0,0,200,100,10,10);
   TextField *tf = new TextField(false);
   tf->setHTMLText(L"<font color='#ffffff' size=14>Window 1</font>");
   tf->setX( 10 );
   tf->setY( 10 );
   win->addChild(tf);
   //g.drawCircle(0,0,200);
   stage->addChild(win,true);
   win->setX(100);
   win->setY(100);
   win->setScaleX(2);
   win->setScaleY(2);
   win->setScale9Grid( DRect(10,10,180,80) );
   win->setScrollRect( DRect(-15,-15,200,200) );
   gWin = win;

   TextField *text = new TextField(false);
   //text->setText(L"Hello, abcdefghijklmnopqrstuvwxyz 1234567890 ABCDEFGHIGKLMNOPQRSTUVWXYZjjj");
   //text->setHTMLText(L"HHHH");
   text->setX( 200 );
   text->setY( 2 );
   //text->background = true;
   text->backgroundColor.SetRGBNative(0xb0b0f0);
   text->autoSize = asLeft;
   text->multiline = true;
   text->wordWrap = true;
   text->mRect.w = 600;
   text->embedFonts = false;
   //text->setHTMLText(L"<font size=20>Hello <font color='#202060' face='times'>go\nod-<br>bye <b>gone for good!</b></font></font>");
   //text->setHTMLText(L"H");

   std::string contents = "Hello !";
   /*
   std::string contents;
   FILE *f = fopen("Test.cpp","rb");
   if (f)
   {
      int ch;
      while( (ch=fgetc(f))!=EOF )
      {
         if (ch==10 || (ch>26 && ch<127) )
            contents += (char)ch;
      }
      fclose(f);
   }
   */
   text->setText( UTF8ToWide(contents.c_str()) );

   stage->addChild(text);

   #if 0
   DisplayObject *shape = new DisplayObject(false);
   shape->GetGraphics().beginFill(0xe0e0e0);
   shape->GetGraphics().drawRect(-100,-20,200,100);
   //shape->setScale9( Rect(-40,-20,80,40) );
   shape->setRotation( 20 );
   //shape->setWidth( 200 );
   shape->setScaleX( 1.5 );
	printf("Size  : %fx%f\n", shape->getWidth(), shape->getHeight() );
	Matrix m = shape->GetLocalMatrix();
	printf("a=%f b=%f c=%f d=%f\n", m.m00, m.m10, m.m01, m.m11 );
	printf(" -- set -- \n");
   shape->setWidth( 300 );

	printf("Size  : %fx%f\n", shape->getWidth(), shape->getHeight() );
	printf("Scale  : %fx%f\n", shape->getScaleX(), shape->getScaleY() );
	m = shape->GetLocalMatrix();
	printf("a=%f b=%f c=%f d=%f\n", m.m00, m.m10, m.m01, m.m11 );

   //shape->setWidth( 250 );
	//printf("Size  : %fx%f\n", shape->getWidth(), shape->getHeight() );


	//m = shape->GetLocalMatrix();
	//printf("a=%f b=%f c=%f d=%f\n", m.m00, m.m10, m.m01, m.m11 );
   shape->setX( 200 );
   shape->setY( 200 );
   stage->addChild(shape);
   #endif

   MainLoop();
   delete frame;
   return 0;
}
