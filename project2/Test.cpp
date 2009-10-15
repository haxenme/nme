#include <Graphics.h>
#include <TextField.h>
#include <Display.h>
#include <Utils.h>
#include <Surface.h>

DisplayObject *gScrollWin = 0;
DisplayObject *gCachObj = 0;
bool gDoSpin = false;

void Handler(Event &ioEvent,void *inStage)
{
   if (ioEvent.mType==etClose)
      TerminateMainLoop();
   else
   {
		Stage *stage = (Stage *)inStage;

		static int x = 0;
		x = (x+1) % 800;
		if (gDoSpin)
		{
			DisplayObject *shape = stage->getChildAt(0);
			double rot = shape->getRotation();
			rot += 1;
			shape->setX(x);
			shape->setRotation(rot);
			if (gScrollWin)
				gScrollWin->setScrollRect( DRect(20,x/8,100,100) );
		}
		if (gCachObj)
			gCachObj->setX(x);

		if (ioEvent.mType==etNextFrame)
			stage->RenderStage();
   }
}

void TestBitmapRender()
{
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
}

void AddGradFill(Stage *inStage)
{
   GraphicsGradientFill *fill = new GraphicsGradientFill(false,
                                 Matrix().createGradientBox(200,200,45,-100,-100), smReflect,
                                 imRGB, 0.5);
   fill->AddStop( 0xffffff, 1, 0 );
   fill->AddStop( 0xff0000, 1, 0.25 );
   fill->AddStop( 0x00ff00, 1, 0.5 );
   fill->AddStop( 0x0000ff, 1, 0.75 );
   fill->AddStop( 0xff00ff, 1, 1 );

   DisplayObject *shape = new DisplayObject();
   Graphics &gfx = shape->GetGraphics();
   gfx.addData(fill);
   //gfx.beginBitmapFill(bg, Matrix().createGradientBox(32,32), true,true );
   gfx.lineStyle(5,0x202040,0.75,false,ssmNormal,scRound,sjMiter);
   gfx.moveTo(-100,-100);
   gfx.lineTo(-100,100);
   gfx.curveTo(0,180,100,100);
   gfx.lineTo(100,-100);
   gfx.lineTo(-100,-100);
   shape->setY(200);
   inStage->addChild(shape);

	gDoSpin = true;
}

void TestScrollRect(Stage *inStage)
{
   gDoSpin = true;
   DisplayObjectContainer *win = new DisplayObjectContainer(true);
   Graphics &g = win->GetGraphics();
   g.lineStyle(2,0x202040,1,false);
   g.beginFill(0x8080f0);
   //g.drawRect(0,0,200,100);
   //g.drawEllipse(0,0,200,100);
   g.drawRoundRect(10,10,200,100,10,10);
   TextField *tf = new TextField(false);
   tf->setHTMLText(L"<font color='#ffffff' size=14>Window 1</font>");
   tf->setX( 10 );
   tf->setY( 10 );
   win->addChild(tf);
   //g.drawCircle(0,0,200);
   inStage->addChild(win,true);
   win->setX(100);
   win->setY(100);
   win->setScaleX(2);
   win->setScaleY(2);
   win->setScale9Grid( DRect(20,20,180,80) );
   win->setScrollRect( DRect(-15,-15,100,100) );
   gScrollWin = win;
}

void TestText(Stage *inStage,bool inFromFile)
{
   TextField *text = new TextField(false);
   //text->setText(L"Hello, abcdefghijklmnopqrstuvwxyz 1234567890 ABCDEFGHIGKLMNOPQRSTUVWXYZjjj");
   //text->setHTMLText(L"HHHH");
   text->setX( 200 );
   text->setY( 2 );
   //text->background = true;
   text->backgroundColor = ARGB(0xffb0b0f0);
   text->autoSize = asLeft;
   text->multiline = true;
   text->wordWrap = true;
   text->mRect.w = 600;
   text->embedFonts = false;

   if (inFromFile)
   {
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
      text->setText( UTF8ToWide(contents.c_str()) );
   }
   else
   {
      text->setHTMLText(L"<font size=20>Hello <font color='#ff0000' face='times'>go\nod-<br>bye <b>gone for good!</b></font></font>");
      text->setX(500);
      text->setAlpha(0.5);
   }

   //text->cacheAsBitmap = true;
   inStage->addChild(text);
}



void TestWidth1(Stage *inStage)
{
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
   inStage->addChild(shape);
}


void TestWidth2(Stage *inStage)
{
      DisplayObjectContainer *base = new DisplayObjectContainer;
      base->GetGraphics().beginFill(0xff0000);
      base->GetGraphics().drawRect(0,0,60,40);
      inStage->addChild(base);

      DisplayObjectContainer *obj = new DisplayObjectContainer;
      Graphics &gfx = obj->GetGraphics();
      gfx.beginFill(0xe0e0e0,0.6);
      gfx.lineStyle(2,0xff0000,1,false,ssmHorizontal, scNone, sjMiter);
      gfx.drawRoundRect( 20,20, 199.5,200, 5, 5 );

      base->addChild(obj);

      DisplayObjectContainer *lobe = new DisplayObjectContainer;
      lobe->GetGraphics().beginFill(0xff0000);
      lobe->GetGraphics().drawRect(40,40,400,40);
      lobe->setScrollRect(DRect( 100,0, 100, 100));
      obj->addChild(lobe);
      printf("Obj width %f\n",obj->getWidth());
      base->cacheAsBitmap = true;
      gCachObj = base;
}


void TestRed(Stage *inStage)
{
   DisplayObject *red = new DisplayObject;
   red->GetGraphics().beginFill(0xff0000);
   red->GetGraphics().drawRect(0,0,100,100);
   inStage->addChild(red);
}

