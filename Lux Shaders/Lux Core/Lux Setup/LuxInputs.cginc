#ifndef LUX_INPUTS_INCLUDED
#define LUX_INPUTS_INCLUDED

#include "UnityCG.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityStandardConfig.cginc"
#include "UnityPBSLighting.cginc" // TBD: remove
#include "UnityStandardUtils.cginc"

//---------------------------------------
// Directional lightmaps & Parallax require tangent space too
// Lux: _NORMALMAP always defined so _TANGENT_TO_WORLD is too
#define _TANGENT_TO_WORLD 1 

#if (_DETAIL_MULX2 || _DETAIL_MUL || _DETAIL_ADD || _DETAIL_LERP)
    #define _DETAIL 1
#endif

// From UnityStandardInput --------------------------------------------------------------------------
half4       _Color;
half        _Cutoff;

// Samplers define Texture filtering and wrapping modes

UNITY_DECLARE_TEX2D(_MainTex);
float4      _MainTex_ST;

UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailAlbedoMap);
float4      _DetailAlbedoMap_ST;

UNITY_DECLARE_TEX2D(_BumpMap);
half        _BumpScale;

UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailMask);
UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailNormalMap);
half        _DetailNormalMapScale;

UNITY_DECLARE_TEX2D_NOSAMPLER(_SpecGlossMap);
UNITY_DECLARE_TEX2D_NOSAMPLER(_MetallicGlossMap);
half        _Metallic;
half        _Glossiness;
half        _GlossMapScale;

UNITY_DECLARE_TEX2D_NOSAMPLER(_OcclusionMap);
half        _OcclusionStrength;

sampler2D   _ParallaxMap;
half        _Parallax;
half        _UVSec;

half4       _EmissionColor;
UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionMap);

//-------------------------------------------------------------------------------------

struct LuxVertexInput
{
    float4 vertex   : POSITION;
    half3 normal    : NORMAL;
    float2 uv0      : TEXCOORD0;
    float2 uv1      : TEXCOORD1;
#if defined(DYNAMICLIGHTMAP_ON) || defined(UNITY_PASS_META)
    float2 uv2      : TEXCOORD2;
#endif
    float2 uv3      : TEXCOORD3;
#ifdef _TANGENT_TO_WORLD
    half4 tangent   : TANGENT;
#endif
    // Lux
    fixed4 color    : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

float4 LuxTexCoords(LuxVertexInput v)
{
    float4 texcoord;
    texcoord.xy = TRANSFORM_TEX(v.uv0, _MainTex); // Always source from uv0
    texcoord.zw = TRANSFORM_TEX(((_UVSec == 0) ? v.uv0 : v.uv1), _DetailAlbedoMap);
    return texcoord;
} 

// Additional Inputs ------------------------------------------------------------------

float2 _Lux_DetailDistanceFade;         // x: Distance in which details like POM and water bumps are rendered / y: Detail Fade Range

fixed _DiffuseScatteringEnabled;
fixed3 _DiffuseScatteringCol;
half _DiffuseScatteringBias;
half _DiffuseScatteringContraction;

// Mix Mapping
#if defined(GEOM_TYPE_BRANCH_DETAIL)
    fixed4 _Color2;
    fixed _Glossiness2;
    
    fixed4 _SpecColor2;
    UNITY_DECLARE_TEX2D_NOSAMPLER(_SpecGlossMap2);

    half _Metallic2;
    UNITY_DECLARE_TEX2D_NOSAMPLER(_MetallicGlossMap2);

