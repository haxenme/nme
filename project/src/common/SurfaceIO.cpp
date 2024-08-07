#include <stdio.h>
#include <Surface.h>
#include <ByteArray.h>
#include <nme/NmeCffi.h>


extern "C" {
#include <jpeglib.h>
#include <png.h>
}
#include <setjmp.h>

using namespace nme;

struct ReadBuf
{
   ReadBuf(const uint8 *inData, int inLen) : mData(inData), mLen(inLen) { }

   bool Read(uint8 *outBuffer, int inN)
   {
      if (inN>mLen)
      {
         memset(outBuffer,0,inN);
         return false;
      }
      memcpy(outBuffer,mData,inN);
      mData+=inN;
      mLen -= inN;
      return true;
   }

   const uint8 *mData;
   int mLen;
};

struct ErrorData
{
   struct jpeg_error_mgr base; // base
   jmp_buf on_error;     // return;
};

static void OnOutput(j_common_ptr cinfo)
{
}
static void OnError(j_common_ptr cinfo)
{
   ErrorData * err = (ErrorData *)cinfo->err;
   // return...
   longjmp(err->on_error, 1);
}

struct MySrcManager
{
   MySrcManager(const JOCTET *inData, int inLen) : mData(inData), mLen(inLen)
   {
      pub.init_source = my_init_source;
      pub.fill_input_buffer = my_fill_input_buffer;
      pub.skip_input_data = my_skip_input_data;
      pub.resync_to_restart = my_resync_to_restart;
      pub.term_source = my_term_source;
      pub.next_input_byte = 0;
      pub.bytes_in_buffer = 0;
      mUsed = false;
      mEOI[0] = 0xff;
      mEOI[1] = JPEG_EOI;
   }

   struct jpeg_source_mgr pub;   /* public fields */
   const JOCTET * mData;
   size_t mLen;
   bool   mUsed;
   unsigned char mEOI[2];

   static void my_init_source(j_decompress_ptr cinfo)
   {
      MySrcManager *man = (MySrcManager *)cinfo->src;
      man->mUsed = false;
   }
   static boolean my_fill_input_buffer(j_decompress_ptr cinfo)
   {
      MySrcManager *man = (MySrcManager *)cinfo->src;
      if (man->mUsed)
      {
          man->pub.next_input_byte = man->mEOI;
          man->pub.bytes_in_buffer = 2;
      }
      else
      {
         man->pub.next_input_byte = man->mData;
         man->pub.bytes_in_buffer = man->mLen;
         man->mUsed = true;
      }
      return TRUE;
   }
   static void my_skip_input_data(j_decompress_ptr cinfo, long num_bytes)
   {
      MySrcManager *man = (MySrcManager *)cinfo->src;
      man->pub.next_input_byte += num_bytes;
      man->pub.bytes_in_buffer -= num_bytes;
      if (man->pub.bytes_in_buffer == 0) // was < 0 and was always false PJK 16JUN12
      {
         man->pub.next_input_byte = man->mEOI;
         man->pub.bytes_in_buffer = 2;
      }
   }
   static boolean my_resync_to_restart(j_decompress_ptr cinfo, int desired)
   {
      MySrcManager *man = (MySrcManager *)cinfo->src;
      man->mUsed = false;
      return TRUE;
   }
   static void my_term_source(j_decompress_ptr cinfo)
   {
   }
 };


namespace nme {

bool gRespectExifOrientation = true;

static bool isLittleEndian()
{
   unsigned short val = 0;
   *(unsigned char *)(&val) = 1;
   return val==1;
}


bool SoftwareDecodeJPeg(unsigned char *inDest, int inWidth, int inHeight, const uint8 *inData,unsigned int inDataLen)
{
   struct jpeg_decompress_struct cinfo;

   // Don't exit on error!
   struct ErrorData jpegError;
   cinfo.err = jpeg_std_error(&jpegError.base);
   jpegError.base.error_exit = OnError;
   jpegError.base.output_message = OnOutput;

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
      return false;
   }

   // Initialize the JPEG decompression object.
   jpeg_create_decompress(&cinfo);

   // Specify data source (ie, a file, or buffer)
   MySrcManager manager(inData,inDataLen);
   cinfo.src = &manager.pub;

   // Read file parameters with jpeg_read_header().
   if (jpeg_read_header(&cinfo, TRUE)!=JPEG_HEADER_OK)
      return false;

   cinfo.out_color_space = JCS_RGB;

   // Start decompressor.
   jpeg_start_decompress(&cinfo);

