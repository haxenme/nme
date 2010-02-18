#include <stdio.h>
#include <Surface.h>
extern "C" {
#include <jpeglib.h>
}
#include <setjmp.h>

using namespace nme;

struct ErrorData
{
   struct jpeg_error_mgr base; // base
   jmp_buf on_error;     // return;
};

static void OnError(j_common_ptr cinfo)
{
   ErrorData * err = (ErrorData *)cinfo->err;
   // return...
   longjmp(err->on_error, 1);
}

static Surface *TryJPEG(FILE *inFile)
{
   struct jpeg_decompress_struct cinfo;

   // Don't exit on error!
   struct ErrorData jpegError;
   cinfo.err = jpeg_std_error(&jpegError.base);
   jpegError.base.error_exit = OnError;

   Surface *result = 0;
   uint8 *row_buf = 0;

   // Establish the setjmp return context for ErrorFunction to use
   if (setjmp(jpegError.on_error))
   {
      if (row_buf)
         free(row_buf);
      if (result)
         result->DecRef();

      jpeg_destroy_decompress(&cinfo);
      return 0;
   }

   // Initialize the JPEG decompression object.
   jpeg_create_decompress(&cinfo);

   // Specify data source (ie, a file)
   jpeg_stdio_src(&cinfo, inFile);

   // Read file parameters with jpeg_read_header().
   if (jpeg_read_header(&cinfo, TRUE)!=JPEG_HEADER_OK)
      return 0;

   cinfo.out_color_space = JCS_RGB;

   // Start decompressor.
   jpeg_start_decompress(&cinfo);

   result = new SimpleSurface(cinfo.output_width, cinfo.output_height, pfXRGB);
   result->IncRef();


   RenderTarget target = result->BeginRender(Rect(cinfo.output_width, cinfo.output_height));


   row_buf = (uint8 *)malloc(cinfo.output_width * 3);

   int red_idx = gC0IsRed ? 0 : 2;
   int blue_idx = 2-red_idx;

   while (cinfo.output_scanline < cinfo.output_height)
   {
      uint8 * src = row_buf;
      uint8 * dest = target.Row(cinfo.output_scanline);

      jpeg_read_scanlines(&cinfo, &row_buf, 1);

      uint8 *end = dest + cinfo.output_width*4;
      while (dest<end)
      {
         dest[0] = src[blue_idx];
         dest[1] = src[1];
         dest[2] = src[red_idx];
         dest[3] = 0xff;
         dest+=4;
         src+=3;
      }
   }
   result->EndRender();

   free(row_buf);

   // Finish decompression.
   jpeg_finish_decompress(&cinfo);

   // Release JPEG decompression object
   jpeg_destroy_decompress(&cinfo);

   return result;
}

namespace nme {

Surface *Surface::Load(const OSChar *inFilename)
{
   FILE *file = OpenRead(inFilename);
   if (!file)
      return 0;

   Surface *result = TryJPEG(file);
   if (!result)
   {
      rewind(file);
      // Try others ...
   }

   fclose(file);
   return result;
}

}