    fixed3 _DiffuseScatteringCol2;
    half _DiffuseScatteringBias2;
    half _DiffuseScatteringContraction2;
#endif

#if defined(EFFECT_BUMP)
    half _LinearSteps;
    // further Inputs in include!
#endif

//  Translucent Lighting
#if defined (LUX_TRANSLUCENTLIGHTING)
    half4 _Lux_Tanslucent_Settings;
    half _Lux_Translucent_NdotL_Shadowstrength;
    half _TranslucencyStrength;
    half _ScatteringPower;
#endif

// Combined Map
#if defined(GEOM_TYPE_BRANCH)
    UNITY_DECLARE_TEX2D_NOSAMPLER(_CombinedMap);
#endif

// From UnityStandardInput --------------------------------------------------------------------------
half DetailMask(float2 uv)
{
    return UNITY_SAMPLE_TEX2D_SAMPLER (_DetailMask, _MainTex, uv).a;
}

half Alpha(float2 uv)
{
#if defined(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A)
    return _Color.a;
#else
    return UNITY_SAMPLE_TEX2D(_MainTex, uv).a * _Color.a;
#endif
}       

half3 NormalInTangentSpace(float4 texcoords)
{
    half3 normalTangent = UnpackScaleNormal(UNITY_SAMPLE_TEX2D(_BumpMap, texcoords.xy), _BumpScale);
    // SM20: instruction count limitation
    // SM20: no detail normalmaps
#if _DETAIL && !defined(SHADER_API_MOBILE) && (SHADER_TARGET >= 30) 
    half mask = DetailMask(texcoords.xy);
    half3 detailNormalTangent = UnpackScaleNormal(UNITY_SAMPLE_TEX2D_SAMPLER(_DetailNormalMap, _BumpMap, texcoords.zw), _DetailNormalMapScale);
    #if _DETAIL_LERP
        normalTangent = lerp(
            normalTangent,
            detailNormalTangent,
            mask);
    #else               
        normalTangent = lerp(
            normalTangent,
            BlendNormals(normalTangent, detailNormalTangent),
            mask);
    #endif
#endif
    return normalTangent;
}

half Occlusion(float2 uv)
{
#if (SHADER_TARGET < 30)
    // SM20: instruction count limitation
    // SM20: simpler occlusion
    #if defined(_OCCLUSIONMAP)
        return tex2D(_OcclusionMap, uv).g;
    #else
        return 1.0;
    #endif
#else
    #if defined(_OCCLUSIONMAP)
        half occ = UNITY_SAMPLE_TEX2D_SAMPLER(_OcclusionMap, _MainTex, uv).g;
        return LerpOneTo (occ, _OcclusionStrength);
    #else
        return 1.0;
    #endif
#endif
}

half3 Emission(float2 uv)
{
#ifndef _EMISSION
    return 0;
#else
    return UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionMap, _MainTex, uv).rgb * _EmissionColor.rgb;
#endif
}

//-------------------------------------------------------------------------------------
// counterpart for NormalizePerPixelNormal
// skips normalization per-vertex and expects normalization to happen per-pixel
half3 NormalizePerVertexNormal (half3 n)
{
    #if (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        return normalize(n);
    #else
        return n; // will normalize per-pixel instead
    #endif
}

half3 NormalizePerPixelNormal (half3 n)
{
    #if (SHADER_TARGET < 30) || UNITY_STANDARD_SIMPLE
        return n;
    #else
        return normalize(n);
    #endif
}

// Get alpha --------------------------------------------------------------------------
half4 Lux_AlbedoAlpha(float2 uv)
{
    return UNITY_SAMPLE_TEX2D(_MainTex, uv) * _Color;
}

// Diffuse/Spec Energy conservation ---------------------------------------------------
inline half4 Lux_EnergyConservationBetweenDiffuseAndSpecular (half4 albedo, half3 specColor, out half oneMinusReflectivity)
{
    oneMinusReflectivity = 1 - SpecularStrength(specColor);
    #if !UNITY_CONSERVE_ENERGY
        return albedo;
    #elif UNITY_CONSERVE_ENERGY_MONOCHROME
        return half4(albedo.rgb * oneMinusReflectivity, albedo.a);
    #else
        return half4(albedo.rgb * (half3(1,1,1) - specColor), albedo.a);
    #endif
}

inline half4 Lux_DiffuseAndSpecularFromMetallic (half4 albedo, half metallic, out half3 specColor, out half oneMinusReflectivity)
{
    specColor = lerp (unity_ColorSpaceDielectricSpec.rgb, albedo.rgb, metallic);
    oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic);
    //return half4(albedo.rgb * oneMinusReflectivity, albedo.a);
    // We must not do any energy conservation at this stage:
    return half4(albedo);
}

// Get albedo -------------------------------------------------------------------------
// Handles detail blending and mix mapping and return occlusion of detail texture in case mixmapping is ebanabled
half4 Lux_Albedo(half2 mixmapValue, half4 temp_albedo_2ndOcclusion, float4 texcoords)
{
    half3 albedo = temp_albedo_2ndOcclusion.rgb;
#if _DETAIL
    #if (SHADER_TARGET < 30)
        // SM20: instruction count limitation
        // SM20: no detail mask
        half mask = 1; 
    #else
        half mask = DetailMask(texcoords.xy);
    #endif

    // Regular Detail Blending
    #if !defined(GEOM_TYPE_BRANCH_DETAIL)
        half3 detailAlbedo = UNITY_SAMPLE_TEX2D_SAMPLER(_DetailAlbedoMap, _MainTex, texcoords.zw).rgb;
        #if _DETAIL_MULX2
            albedo *= LerpWhiteTo (detailAlbedo * unity_ColorSpaceDouble.rgb, mask);
        #elif _DETAIL_MUL
            albedo *= LerpWhiteTo (detailAlbedo, mask);
        #elif _DETAIL_ADD
            albedo += detailAlbedo * mask;
        #elif _DETAIL_LERP
            albedo = lerp (albedo, detailAlbedo, mask);
        #endif
        temp_albedo_2ndOcclusion = half4(albedo, 1);
    // Mix Mapping
    #else
        half4 detailAlbedo = UNITY_SAMPLE_TEX2D_SAMPLER (_DetailAlbedoMap, _MainTex, texcoords.zw).rgba * _Color2.rgba;
        albedo = lerp(albedo, detailAlbedo.rgb, mixmapValue.y);
        temp_albedo_2ndOcclusion = half4(albedo, detailAlbedo.a);
    #endif
#endif
    return temp_albedo_2ndOcclusion;
}


