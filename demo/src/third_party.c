/* As implementações das bibliotecas de um cabeçalho só (domínio público/MIT,
 * em third_party/stb): o rasterizador de fontes e o gravador de PNG das
 * capturas de tela. */
#if defined(__GNUC__)
#pragma GCC diagnostic ignored "-Wunused-function"
#pragma GCC diagnostic ignored "-Wsign-compare"
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#endif

#include <SDL3/SDL_stdinc.h>

#define STBTT_malloc(x, u) ((void)(u), SDL_malloc(x))
#define STBTT_free(x, u) ((void)(u), SDL_free(x))
#define STB_TRUETYPE_IMPLEMENTATION
#include "stb_truetype.h"

#define STBIW_MALLOC(sz) SDL_malloc(sz)
#define STBIW_REALLOC(p, sz) SDL_realloc(p, sz)
#define STBIW_FREE(p) SDL_free(p)
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STBI_WRITE_NO_STDIO
#include "stb_image_write.h"
