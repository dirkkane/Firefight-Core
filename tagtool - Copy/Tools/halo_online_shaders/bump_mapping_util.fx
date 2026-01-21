
#ifndef BUMP_CONVERT
#if defined(pc) && (DX_VERSION == 9)
#define BUMP_CONVERT(x)  ((x) * (255.0f / 127.f) - (128.0f / 127.f))
#else
#define BUMP_CONVERT(x)  (x)
#endif
#endif