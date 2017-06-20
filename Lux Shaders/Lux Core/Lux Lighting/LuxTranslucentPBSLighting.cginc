#ifndef LUX_TRANSLUCENT_PBS_LIGHTING_INCLUDED
#define LUX_TRANSLUCENT_PBS_LIGHTING_INCLUDED

//#include "AutoLight.cginc"

#include "UnityShaderVariables.cginc"
#include "UnityStandardConfig.cginc"
#include "UnityLightingCommon.cginc"
#include "UnityGlobalIllumination.cginc"

#include "../Lux Core/Lux Lighting/LuxAreaLights.cginc"
#include "../Lux Core/Lux BRDFs/LuxStandardBRDF.cginc"
#include "../Lux Core/Lux Utils/LuxUtils.cginc"

// keyword is needed by e.g. dynmaic weather but might not be set in case we have a custom surface shader
#ifndef LUX_TRANSLUCENTLIGHTING
	#define LUX_TRANSLUCENTLIGHTING
#endif

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

//-------------------------------------------------------------------------------------

// Surface shader output structure to be used with physically
// based shading model.

//-------------------------------------------------------------------------------------
// Specular workflow

struct SurfaceOutputLuxTranslucentSpecular
{
	fixed3 Albedo;			// diffuse color
	fixed3 Specular;		// specular color
	fixed3 Normal;			// tangent space normal, if written
	half3 Emission;
	half Smoothness;		// 0=rough, 1=smooth
	half Occlusion;			// occlusion (default 1)
	fixed Alpha;			// alpha for transparencies

	fixed Translucency;
	half ScatteringPower;
	float3 worldPosition;	// as it is needed by area lights
	half Shadow;
	fixed Atten;

	fixed4 SnowWorldNormal; // xyz = normal, w = blend factor
	float4 LightmapCoords;
};

half4 _Lux_Tanslucent_Settings; // x: bump distortion, y: power, z: 1.0 - shadow Strength, w: Scale
half _Lux_Translucent_NdotL_Shadowstrength;

#if !defined(LUX_STANDARD_CORE_INCLUDED)
	half _TranslucencyStrength;
	half _ScatteringPower;
#endif

//	//////////////////////////////

inline half4 LightingLuxTranslucentSpecular (SurfaceOutputLuxTranslucentSpecular s, half3 viewDir, UnityGI gi)
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
	#if defined(LUX_AREALIGHTS) && !defined(GEOM_TYPE_FROND)
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

//	Shadow atten
//	
	#if defined (DIRECTIONAL)
	// || defined (DIRECTIONAL_COOKIE)
		half bakedAtten = UnitySampleBakedOcclusion(s.LightmapCoords.xy, s.worldPosition);
		float zDist = dot(_WorldSpaceCameraPos - s.worldPosition, UNITY_MATRIX_V[2].xyz);
		float fadeDist = UnityComputeShadowFadeDistance(s.worldPosition, zDist);
//		s.Shadow = saturate(s.Shadow + UnityComputeShadowFade(fadeDist));
		//s.Shadow = UnityMixRealtimeAndBakedShadows(s.Shadow, bakedAtten, UnityComputeShadowFade(fadeDist));
	#endif
/*	s.Shadow = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
*/

//	///////////////////////////////////////	
//	Real time lighting uses the Lux BRDF
	half4 c = Lux_BRDF1_PBS (s.Albedo, s.Specular, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir,
				// Deferred expects these inputs to be calculates up front, forward does not. So we simply fill the input struct with zeros.
				half3(0, 0, 0), 0, 0, 0, 0,
				nl,
				ndotlDiffuse,
				gi.light, gi.indirect, specularIntensity, s.Shadow);

//	///////////////////////////////////////
//	Translucency
	half3 lightScattering = 0;
	// openGLcore on win does not like == 0.0 so we check against 0.001
	UNITY_BRANCH
	if (s.ScatteringPower < 0.001) {
		half wrap = 0.5;
		half wrappedNdotL = saturate( ( dot(-diffuseNormal, diffuseLightDir) + wrap ) / ( (1 + wrap) * (1 + wrap) ) );

		half VdotL = saturate( dot(viewDir, -diffuseLightDir) );
		half a2 = 0.7 * 0.7;
		half d = ( VdotL * a2 - VdotL ) * VdotL + 1;
		half GGX = (a2 / UNITY_PI) / (d * d);
		lightScattering = wrappedNdotL * GGX * s.Translucency * gi.light.color * lerp(s.Shadow * s.Atten, s.Atten, _Lux_Translucent_NdotL_Shadowstrength);
		c.rgb += lightScattering * s.Albedo * _Lux_Tanslucent_Settings.w;
	}
	UNITY_BRANCH
	if (s.ScatteringPower > 0.001) {
		//	https://colinbarrebrisebois.com/2012/04/09/approximating-translucency-revisited-with-simplified-spherical-gaussian/
		half3 transLightDir = diffuseLightDir + diffuseNormal * _Lux_Tanslucent_Settings.x;
		half transDot = dot( -transLightDir, viewDir );
		transDot = exp2(saturate(transDot) * s.ScatteringPower - s.ScatteringPower) * s.Translucency;
		half shadowFactor = /*saturate(transDot) */ _Lux_Tanslucent_Settings.z * s.Translucency;
		#if defined (DIRECTIONAL)
			lightScattering = transDot * lerp(gi.light.color, _LightColor0.rgb, shadowFactor);
		#elif defined (DIRECTIONAL_COOKIE)
			lightScattering = 0;
		#else
			lightScattering = transDot * gi.light.color * lerp(s.Shadow * s.Atten, s.Atten, shadowFactor);
		#endif
		c.rgb += lightScattering * s.Albedo * _Lux_Tanslucent_Settings.w;
	}


//	Baked Lighting uses Unity's built in BRDF	
	c.rgb += UNITY_BRDF_GI (s.Albedo, s.Specular, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, s.Occlusion, gi);
	c.a = outputAlpha;

	return c;
}

inline void LightingLuxTranslucentSpecular_GI (
	// using inout here because we might have to combine 2 worldnormals here
	inout SurfaceOutputLuxTranslucentSpecular s,
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

#endif