void TestMask(Stage *inStage)
{
      DisplayObjectContainer *masked = new DisplayObjectContainer;
      Graphics *gfx = &masked->GetGraphics();
      gfx->beginFill(0x308030);
      gfx->drawRect( 100,100, 400,400 );
      inStage->addChild(masked);

      DisplayObjectContainer *masked_child = new DisplayObjectContainer;
      gfx = &masked_child->GetGraphics();
      gfx->lineStyle(2,0xff0000);
      gfx->moveTo( 0,0);
      gfx->lineTo( 500,500);
      masked->addChild(masked_child);
      masked->cacheAsBitmap = true;

      TextField *tf = new TextField;
      tf->setText(L"MASKEDMASKEDMASKEDMASKEDMASKED");
      tf->autoSize = asLeft;
      tf->setX(200);
      tf->setY(150);
      masked->addChild(tf);

      DisplayObjectContainer *m = new DisplayObjectContainer;
      gfx = &m->GetGraphics();
      gfx->beginFill(0xa0a0a0);
      gfx->drawCircle( 100,100, 50 );
      inStage->addChild(m);
      m->setX(100);
      m->setY(100);
      m->cacheAsBitmap = true;

      DisplayObject *m_child = new DisplayObject;
      gfx = &m_child->GetGraphics();
      gfx->beginFill(0xa0a0a0);
      gfx->drawCircle( 100,100, 50 );
      m->addChild(m_child);
      m_child->setX(20);
      m_child->setY(20);

      tf = new TextField;
      tf->setText(L"MASK MASK MASK");
      tf->autoSize = asLeft;
      tf->setX(150);
      tf->setY(120);
      //m->addChild(tf);

      masked->setMask(m);
}

DisplayObject *CreateOne()
{
   DisplayObject *obj = new DisplayObject();
   Graphics &gfx = obj->GetGraphics();
   GraphicsGradientFill *g1 = new GraphicsGradientFill(true,
                                 Matrix().createGradientBox(100,100), smReflect, imRGB);
   g1->AddStop( 0x404040, 1, 0 );
   g1->AddStop( 0xa0a0a0, 1, 1 );
   gfx.addData(g1);
   gfx.drawRect(0,0,100,100);


   GraphicsGradientFill *g2 = new GraphicsGradientFill(true,
                                 Matrix().createGradientBox(100,100), smReflect, imRGB);
   g2->AddStop( 0x20a200, 1, 0 );
   g2->AddStop( 0xffff20, 1, 1 );
   gfx.addData(g2);
   gfx.drawRect(6,6,88,88);

   return obj;
}


DisplayObject *CreateTwo()
{
   DisplayObject *obj = new DisplayObject();
   Graphics &gfx = obj->GetGraphics();

   GraphicsGradientFill *g1 = new GraphicsGradientFill(true,
                                 Matrix().createGradientBox(100,100), smReflect, imRGB);
   g1->AddStop( 0x404040, 1, 0 );
   g1->AddStop( 0xa0a0a0, 1, 1 );
   gfx.addData(g1);
   gfx.drawCircle(50,50,50);


   GraphicsGradientFill *g2 = new GraphicsGradientFill(true,
                                 Matrix().createGradientBox(100,100), smReflect, imRGB);
   g2->AddStop( 0xff0000, 1, 0 );
   g2->AddStop( 0x0000ff, 1, 1 );
   gfx.addData(g2);
   gfx.drawCircle(50,50,44);

   return obj;
}



void TestBlend(Stage *inStage)
{
   for(int mode=bmNormal; mode<=bmHardLight;mode++)
   {
      DisplayObjectContainer *container = new DisplayObjectContainer;
      inStage->addChild(container);
      int x = mode%4;
      int y = mode/4;
      container->setX(x*150);
      container->setY(y*150);
      DisplayObject *obj1 =  CreateOne();
      container->addChild(obj1);
      DisplayObject *obj2 =  CreateTwo();
      obj2->setX(50);
      obj2->setY(50);
      obj2->blendMode = (BlendMode)mode;
      container->addChild(obj2);
   }
}


void TestColourTrans(Stage *inStage)
{
   for(int a=0;a<3;a++)
      for(int b=0;b<3;b++)
      {
         DisplayObjectContainer *container = new DisplayObjectContainer;
         inStage->addChild(container);
         container->setX(a*150);
         container->setY(b*150);
         DisplayObject *obj1 =  CreateOne();
         container->addChild(obj1);
         DisplayObject *obj2 =  CreateTwo();
         obj2->setX(50);
         obj2->setY(50);
         container->addChild(obj2);

         container->setAlpha(a==0?1 : a==1?0.4 : 0.3);
         container->colorTransform.redScale = b;
         container->cacheAsBitmap = true;
      }
}

void TestLines(Stage *inStage)
{
   DisplayObject *obj = new DisplayObject();
   Graphics &gfx = obj->GetGraphics();

   gfx.lineStyle(10,0x00ff00);
   gfx.moveTo(40,40);
   gfx.curveTo(240,400,440,40);

   inStage->addChild(obj);
}


int main(int inargc,char **arvg)
{
   Frame *frame = CreateMainFrame(640,400,wfResizable|wfHardware,L"Hello");

   Stage *stage = frame->GetStage();
   stage->IncRef();
   stage->SetEventHandler(Handler,stage);

   AddGradFill(stage);

   // TestScrollRect(stage);

   // TestText(stage,true);

   // TestText(stage,false);

   // TestWidth1(stage);

   // TestWidth2(stage);

   //TestRed(stage);

   // TestMask(stage);

   // TestBlend(stage);

   // TestColourTrans(stage);

   // TestLines(stage);

   MainLoop();
   delete frame;
   return 0;
}
