float3x3 rgbToXYZ_ = (float3x3(
    0.4124564, 0.3575761, 0.1804375,
    0.2126729, 0.7151522, 0.0721750,
    0.0193339, 0.1191920, 0.9503041
));

// Used to convert from XYZ to linear RGB space
float3x3 xyzToRGB_ = (float3x3(
    3.2404542, -1.5371385, -0.4985314,
    -0.9692660, 1.8760108, 0.0415560,
    0.0556434, -0.2040259, 1.0572252
));

// Converts a color from linear RGB to XYZ space
float3 rgbToXYZ(float3 rgb) 
{
    return mul(rgbToXYZ_, rgb);
}

// Converts a color from XYZ to linear RGB space
float3 xyzToRGB(float3 xyz) 
{
    return mul(xyzToRGB_, xyz);
}

// Converts a color from XYZ to xyY space (Y is luminosity)
float3 xyzToXYY(float3 xyz) 
{
    float Y = xyz.y;
    float x = xyz.x / (xyz.x + xyz.y + xyz.z);
    float y = xyz.y / (xyz.x + xyz.y + xyz.z);
    return float3(x, y, Y);
}

// Converts a color from xyY space to XYZ space
float3 xyyToXYZ(float3 xyY) 
{
    float Y = xyY.z;
    float x = Y * xyY.x / xyY.y;
    float z = Y * (1.0 - xyY.x - xyY.y) / xyY.y;
    return float3(x, Y, z);
}

// Converts a color from linear RGB to xyY space
float3 rgbToXYY(float3 rgb) 
{
    float3 xyz = rgbToXYZ(rgb);
    return xyzToXYY(xyz);
}

// Converts a color from xyY space to linear RGB
float3 xyyToRGB(float3 xyY) 
{
    float3 xyz = xyyToXYZ(xyY);
    return xyzToRGB(xyz);
}