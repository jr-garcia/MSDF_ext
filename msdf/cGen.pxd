from cExt cimport *

cdef extern from "core/Vector2.h" namespace 'msdfgen' nogil:
    cdef cppclass Vector2:
        double x, y
        Vector2()
        Vector2(double val)
        Vector2(double x, double y)

        # Sets individual elements of the vector.
        void set(double x, double y)

        Vector2 operator+() const
        Vector2 operator-() const
        Vector2 operator+(const Vector2 &other) const
        Vector2 operator-(const Vector2 &other) const
        Vector2 operator*(const Vector2 &other) const
        Vector2 operator/(const Vector2 &other) const
        Vector2 operator*(double value) const
        Vector2 operator/(double value) const
        Vector2 operator*(double value, const Vector2 &vector)
        Vector2 operator/(double value, const Vector2 &vector)


cdef extern from "core/edge-coloring.h" namespace 'msdfgen' nogil:
    # Assigns colors to edges of the shape in accordance to the multi-channel distance field technique.
    # May split some edges if necessary.
    # angleThreshold specifies the maximum angle (in radians) to be considered a corner, for example 3 (~172 degrees).
    # Values below 1/2 PI will be treated as the external angle.

    void edgeColoringSimple(Shape &shape, double angleThreshold, unsigned long long seed)

cdef extern from "msdfgen.h" namespace 'msdfgen' nogil:

    # Generates a conventional single-channel signed distance field.
    void generateSDF(Bitmap[float] &output, const Shape &shape, double range, const Vector2 &scale, const Vector2 &translate)

    # Generates a single-channel signed pseudo-distance field.
    void generatePseudoSDF(Bitmap[float] &output, const Shape &shape, double range, const Vector2 &scale, const Vector2 &translate)

    # Generates a multi-channel signed distance field. Edge colors must be assigned first! (see edgeColoringSimple)
    void generateMSDF(Bitmap[FloatRGB] &output, const Shape &shape, double range, const Vector2 &scale, const Vector2 &translate, double edgeThreshold)
    # = 1.00000001