#ifndef LUX_STRUCTS_INCLUDED
#define LUX_STRUCTS_INCLUDED

struct LuxFragment
{

        half3   worldNormal;            // per Pixel world normal
        half3   tangentNormal;          // per Pixel normal in tangent space
        half3   worldNormalFace;        // per Vertex world normal

        half3   eyeVec;                 // view vector in world space
        half3   eyeVecTangent;          // view vector in tangent space

        half4   tangentToWorld[3];      // tangent to world matrix (not used in custom surface shaders)

        float3  worldPos;
        float   viewDepth;              // distance to camera
        float   facingSign;

        fixed4  vertexColor;

        half    height;
        half2   mixmapValue;

        float   scale;

    #if defined (_SNOW) 
        half2   snowAmount;
        //half3   snowNormal;
        //half    normalBlendFactor;
        half    snowHeightFadeState;
        half    uniqueSnowMaskValue;    // Unique snow mask: May come from vertex colors or texture input.

        float2  baseSnowUVs;
    #endif

        half    normalBlendFactor;
        half3   snowNormal;             // As they might be called even if _SNOW is not declared (surface shaders)

        half    puddleMaskValue;        // Must always be declared as parallax writes to it
    
    #if defined (_WETNESS_SIMPLE) || defined (_WETNESS_RIPPLES) || defined (_WETNESS_FLOW) || defined (_WETNESS_FULL) || defined (_SNOW) 
        half2   waterAmount;
        half3   waterNormal;
        half4   waterColor;
 //   #if defined (_WETNESS_FLOW) || defined (_WETNESS_FULL)
 //       half2   waterFlowDir;
 //   #endif
        half2   localWater;
    #endif

        half2   waterFlowDir;

        half    NdotV;

        float4  baseUV;         // original UV from vertex shader
    
        float4  extrudedUV;     // UV after PM / POM / needed even if PM or POM are disabled
    //#if defined (_PARALLAXMAP)
        float2  offset;         // texture coord offset prom PM/POM
        float2  offsetInWS;
        float2  offsetWaterInWS;
        float2  offsetInWS_Surface;
    //#endif

    //#if defined (_WETNESS_SIMPLE) || defined (_WETNESS_RIPPLES) || defined (_WETNESS_FLOW) || defined (_WETNESS_FULL)
        float4  finalUV;    // UV after wetness
    //#endif
    //#if defined (LUX_STANDARD_CORE_INCLUDED)
        fixed4  albedoAlpha;
    //#endif
        float   detailBlendState;
};

// -------------------------------------------------------------------------------------

// Setup custom surface shaders


#if !defined (LUX_STANDARD_CORE_INCLUDED)
    #if !defined(TESSELLATION_ON)
        float4 _MainTex_ST;
    #endif
    float2 _Lux_DetailDistanceFade;
    // when using mix mapping
//    #if defined(GEOM_TYPE_BRANCH_DETAIL)
        /*sampler2D _DetailAlbedoMap;
        sampler2D _DetailNormalMap;
        fixed4 _Color2;
        sampler2D _SpecGlossMap2;*/
        UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailAlbedoMap);
        UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailNormalMap);
        UNITY_DECLARE_TEX2D_NOSAMPLER(_SpecGlossMap2);
        fixed4 _Color2;
        fixed3 _SpecColor2;
        fixed _Glossiness2;
//    #endif

    //  Macro to declare and intialize the LuxFragment structure
    #define LUX_SETUP(mainUV, secondaryUV, viewDir, worldPosition, distToCamera, flowDir, vColor, ObjScale) \
        LuxFragment lux; \
        UNITY_INITIALIZE_OUTPUT(LuxFragment,lux); \
        lux.baseUV = float4(mainUV.xy, secondaryUV); \
        lux.extrudedUV = lux.baseUV; \
        lux.finalUV = lux.baseUV; \
        lux.eyeVecTangent = normalize(viewDir); \
        lux.worldPos = worldPosition; \
        lux.viewDepth = distToCamera; \
        lux.waterFlowDir = flowDir; \
        lux.height = 0.25; \
        lux.vertexColor = vColor; \
        lux.mixmapValue = half2(1,0); \
        lux.detailBlendState = saturate( (_Lux_DetailDistanceFade.x - lux.viewDepth) / _Lux_DetailDistanceFade.y); \
        lux.detailBlendState *= lux.detailBlendState; \
        lux.scale = ObjScale;

    #define LUX_SET_HEIGHT(heightVal) \
        lux.height = heightVal;

#endif

// -------------------------------------------------------------------------------------
#endif