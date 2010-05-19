#include <Surface.h>
//#include <ApplicationServices/ApplicationServices.h>
#include <UIKit/UIImage.h>


namespace nme {

Surface *Surface::Load(const OSChar *inFilename)
{
    NSString *str = [[NSString alloc] initWithUTF8String:inFilename];
    NSString *path = [[NSBundle mainBundle] pathForResource:str ofType:nil];
    [str release];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
    if (image == nil)
       return 0;
    //[path release];

    CGSize size = image.size;
    int width = CGImageGetWidth(image.CGImage);
    int height = CGImageGetHeight(image.CGImage);
    //printf("Size %dx%d\n", width, height );

    bool has_alpha =   CGImageGetAlphaInfo(image.CGImage)!=kCGImageAlphaNone;
    Surface *result = new SimpleSurface(width,height,has_alpha?pfARGB:pfXRGB);
    result->IncRef();
    AutoSurfaceRender renderer(result);
    const RenderTarget &target = renderer.Target();


    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate( target.Row(0),
       width, height, 8, target.mSoftStride, colorSpace,
       (has_alpha?kCGImageAlphaPremultipliedLast:kCGImageAlphaNoneSkipLast) |
            kCGBitmapByteOrderDefault );
    CGColorSpaceRelease( colorSpace );

    CGContextClearRect( context, CGRectMake( 0, 0, width, height ) );
    //CGContextTranslateCTM( context, 0, height - height );
    CGContextDrawImage( context, CGRectMake( 0, 0, width, height ), image.CGImage );

    CGContextRelease(context);

   [image release];

   return result;
}

Surface *Surface::LoadFromBytes(const uint8 *inBytes,int inLen)
{
	return 0;
}


}