   int activeHeight = std::min( (int)inHeight,  (int)cinfo.output_height);
   bool trim = inWidth < cinfo.output_width;
   int activeWidth = std::min( (int)inWidth,  (int)cinfo.output_width);
   std::vector<uint8> rowBuf(trim ? cinfo.output_width : 0);
   uint8 *bufPtr = trim ? &rowBuf[0] : nullptr;


   while (cinfo.output_scanline < activeHeight)
   {
      uint8 * dest = inDest + cinfo.output_scanline * 3 * inWidth;
      if (trim)
      {
         jpeg_read_scanlines(&cinfo, &bufPtr, 1);
         memcpy(dest, bufPtr, 3*activeWidth);
      }
      else
         jpeg_read_scanlines(&cinfo, &dest, 1);
   }

   // Finish decompression.
   jpeg_finish_decompress(&cinfo);

   // Release JPEG decompression object
   jpeg_destroy_decompress(&cinfo);

   return true;
}
}

// Returns requiured CW quardant rotation
static int parseExif(const uint8 *data, int inLen)
{
   //printf("parseExif %d %c%c%c%c\n",inLen, data[0], data[1], data[2], data[3]);
   int rotation = 0;

   #define NEXT_SHORT (exif[msb]<<8) | exif[1-msb]; exif+=2
   #define NEXT_INT big ? (exif[0]<<24) | (exif[1]<<16) | (exif[2]<<8) | exif[3] : \
                         (exif[3]<<24) | (exif[2]<<16) | (exif[1]<<8) | exif[0]; \
                         exif+=4;

   if (inLen>10 && data[0]=='E' && data[1]=='x' && data[2]=='i' && data[3]=='f')
   {
      const uint8 *exif = data + 6;
      const uint8 *end = data + inLen;

      bool little = exif[0]==0x49 && exif[1]==0x49;
      bool big = exif[0]==0x4D && exif[1]==0x4D;
      if (!little && !big)
         return rotation;
      exif += 2;
      int msb = big ? 0 : 1;
      int test = NEXT_SHORT;
      if (test!=42)
         return rotation;

      int offset = NEXT_INT;
      if (offset>=8 && exif+(offset-8)+2 <= end )
      {
         exif += offset-8;
         int entries = NEXT_SHORT;
         //printf("Found exif entries:%d\n", entries);
         for(int e=0; e<entries && exif+12<end; e++)
         {
            int tag = NEXT_SHORT;
            int type = NEXT_SHORT;
            int vpos = NEXT_INT;
            int val = NEXT_SHORT;
            exif += 2;
            //printf("  tag:%d, type:%d val:%d\n", tag, type, val );
            // Orientation/short
            if (tag==274 && type==3)
            {
               //printf("Found rotation: %d\n", val);
               switch(val)
               {
                  case 1: return 0; // normal - no rotation
                  case 3: return 2; // 180 rotation
                  case 6: return 1; // must rotate 90 cw
                  case 8: return 3; // must rotate 270 cw (90 acw)
                  default:
                     //printf(" unknown rotation: %d\n", val);
                     // Mirror cases - not handled
                     return 0;
               }
            }
         }

      }
   }

   return rotation;
}

static const int APP0  = 0xe0;
static const int COM   = 0xfe;

