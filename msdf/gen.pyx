# cython: c_string_type=bytes
# cython: c_string_encoding=utf8
# cython: boundscheck=False
from libc.math cimport M_PI
from cython.operator cimport dereference as deref
from libc.string cimport memcpy
from libc.stdlib cimport malloc, free
from libc.stdio cimport printf
from cython.parallel cimport prange

cimport cGen


cdef float getAngle(float value) nogil:
    return M_PI*value/180


cdef class Bitmap:
    cdef cGen.Bitmap[cGen.FloatRGB] store
    cdef readonly int size
    cdef readonly float scaleX
    cdef readonly float scaleY

    def __init__(self, int size):
        self.size = size

    cdef inline void fill(self, cGen.Bitmap[cGen.FloatRGB] bm) nogil:
        self.store = bm

    cdef void fillAll(self, cGen.Bitmap[cGen.FloatRGB] bm, cGen.Vector2 scale) nogil:
        self.scaleX = scale.x
        self.scaleY = scale.y
        self.store = bm

    def getSize(self):
        return self.store.width(), self.store.height()

    def __getitem__(self, val):
        cdef float r,g,b
        cdef cGen.FloatRGB rgb= self.store(<int>val[0], <int>val[1])
        r = rgb.r
        g = rgb.g
        b = rgb.b
        return r,g,b

    def asArray(self, float[:,:,:]bm not None):
        cdef int alen, w, h, d, x, y
        w = bm.shape[0]
        h = bm.shape[1]
        d = bm.shape[2]
        if w != self.size or h != self.size or d != 3:
            raise RuntimeError('wrong shape (({shape},{shape},3) required)'.format(shape=self.size))
        with nogil:
            for x in prange(self.size):
                for y in range(self.size):
                    memcpy(<void*>&bm[x, y][0], <void*>&self.store(y, w - x - 1).r, sizeof(cGen.FloatRGB))


DEF RANGE_PX = 0
DEF RANGE_UNIT = 1
DEF LARGE_VALUE = 1e240


cdef cGen.Bitmap[cGen.FloatRGB] makeOne(cGen.Vector2* refscale,
            char* fontPath, int char, int size=16, double range=2.0,
            float border=1.0, float edgeThreshold= 1.00000001, float angle=179, int seed=0) nogil except +:
    cdef cGen.FreetypeHandle* ft = cGen.initializeFreetype()
    cdef cGen.FontHandle* font
    cdef cGen.Shape shape
    cdef cGen.Bitmap[cGen.FloatRGB] msdf
    cdef cGen.Vector2 translate = cGen.Vector2(0)
    cdef cGen.Vector2 scale = cGen.Vector2(1)
    cdef double avgScale, largerside, totalWidth, totalHeight
    cdef cGen.Vector2 frame, dims, res
    cdef float pxRange = border
    cdef double l=LARGE_VALUE, b=LARGE_VALUE, r=-LARGE_VALUE, t=-LARGE_VALUE, glyphAdvance=0

    cdef int rangeMode = RANGE_PX
    if not ft:
        with gil:
            raise RuntimeError('failed to initialize Freetype')
    else:
        font = cGen.loadFont(ft, fontPath)
        if not font:
            with gil:
                raise RuntimeError(b'failed to load font at ' + fontPath)
        else:
            if not cGen.loadGlyph(shape, font, char, &glyphAdvance):
                with gil:
                    raise RuntimeError('failed to load glyph for char ' + str(char))
            else:
                shape.normalize()
                shape.bounds(l,b,r,t)
                avgScale = .5*(scale.x+scale.y)

                # Auto-frame
                frame = cGen.Vector2(size, size)
                frame -= 2 * pxRange
                if (l >= r or b >= t):
                    l=0
                    b=0
                    r=1
                    t=1
                if (frame.x <= 0 or frame.y <= 0):
                    return cGen.Bitmap[cGen.FloatRGB](-1, -1)
                dims = cGen.Vector2(r-l, t-b)
                if dims.x*frame.y < dims.y*frame.x :
                    translate.set(.5*(frame.x/frame.y*dims.y-dims.x)-l, -b)
                    avgScale = frame.y / dims.y
                    scale = cGen.Vector2(avgScale)
                else:
                    translate.set(-l, .5*(frame.y/frame.x*dims.x-dims.y)-b)
                    avgScale = frame.x / dims.x
                    scale = cGen.Vector2(avgScale)

                translate += cGen.Vector2(pxRange / scale.x, pxRange / scale.y)

                #                              max. angle
                cGen.edgeColoringSimple(shape, getAngle(angle), seed)
                #                          image width, height
                msdf = cGen.Bitmap[cGen.FloatRGB](size, size)

                cGen.generateMSDF(msdf, shape,
                                  range,
                                  scale,
                                  translate,
                                  edgeThreshold)

            cGen.destroyFont(font)
        cGen.deinitializeFreetype(ft)
    deref(refscale).set(scale.x, scale.y)
    return msdf



def multiMake(str fontPath, list chars, int size=16, double distance=2.0, str output="",
              float border=1.0, float edgeThreshold= 1.00000001, float angle=179, int seed=0):
    cdef int i = 0, charlen = len(chars)
    cdef int* cchars = <int*>malloc(sizeof(int) * charlen)
    cdef bytes tFontPath = fontPath.encode()
    cdef char* bFontPath = tFontPath
    cdef cGen.Bitmap[cGen.FloatRGB]** bms = <cGen.Bitmap[cGen.FloatRGB]**>malloc(sizeof(cGen.FloatRGB) * size * size * charlen)
    cdef list ret = []
    cdef cGen.Vector2** scales = <cGen.Vector2**>malloc(sizeof(cGen.Vector2)*charlen)

    for i in range(charlen):
        cchars[i] = chars[i]
        ret.append(Bitmap(size=size))

    with nogil:
        for i in prange(charlen):
            scales[i] = new cGen.Vector2(1)
            bms[i] = new cGen.Bitmap[cGen.FloatRGB](makeOne(scales[i], bFontPath, cchars[i], size, distance,
                                                            border, edgeThreshold, angle, seed))
            if bms[i].width() == -1:
                with gil:
                    raise RuntimeError(u"Cannot fit the specified pixel range for char {} ({}) ".format(
                            cchars[i], chr(cchars[i])))

    cdef Bitmap tBm
    for i in range(charlen):
        tBm = <Bitmap> ret[i]
        tBm.fillAll(deref(bms[i]), deref(scales[i]))
        free(scales[i])
        free(bms[i])

    free(scales)
    free(bms)
    free(cchars)

    return ret


def makeSDF(str fontPath, const int c, int size=16, double distance=2.0,
            float border=1.0, float edgeThreshold= 1.00000001, angle=179, int seed=0):
    cdef cGen.Vector2 scale = cGen.Vector2(1)
    cdef bytes tFontPath = fontPath.encode()
    cdef char* bFontPath = tFontPath
    cdef cGen.Bitmap[cGen.FloatRGB] bms = makeOne(&scale, bFontPath, c, size, distance,
                                                            border, edgeThreshold, angle, seed)
    cdef Bitmap bitmap = Bitmap(size)
    bitmap.fillAll(bms, scale)
    return bitmap