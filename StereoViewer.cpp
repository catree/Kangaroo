#include <Eigen/Eigen>
#include <pangolin/pangolin.h>
#include <pangolin/glcuda.h>

#include <cuda.h>
#include <cuda_runtime.h>
#include <cuda_gl_interop.h>

#include "common/RpgCameraOpen.h"
#include "cu/all.h"

using namespace std;
using namespace pangolin;
using namespace Gpu;

int main( int /*argc*/, char* argv[] )
{
    // Open video device
    CameraDevice camera = OpenRpgCamera(
//            "AlliedVision:[NumChannels=2,CamUUID0=5004955,CamUUID1=5004954,ImageBinningX=2,ImageBinningY=2,ImageWidth=694,ImageHeight=518]//"
//            "FileReader:[NumChannels=2,DataSourceDir=/Users/slovegrove/data/CityBlock-Noisy,Channel-0=left.*pgm,Channel-1=right.*pgm,StartFrame=0]//"
            "FileReader:[NumChannels=2,DataSourceDir=/Users/slovegrove/data/xb3,Channel-0=left.*pgm,Channel-1=right.*pgm,StartFrame=0]//"
//            "Dvi2Pci:[NumImages=2,ImageWidth=640,ImageHeight=480,BufferCount=60]//"
    );

//    CameraDevice camera = OpenPangoCamera(
//        "file:[stream=0,fmt=GRAY8]///Users/slovegrove/data/3DCam/DSCF0051.AVI",
//        "file:[stream=1,fmt=GRAY8]///Users/slovegrove/data/3DCam/DSCF0051.AVI"
//    );

    // Capture first image
    std::vector<rpg::ImageWrapper> img;
    camera.Capture(img);

    // Check we received one or more images
    if(img.empty()) {
        std::cerr << "Failed to capture first image from camera" << std::endl;
        return -1;
    }

    // N cameras, each w*h in dimension, greyscale
    const unsigned int w = img[0].width();
    const unsigned int h = img[0].height();

    // Setup OpenGL Display (based on GLUT)
    pangolin::CreateGlutWindowAndBind(__FILE__,2*w,2*h);

    // Initialise CUDA, allowing it to use OpenGL context
    cudaGLSetGLDevice(0);

    // Setup default OpenGL parameters
    glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable (GL_BLEND);
    glEnable (GL_LINE_SMOOTH);
    glPixelStorei(GL_PACK_ALIGNMENT,1);
    glPixelStorei(GL_UNPACK_ALIGNMENT,1);

    // Tell the base view to arrange its children equally
    View& screen = CreateDisplay().SetAspect((double)w/h);

    // Texture we will use to display camera images
//    GlTextureCudaArray tex(w,h,GL_LUMINANCE8);
    GlTextureCudaArray texrgb(w,h,GL_RGBA8);

    // Allocate Camera Images on device for processing
    Image<unsigned char, TargetDevice, Manage> dCamImg[] = {{w,h},{w,h}};
    Image<uchar4, TargetDevice, Manage> d3d(w,h);

    int shift = 0;
    bool run = true;

    pangolin::RegisterKeyPressCallback('=', [&shift](){shift++;} );
    pangolin::RegisterKeyPressCallback('-', [&shift](){shift--;} );
    pangolin::RegisterKeyPressCallback(' ', [&run](){run = !run;} );

    for(unsigned long frame=0; !pangolin::ShouldQuit(); ++frame)
    {
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glColor3f(1,1,1);

        if( run || frame == 0 ) {
            camera.Capture(img);

            // Upload images to device
            for(int i=0; i<2; ++i ) {
                dCamImg[i].CopyFrom( Image<unsigned char,TargetHost>(img[i].Image.data,w,h) );
            }
        }

        // Perform Processing
        MakeAnaglyth(d3d, dCamImg[0], dCamImg[1], shift);

        // Draw Anaglyph
        screen.Activate();
        CopyDevMemtoTex(d3d.ptr, d3d.pitch, texrgb );
        texrgb.RenderToViewportFlipY();

        pangolin::FinishGlutFrame();
        usleep(1000000 / 30);
    }
}