// Get normals TS ------------------------------------------------------------------------
// Handles detail blending and mix mapping
//#ifdef _NORMALMAP
half3 Lux_NormalInTangentSpace(half2 mixmapValue, float4 texcoords)
{
    half3 normalTangent = UnpackScaleNormal(UNITY_SAMPLE_TEX2D(_BumpMap, texcoords.xy), _BumpScale);
    // SM20: instruction count limitation
    // SM20: no detail normalmaps

    #if _DETAIL && !defined(SHADER_API_MOBILE) && (SHADER_TARGET >= 30) 
    
        // Regular Detail Blending
        #if !defined(GEOM_TYPE_BRANCH_DETAIL)
            half mask = DetailMask(texcoords.xy);
            half3 detailNormalTangent = UnpackScaleNormal(UNITY_SAMPLE_TEX2D_SAMPLER(_DetailNormalMap, _BumpMap, texcoords.zw), _DetailNormalMapScale);
            #if _DETAIL_LERP
                normalTangent = lerp(
                    normalTangent,
                    detailNormalTangent,
                    mask);
            #else               
                normalTangent = lerp(
                    normalTangent,
                    BlendNormals(normalTangent, detailNormalTangent),
                    mask);
            #endif
        // Mix Mapping
        #else
            half3 detailNormalTangent = UnpackScaleNormal(UNITY_SAMPLE_TEX2D_SAMPLER(_DetailNormalMap, _BumpMap, texcoords.zw), _DetailNormalMapScale);
            normalTangent = normalTangent * mixmapValue.x + detailNormalTangent * mixmapValue.y;
        #endif
    #endif

    return normalTangent;
}
//#endif

// Get normals WS ------------------------------------------------------------------------
half3 Lux_PerPixelWorldNormal(half2 mixmapValue, float4 i_tex, half4 tangentToWorld[3])
{
#ifdef _NORMALMAP
    half3 tangent = tangentToWorld[0].xyz;
    half3 binormal = tangentToWorld[1].xyz;
    half3 normal = tangentToWorld[2].xyz;

    #if UNITY_TANGENT_ORTHONORMALIZE
        normal = NormalizePerPixelNormal(normal);

        // ortho-normalize Tangent
        tangent = normalize (tangent - normal * dot(tangent, normal));

        // recalculate Binormal
        half3 newB = cross(normal, tangent);
        binormal = newB * sign (dot (newB, binormal));
    #endif

    half3 normalTangent = Lux_NormalInTangentSpace(mixmapValue, i_tex);
    half3 normalWorld = NormalizePerPixelNormal(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z); // @TODO: see if we can squeeze this normalize on SM2.0 as well
#else
    half3 normalWorld = normalize(tangentToWorld[2].xyz);
#endif
    return normalWorld;
}

// Convert normals to WS ------------------------------------------------------------------------
half3 Lux_ConvertPerPixelWorldNormal(half3 normalTangent, half4 tangentToWorld[3])
{
#ifdef _NORMALMAP
    half3 tangent = tangentToWorld[0].xyz;
    half3 binormal = tangentToWorld[1].xyz;
    half3 normal = tangentToWorld[2].xyz;

    #if UNITY_TANGENT_ORTHONORMALIZE
        normal = NormalizePerPixelNormal(normal);
        // ortho-normalize Tangent
        tangent = normalize (tangent - normal * dot(tangent, normal));
        // recalculate Binormal
        half3 newB = cross(normal, tangent);
        binormal = newB * sign (dot (newB, binormal));
    #endif

    half3 normalWorld = NormalizePerPixelNormal(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z); // @TODO: see if we can squeeze this normalize on SM2.0 as well
#else
    half3 normalWorld = normalize(tangentToWorld[2].xyz);
#endif
    return normalWorld;
}


// Get occlusion ----------------------------------------------------------------------------

