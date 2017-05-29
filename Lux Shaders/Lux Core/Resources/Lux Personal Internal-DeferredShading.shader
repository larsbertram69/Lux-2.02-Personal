Shader "Hidden/Lux Personal Internal-DeferredShading" {
Properties {
	_LightTexture0 ("", any) = "" {}
	_LightTextureB0 ("", 2D) = "" {}
	_ShadowMapTexture ("", any) = "" {}
	_SrcBlend ("", Float) = 1
	_DstBlend ("", Float) = 1
}
SubShader {

// Pass 1: Lighting pass
//  LDR case - Lighting encoded into a subtractive ARGB8 buffer
//  HDR case - Lighting additively blended into floating point buffer
Pass {
	ZWrite Off
	Blend [_SrcBlend] [_DstBlend]

CGPROGRAM
#pragma target 3.0
#pragma vertex vert_deferred
#pragma fragment frag
#pragma multi_compile_lightpass
#pragma multi_compile ___ UNITY_HDR_ON

#pragma multi_compile __ LUX_AREALIGHTS

#pragma exclude_renderers nomrt

#include "UnityCG.cginc"
#include "Lux Deferred Library.cginc"
#include "UnityPBSLighting.cginc"
#include "UnityStandardUtils.cginc"
#include "UnityStandardBRDF.cginc"

#include "../Lux Lighting/LuxAreaLights.cginc"
#include "../Lux BRDFs/LuxStandardBRDF.cginc"

sampler2D _CameraGBufferTexture0;
sampler2D _CameraGBufferTexture1;
sampler2D _CameraGBufferTexture2;

half4 CalculateLight (unity_v2f_deferred i)
{
	float3 wpos;
	float2 uv;
	float atten, fadeDist, shadow, transfade;
	UnityLight light;
	UNITY_INITIALIZE_OUTPUT(UnityLight, light);
	
//	///////////////////////////////////////	
//	Lux: Light attenuation and shadow attenuation will be returned separately	
	LuxDeferredCalculateLightParams (i, wpos, uv, light.dir, atten, fadeDist, shadow, transfade);

	half4 gbuffer0 = tex2D (_CameraGBufferTexture0, uv);
	half4 gbuffer1 = tex2D (_CameraGBufferTexture1, uv);
	half4 gbuffer2 = tex2D (_CameraGBufferTexture2, uv);

	light.color = _LightColor.rgb * atten;

	half3 baseColor = gbuffer0.rgb;
	half3 specColor = gbuffer1.rgb;
	half oneMinusRoughness = gbuffer1.a;

	float3 eyeVec = normalize(wpos-_WorldSpaceCameraPos);
	half oneMinusReflectivity = 1 - SpecularStrength(specColor.rgb);
	
	UnityIndirect ind;
	UNITY_INITIALIZE_OUTPUT(UnityIndirect, ind);
	ind.diffuse = 0;
	ind.specular = 0;

//	//////////////////////
//	Lux: Set up the needed variables for area lights
	half4 res = 1;
	half3 normalWorld = gbuffer2.rgb * 2 - 1;

	half specularIntensity = 1;
	half3 diffuseNormalWorld = normalWorld;
	half3 diffuseLightDir = light.dir;


//	///////////////////////////////////////	
//	Lux: Important!
	normalWorld = normalize(normalWorld); // To avoid strange lighting artifacts on very smooth surfaces

	half nl = saturate(dot(normalWorld, light.dir));
	half ndotlDiffuse = nl;
	
//	///////////////////////////////////////	
//	Lux: Area lights
	#if defined(LUX_AREALIGHTS)
		// NOTE: Deferred needs other inputs than forward
		float3 lightPos = float3(unity_ObjectToWorld[0][3], unity_ObjectToWorld[1][3], unity_ObjectToWorld[2][3]);
		Lux_AreaLight (light, specularIntensity, diffuseLightDir, ndotlDiffuse, light.dir, _LightColor.a, lightPos, wpos, eyeVec, normalWorld, diffuseNormalWorld, 1.0 - oneMinusRoughness);
		nl = saturate(dot(normalWorld, light.dir));
	#else
		diffuseLightDir = light.dir;
		// If area lights are disabled we still have to reduce specular intensity
		#if !defined(DIRECTIONAL) && !defined(DIRECTIONAL_COOKIE)
			specularIntensity = saturate(_LightColor.a);
		#endif
	#endif

//	///////////////////////////////////////	
//	Lux: Set up inputs shared by all BRDFs
	#define viewDir -eyeVec

	half3 halfDir = Unity_SafeNormalize (light.dir + viewDir);
	half nh = BlinnTerm (normalWorld, halfDir);
	half nv = DotClamped (normalWorld, viewDir);
	half lv = DotClamped (light.dir, viewDir);
	half lh = DotClamped (light.dir, halfDir);

//	/////////////////////
//	Lux: Standard Lighting
	
//	Add support for "real" lambert lighting
	specularIntensity = (specColor.r == 0.0) ? 0.0 : specularIntensity;

	res = Lux_BRDF1_PBS (baseColor, specColor, oneMinusReflectivity, oneMinusRoughness, normalWorld, -eyeVec,
		  halfDir, nh, nv, lv, lh,
		  nl,
		  ndotlDiffuse,
	 	  light, ind,
	 	  specularIntensity,
	 	  shadow);

	return res;
}

#ifdef UNITY_HDR_ON
half4
#else
fixed4
#endif
frag (unity_v2f_deferred i) : SV_Target
{
	half4 c = CalculateLight(i);
	#ifdef UNITY_HDR_ON
	return c;
	#else
	return exp2(-c);
	#endif
}

ENDCG
}


// Pass 2: Final decode pass.
// Used only with HDR off, to decode the logarithmic buffer into the main RT
Pass {
	ZTest Always Cull Off ZWrite Off
	Stencil {
		ref [_StencilNonBackground]
		readmask [_StencilNonBackground]
		// Normally just comp would be sufficient, but there's a bug and only front face stencil state is set (case 583207)
		compback equal
		compfront equal
	}

CGPROGRAM
#pragma target 3.0
#pragma vertex vert
#pragma fragment frag
#pragma exclude_renderers nomrt

sampler2D _LightBuffer;
struct v2f {
	float4 vertex : SV_POSITION;
	float2 texcoord : TEXCOORD0;
};

v2f vert (float4 vertex : POSITION, float2 texcoord : TEXCOORD0)
{
	v2f o;
	o.vertex = UnityObjectToClipPos(vertex);
	o.texcoord = texcoord.xy;
	return o;
}

fixed4 frag (v2f i) : SV_Target
{
	return -log2(tex2D(_LightBuffer, i.texcoord));
}
ENDCG 
}

}
Fallback Off
}
