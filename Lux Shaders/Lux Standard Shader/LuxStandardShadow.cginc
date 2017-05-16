#ifndef LUX_STANDARD_SHADOW_INCLUDED
#define LUX_STANDARD_SHADOW_INCLUDED

// NOTE: had to split shadow functions into separate file,
// otherwise compiler gives trouble with LIGHTING_COORDS macro (in UnityStandardCore.cginc)


#include "UnityCG.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityStandardConfig.cginc"

// Do dithering for alpha blended shadows on SM3+/desktop;
// on lesser systems do simple alpha-tested shadows
#if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
    #if !((SHADER_TARGET < 30) || defined (SHADER_API_MOBILE) || defined(SHADER_API_D3D11_9X) || defined (SHADER_API_PSP2) || defined (SHADER_API_PSM))
    #define UNITY_STANDARD_USE_DITHER_MASK 1
    #endif
#endif

// Need to output UVs in shadow caster, since we need to sample texture and do clip/dithering based on it
#if defined(_ALPHATEST_ON) || defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
#define UNITY_STANDARD_USE_SHADOW_UVS 1
#endif

// Has a non-empty shadow caster output struct (it's an error to have empty structs on some platforms...)
#if !defined(V2F_SHADOW_CASTER_NOPOS_IS_EMPTY) || defined(UNITY_STANDARD_USE_SHADOW_UVS)
#define UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT 1
#endif


half4       _Color;
half        _Cutoff;
sampler2D   _MainTex;
float4      _MainTex_ST;
#ifdef UNITY_STANDARD_USE_DITHER_MASK
sampler3D   _DitherMaskLOD;
#endif

// usually defined in include
#if defined (_PARALLAXMAP)
    sampler2D   _ParallaxMap;
    half        _Parallax;
    //half      _ParallaxTiling;
    #if defined(EFFECT_BUMP)
        float2      _Lux_DetailDistanceFade;
        half        _LinearSteps;
    #endif
#endif

half        _UVSec;
sampler2D   _DetailAlbedoMap;
float4      _DetailAlbedoMap_ST;
//sampler2D _DetailMask;


// From Standard Core

//-------------------------------------------------------------------------------------
// counterpart for NormalizePerPixelNormal
// skips normalization per-vertex and expects normalization to happen per-pixel
half3 NormalizePerVertexNormal (half3 n)
{
    #if (SHADER_TARGET < 30)
        return normalize(n);
    #else
        return n; // will normalize per-pixel instead
    #endif
}

half3 NormalizePerPixelNormal (half3 n)
{
    #if (SHADER_TARGET < 30)
        return n;
    #else
        return normalize(n);
    #endif
}

// to make the includes not define the inputs twice
#define LUX_STANDARD_CORE_INCLUDED

#include "UnityStandardUtils.cginc"
#include "../Lux Core/Lux Utils/LuxUtils.cginc"
#include "../Lux Core/Lux Setup/LuxStructs.cginc"
#if defined (_PARALLAXMAP)
    #include "../Lux Core/Lux Features/LuxParallax.cginc"
#endif

struct VertexInput
{
    float4 vertex   : POSITION;
    float3 normal   : NORMAL;
    float2 uv0      : TEXCOORD0;
    //Lux
    float4 tangent  : TANGENT;
    // PM / POM?
    #if defined (_PARALLAXMAP)
        // Mix Mapping?
        #if defined (GEOM_TYPE_BRANCH_DETAIL)
            float2 uv1 : TEXCOORD1;
            // Mixmapping defined by vertex colors?
            #if !defined(GEOM_TYPE_LEAF)
                fixed4 color : COLOR0;
            #endif
        #endif
    #endif
};