// Regular Blending
#if !defined(GEOM_TYPE_BRANCH_DETAIL)

//  Base function
    half Lux_Occlusion(float2 uv)
    {
    #if (SHADER_TARGET < 30)
        // SM20: instruction count limitation
        // SM20: simpler occlusion
        #if defined(_OCCLUSIONMAP)
            half occ = tex2D(_OcclusionMap, uv).g;
            return occ;
        #else
            return 1.0;
        #endif
    #else
        #if defined(_OCCLUSIONMAP)
            half occ = UNITY_SAMPLE_TEX2D_SAMPLER(_OcclusionMap, _MainTex, uv).g;
            occ = LerpOneTo (occ, _OcclusionStrength);
            return occ;
        #else
            return 1.0;
        #endif
    #endif
    }

//  Overload when using combined map
    half Lux_Occlusion( half occ)
    {
    #if (SHADER_TARGET < 30)
        // SM20: instruction count limitation
        // SM20: simpler occlusion
        return occ;
    #else
        occ = LerpOneTo (occ, _OcclusionStrength);
        return occ;
    #endif
    }

// Mix Mapping
#else

//  Base function
    half Lux_Occlusion(half2 mixmapValue, half occlusion2, float2 uv)
    {
    #if (SHADER_TARGET < 30)
        // SM20: instruction count limitation
        // SM20: simpler occlusion
        #if defined(_OCCLUSIONMAP)
            half occ = UNITY_SAMPLE_TEX2D_SAMPLER(_OcclusionMap, _MainTex, uv).g;
            return occ * mixmapValue.x + occlusion2 * mixmapValue.y;
        #else
            return mixmapValue.x + occlusion2 * mixmapValue.y;
        #endif
    #else
        #if defined(_OCCLUSIONMAP)
            half occ = UNITY_SAMPLE_TEX2D_SAMPLER(_OcclusionMap, _MainTex, uv).g;
            occ = LerpOneTo (occ, _OcclusionStrength);
            return occ * mixmapValue.x + occlusion2 * mixmapValue.y;
        #else
            return mixmapValue.x + occlusion2 * mixmapValue.y;
        #endif 
    #endif
    }

//  Overload when using combined map
    half Lux_Occlusion(half2 mixmapValue, half occ, half occlusion2)
    {
    #if (SHADER_TARGET < 30)
        // SM20: instruction count limitation
        // SM20: simpler occlusion
        return occ * mixmapValue.x + occlusion2 * mixmapValue.y;
    #else
        occ = LerpOneTo (occ, _OcclusionStrength);
        return occ * mixmapValue.x + occlusion2 * mixmapValue.y; 
    #endif
    }
#endif

// Get specular gloss ------------------------------------------------------------------------
half4 Lux_SpecularGloss(half2 mixmapValue, float4 uv)
{
    half4 sg;
    half4 sg2;
#ifdef _SPECGLOSSMAP
    sg = UNITY_SAMPLE_TEX2D_SAMPLER(_SpecGlossMap, _MainTex, uv.xy); 
#else
    sg = half4(_SpecColor.rgb, _Glossiness);
#endif

// mixmapping supports a second spec gloss value
#if defined (GEOM_TYPE_BRANCH_DETAIL)
    #if defined (GEOM_TYPE_FROND)
        sg2 = UNITY_SAMPLE_TEX2D_SAMPLER(_SpecGlossMap2, _MainTex, uv.zw);
    #else
        sg2 = half4(_SpecColor2.rgb, _Glossiness2);
    #endif
    sg = sg * mixmapValue.x + sg2 * mixmapValue.y;
#endif
    return sg;
}

// Get metallic gloss ------------------------------------------------------------------------
half2 Lux_MetallicGloss(half2 mixmapValue, float4 uv)
{
    half2 mg;
    half2 mg2;
#ifdef _METALLICGLOSSMAP
    mg = UNITY_SAMPLE_TEX2D_SAMPLER(_MetallicGlossMap, _MainTex, uv.xy).ra;
#else
    mg = half2(_Metallic, _Glossiness);
#endif

// mixmapping supports a second spec gloss value
#if defined (GEOM_TYPE_BRANCH_DETAIL)
    #if defined (GEOM_TYPE_FROND)
        mg2 = UNITY_SAMPLE_TEX2D_SAMPLER(_MetallicGlossMap2, _MainTex, uv.zw).ra;
    #else
        mg2 = half2(_Metallic2, _Glossiness2);
    #endif
    mg = mg * mixmapValue.x + mg2 * mixmapValue.y;
#endif
    return mg;
}


// -------------------------------------------------------------------------------------
#endif