static Surface *TryJPEG(FILE *inFile,const uint8 *inData, int inDataLen, IAppDataCallback *onAppData=nullptr)
{
   struct jpeg_decompress_struct cinfo;

   // Don't exit on error!
   struct ErrorData jpegError;
   cinfo.err = jpeg_std_error(&jpegError.base);
   jpegError.base.error_exit = OnError;
   jpegError.base.output_message = OnOutput;

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

   // Specify data source (ie, a file, or buffer)
   MySrcManager manager(inData,inDataLen);
   if (inFile)
      jpeg_stdio_src(&cinfo, inFile);
   else
   {
      cinfo.src = &manager.pub;
   }

   if (onAppData || gRespectExifOrientation)
   {
      cinfo.client_data = onAppData;
      unsigned int bufSize = inDataLen>0 ? inDataLen : 1<<20;
      if (onAppData)
      {
         jpeg_save_markers(&cinfo, COM, bufSize);
         for(int i=0;i<15;i++)
            jpeg_save_markers(&cinfo, APP0 + i, bufSize);
      }
      else
      {
         jpeg_save_markers(&cinfo, APP0 + 1, bufSize);
      }
   }

   // Read file parameters with jpeg_read_header().
   if (jpeg_read_header(&cinfo, TRUE)!=JPEG_HEADER_OK)
      return 0;

   int rotation = 0;
   if (gRespectExifOrientation)
   {
      jpeg_saved_marker_ptr marker = cinfo.marker_list;
      while(marker)
      {
         if (marker->marker==APP0+1)
         {
            rotation = parseExif(marker->data, marker->data_length);
            if (rotation)
               break;
         }
         marker = marker->next;
      }
   }

   cinfo.out_color_space = JCS_RGB;

   // Start decompressor.
   jpeg_start_decompress(&cinfo);

   int imageW = rotation==1 || rotation==3 ? cinfo.output_height : cinfo.output_width;
   int imageH = rotation==1 || rotation==3 ? cinfo.output_width : cinfo.output_height;
   result = new SimpleSurface(imageW, imageH, pfRGB);
   result->IncRef();


   std::vector<RGB> rowBuf;
   if (rotation!=0)
      rowBuf.resize(cinfo.output_width);


   RenderTarget target = result->BeginRender(Rect(imageW, imageH));

   int strideBytes = target.Row(1)-target.Row(0);

   while (cinfo.output_scanline < cinfo.output_height)
   {
      int y = cinfo.output_scanline;
      uint8 * dest = rotation==0 ? target.Row(y) : (uint8 *)&rowBuf[0];
      jpeg_read_scanlines(&cinfo, &dest, 1);

      if (rotation==1)
      {
         // 90 CW.  First row starts at the right and goes down
         RGB *col = ((RGB *)target.Row(0)) + imageW - 1 - y;
         for(int x=0; x<imageH; x++)
         {
            *col = rowBuf[x];
            col = (RGB *)((char *)col + strideBytes);
         }
      }
      else if (rotation==2)
      {
         // 180 CW.  First row starts at the bottom-right and goes left
         RGB *row = ((RGB *)target.Row(imageH-1-y)) + imageW - 1;
         for(int x=0; x<imageW; x++)
            row[-x] = rowBuf[x];
      }
      else if (rotation==3)
      {
         // 90 ACW.  First row starts at the bottom-left and goes up
         RGB *col = ((RGB *)target.Row(imageH-1)) + y;
         for(int x=0; x<imageH; x++)
         {
            *col = rowBuf[x];
            col = (RGB *)((char *)col - strideBytes);
         }
      }

   }
   result->EndRender();

   if (onAppData)
   {
      jpeg_saved_marker_ptr marker = cinfo.marker_list;
      if (marker)
      {
         onAppData->beginCallbacks();
         while(marker)
         {
            onAppData->onAppData(marker->marker, marker->data, marker->data_length);
            marker = marker->next;
         }
         onAppData->endCallbacks();
      }
   }

   // Finish decompression.
   jpeg_finish_decompress(&cinfo);

   // Release JPEG decompression object
   jpeg_destroy_decompress(&cinfo);

   return result;
}






struct MyDestManager
{
   enum { BUF_SIZE = 4096 };
   struct jpeg_destination_mgr pub;   /* public fields */
   QuickVec<uint8> mOutput;
   uint8   mTmpBuf[BUF_SIZE];

   MyDestManager()
   {
      pub.init_destination    = init_buffer;
      pub.empty_output_buffer = copy_buffer;
      pub.term_destination    = term_buffer;
      pub.next_output_byte    = mTmpBuf;
      pub.free_in_buffer      = BUF_SIZE;
   }

   void CopyBuffer()
   {
      mOutput.append( mTmpBuf, BUF_SIZE);
      pub.next_output_byte    = mTmpBuf;
      pub.free_in_buffer      = BUF_SIZE;
   }

   void TermBuffer()
   {
      mOutput.append( mTmpBuf, BUF_SIZE - pub.free_in_buffer );
   }


   static void init_buffer(jpeg_compress_struct* cinfo) {}

   static boolean copy_buffer(jpeg_compress_struct* cinfo)
   {
      MyDestManager *man = (MyDestManager *)cinfo->dest;
      man->CopyBuffer( );
      return TRUE;
   }

   static void term_buffer(jpeg_compress_struct* cinfo)
   {
      MyDestManager *man = (MyDestManager *)cinfo->dest;
      man->TermBuffer();
   }

};