#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
struct VertexOutputShadowCaster
{
    V2F_SHADOW_CASTER_NOPOS
    #if defined(UNITY_STANDARD_USE_SHADOW_UVS)
        float2 tex : TEXCOORD1;
        // PM / POM?
        #if defined (_PARALLAXMAP)
            half3 viewDirForParallax : TEXCOORD3;
            float4 posWorld : TEXCOORD4;
            // Mix Mapping?
            #if defined (GEOM_TYPE_BRANCH_DETAIL)
                float2 tex2 : TEXCOORD2;
                // Mixmapping defined by vertex colors?
                #if !defined(GEOM_TYPE_LEAF)
                    fixed4 color : COLOR0;
                #endif
            #endif
        #endif
    #endif
};
#endif


// We have to do these dances of outputting SV_POSITION separately from the vertex shader,
// and inputting VPOS in the pixel shader, since they both map to "POSITION" semantic on
// some platforms, and then things don't go well.


void vertShadowCaster (VertexInput v,
    #ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
    out VertexOutputShadowCaster o,
    #endif
    out float4 opos : SV_POSITION)
{
    TRANSFER_SHADOW_CASTER_NOPOS(o,opos)
    #if defined(UNITY_STANDARD_USE_SHADOW_UVS)
        o.tex = TRANSFORM_TEX(v.uv0, _MainTex);
        // PM/POM?
        #if defined(_PARALLAXMAP) 
            // Fix for dynamic batching
            v.normal = normalize(v.normal);
            v.tangent.xyz = normalize(v.tangent.xyz);
            // Create out own tangent space rotation as otherwise we would normalize normal and tangent twice
            float3 binormal = cross( v.normal, v.tangent.xyz ) * v.tangent.w;
            float3x3 rotation = float3x3( v.tangent.xyz, binormal, v.normal );
            // We have to distinguish between depth and shadow pass (forward rendering) / unity_LightShadowBias is (0,0,0,0) when rendering depth in forward
            half3 viewDirForParallax = ( dot(unity_LightShadowBias, 1.0) == 0.0 ) ? mul(rotation, ObjSpaceViewDir(v.vertex)) : ObjSpaceLightDir(v.vertex);
            o.viewDirForParallax = viewDirForParallax;
            // Mix Mapping?
            #if defined (GEOM_TYPE_BRANCH_DETAIL)
                o.tex2 = TRANSFORM_TEX(((_UVSec == 0.0) ? v.uv0 : v.uv1), _DetailAlbedoMap);
            #endif
            // Mixmapping defined by vertex colors?
            #if defined (GEOM_TYPE_BRANCH_DETAIL) && !defined(GEOM_TYPE_LEAF)
                o.color = v.color;
            #endif
            float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
            o.posWorld.xyz = posWorld.xyz;
            o.posWorld.w = distance(_WorldSpaceCameraPos, posWorld);
        #endif
    #endif
}

