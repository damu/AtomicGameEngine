#include <iostream>
#include <string>
#include <cstdio>

#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image.h"
#include "stb_image_write.h"

#include "PVRTexTool/Library/Include/PVRTexture.h"
#include "PVRTexTool/Library/Include/PVRTextureUtilities.h"
#include "PVRTexTool/Library/Include/PVRTString.h"
#include "PVRTexTool/Library/Include/PVRTGlobal.h"

// seems like the PVRTexTool guys forgot to define this... Not sure if =std::string::npos is correct but it seems to work.
const size_t CPVRTString::npos=std::string::npos;

void convert_image_to_tga(const std::string& input_filename,const std::string& output_filename)
{
    int w,h,comp;
    unsigned char *image_data=stbi_load(input_filename.c_str(),&w,&h,&comp,0);
    if(!image_data)
    {
        std::cerr<<"ERROR: Could not open "<<input_filename<<std::endl;
        return;
    }
    stbi_write_tga(output_filename.c_str(),w,h,comp,image_data);
    stbi_image_free(image_data);
}

void step_convert_pngs_to_tgas()
{
    std::cout<<"Converting the six cubemap PNGs from the AtomicEditor to six TGAs for cmft..."<<std::endl;

    convert_image_to_tga("Cubemap_PosX.png","Cubemap_PosX.tga");
    convert_image_to_tga("Cubemap_NegX.png","Cubemap_NegX.tga");
    convert_image_to_tga("Cubemap_PosY.png","Cubemap_PosY.tga");
    convert_image_to_tga("Cubemap_NegY.png","Cubemap_NegY.tga");
    convert_image_to_tga("Cubemap_PosZ.png","Cubemap_PosZ.tga");
    convert_image_to_tga("Cubemap_NegZ.png","Cubemap_NegZ.tga");
}

// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void step_run_cmft()
{
    std::cout<<"Running cmft... (this takes a while!)"<<std::endl;

    system("cmft.exe"
           " --inputFacePosX Cubemap_PosX.tga"
           " --inputFaceNegX Cubemap_NegX.tga"
           " --inputFacePosY Cubemap_PosY.tga"
           " --inputFaceNegY Cubemap_NegY.tga"
           " --inputFacePosZ Cubemap_PosZ.tga"
           " --inputFaceNegZ Cubemap_NegZ.tga"
           " --filter radiance"
           " --outputNum 7"
           " --edgeFixup warp"
           " --lightingModel blinnbrdf"
           " --glossScale 10"
           " --glossBias 3"
           " --outputGammaNumerator 220 --outputGammaDenominator 100"
           " --outputGammaNumerator 45 --outputGammaDenominator 100"
           " --generateMipChain true --mipCount 7 --excludebase true"
           " --output0 cubemap --output0params dds,bgr8,cubemap");

    std::remove("Cubemap_PosX.tga");
    std::remove("Cubemap_NegX.tga");
    std::remove("Cubemap_PosY.tga");
    std::remove("Cubemap_NegY.tga");
    std::remove("Cubemap_PosZ.tga");
    std::remove("Cubemap_NegZ.tga");
}

// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* Currently unused. This area was for calling an externally installed PVRTexToolCli but currently this program used the PVRTexTool library.
#ifdef __WIN32__
 #include <windows.h>

std::wstring get_registry_value(HKEY key,std::wstring subkey)
{
    std::wstring ret;

    HKEY hKey=0;
    wchar_t buf[4096];
    DWORD dwType=0;
    DWORD dwBufSize=sizeof(buf);
    if(RegOpenKey(key,subkey.c_str(),&hKey)==ERROR_SUCCESS)
    {
        dwType=REG_SZ;
        if(RegQueryValueEx(hKey,L"",0,&dwType,(BYTE*)buf,&dwBufSize)==ERROR_SUCCESS)
            ret=std::wstring(buf);
        else
            std::cout<<"Can not query for key value\n";
        RegCloseKey(hKey);
    }
    else
        std::cout<<"Can not open subkey "<<std::string(subkey.begin(),subkey.end())<<std::endl;

    return ret;
}
#endif

void step_run_pvrtextoolcli()
{
    std::cout<<"Running PVRTexToolCLI..."<<std::endl;
    std::wstring path_to_pvrtextoolcli;
#ifdef __WIN32__
    path_to_pvrtextoolcli=get_registry_value(HKEY_CLASSES_ROOT,L"Imagination.Texture.2016_R2\\DefaultIcon");
#endif
    if(path_to_pvrtextoolcli.size())
    {
        int folders_to_go_up=3;
        for(int i=path_to_pvrtextoolcli.size();i>0;i--)
        {
            if(path_to_pvrtextoolcli[i]=='\\')
                folders_to_go_up--;

            if(folders_to_go_up<=0)
            {
                path_to_pvrtextoolcli.erase(i);
                break;
            }
        }
        path_to_pvrtextoolcli.append(L"\\CLI\\Windows_x86_64\\");
    }
    else
        std::cout<<"WARNING: Path to PVRTexToolCLI not found (only supported on Windows). Trying to run that without the full path."<<std::endl;

    path_to_pvrtextoolcli.append(L"PVRTexToolCLI.exe");

    std::string command(path_to_pvrtextoolcli.begin(),path_to_pvrtextoolcli.end());
    std::cout<<"Detected path to PVRTexToolCLI: \""<<command<<"\""<<std::endl;

    system(command.c_str());
}
*/

void step_convert_dds_to_pvr()
{
    std::cout<<"\nConverting the DDS file to a PVR file..."<<std::endl;

    pvrtexture::CPVRTexture texture("cubemap.dds");
    pvrtexture::Transcode(texture,texture.getPixelType(),texture.getChannelType(),texture.getColourSpace());
    texture.saveFile("cubemap.pvr");

    std::remove("cubemap.dds");
}

// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

int main(int argc,char *argv[])
{
    std::cout<<"Cubemap Converter"<<std::endl;

    step_convert_pngs_to_tgas();
    step_run_cmft();
    step_convert_dds_to_pvr();

    return 0;
}