static bool EncodeJPG(Surface *inSurface, ByteArray *outBytes,double inQuality)
{
     struct jpeg_compress_struct cinfo;

   // Don't exit on error!
   struct ErrorData jpegError;
   cinfo.err = jpeg_std_error(&jpegError.base);
   jpegError.base.error_exit = OnError;
   jpegError.base.output_message = OnOutput;

   MyDestManager dest;

   int w = inSurface->Width();
   int h = inSurface->Height();

   jpeg_create_compress(&cinfo);
 

   // Establish the setjmp return context for ErrorFunction to use
   if (setjmp(jpegError.on_error))
   {
      jpeg_destroy_compress(&cinfo);
      return false;
   }


   cinfo.dest = (jpeg_destination_mgr *)&dest;
 
   cinfo.image_width      = w;
   cinfo.image_height     = h;
   cinfo.input_components = 3;
   cinfo.in_color_space   = JCS_RGB;
 
   jpeg_set_defaults(&cinfo);
   jpeg_set_quality(&cinfo, (int)(inQuality * 100), TRUE);
   jpeg_start_compress(&cinfo, TRUE);
 
   PixelFormat srcFmt = inSurface->Format();
   if (srcFmt==pfAlpha)
      srcFmt = pfLuma;

   if (srcFmt == pfRGB)
   {
      QuickVec<JSAMPROW> row_buf(h);
      for(int y=0;y<h;y++)
         row_buf[y] = (JSAMPROW)inSurface->Row(y);
      jpeg_write_scanlines(&cinfo, &row_buf[0], h);
   }
   else
   {
      int pw = BytesPerPixel(pfRGB);
      QuickVec<uint8> row_data(pw*w);
      uint8 *buf = &row_data[0];
      JSAMPROW *row_pointer = &buf;

      while (cinfo.next_scanline < cinfo.image_height)
      {
         const uint8 *src = (const uint8 *)inSurface->Row(cinfo.next_scanline);

         PixelConvert(w,1,
           srcFmt,  src, inSurface->GetStride(), 0,
           pfRGB, buf, pw*w, 0 );

         jpeg_write_scanlines(&cinfo, row_pointer, 1);
      }
   }
   jpeg_finish_compress(&cinfo);

   *outBytes = ByteArray(dest.mOutput);
 
   return true;
}



static void user_error_fn(png_structp png_ptr, png_const_charp error_msg)
{
   #ifdef NME_TOOLKIT_BUILD
   longjmp( png_jmpbuf(png_ptr), 1);
   #else
   longjmp(png_ptr->jmpbuf, 1);
   #endif
}
static void user_warning_fn(png_structp png_ptr, png_const_charp warning_msg) { }
static void user_read_data_fn(png_structp png_ptr, png_bytep data, png_size_t length)
{
    png_voidp buffer = png_get_io_ptr(png_ptr);
    ((ReadBuf *)buffer)->Read(data,length);
}

void user_write_data(png_structp png_ptr, png_bytep data, png_size_t length)
{
    QuickVec<unsigned char> *buffer = (QuickVec<unsigned char> *)png_get_io_ptr(png_ptr);
    buffer->append((unsigned char *)data,(int)length);
} 
void user_flush_data(png_structp png_ptr) { }


