#include <Graphics.h>
#include <TextField.h>
#include <Display.h>
#include <Utils.h>


void Handler(Event &ioEvent,void *inStage)
{
   if (ioEvent.mType==etClose)
      TerminateMainLoop();
   else
   {
   Stage *stage = (Stage *)inStage;

   static int tx = 0;
   static float rot = 0;
   tx = (tx+1) % 500;
   rot += 1;
   if (rot>360) rot-=360;

   DisplayObject *shape = stage->getChildAt(0);
   shape->setX(tx);
   shape->setRotation(rot);

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

   shape = new DisplayObject();
   Graphics &g = shape->GetGraphics();
   g.lineStyle(5,0x404080);
   g.beginFill(0x8080f0);
   //g.drawRect(0,0,200,100);
   //g.drawEllipse(0,0,200,100);
   //g.drawRoundRect(0,0,200,100,10,10);
   g.drawCircle(0,0,200);
   shape->setX(100);
   shape->setY(100);
   stage->addChild(shape);

   TextField *text = new TextField(false);
   //text->setText(L"Hello, abcdefghijklmnopqrstuvwxyz 1234567890 ABCDEFGHIGKLMNOPQRSTUVWXYZjjj");
   //text->setHTMLText(L"HHHH");
   text->mRect.x = 200;
   text->mRect.y = 2;
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

   MainLoop();
   delete frame;
   return 0;
}