half4 fragShadowCaster (
    #ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
    VertexOutputShadowCaster i
    #endif
    #ifdef UNITY_STANDARD_USE_DITHER_MASK
    , UNITY_VPOS_TYPE vpos : VPOS
    #endif
    #if defined (UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT) && defined (EFFECT_HUE_VARIATION)
    ,
    #endif
    #if defined(EFFECT_HUE_VARIATION)
        float facing : VFACE 
    #endif
    ) : SV_Target
{
    #if defined(UNITY_STANDARD_USE_SHADOW_UVS)

        LuxFragment lux;
        UNITY_INITIALIZE_OUTPUT(LuxFragment,lux);

        float3 facingFlip = float3(1.0f, 1.0f, 1.0f);
        //  Lux: VFACE
        #if defined(EFFECT_HUE_VARIATION)
            #if UNITY_VFACE_FLIPPED
                facing = -facing;
            #endif
            #if UNITY_VFACE_AFFECTED_BY_PROJECTION
                facing *= _ProjectionParams.x; // take possible upside down rendering into account
            #endif
            facingFlip = float3( 1.0f, 1.0f, facing);
        #endif

        #if defined (_PARALLAXMAP)

            lux.extrudedUV = float4(i.tex.xy, 0.0f, 0.0f);
            lux.height = 0.25h;
            lux.offset = 0.0h;

            //  //////////////////////////////////////////
            //  Lux: Get the Mix Map Blend value
            //  We do regular detail blending – so just set the mixmapValue accordingly.
            #if !defined (GEOM_TYPE_BRANCH_DETAIL)
                lux.mixmapValue = half2(1.0h, 0.0h);
            //  We use Mix Mapping
            #else
                //  Set uvs for 2nd texture
                lux.extrudedUV.zw = i.tex2.xy;
                #if !defined(GEOM_TYPE_LEAF)
                //  Using Vertex Color Red
                    lux.mixmapValue = half2(i.color.r, 1.0h - i.color.r);
                #else
                //  Using Mask Texture / Only Parallax Mapping needs the Mask, POM samples it itself
                    half mixmap = 0.0h;
                    #if defined (_PARALLAXMAP) && !defined(EFFECT_BUMP)
                        //  Read mixmap and first height in a single lookup
                        half2 heightMix = tex2D (_ParallaxMap, i.tex.xy).gb;
                        mixmap = heightMix.y;
                        lux.height = heightMix.x;
                        #define FIRSTHEIGHT_READ
// not needed here
//                  #else
//                      mixmap = tex2D (_DetailMask, i.tex.xy).g;
                    #endif
                    lux.mixmapValue = half2(mixmap, 1.0h - mixmap);
                #endif
            #endif

        //  //////////////////////////////////////////
        //  Lux: Call custom parallax functions which handle mix mapping and return height and offset
        
        //  because we use inout    
            lux.eyeVecTangent = normalize(i.viewDirForParallax) * facingFlip;
            half puddleMaskDummy = 0.0h;

            #if defined(EFFECT_BUMP)
                float detailBlendState = saturate( (_Lux_DetailDistanceFade.x - i.posWorld.w) / _Lux_DetailDistanceFade.y);
                detailBlendState *= detailBlendState;
                // Mixmapping
                #if defined (GEOM_TYPE_BRANCH_DETAIL)
                    Lux_SimplePOM_MixMap(lux, _LinearSteps, _ParallaxMap); //    (height, offset, i_tex, mixmapValue, puddleMaskDummy, viewDirForParallax, _LinearSteps, detailBlendState, _ParallaxMap);
                // Regular blending
                #else
                    Lux_SimplePOM(lux, _LinearSteps, _ParallaxMap); //           (height, offset, i_tex, puddleMaskDummy, viewDirForParallax, _LinearSteps, detailBlendState, _ParallaxMap);
                #endif
            #else
               Lux_Parallax(lux); //                (height, offset, i_tex, mixmapValue, puddleMaskDummy, viewDirForParallax);
            #endif
        //  Finally tweak the uvs
            i.tex = lux.extrudedUV.xy;
        #endif

        //  /////////////////////

        half alpha = tex2D(_MainTex, i.tex).a * _Color.a;
        #if defined(_ALPHATEST_ON)
            clip (alpha - _Cutoff);
        #endif
        #if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
        
            #if defined(UNITY_STANDARD_USE_DITHER_MASK)
                // Use dither mask for alpha blended shadows, based on pixel position xy
                // and alpha level. Our dither texture is 4x4x16.
                half alphaRef = tex3D(_DitherMaskLOD, float3(vpos.xy*0.25f,alpha*0.9375f)).a;

                    // We have to distinguish between depth and shadow pass (forward rendering) / unity_LightShadowBias is (0,0,0,0) when rendering depth in forward
                //  alphaRef = ( dot(unity_LightShadowBias, 1.0) == 0.0 ) ? 1.0 : alphaRef;

                clip (alphaRef - 0.01h);
            #else
                clip (alpha - _Cutoff);
            #endif
        
        #endif
    #endif // #if defined(UNITY_STANDARD_USE_SHADOW_UVS)

    SHADOW_CASTER_FRAGMENT(i)
}           

#endif // UNITY_STANDARD_SHADOW_INCLUDED
