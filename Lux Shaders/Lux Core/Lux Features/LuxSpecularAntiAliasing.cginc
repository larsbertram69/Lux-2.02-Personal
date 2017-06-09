#ifndef LUX_SPECULARANITALIASING_INCLUDED
#define LUX_SPECULARANITALIASING_INCLUDED

//  Additional Inputs ------------------------------------------------------------------

//	Surface shader Macro Definitions ---------------------------------------------------

    #if LUX_SPEC_ANITALIASING
        #define LUX_SPECULARANITALIASING \
            fixed3 worldNormalFace = WorldNormalVector(IN, half3(0,0,1)); \
            o.worldNormalFace = worldNormalFace; \
            float roughness = 1.0 - o.Smoothness; \
            float3 deltaU = ddx( worldNormalFace ); \
            float3 deltaV = ddy( worldNormalFace ); \
            float variance = SCREEN_SPACE_VARIANCE * ( dot ( deltaU , deltaU ) + dot ( deltaV , deltaV ) ); \
            float kernelSquaredRoughness = min( 2.0 * variance , SAATHRESHOLD ); \
            float squaredRoughness = saturate( roughness * roughness + kernelSquaredRoughness ); \
            o.Smoothness = 1.0 - sqrt(squaredRoughness); 
    #else
        #define LUX_SPECULARANITALIASING  
    #endif

#endif