static Surface *TryPNG(FILE *inFile,const uint8 *inData, int inDataLen)
{
   png_structp png_ptr;
   png_infop info_ptr;
   png_uint_32 width, height;
   int bit_depth, color_type, interlace_type;

   /* Create and initialize the png_struct with the desired error handler
    * functions.  If you want to use the default stderr and longjump method,
    * you can supply NULL for the last three parameters.  We also supply the
    * the compiler header file version, so that we know if the application
    * was compiled with a compatible version of the library.  REQUIRED
    */
   png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING,
      0, user_error_fn, user_warning_fn);

   if (png_ptr == NULL)
      return (0);

   /* Allocate/initialize the memory for image information.  REQUIRED. */
   info_ptr = png_create_info_struct(png_ptr);
   if (info_ptr == NULL)
   {
      png_destroy_read_struct(&png_ptr, (png_infopp)NULL, (png_infopp)NULL);
      return (0);
   }

   /* Set error handling if you are using the setjmp/longjmp method (this is
    * the normal method of doing things with libpng).  REQUIRED unless you
    * set up your own error handlers in the png_create_read_struct() earlier.
    */

   Surface *result = 0;
   RenderTarget target;

   if (setjmp(png_jmpbuf(png_ptr)))
   {
      if (result)
      {
         result->EndRender();
         result->DecRef();
      }

      /* Free all of the memory associated with the png_ptr and info_ptr */
      png_destroy_read_struct(&png_ptr, &info_ptr, (png_infopp)NULL);
      /* If we get here, we had a problem reading the file */
      return (0);
   }

   ReadBuf buffer(inData,inDataLen);
   if (inFile)
   {
      png_init_io(png_ptr, inFile);
   }
   else
   {
      png_set_read_fn(png_ptr,(void *)&buffer, user_read_data_fn);
   }

   png_read_info(png_ptr, info_ptr);

   png_get_IHDR(png_ptr, info_ptr, &width, &height, &bit_depth, &color_type,
       &interlace_type, NULL, NULL);

   bool has_alpha = color_type== PNG_COLOR_TYPE_GRAY_ALPHA ||
                    color_type==PNG_COLOR_TYPE_RGB_ALPHA ||
                    png_get_valid(png_ptr, info_ptr, PNG_INFO_tRNS);

   bool load16 = color_type== PNG_COLOR_TYPE_GRAY && bit_depth==16;
   bool swap16 = load16 && isLittleEndian();

   /* Add filler (or alpha) byte (before/after each RGB triplet) */
   //png_set_expand(png_ptr);
   //png_set_filler(png_ptr, 0xff, PNG_FILLER_AFTER);
   //png_set_gray_1_2_4_to_8(png_ptr);
   png_set_palette_to_rgb(png_ptr);

   if (!load16)
      png_set_gray_to_rgb(png_ptr);

   // Stripping 16 bits per channel to 8 bits per channel.
   if (!load16 && bit_depth == 16)
      png_set_strip_16(png_ptr);

   if (has_alpha)
      png_set_bgr(png_ptr);

   result = new SimpleSurface(width,height, load16 ? pfUInt16 : has_alpha ? pfBGRA : pfRGB);
   result->IncRef();
   target = result->BeginRender(Rect(width,height));
   
   /* if the image is interlaced, run multiple passes */
   int number_of_passes = png_set_interlace_handling(png_ptr);
   
   for (int pass = 0; pass < number_of_passes; pass++)
   {
      for (int i = 0; i < height; i++)
      {
         png_bytep anAddr = (png_bytep) target.Row(i);
         png_read_rows(png_ptr, (png_bytepp) &anAddr, NULL, 1);

         if (swap16)
         {
            unsigned short *r = (unsigned short *)anAddr;
            for(int x=0;x<width;x++)
            {
               int v = r[x];
               r[x] = ((v>>8) & 0xff) | ( (v&0xff)<<8 );
            }
         }
      }
   }

   result->EndRender();

   /* read rest of file, and get additional chunks in info_ptr - REQUIRED */
   png_read_end(png_ptr, info_ptr);

   /* clean up after the read, and free any memory allocated - REQUIRED */
   png_destroy_read_struct(&png_ptr, &info_ptr, (png_infopp)NULL);

   /* that's it */
   return result;
}

