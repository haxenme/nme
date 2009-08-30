#include <Graphics.h>

Graphics gGraphics;
RenderState gState;

void Handler(Event &ioEvent,void *inStage)
{
	Stage *stage = (Stage *)inStage;

	static int tx = 0;
	static float rot = 0;
	tx = (tx+1) % 500;
	rot += 1;
	if (rot>360) rot-=360;

	if (ioEvent.mType==etNextFrame)
	{
		Surface *surface = stage->GetPrimarySurface();
		AutoSurfaceRender render(surface,0,stage);
		surface->Clear(0x202020);
		gState.mTransform.mMatrix = Matrix().Rotate(rot).Translate(tx+100,200);
		gState.mClipRect = Rect( surface->Width(), surface->Height() );
		gState.mTransform.mAAFactor = 4;
		gState.mAAClipRect = gState.mClipRect * gState.mTransform.mAAFactor;

		gGraphics.Render(render.Target(),gState);
	}
}


int main(int inargc,char **arvg)
{
   Frame *frame = CreateMainFrame(640,400,wfResizable,"Hello");

	frame->GetStage()->SetEventHandler(Handler,frame->GetStage());

	gGraphics.lineStyle(5,0xff0000,0.75);

	GraphicsGradientFill *fill = new GraphicsGradientFill(true,
											Matrix().createGradientBox(200,200,45,-100,-100), smPad );
	fill->AddStop( 0xffffff, 1, 0 );
	fill->AddStop( 0xff0000, 1, 0.25 );
	fill->AddStop( 0x00ff00, 1, 0.5 );
	fill->AddStop( 0x0000ff, 1, 0.75 );
	fill->AddStop( 0xff00ff, 1, 1 );
	gGraphics.addData(fill);
	gGraphics.moveTo(-100,-100);
	gGraphics.lineTo(-100,100);
	gGraphics.lineTo(100,100);
	gGraphics.lineTo(100,-100);
	gGraphics.lineTo(-100,-100);

	Extent2DF ext = gGraphics.GetExtent(gState.mTransform);
	printf("Extent %f,%f ... %f,%f\n", ext.mMinX, ext.mMinY, ext.mMaxX, ext.mMaxY);

   MainLoop();
   delete frame;
   return 0;
}
