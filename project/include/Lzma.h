#ifndef NME_LZMA_H
#define NME_LZMA_H

#ifndef HXCPP_JS_PRIME

#include <nme/NmeCffi.h>

namespace nme {

	class Lzma {
		public:
		
			static void Encode(buffer input_buffer, buffer output_buffer);
			static void Decode(buffer input_buffer, buffer output_buffer);
	};
	
}

#endif

#endif