static bool EncodePNG(Surface *inSurface, ByteArray *outBytes)
{
   /* initialize stuff */
   png_structp png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, user_error_fn, user_warning_fn);

   if (!png_ptr)
      return false;

   png_infop info_ptr = png_create_info_struct(png_ptr);
   if (!info_ptr)
      return false;

   if (setjmp(png_jmpbuf(png_ptr)))
   {
      /* Free all of the memory associated with the png_ptr and info_ptr */
      png_destroy_write_struct(&png_ptr, &info_ptr );
      /* If we get here, we had a problem reading the file */
      return false;
   }

   QuickVec<uint8> out_buffer;

   png_set_write_fn(png_ptr, &out_buffer, user_write_data, user_flush_data);

   int w = inSurface->Width();
   int h = inSurface->Height();

   int bit_depth = 8;
   bool swap16 = false;
   int color_type = PNG_COLOR_TYPE_RGB;
   bool swapBgr = false;
   PixelFormat color_format = pfRGB;
   PixelFormat srcFmt = inSurface->Format();

   if (srcFmt==pfUInt16)
   {
      bit_depth = 16;
      color_type = PNG_COLOR_TYPE_GRAY;
      color_format = srcFmt;
      swap16 = isLittleEndian();
   }
   else if (srcFmt==pfAlpha || srcFmt==pfLuma)
   {
      color_type = PNG_COLOR_TYPE_GRAY;
      color_format = srcFmt;
   }
   else if (srcFmt==pfLumaAlpha)
   {
      color_type = PNG_COLOR_TYPE_GRAY_ALPHA;
      color_format = srcFmt;
   }
   else if ( !HasAlphaChannel(srcFmt) )
   {
      color_type = PNG_COLOR_TYPE_RGB;
      color_format = pfRGB;
   }
   else
   {
      color_type = PNG_COLOR_TYPE_RGB_ALPHA;
      color_format = pfBGRA;
      swapBgr = true;

      if (srcFmt==pfRGBA)
      {
         swapBgr = false;
         srcFmt = pfBGRA;
      }
   }

   png_set_IHDR(png_ptr, info_ptr, w, h,
           bit_depth, color_type, PNG_INTERLACE_NONE,
           PNG_COMPRESSION_TYPE_BASE, PNG_FILTER_TYPE_BASE);

   if (swapBgr)
      png_set_bgr(png_ptr);

   png_write_info(png_ptr, info_ptr);

   if (swap16)
   {
      QuickVec<unsigned short> row_data(w);

      for(int y=0;y<h;y++)
      {
         unsigned short *buf = &row_data[0];
         const unsigned short *src = (const unsigned short *)inSurface->Row(y);
         for(int x=0;x<w;x++)
         {
            int v = src[x];
            buf[x] = ((v>>8) & 0xff) | ( (v&0xff)<<8 );
         }

         png_write_rows(png_ptr, (png_bytepp)&buf, 1);
      }
   }
   else if (srcFmt==color_format)
   {
      QuickVec<png_bytep> row_pointers(h);
      for(int y=0;y<h;y++)
         row_pointers[y] = (png_bytep)inSurface->Row(y);
      png_write_image(png_ptr, &row_pointers[0]);
   }
   else
   {
      int pw = BytesPerPixel(color_format);

      QuickVec<uint8> row_data(pw*w);
      png_bytep row = &row_data[0];

      for(int y=0;y<h;y++)
      {
         uint8 *buf = &row_data[0];
         const uint8 *src = (const uint8 *)inSurface->Row(y);

         PixelConvert(w,1,
           srcFmt,  src, inSurface->GetStride(), 0,
           color_format, buf, pw*w, 0 );

         png_write_rows(png_ptr, &row, 1);
      }
   }


   png_write_end(png_ptr, NULL);

   *outBytes = ByteArray(out_buffer);

   return true;
}

namespace nme {

Surface *Surface::Load(const OSChar *inFilename, IAppDataCallback *onAppData)
{
   FILE *file = OpenRead(inFilename);
   if (!file)
   {
      #ifdef ANDROID
      ByteArray bytes = AndroidGetAssetBytes(inFilename);
      if (bytes.Ok())
      {
         Surface *result = LoadFromBytes(bytes.Bytes(), bytes.Size(), onAppData);
         return result;
      }

      #endif
      return 0;
   }

   AutoGCBlocking block;

   int len = 0;
   while(inFilename[len])
      len++;

   bool jpegFirst = false;
   bool pngFirst = false;
   if (len>4)
   {
      // Jpeg/jpg
      if (inFilename[len-4]=='j' || inFilename[len-4]=='J' || 
             inFilename[len-3]=='j' || inFilename[len-4]=='J' )
         jpegFirst = true;
      else if (inFilename[len-3]=='p' || inFilename[len-3]=='P' )
         pngFirst = true;
   }
   Surface *result = 0;

   if (jpegFirst)
   {
      result = TryJPEG(file,0,0, onAppData);
      if (!result)
      {
         rewind(file);
         result = TryPNG(file,0,0);
      }
   }
   else if (pngFirst)
   {
      result = TryPNG(file,0,0);
      if (!result)
      {
         rewind(file);
         result = TryJPEG(file,0,0, onAppData);
      }
   }
   else
   {
      uint8 first = 0;
      fread(&first,1,1,file);
      if (first==0xff)
      {
         rewind(file);
         result = TryJPEG(file,0,0, onAppData);
      }
      else if (first==0x89)
      {
         rewind(file);
         result = TryPNG(file,0,0);
      }
   }

   fclose(file);
   return result;
}

Surface *Surface::LoadFromBytes(const uint8 *inBytes,int inLen, IAppDataCallback *onAppData)
{
   if (!inBytes || !inLen)
      return 0;

   Surface *result = 0;
   if (*inBytes==0xff)
      result = TryJPEG(0,inBytes,inLen,onAppData);
   else if (*inBytes==0x89)
      result = TryPNG(0,inBytes,inLen);

   return result;
}

bool Surface::Encode( ByteArray *outBytes,bool inPNG,double inQuality)
{
   if (inPNG)
      return EncodePNG(this,outBytes);
   
   else
      return EncodeJPG(this,outBytes,inQuality);
}


} // end namespace NME
