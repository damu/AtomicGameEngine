#ifdef COMPILEPS
  #ifdef PBR

    // Following BRDF methods are based upon research Frostbite EA
    //[Lagrade et al. 2014, "Moving Frostbite to Physically Based Rendering"]
    
    //Schlick Fresnel
    //specular  = the rgb specular color value of the pixel
    //VdotH     = the dot product of the camera view direction and the half vector 
    float3 SchlickFresnel(float3 specular, float VdotH)
    {
        return specular + (float3(1.0, 1.0, 1.0) - specular) * pow(1.0 - VdotH, 5.0);
    }

    //Schlick Gaussian Fresnel 
    //specular  = the rgb specular color value of the pixel
    //VdotH     = the dot product of the camera view direction and the half vector 
    float3 SchlickGaussianFresnel(in float3 specular, in float VdotH)
    {
        float sphericalGaussian = pow(2.0, (-5.55473 * VdotH - 6.98316) * VdotH);
        return specular + (float3(1.0, 1.0, 1.0) - specular) * sphericalGaussian;
    }

    //Get Fresnel
    //specular  = the rgb specular color value of the pixel
    //VdotH     = the dot product of the camera view direction and the half vector 
    float3 Fresnel(float3 specular, float VdotH)
    {
        return SchlickFresnel(specular, VdotH);
    }

    // [Neumann et al. 1999, "Compact metallic reflectance models"]
    float NeumannVisibility( float NdotV, float NdotL )
    {
        return 1 / ( 4 * max( NdotL, NdotV ) );
    }

    // [Kelemen 2001, "A microfacet based coupled specular-matte brdf model with importance sampling"]
    float KelemenVisibility( float VdotH )
    {
        // constant to prevent NaN
        return rcp( 4 * VdotH * VdotH + 1e-5);
    }

    // Smith GGX corrected Visibility
    // [Smith 1967, "Geometrical shadowing of a random rough surface"]
    // NdotL        = the dot product of the normal and direction to the light
    // NdotV        = the dot product of the normal and the camera view direction
    // roughness    = the roughness of the pixel
    float SmithGGXSchlickVisibility(float NdotL, float NdotV, float roughness)
    {
        float rough2 = roughness * roughness;
        float lambdaV = NdotL  * sqrt((-NdotV * rough2 + NdotV) * NdotV + rough2);   
        float lambdaL = NdotV  * sqrt((-NdotL * rough2 + NdotL) * NdotL + rough2);
    
        return 0.5 / (lambdaV + lambdaL);
    }

    // [Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"]
    float SmithJointApproxVisibility( float roughness, float NdotV, float NdotL )
    {
        float a = roughness * roughness;
        float Vis_SmithV = NdotL * ( NdotV * ( 1 - a ) + a );
        float Vis_SmithL = NdotV * ( NdotL * ( 1 - a ) + a );
        return 0.5 * rcp( Vis_SmithV + Vis_SmithL );
    }

    // Get Visibility
    // NdotL        = the dot product of the normal and direction to the light
    // NdotV        = the dot product of the normal and the camera view direction
    // roughness    = the roughness of the pixel
    float Visibility(float NdotL, float NdotV, float VdotH, float roughness)
    {
        //return NeumannVisibility(NdotV, NdotL);
        //return KelemenVisibility(VdotH);
        //return SmithJointApproxVisibility(roughness, NdotV, NdotL);
        return SmithGGXSchlickVisibility(NdotL, NdotV, roughness);
    }

    // GGX Distribution
    // NdotH        = the dot product of the normal and the half vector
    // roughness    = the roughness of the pixel
    float GGXDistribution(float NdotH, float roughness)
    {
        float rough2 = roughness * roughness;
        float tmp =  (NdotH * rough2 - NdotH) * NdotH + 1;
        return rough2 / (tmp * tmp);
    }

    // Blinn Distribution
    // NdotH        = the dot product of the normal and the half vector
    // roughness    = the roughness of the pixel
    float BlinnPhongDistribution(in float NdotH, in float roughness)
    {
        float specPower = max((2.0 / (roughness * roughness)) - 2.0, 1e-4f); // Calculate specular power from roughness
        return pow(saturate(NdotH), specPower);
    }

    // Beckmann Distribution
    // NdotH        = the dot product of the normal and the half vector
    // roughness    = the roughness of the pixel
    float BeckmannDistribution(in float NdotH, in float roughness)
    {
        float rough2 = roughness * roughness;
        float roughnessA = 1.0 / (4.0 * rough2 * pow(NdotH, 4.0));
        float roughnessB = NdotH * NdotH - 1.0;
        float roughnessC = rough2 * NdotH * NdotH;
        return roughnessA * exp(roughnessB / roughnessC);
    }

    // Get Distribution
    // NdotH        = the dot product of the normal and the half vector
    // roughness    = the roughness of the pixel
    float Distribution(float NdotH, float roughness)
    {
        return GGXDistribution(NdotH, roughness);
    }

    // Lambertian Diffuse
    // diffuseColor = the rgb color value of the pixel
    // roughness    = the roughness of the pixel
    // NdotV        = the normal dot with the camera view direction
    // NdotL        = the normal dot with the light direction
    // VdotH        = the camera view direction dot with the half vector
    float3 LambertianDiffuse(float3 diffuseColor, float NdotL)
    {
        return diffuseColor * (1 / M_PI);
    }

    // Burley Diffuse
    // [Burley 2012, "Physically-Based Shading at Disney"]
    // diffuseColor = the rgb color value of the pixel
    // roughness    = the roughness of the pixel
    // NdotV        = the normal dot with the camera view direction
    // NdotL        = the normal dot with the light direction
    // VdotH        = the camera view direction dot with the half vector
    float3 BurleyDiffuse(float3 diffuseColor, float roughness, float NdotV, float NdotL, float VdotH)
    {
        float FD90 = ( 0.5 + 2 * VdotH * VdotH ) * roughness;
        float FdV = 1 + (FD90 - 1) * pow( 1 - NdotV, 5 );
        float FdL = 1 + (FD90 - 1) * pow( 1 - NdotL, 5 );
        return diffuseColor * ( 1 / M_PI * FdV * FdL ) * ( 1 - 0.3333 * roughness );  
    }

    // OrenNayar Diffuse
    // [Gotanda 2012, "Beyond a Simple Physically Based Blinn-Phong Model in Real-Time"]
    // diffuseColor = the rgb color value of the pixel
    // roughness    = the roughness of the pixel
    // NdotV        = the normal dot with the camera view direction
    // NdotL        = the normal dot with the light direction
    // VdotH        = the camera view direction dot with the half vector
    float3 OrenNayarDiffuse( float3 diffuseColor, float roughness, float NdotV, float NdotL, float VdotH )
    {
        float a = roughness * roughness;
        float s = a;
        float s2 = s * s;
        float VoL = 2 * VdotH * VdotH - 1; 
        float Cosri = VoL - NdotV * NdotL;
        float C1 = 1 - 0.5 * s2 / (s2 + 0.33);
        float C2 = 0.45 * s2 / (s2 + 0.09) * Cosri * ( Cosri >= 0 ? rcp( max( NdotL, NdotV ) ) : 1 );
        return diffuseColor * ( C1 + C2 ) * ( 1 + roughness * 0.5 );
    }

    // Gotanda Diffuse
    // [Gotanda 2014, "Designing Reflectance Models for New Consoles"]
    // diffuseColor = the rgb color value of the pixel
    // roughness    = the roughness of the pixel
    // NdotV        = the normal dot with the camera view direction
    // NdotL        = the normal dot with the light direction
    // VdotH        = the camera view direction dot with the half vector
    float3 GotandaDiffuse( float3 diffuseColor, float roughness, float NdotV, float NdotL, float VdotH )
    {
        float a = roughness * roughness;
        float a2 = a * a;
        float F0 = 0.04;
        float VoL = 2 * VdotH * VdotH - 1;
        float Cosri = VoL - NdotV * NdotL;

        float a2_13 = a2 + 1.36053;
        float Fr = ( 1 - ( 0.542026*a2 + 0.303573*a ) / a2_13 ) * ( 1 - pow( 1 - NdotV, 5 - 4*a2 ) / a2_13 ) * ( ( -0.733996*a2*a + 1.50912*a2 - 1.16402*a ) * pow( 1 - NdotV, 1 + rcp(39*a2*a2+1) ) + 1 );
        float Lm = ( max( 1 - 2*a, 0 ) * ( 1 - pow( 1 - NdotL , 5)) + min( 2*a, 1 ) ) * ( 1 - 0.5*a + 0.5*a * NdotL );
        float Vd = ( a2 / ( (a2 + 0.09) * (1.31072 + 0.995584 * NdotV) ) ) * ( 1 - pow( 1 - NdotL, ( 1 - 0.3726732 * NdotV * NdotV ) / ( 0.188566 + 0.38841 * NdotV ) ) );
        float Bp = Cosri < 0 ? 1.4 * NdotV * Cosri : Cosri / max( NdotL, 1e-8 );
        float Lr = (21.0 / 20.0) * (1 - F0) * ( Fr * Lm + Vd + Bp );

        return diffuseColor / M_PI * Lr;
    }

    //Get Diffuse
    // diffuseColor = the rgb color value of the pixel
    // roughness    = the roughness of the pixel
    // NdotV        = the normal dot with the camera view direction
    // NdotL        = the normal dot with the light direction
    // VdotH        = the camera view direction dot with the half vector
    float3 Diffuse(float3 diffuseColor, float roughness, float NdotV, float NdotL, float VdotH)
    {
        //return LambertianDiffuse(diffuseColor, NdotL);
        return BurleyDiffuse(diffuseColor, roughness, NdotV, NdotL, VdotH);
        //return OrenNayarDiffuse(diffuseColor, roughness, NdotV, NdotL, VdotH);
        //return GotandaDiffuse(diffuseColor, roughness, NdotV, NdotL, VdotH);
    }

  #endif
#endif
