#ifndef LUX_MIXMAPPING_INCLUDED
#define LUX_MIXMAPPING_INCLUDED

//  Additional Inputs ------------------------------------------------------------------

half _ParallaxTiling;

#ifndef LUX_STANDARD_CORE_INCLUDED
	float _Parallax;
	sampler2D _ParallaxMap;
    float4 _ParallaxMap_ST;
    #if defined (EFFECT_BUMP)
        float _LinearSteps;
    #endif
#endif




//	Surface shader Macro Definitions ---------------------------------------------------

//  POM // Meta Pass always uses simple parallax mapping
#if defined(EFFECT_BUMP) && !defined (UNITY_PASS_META)
    // Mixmapping
    #if defined (GEOM_TYPE_BRANCH_DETAIL)
        #define LUX_PARALLAX \
            Lux_SimplePOM_MixMap (lux.height, lux.offset, lux.extrudedUV, lux.mixmapValue, lux.puddleMaskValue, normalize(lux.eyeVecTangent), _LinearSteps, lux.detailBlendState, _ParallaxMap); \
            lux.finalUV = lux.extrudedUV;
    // Regular blending 
    #else
        #define LUX_PARALLAX \
            Lux_SimplePOM (lux.height, lux.offset, lux.extrudedUV, lux.puddleMaskValue, normalize(lux.eyeVecTangent), _LinearSteps, lux.detailBlendState, _ParallaxMap); \
            lux.finalUV = lux.extrudedUV;

         #define LUX_PARALLAX_SCALED \
            lux.finalUV = lux.finalUV;

    #endif
//  Simple Parallax
#else
    #define LUX_PARALLAX \
    	Lux_Parallax (lux.height, lux.offset, lux.extrudedUV, lux.mixmapValue, lux.puddleMaskValue, lux.eyeVecTangent); \
    	lux.finalUV = lux.extrudedUV;
#endif

#endif