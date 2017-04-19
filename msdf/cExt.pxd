ctypedef bint bool

cdef extern from "core/Bitmap.h" namespace 'msdfgen' nogil:
    cdef cppclass FloatRGB:
        float r, g, b

    # A 2D image bitmap.
    cdef cppclass Bitmap[T]:
        Bitmap()
        Bitmap(int width, int height)
        Bitmap(const Bitmap[T] &orig)

        Bitmap[T] & operator=(const Bitmap[T] &orig)

        # Bitmap width in pixels.
        int width() const
        # Bitmap height in pixels.
        int height() const
        T & operator()(int x, int y)

cdef extern from "core/Shape.h" namespace 'msdfgen' nogil:
    cdef cppclass Shape:
        Shape()
        # Normalizes the shape geometry for distance field generation.
        void normalize()
        void bounds(double &l, double &b, double &r, double &t) const

cdef extern from "ext/save-png.h" namespace 'msdfgen' nogil:
    # A floating-point RGB pixel.
    cdef cppclass FloatRGB:
        float r, g, b

    bool savePng(const Bitmap[float] &bitmap, const char* filename)
    bool savePng(const Bitmap[FloatRGB] &bitmap, const char* filename)

cdef extern from "ext/import-font.h" namespace 'msdfgen' nogil:
    cdef cppclass FreetypeHandle
    cdef cppclass FontHandle

    # Initializes the FreeType library
    FreetypeHandle* initializeFreetype()

    # Deinitializes the FreeType library
    void deinitializeFreetype(FreetypeHandle* library)

    # Loads a font file and returns its handle
    FontHandle* loadFont(FreetypeHandle* library, const char* filename)

    # Unloads a font file
    void destroyFont(FontHandle* font)

    # Returns the size of one EM in the font's coordinate system
    bool getFontScale(double &output, FontHandle* font)

    # Returns the width of space and tab
    bool getFontWhitespaceWidth(double &spaceAdvance, double &tabAdvance, FontHandle* font)

    # Loads the shape prototype of a glyph from font file
    bool loadGlyph(Shape &output, FontHandle* font, int unicode, double* advance)

    # Returns the kerning distance adjustment between two specific glyphs.
    bool getKerning(double &output, FontHandle* font, int unicode1, int unicode2)