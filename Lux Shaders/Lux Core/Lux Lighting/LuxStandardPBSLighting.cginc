#ifndef LUX_STANDARD_PBS_LIGHTING_INCLUDED
#define LUX_STANDARD_PBS_LIGHTING_INCLUDED

#include "UnityShaderVariables.cginc"
#include "UnityStandardConfig.cginc"
#include "UnityLightingCommon.cginc"
#include "UnityGlobalIllumination.cginc"

#include "../Lux Core/Lux Lighting/LuxAreaLights.cginc"
#include "../Lux Core/Lux BRDFs/LuxStandardBRDF.cginc"
#include "../Lux Core/Lux Utils/LuxUtils.cginc"

//-------------------------------------------------------------------------------------
// Default BRDF to use:
#if !defined (UNITY_BRDF_PBS) // allow to explicitly override BRDF in custom shader
	// still add safe net for low shader models, otherwise we might end up with shaders failing to compile
	// the only exception is WebGL in 5.3 - it will be built with shader target 2.0 but we want it to get rid of constraints, as it is effectively desktop
	#if SHADER_TARGET < 30 && !UNITY_53_SPECIFIC_TARGET_WEBGL
		#define UNITY_BRDF_PBS BRDF3_Unity_PBS
	#elif UNITY_PBS_USE_BRDF3
		#define UNITY_BRDF_PBS BRDF3_Unity_PBS
	#elif UNITY_PBS_USE_BRDF2
		#define UNITY_BRDF_PBS BRDF2_Unity_PBS
	#elif UNITY_PBS_USE_BRDF1
		#define UNITY_BRDF_PBS BRDF1_Unity_PBS
	#elif defined(SHADER_TARGET_SURFACE_ANALYSIS)
		// we do preprocess pass during shader analysis and we dont actually care about brdf as we need only inputs/outputs
		#define UNITY_BRDF_PBS BRDF1_Unity_PBS
	#else
		#error something broke in auto-choosing BRDF
	#endif
#endif

//-------------------------------------------------------------------------------------
// BRDF for lights extracted from *indirect* directional lightmaps (baked and realtime).
// Baked directional lightmap with *direct* light uses UNITY_BRDF_PBS.
// For better quality change to BRDF1_Unity_PBS.
// No directional lightmaps in SM2.0.

#if !defined(UNITY_BRDF_PBS_LIGHTMAP_INDIRECT)
	#define UNITY_BRDF_PBS_LIGHTMAP_INDIRECT BRDF2_Unity_PBS
#endif
#if !defined (UNITY_BRDF_GI)
	#define UNITY_BRDF_GI BRDF_Unity_Indirect
#endif

//-------------------------------------------------------------------------------------


inline half3 BRDF_Unity_Indirect (half3 baseColor, half3 specColor, half oneMinusReflectivity, half oneMinusRoughness, half3 normal, half3 viewDir, half occlusion, UnityGI gi)
{
	half3 c = 0;
	#if defined(DIRLIGHTMAP_SEPARATE)
		gi.indirect.diffuse = 0;
		gi.indirect.specular = 0;

		#ifdef LIGHTMAP_ON
			c += UNITY_BRDF_PBS_LIGHTMAP_INDIRECT (baseColor, specColor, oneMinusReflectivity, oneMinusRoughness, normal, viewDir, gi.light2, gi.indirect).rgb * occlusion;
		#endif
		#ifdef DYNAMICLIGHTMAP_ON
			c += UNITY_BRDF_PBS_LIGHTMAP_INDIRECT (baseColor, specColor, oneMinusReflectivity, oneMinusRoughness, normal, viewDir, gi.light3, gi.indirect).rgb * occlusion;
		#endif
	#endif
	return c;
}

// Horizon Occlusion for Normal Mapped Reflections: http://marmosetco.tumblr.com/post/81245981087
float GetHorizonOcclusion(float3 V, float3 normalWS, float3 vertexNormal, float horizonFade)
{
    float3 R = reflect(-V, normalWS);
    float specularOcclusion = saturate(1.0 + horizonFade * dot(R, vertexNormal));
    // smooth it
    return specularOcclusion; // * specularOcclusion;
}

//-------------------------------------------------------------------------------------

// Surface shader output structure to be used with physically
// based shading model.

//-------------------------------------------------------------------------------------
// Specular workflow

struct SurfaceOutputLuxStandardSpecular
{
	fixed3 Albedo;		// diffuse color
	fixed3 Specular;	// specular color
	half Metallic;		// metallic – just to make metallic workflow work properly
	fixed3 Normal;		// tangent space normal, if written
	fixed3 BlurredNormal;
	half3 Emission;
	half Smoothness;	// 0=rough, 1=smooth
	half Occlusion;		// occlusion (default 1)
	fixed Alpha;		// alpha for transparencies

	fixed Shadow;
	float3 worldPosition;	// as it is needed by area lights
	fixed3 worldNormalFace;
	fixed4 SnowWorldNormal; // xyz = normal, w = blend factor
};

