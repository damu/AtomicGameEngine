#include "Uniforms.hlsl"
#include "Transform.hlsl"
#include "Samplers.hlsl"
#include "ScreenPos.hlsl"
#include "PostProcess.hlsl"

void VS(float4 iPos : POSITION,
    out float2 oScreenPos : TEXCOORD0,
    out float4 oPos : OUTPOSITION)
{
    float4x3 modelMatrix = iModelMatrix;
    float3 worldPos = GetWorldPos(modelMatrix);
    oPos = GetClipPos(worldPos);
    oScreenPos = GetScreenPosPreDiv(oPos);
}

void PS(float2 iScreenPos : TEXCOORD0,
    out float4 oColor : OUTCOLOR0)
{
    float3 color = Sample2D(DiffMap, iScreenPos).rgb;
    float3 sRGBLo = color * 12.92;
    float3 sRGBHi = (pow(abs(color), 1.0/2.4) * 1.055) - 0.055;
    float3 sRGB = (color <= 0.0031308) ? sRGBLo : sRGBHi; 
    oColor = float4(sRGB, 1.0);
}
