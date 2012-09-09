#include "kangaroo.h"
#include "launch_utils.h"
#include "Image.h"

namespace Gpu
{

//////////////////////////////////////////////////////
// Image Scale / Bias
// b = s*a+offset
//////////////////////////////////////////////////////

template<typename Tout, typename Tin, typename Tup>
__global__ void KernElementwiseScaleBias(Image<Tout> b, const Image<Tin> a, Tup s, Tup offset)
{
    const int x = blockIdx.x*blockDim.x + threadIdx.x;
    const int y = blockIdx.y*blockDim.y + threadIdx.y;

    if(b.InBounds(x,y)) {
        const Tup v1 = ConvertPixel<Tup,Tin>(a(x,y));
        b(x,y) = ConvertPixel<Tout,Tup>(s*v1+offset);
    }
}

template<typename Tout, typename Tin, typename Tup>
void ElementwiseScaleBias(Image<Tout> b, const Image<Tin> a, Tup s, Tup offset)
{
    dim3 blockDim, gridDim;
    InitDimFromOutputImageOver(blockDim,gridDim, b);
    KernElementwiseScaleBias<Tout,Tin,Tup><<<gridDim,blockDim>>>(b,a,s,offset);
}


//////////////////////////////////////////////////////
// Image Addition
// c = sa*a + sb*b + offset
//////////////////////////////////////////////////////

template<typename Tout, typename Tin1, typename Tin2, typename Tup>
__global__ void KernElementwiseAdd(Image<Tout> c, const Image<Tin1> a, const Image<Tin2> b, Tup sa, Tup sb, Tup offset)
{
    const int x = blockIdx.x*blockDim.x + threadIdx.x;
    const int y = blockIdx.y*blockDim.y + threadIdx.y;

    if(c.InBounds(x,y)) {
        const Tup v1 = sa * ConvertPixel<Tup,Tin1>(a(x,y));
        const Tup v2 = sb * ConvertPixel<Tup,Tin2>(b(x,y));
        c(x,y) = ConvertPixel<Tout,Tup>(v1+v2+offset);
    }
}

template<typename Tout, typename Tin1, typename Tin2, typename Tup>
void ElementwiseAdd(Image<Tout> c, const Image<Tin1> a, const Image<Tin2> b, Tup sa, Tup sb, Tup offset )
{
    dim3 blockDim, gridDim;
    InitDimFromOutputImageOver(blockDim,gridDim, c);
    KernElementwiseAdd<Tout,Tin1,Tin2,Tup><<<gridDim,blockDim>>>(c,a,b,sa,sb,offset);
}

//////////////////////////////////////////////////////
// Image Multiplication
// c = scalar * a*b + offset
//////////////////////////////////////////////////////

template<typename Tout, typename Tin1, typename Tin2, typename Tup>
__global__ void KernElementwiseMultiply(Image<Tout> c, const Image<Tin1> a, const Image<Tin2> b, Tup scalar, Tup offset)
{
    const int x = blockIdx.x*blockDim.x + threadIdx.x;
    const int y = blockIdx.y*blockDim.y + threadIdx.y;

    if(c.InBounds(x,y)) {
        const Tup v1 = ConvertPixel<Tup,Tin1>(a(x,y));
        const Tup v2 = ConvertPixel<Tup,Tin2>(b(x,y));
        c(x,y) = ConvertPixel<Tout,Tup>( scalar * (v1 * v2) + offset );
    }
}

template<typename Tout, typename Tin1, typename Tin2, typename Tup>
void ElementwiseMultiply(Image<Tout> c, const Image<Tin1> a, const Image<Tin2> b, Tup scalar, Tup offset )
{
    dim3 blockDim, gridDim;
    InitDimFromOutputImageOver(blockDim,gridDim, c);
    KernElementwiseMultiply<Tout,Tin1,Tin2,Tup><<<gridDim,blockDim>>>(c,a,b,scalar,offset);
}

//////////////////////////////////////////////////////
// Image Division
// c = scalar * (a+sa) / (b+sb) + offset
//////////////////////////////////////////////////////

template<typename Tout, typename Tin1, typename Tin2, typename Tup>
__global__ void KernElementwiseDivision(Image<Tout> c, const Image<Tin1> a, const Image<Tin2> b, Tup sa, Tup sb, Tup scalar, Tup offset)
{
    const int x = blockIdx.x*blockDim.x + threadIdx.x;
    const int y = blockIdx.y*blockDim.y + threadIdx.y;

    if(c.InBounds(x,y)) {
        const Tup v1 = ConvertPixel<Tup,Tin1>(a(x,y));
        const Tup v2 = ConvertPixel<Tup,Tin2>(b(x,y));
        c(x,y) = ConvertPixel<Tout,Tup>( scalar * (v1+sa)/(v2+sb) + offset );
    }
}

template<typename Tout, typename Tin1, typename Tin2, typename Tup>
void ElementwiseDivision(Image<Tout> c, const Image<Tin1> a, const Image<Tin2> b, Tup sa, Tup sb, Tup scalar, Tup offset)
{
    dim3 blockDim, gridDim;
    InitDimFromOutputImageOver(blockDim,gridDim, c);
    KernElementwiseDivision<Tout,Tin1,Tin2,Tup><<<gridDim,blockDim>>>(c,a,b,sa,sb,scalar,offset);
}

//////////////////////////////////////////////////////
// Image Square
// b = scalar * a^2 + offset
//////////////////////////////////////////////////////

template<typename Tout, typename Tin, typename Tup>
__global__ void KernElementwiseSquare(Image<Tout> b, const Image<Tin> a, Tup scalar, Tup offset)
{
    const int x = blockIdx.x*blockDim.x + threadIdx.x;
    const int y = blockIdx.y*blockDim.y + threadIdx.y;

    if(b.InBounds(x,y)) {
        const Tup v1 = ConvertPixel<Tup,Tin>(a(x,y));
        b(x,y) = ConvertPixel<Tout,Tup>( (scalar * v1*v1) + offset );
    }
}

template<typename Tout, typename Tin, typename Tup>
void ElementwiseSquare(Image<Tout> b, const Image<Tin> a, Tup scalar, Tup offset )
{
    dim3 blockDim, gridDim;
    InitDimFromOutputImageOver(blockDim,gridDim, b);
    KernElementwiseSquare<Tout,Tin,Tup><<<gridDim,blockDim>>>(b,a,scalar,offset);
}

//////////////////////////////////////////////////////
// Image Multiplication / Addition
// d = sab*a*b+ sc*c + offset
//////////////////////////////////////////////////////

template<typename Tout, typename Tin1, typename Tin2, typename Tin3, typename Tup>
__global__ void KernElementwiseMultiplyAdd(Image<Tout> d, const Image<Tin1> a, const Image<Tin2> b, const Image<Tin3> c, Tup sab, Tup sc, Tup offset)
{
    const int x = blockIdx.x*blockDim.x + threadIdx.x;
    const int y = blockIdx.y*blockDim.y + threadIdx.y;

    if(c.InBounds(x,y)) {
        const Tup v1 = ConvertPixel<Tup,Tin1>(a(x,y));
        const Tup v2 = ConvertPixel<Tup,Tin2>(b(x,y));
        const Tup v3 = ConvertPixel<Tup,Tin3>(c(x,y));
        d(x,y) = ConvertPixel<Tout,Tup>( sab*v1*v2 + sc*v3 + offset );
    }
}

template<typename Tout, typename Tin1, typename Tin2, typename Tin3, typename Tup>
void ElementwiseMultiplyAdd(Image<Tout> d, const Image<Tin1> a, const Image<Tin2> b, const Image<Tin3> c, Tup sab, Tup sc, Tup offset)
{
    dim3 blockDim, gridDim;
    InitDimFromOutputImageOver(blockDim,gridDim, d);
    KernElementwiseMultiplyAdd<Tout,Tin1,Tin2,Tin3,Tup><<<gridDim,blockDim>>>(d,a,b,c,sab,sc,offset);
}


//////////////////////////////////////////////////////
// Instantiate Templates
//////////////////////////////////////////////////////

template void ElementwiseScaleBias(Image<float> b, const Image<unsigned char> a, float s, float offset);
template void ElementwiseAdd(Image<unsigned char>, Image<unsigned char>, Image<unsigned char>, int, int, int);
template void ElementwiseMultiply(Image<float>, Image<float>, Image<float>, float,float);
template void ElementwiseMultiply(Image<float>, Image<unsigned char>, Image<unsigned char>, float,float);
template void ElementwiseSquare<float,float,float>(Image<float>, Image<float>, float, float);
template void ElementwiseSquare<float,unsigned char,float>(Image<float>, Image<unsigned char>, float, float);
template void ElementwiseMultiplyAdd(Image<float> d, const Image<float> a, const Image<float> b, const Image<float> c, float sab, float sc, float offset);
template void ElementwiseMultiplyAdd(Image<float> d, const Image<float> a, const Image<unsigned char> b, const Image<float> c, float sab, float sc, float offset);
template void ElementwiseDivision(Image<float> c, const Image<float> a, const Image<float> b, float sa, float sb, float scalar, float offset);
}