inline half4 LightingLuxStandardSpecular (SurfaceOutputLuxStandardSpecular s, half3 viewDir, UnityGI gi)
{
	s.Normal = normalize(s.Normal);
	// energy conservation
	half oneMinusReflectivity;
	s.Albedo = EnergyConservationBetweenDiffuseAndSpecular (s.Albedo, s.Specular, /*out*/ oneMinusReflectivity);

	// shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
	// this is necessary to handle transparency in physically correct way - only diffuse component gets affected by alpha
	half outputAlpha;
	s.Albedo = PreMultiplyAlpha (s.Albedo, s.Alpha, oneMinusReflectivity, /*out*/ outputAlpha);

//	///////////////////////////////////////	
//	Lux 
//	Lambert Lighting
	half specularIntensity = 1.0;
	fixed3 diffuseNormal = s.Normal;
	half3 diffuseLightDir = 0;
	half nl = saturate(dot(s.Normal, gi.light.dir));
	half ndotlDiffuse = nl;

//	///////////////////////////////////////	
//	Lux Area lights
	#if defined(LUX_AREALIGHTS)
		// NOTE: Forward needs other inputs than deferred
		Lux_AreaLight(gi.light, specularIntensity, diffuseLightDir, ndotlDiffuse, gi.light.dir, _LightColor0.a, _WorldSpaceLightPos0.xyz, s.worldPosition, viewDir, s.Normal, diffuseNormal, 1.0 - s.Smoothness);
		nl = saturate(dot(s.Normal, gi.light.dir));
	#else
		diffuseLightDir = gi.light.dir;
		// If area lights are disabled we still have to reduce specular intensity
		#if !defined(DIRECTIONAL) && !defined(DIRECTIONAL_COOKIE)
			specularIntensity = saturate(_LightColor0.a);
		#endif
	#endif
	specularIntensity = (s.Specular.r == 0.0) ? 0.0 : specularIntensity;

//	Horizon Occlusion
	#if defined (UNITY_PASS_FORWARDBASE)
		#if LUX_HORIZON_OCCLUSION
			gi.indirect.specular *= GetHorizonOcclusion(viewDir, s.Normal, s.worldNormalFace, HORIZON_FADE);	
		#endif
	#endif

//	///////////////////////////////////////	
//	Direct lighting uses the Lux BRDF
	half4 c = Lux_BRDF1_PBS(s.Albedo, s.Specular, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir,
		// Deferred expects these inputs to be calculates up front, custom forward does not. So we simply fill the input struct with zeros.
		half3(0, 0, 0), 0, 0, 0, 0,
		nl,
		ndotlDiffuse,
		gi.light, gi.indirect, specularIntensity, s.Shadow);

	c.rgb += UNITY_BRDF_GI (s.Albedo, s.Specular, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, s.Occlusion, gi);
	c.a = outputAlpha;
	return c;
}


inline half4 LightingLuxStandardSpecular_Deferred (SurfaceOutputLuxStandardSpecular s, half3 viewDir, UnityGI gi, out half4 outDiffuseOcclusion, out half4 outSpecSmoothness, out half4 outNormal)
{
	// energy conservation
	half oneMinusReflectivity;
	s.Albedo = EnergyConservationBetweenDiffuseAndSpecular (s.Albedo, s.Specular, /*out*/ oneMinusReflectivity);

//	Horizon Occlusion – legacy reflections
	#if !UNITY_ENABLE_REFLECTION_BUFFERS
		#if LUX_HORIZON_OCCLUSION
			gi.indirect.specular *= GetHorizonOcclusion(viewDir, s.Normal, s.worldNormalFace, HORIZON_FADE);
		#endif
	#endif

	half4 c = UNITY_BRDF_PBS (s.Albedo, s.Specular, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, gi.light, gi.indirect);
	c.rgb += UNITY_BRDF_GI (s.Albedo, s.Specular, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, s.Occlusion, gi);

//	Horizon Occlusion – deferred reflections
	#if UNITY_ENABLE_REFLECTION_BUFFERS
		#if LUX_HORIZON_OCCLUSION
			s.Occlusion *= GetHorizonOcclusion(viewDir, s.Normal, s.worldNormalFace, HORIZON_FADE);
		#endif
	#endif

	outDiffuseOcclusion = half4(s.Albedo, s.Occlusion);
	outSpecSmoothness = half4(s.Specular, s.Smoothness);
	outNormal = half4(s.Normal * 0.5 + 0.5, 1);
	half4 emission = half4(s.Emission + c.rgb, 1);
	return emission;
}

inline void LightingLuxStandardSpecular_GI (
	// using inout here because we might have to combine 2 worldnormals
	inout SurfaceOutputLuxStandardSpecular s,
	UnityGIInput data,
	inout UnityGI gi)
{
	//#if defined(_Snow)  <-- does not get compiled out?
		s.Normal = lerp(s.Normal, s.SnowWorldNormal.xyz, s.SnowWorldNormal.w);
	//#endif
#if defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
    gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal);
#else
    Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.Smoothness, data.worldViewDir, s.Normal, s.Specular);
    gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal, g);
#endif
}


#endif // LUX_STANDARD_PBS_LIGHTING_INCLUDED
