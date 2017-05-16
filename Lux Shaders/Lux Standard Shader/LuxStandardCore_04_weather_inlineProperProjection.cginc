// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Lux Standard Core based on UnityStandard Core Version 5.3.3.f1

// Main work is done in "inline FragmentCommonData FragmentSetup" although i have also made some other changes


// TODO:
// Limit POM
// Limit Wet effects
// Rain Ripples and POM - solved for deferred but why the fuck does it not work in forward?


#ifndef UNITY_STANDARD_CORE_INCLUDED
#define UNITY_STANDARD_CORE_INCLUDED

#include "UnityCG.cginc"
#include "UnityShaderVariables.cginc"
#include "UnityStandardConfig.cginc"
#include "UnityStandardInput.cginc"
#include "UnityPBSLighting.cginc"
#include "UnityStandardUtils.cginc"
#include "UnityStandardBRDF.cginc"

#include "AutoLight.cginc"
#include "LuxAutoLight.cginc"

#include "../Lux Core/Lux Utils/LuxUtils.cginc"
#include "../Lux Core/Lux BRDFs/LuxStandardBRDF.cginc"
#include "../Lux Core/Lux Lighting/LuxAreaLights.cginc"



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

// We include thes files here as the rely on the functions above.
#include "../Lux Core/Lux Features/LuxDynamicWeather.cginc"
#include "../Lux Core/Lux Features/LuxSimplePOM.cginc"
#include "../Lux Core/Lux Utils/LuxInputs.cginc"



//-------------------------------------------------------------------------------------
UnityLight MainLight (half3 normalWorld)
{
	UnityLight l;
	#ifdef LIGHTMAP_OFF
		l.color = _LightColor0.rgb;
		l.dir = _WorldSpaceLightPos0.xyz;
		l.ndotl = LambertTerm (normalWorld, l.dir);
	#else
		// no light specified by the engine
		// analytical light might be extracted from Lightmap data later on in the shader depending on the Lightmap type
		l.color = half3(0.f, 0.f, 0.f);
		l.ndotl  = 0.f;
		l.dir = half3(0.f, 0.f, 0.f);
	#endif
	return l;
}

UnityLight AdditiveLight (half3 normalWorld, half3 lightDir, half atten)
{
	UnityLight l;
	l.color = _LightColor0.rgb;
	l.dir = lightDir;
	#ifndef USING_DIRECTIONAL_LIGHT
		l.dir = NormalizePerPixelNormal(l.dir);
	#endif
	l.ndotl = LambertTerm (normalWorld, l.dir);
	// shadow the light
	l.color *= atten;
	return l;
}

UnityLight DummyLight (half3 normalWorld)
{
	UnityLight l;
	l.color = 0;
	l.dir = half3 (0,1,0);
	l.ndotl = LambertTerm (normalWorld, l.dir);
	return l;
}

UnityIndirect ZeroIndirect ()
{
	UnityIndirect ind;
	ind.diffuse = 0;
	ind.specular = 0;
	return ind;
}

//-------------------------------------------------------------------------------------
// Common fragment setup

// deprecated
half3 WorldNormal(half4 tan2world[3])
{
	return normalize(tan2world[2].xyz);
}

// deprecated
#ifdef _TANGENT_TO_WORLD
	half3x3 ExtractTangentToWorldPerPixel(half4 tan2world[3])
	{
		half3 t = tan2world[0].xyz;
		half3 b = tan2world[1].xyz;
		half3 n = tan2world[2].xyz;

	#if UNITY_TANGENT_ORTHONORMALIZE
		n = NormalizePerPixelNormal(n);

		// ortho-normalize Tangent
		t = normalize (t - n * dot(t, n));

		// recalculate Binormal
		half3 newB = cross(n, t);
		b = newB * sign (dot (newB, b));
	#endif

		return half3x3(t, b, n);
	}
#else
	half3x3 ExtractTangentToWorldPerPixel(half4 tan2world[3])
	{
		return half3x3(0,0,0,0,0,0,0,0,0);
	}
#endif

#ifdef _PARALLAXMAP
	#define IN_VIEWDIR4PARALLAX(i) NormalizePerPixelNormal(half3(i.tangentToWorldAndParallax[0].w,i.tangentToWorldAndParallax[1].w,i.tangentToWorldAndParallax[2].w))
	#define IN_VIEWDIR4PARALLAX_FWDADD(i) NormalizePerPixelNormal(i.viewDirForParallax.xyz)
#else
	#define IN_VIEWDIR4PARALLAX(i) half3(0,0,0)
	#define IN_VIEWDIR4PARALLAX_FWDADD(i) half3(0,0,0)
#endif

// Lux needs worldPos for area Lights and rain ripples.
//#if UNITY_SPECCUBE_BOX_PROJECTION

// Lux i.posWorld is float4!
	#define IN_WORLDPOS(i) i.posWorld.xyz
//#else
//	#define IN_WORLDPOS(i) half3(0,0,0)
//#endif

#define IN_LIGHTDIR_FWDADD(i) half3(i.tangentToWorldAndLightDir[0].w, i.tangentToWorldAndLightDir[1].w, i.tangentToWorldAndLightDir[2].w)

// Lux: distanceToCam, pos, color, facing, scale (fogCoord) added
#define FRAGMENT_SETUP(x) FragmentCommonData x = \
	FragmentSetup(i.tex, i.eyeVec, IN_VIEWDIR4PARALLAX(i), i.tangentToWorldAndParallax, IN_WORLDPOS(i), i.posWorld.w, i.pos, i.color, i.fogCoord, facing);

// Lux: distanceToCam pos, color, worldPos (as needed by area lights), facing, scale (fogCoord) added
#define FRAGMENT_SETUP_FWDADD(x) FragmentCommonData x = \
	FragmentSetup(i.tex, i.eyeVec, IN_VIEWDIR4PARALLAX_FWDADD(i), i.tangentToWorldAndLightDir, IN_WORLDPOS(i), i.posWorld.w, i.pos, i.color, i.fogCoord, facing);

// Lux: occlusion, occlusion2, emission, translucency added
struct FragmentCommonData
{
	half3 diffColor, specColor;
	// Note: oneMinusRoughness & oneMinusReflectivity for optimization purposes, mostly for DX9 SM2.0 level.
	// Most of the math is being done on these (1-x) values, and that saves a few precious ALU slots.
	half oneMinusReflectivity, oneMinusRoughness;
	half3 normalWorld, eyeVec, posWorld;
	half alpha;
	half occlusion;
	half occlusion2;
	half3 emission;

#if UNITY_OPTIMIZE_TEXCUBELOD || UNITY_STANDARD_SIMPLE
	half3 reflUVW;
#endif

#if UNITY_STANDARD_SIMPLE
	half3 tangentSpaceNormal;
#endif

//	Translucent Lighting
#if defined (LOD_FADE_PERCENTAGE)
	half translucency;
#endif
};

#ifndef UNITY_SETUP_BRDF_INPUT
	#define UNITY_SETUP_BRDF_INPUT SpecularSetup
#endif




//	Lux: albedo already sampled
inline FragmentCommonData SpecularSetup (half2 mixmapValue, half3 albedoColor, float4 i_tex)
{

	// Lux: custom SpecGloss function
	half4 specGloss = Lux_SpecularGloss(mixmapValue, i_tex);
	half3 specColor = specGloss.rgb;
	half oneMinusRoughness = specGloss.a;

	half oneMinusReflectivity;
	half4 temp_albedo_2ndOcclusion = half4(albedoColor, 1);

	// Lux: diffColor contains diffColor.rgb: the tweaked diffColor / diffColor.a: occlusion of the detail texture
	half4 diffColor = Lux_EnergyConservationBetweenDiffuseAndSpecular (Lux_Albedo(mixmapValue, temp_albedo_2ndOcclusion, i_tex), specColor, /*out*/ oneMinusReflectivity);
	
	FragmentCommonData o = (FragmentCommonData)0;
	o.diffColor = diffColor.rgb;
	// Lux
	o.occlusion2 = diffColor.a;
	o.specColor = specColor;
	o.oneMinusReflectivity = oneMinusReflectivity;
	o.oneMinusRoughness = oneMinusRoughness;
	return o;
}


//	Lux: albedo already sampled
inline FragmentCommonData MetallicSetup (half2 mixmapValue, half3 albedoColor, float4 i_tex)
{
	half2 metallicGloss = MetallicGloss(i_tex.xy);
	half metallic = metallicGloss.x;
	half oneMinusRoughness = metallicGloss.y;

	half oneMinusReflectivity;
	half3 specColor;
	half4 temp_albedo_2ndOcclusion = half4(albedoColor, 1);

	// Lux: diffColor contains diffColor.rgb: the tweaked diffColor / diffColor.a: occlusion of the detail texture
	half4 diffColor = Lux_DiffuseAndSpecularFromMetallic (Lux_Albedo(mixmapValue, temp_albedo_2ndOcclusion, i_tex), metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

	FragmentCommonData o = (FragmentCommonData)0;
	o.diffColor = diffColor.rgb;
	// Lux
	o.occlusion2 = diffColor.a;
	o.specColor = specColor;
	o.oneMinusReflectivity = oneMinusReflectivity;
	o.oneMinusRoughness = oneMinusRoughness;
	return o;
} 

//inline FragmentCommonData FragmentSetup (float4 i_tex, half3 i_eyeVec, half3 i_viewDirForParallax, half4 tangentToWorld[3], half3x3 i_tanToWorld, half3 i_posWorld, fixed4 i_color, float4 i_fogCoord, float facingSign)
inline FragmentCommonData FragmentSetup (float4 i_tex, half3 i_eyeVec, half3 i_viewDirForParallax, half4 tangentToWorld[3], half3 i_posWorld, float i_distanceToCam, float4 i_pos, fixed4 i_color, float4 i_fogCoord, float facingSign)
{


	half3x3 i_tanToWorld = half3x3(
		tangentToWorld[0].xyz,
		tangentToWorld[1].xyz,
		tangentToWorld[2].xyz
	);


	half height = 0.25;
	float2 offset = 0.0;

	float detailBlendState = saturate( (_Lux_DetailDistanceFade.x - i_distanceToCam  ) / _Lux_DetailDistanceFade.y );

	detailBlendState = saturate( (50- i_distanceToCam  ) / 12 );

detailBlendState = saturate( (_Lux_DetailDistanceFade.x - i_distanceToCam) / _Lux_DetailDistanceFade.y);

//	i_viewDirForParallax = Unity_SafeNormalize(i_viewDirForParallax);

float2 test = i_tex.xy;
float4 orig_i_tex = i_tex;

//	Lux: Get the Mix Map Blend value
	#if !defined(GEOM_TYPE_LEAF)
	//	Using Vertex Color Red
		half2 mixmapValue = half2(i_color.r, 1.0 - i_color.r);
		float2 blendValue = mixmapValue;
	#else
	//	Using Mask Texture / Only Parallax Mapping needs the Mask, POM samples it itself
		half mixmap = 0;
		#if defined (_PARALLAXMAP) && !defined(EFFECT_BUMP)
			// Read mixmap and first height in a single lookup
			half2 heightMix = tex2D (_ParallaxMap, i_tex.xy).gb;
			mixmap = heightMix.y;
			height = heightMix.x;
			#define FIRSTHEIGHT_READ
		#else
			mixmap = tex2D (_DetailMask, i_tex.xy).g;
		#endif
		half2 mixmapValue = half2(mixmap, 1.0 - mixmap);
	#endif

//	Lux: Call custom parallax functions which handle mix mapping and return height and offset
	#if defined (_PARALLAXMAP)
		#if defined(EFFECT_BUMP)
			Lux_ParallaxPOM (height, offset, i_tex, mixmapValue, i_viewDirForParallax, _POM_LinearSteps, detailBlendState);
		#else
			Lux_Parallax (height, offset, i_tex, mixmapValue, i_viewDirForParallax);
		#endif
	#endif

//	Lux: We have to calculate the worldNormal up front
//	Lux: Custom normal function which handles mix mapping
	half3 normalTangent = Lux_NormalInTangentSpace(mixmapValue, i_tex);
//	Calculate a smoothed Worldnormal for snow
	half3 smoothedNormalTangent = normalize(normalTangent + half3(0,0,6) * _Lux_SnowAmount) ; // * _Lux_SnowAmount * _Lux_SnowAmount * tangentToWorld[2].y);
	float3 worldNormal = Lux_ConvertPerPixelWorldNormal (smoothedNormalTangent, tangentToWorld) * facingSign;

//	Before calling wetness we have to store the unrefracted uvs
	float2 i_tex_unrefracted = i_tex.xy;

//	/////////////////////////////////////////
//	Dynamic Weather
	half wetnessMask = 0; 
	half3 flowNormal = 0;
	half3 rippleNormal = half3(0,0,1);
	half2 wetFactor = 0;
	half3 wetnormal = half3(0,0,1);
	half snowAmount = 0;


	// In order to automatically scale the water bump maps we need "objectScale_TextureScaleRatio"
	// i_fogCoord.ww contains the object's scale calculated in the vertex shader (only uniformly scaled objects are handled properly)
	float2 objectScale_TextureScaleRatio = i_fogCoord.ww / _MainTex_ST.xy;
	float2 objectScale = i_fogCoord.ww / _MainTex_ST.xy;

	#if defined (_WETNESS_SIMPLE) || defined (_WETNESS_RIPPLES) || defined (_WETNESS_FLOW) || defined (_WETNESS_FULL)

		half4 testpuddle = tex2D(_Lux_SnowMask, (i_tex.xy * _SnowMaskTiling ));


		//	offset from parallax or pom multiplied by (scale of object / Main texture tiling)
		//	-offset * (i_fogCoord.ww / _MainTex_ST.xy) * 10 // Offset is in tangent space!!!!!
		//	so we project the texture offset from tangent to world space as the water ripples are sampled in world space
		half2 offsetInWS = mul( half3(offset.xy * objectScale_TextureScaleRatio, 0), i_tanToWorld).xz * 10;

half2 snowMask;

		Lux_DynamicWeather (
			// OUT
			snowMask, 					// half2 / x: actual snow mask / y: mask for melted snow equals water
			snowAmount,
			wetnessMask,
			rippleNormal,
			flowNormal,
			i_tex,						// IN: the offsetted texture coords / Out the refreacted/none refracted texture coords based on wetness and snow

			// IN
			i_tex_unrefracted,			// 
			i_posWorld,					// world position
			height,						// sampled height from Parallax or POM
			offsetInWS,					// offset in world space for the uvs (from parallax or pom)
			objectScale_TextureScaleRatio,	//

			

			tangentToWorld[2].xyz, 		// world normal of face
			worldNormal,				// world normal of pixel

			// Water
			testpuddle.x,				// puddle mask or distrbution
			i_fogCoord.yz,				// water folw direction from vertex shader

			// Snow
		//	snowHeightFadeState
			_Lux_SnowMask,				// Texture wich contain the snow masks

			detailBlendState			// 



		);


/*

		wetFactor = ComputeWaterAccumulation(								// returns x: water in cracks and puddles / y: water in puddles only
			height.x,														// sampled height
			testpuddle.a, //0, //i_color.r,									// puddle mask - taken from vertex color
			tangentToWorld[2].y 											// worldNormal up of face
		);

//wetFactor = 1;



/////////////////////////

	

	if (detailBlendState > 0.001 ) {

		

		rippleNormal = AddWaterRipples (									// returns the animated ripple normal
			wetFactor,														// overall wetness / wetness in puddles
			i_posWorld,														// world position which i taken for the uvs
		//	offset from parallax or pom multiplied by (scale of object / Main texture tiling)
		//	-offset * (i_fogCoord.ww / _MainTex_ST.xy) * 10 // Offset is in tangent space!!!!!
		//	so we project the texture offset from tangent to world space as the water ripples are sampled in world space
			mul(half3(offset.xy * objectScale_TextureScaleRatio , 0), i_tanToWorld).xz * 10
		);
	

		//	Debug
		//  rippleNormal = tex2D(_Lux_RainRipples, (i_posWorld.xz - offset * (i_fogCoord.ww / _MainTex_ST.xy)) * _Lux_RippleTiling  );
		//  rippleNormal *= wetFactor.x;

			float2 flowdir = mul( float3(0,1,0), i_tanToWorld).xz;

		flowNormal = AddWaterFlow (
			i_tex_unrefracted * objectScale_TextureScaleRatio,
			i_fogCoord.yz,							// flowdir,		// tangentToWorld[2].xy,
			tangentToWorld[2].xyz,					// Worldnormal of face
			wetFactor.x,
			objectScale_TextureScaleRatio
		);

	wetnormal = lerp(wetnormal, normalize(half3(rippleNormal.xy + flowNormal.xy, rippleNormal.z * flowNormal.z)), detailBlendState);
}

//	/////////////////////////////////////////
//	Snowdistribution relies on the unrefracted normal and the original uvs

// TODO: conditional texture reads of snow masks!

 	float snowHeightFadeState = saturate((i_posWorld.y - _Lux_SnowHeightParams.x) / _Lux_SnowHeightParams.y);
	snowHeightFadeState = sqrt(snowHeightFadeState);

	half2 snowAmount_temp = ComputeSnowAccumulation (
		//i_tex.xy, _Lux_SnowMask, height, o.occlusion, 1.0, worldNormal
		//i_tex.xy, _Lux_SnowMask, height, 1.0 - worldNormal.y * worldNormal.y * height , 1.0, worldNormal
		i_tex_unrefracted,													// 
		_Lux_SnowMask,														// global snow mask texture
		height,																// height if the pixel from pm or pom
		saturate(1.0 - (worldNormal.y * worldNormal.y) * 0.5 * height), 	// some kind of ao
		worldNormal,														// world normal of pixel
		tangentToWorld[2].xyz,												// world normal up of face
		i_posWorld,
		_SnowSlopeDamp,														// slope damp
		i_color.r, 															// unique snow mask – here taken from vertex colors
		snowHeightFadeState 												// blend state according to worldpos.y

//orig_i_tex, test, _Lux_SnowMask, height, saturate(1.0 - (worldNormal.y * worldNormal.y) * 0.5 * height) , 1.0, worldNormal, tangentToWorld[2].xyz

	);

	snowAmount = snowAmount_temp.x;

	// Add melting snow to wetnessMask
	wetnessMask = saturate( wetFactor.x + sqrt( saturate(2.25 * snowAmount_temp.y * ( _Lux_SnowMelt.y )) * sqrt(_Lux_SnowAmount)) ); //* saturate(  (_Lux_SnowMelt.y - (height + snowAmount.y * (1-_Lux_SnowMelt.y)) * 0.5  ) );
	//	Add Refraction from wetness but mask them on snow

// siehe oben!!!!!!! wetnormal ///// factor neu: refraction für ripples sieht besser aus

i_tex = i_tex + (rippleNormal.xyxy * _Lux_RippleDistortion + flowNormal.xyxy) * float4(1, 1, _DetailAlbedoMap_ST.xy / _MainTex_ST.xy) * wetnessMask * (1 - saturate(2 * snowAmount.x)) * (1 - _Lux_WaterToSnow.x);

*/

#endif
/// END Dynamic Weather Part 1
//	//////////////////////////////////////////

//	Lux: Sample main albedo and alpha in one single texture lookup
	half4 AlbedoAlpha = Lux_AlbedoAlpha(i_tex.xy); 
	#if defined(_ALPHATEST_ON)
		clip (AlbedoAlpha.a - _Cutoff);
	#endif

	half3 diffuseScatter = 0;

//	Lux: Pass the already sampled albedo to the Setup Functions
	FragmentCommonData o = UNITY_SETUP_BRDF_INPUT (mixmapValue, AlbedoAlpha.rgb, i_tex);

// Combined Map
	#if defined(GEOM_TYPE_BRANCH)
		half4 combined = tex2D(_CombinedMap, i_tex.xy);
	#endif	

//	Lux: Calculate occlusion and emission in FragmentSetup to keep things together and simple
	#if !defined(LUX_FORWARDADD_PASS)
		// Lux Mix Mapping: Combine 1st and 2nd occlusion
		#if defined (GEOM_TYPE_BRANCH_DETAIL)
			// Do we have a combined map?
			#if defined(GEOM_TYPE_BRANCH)
				o.occlusion = Lux_Occlusion(mixmapValue, o.occlusion2, i_tex.xy);
			#else
				o.occlusion = Lux_Occlusion(mixmapValue, o.occlusion2, i_tex.xy);
			#endif
		#else
		// Regular detail blending does not have a 2nd occlusion map
			// Do we have a combined map?
			#if defined(GEOM_TYPE_BRANCH)
				o.occlusion = Lux_Occlusion(combined.g);
			#else
				o.occlusion = Occlusion(i_tex.xy);
			#endif
		#endif
		// Tweak occlusion and emission according to snowAmount
		o.occlusion = lerp(o.occlusion, 1, snowAmount.x);
		o.emission = Emission(i_tex.xy) * (1.125 - snowAmount.x);
	#endif

//	Lux: Lighting Features
//	Translucent Lighting
	#if defined (LOD_FADE_PERCENTAGE)
		// Combined maps?
		#if defined(GEOM_TYPE_BRANCH)
			o.translucency = combined.b;
		#else
			o.translucency = _TranslucencyStrength;
		#endif
		o.translucency *= (1.5 - snowAmount.x);
	#endif



//	Lux we have to resample the combined and blended normals using the refracted uvs
	normalTangent = Lux_NormalInTangentSpace(mixmapValue, i_tex);

	half4 waterColor = 0;

//	#if defined (_WETNESS_SIMPLE) || defined (_WETNESS_RIPPLES) || defined (_WETNESS_FLOW) || defined (_WETNESS_FULL) || defined (_SNOW)
		ApplySnowAndWetness (o.diffColor, normalTangent, o.oneMinusRoughness, o.specColor, o.oneMinusReflectivity, snowAmount, wetnormal, wetnessMask, waterColor, i_tex_unrefracted, orig_i_tex, objectScale, detailBlendState ); //i_tex_unrefracted);

	//	EnergyConservation after adding snow and water / NOTE: Here we use the built in function
		o.diffColor = EnergyConservationBetweenDiffuseAndSpecular ( o.diffColor, o.specColor, /*out*/ o.oneMinusReflectivity);
//	#endif

//	Now we can compute the final worldNormal
	worldNormal = Lux_ConvertPerPixelWorldNormal(normalTangent, tangentToWorld) * facingSign;
	float3 worldEyeVec = NormalizePerPixelNormal(i_eyeVec);
// has to move!!!!!!!!!!!!!!!!!!!!!!!!!!!
//	Lux: Diffuse Scattering
//	half3 diffuseScatter = 0;


	half NdotV = dot(worldNormal, worldEyeVec);

	// Mix Mapping
	#if defined(GEOM_TYPE_BRANCH_DETAIL)
		if(_DiffuseScatteringEnabled > 0.0) {
			fixed3 scatterColor = lerp(_DiffuseScatteringCol, _DiffuseScatteringCol2, mixmapValue.y);
			half2 scatterBias_Contraction = lerp( half2(_DiffuseScatteringBias, _DiffuseScatteringContraction), half2(_DiffuseScatteringBias2, _DiffuseScatteringContraction2), mixmapValue.y);
			diffuseScatter = scatterColor * (exp2(-(NdotV * NdotV * scatterBias_Contraction.y)) + scatterBias_Contraction.x);
			}
	#else
	// Regular Detail Blending
		if (_DiffuseScatteringEnabled > 0.0) {
			diffuseScatter = _DiffuseScatteringCol * (exp2(-(NdotV * NdotV * _DiffuseScatteringContraction)) + _DiffuseScatteringBias);
		}
	#endif

	// snow scatter
	half3 snowScatter = _Lux_SnowScatterColor * (exp2(-(NdotV * NdotV * _DiffuseScatteringContraction)) + _DiffuseScatteringBias);

	diffuseScatter = lerp(diffuseScatter, snowScatter, snowAmount );

	o.diffColor += diffuseScatter;

//	End Scattering


	o.normalWorld = worldNormal;
	o.eyeVec = worldEyeVec;
	o.posWorld = i_posWorld;

	// NOTE: shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
	o.diffColor = PreMultiplyAlpha (o.diffColor, AlbedoAlpha.a, o.oneMinusReflectivity, /*out*/ o.alpha);


//o.diffColor *= wetnessMask * half3(1,0,0); //half3(wetnormal.xy * 8, wetnormal.z); //height; //detailBlendState; //; //half3(wetnormal.xy * 8, wetnormal.z); // * fadeOutWaterBumps; //.xxx; abs(offset.xyx) * 10; // i_pos.w; //

// Debug
if (_DiffuseScatteringEnabled > 0.0) {
//	o.diffColor = _DiffuseScatteringCol; //half3(1,1,0); 
}

	return o;
}

inline UnityGI FragmentGI (FragmentCommonData s, half occlusion, half4 i_ambientOrLightmapUV, half atten, UnityLight light, bool reflections)
{
	UnityGIInput d;
	d.light = light;
	d.worldPos = s.posWorld;
	d.worldViewDir = -s.eyeVec;
	d.atten = atten;
	#if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
		d.ambient = 0;
		d.lightmapUV = i_ambientOrLightmapUV;
	#else
		d.ambient = i_ambientOrLightmapUV.rgb;
		d.lightmapUV = 0;
	#endif
	d.boxMax[0] = unity_SpecCube0_BoxMax;
	d.boxMin[0] = unity_SpecCube0_BoxMin;
	d.probePosition[0] = unity_SpecCube0_ProbePosition;
	d.probeHDR[0] = unity_SpecCube0_HDR;

	d.boxMax[1] = unity_SpecCube1_BoxMax;
	d.boxMin[1] = unity_SpecCube1_BoxMin;
	d.probePosition[1] = unity_SpecCube1_ProbePosition;
	d.probeHDR[1] = unity_SpecCube1_HDR;

	if(reflections)
	{
		Unity_GlossyEnvironmentData g;
		g.roughness		= 1 - s.oneMinusRoughness;
	#if UNITY_OPTIMIZE_TEXCUBELOD || UNITY_STANDARD_SIMPLE
		g.reflUVW 		= s.reflUVW;
	#else
		g.reflUVW		= reflect(s.eyeVec, s.normalWorld);
	#endif

		return UnityGlobalIllumination (d, occlusion, s.normalWorld, g);
	}
	else
	{
		return UnityGlobalIllumination (d, occlusion, s.normalWorld);
	}
}

inline UnityGI FragmentGI (FragmentCommonData s, half occlusion, half4 i_ambientOrLightmapUV, half atten, UnityLight light)
{
	return FragmentGI(s, occlusion, i_ambientOrLightmapUV, atten, light, true);
}


//-------------------------------------------------------------------------------------
half4 OutputForward (half4 output, half alphaFromSurface)
{
	#if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
		output.a = alphaFromSurface;
	#else
		UNITY_OPAQUE_ALPHA(output.a);
	#endif
	return output;
}

inline half4 VertexGIForward(LuxVertexInput v, float3 posWorld, half3 normalWorld)
{
	half4 ambientOrLightmapUV = 0;
	// Static lightmaps
	#ifndef LIGHTMAP_OFF
		ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		ambientOrLightmapUV.zw = 0;
	// Sample light probe for Dynamic objects only (no static or dynamic lightmaps)
	#elif UNITY_SHOULD_SAMPLE_SH
		#ifdef VERTEXLIGHT_ON
			// Approximated illumination from non-important point lights
			ambientOrLightmapUV.rgb = Shade4PointLights (
				unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
				unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
				unity_4LightAtten0, posWorld, normalWorld);
		#endif

		ambientOrLightmapUV.rgb = ShadeSHPerVertex (normalWorld, ambientOrLightmapUV.rgb);		
	#endif

	#ifdef DYNAMICLIGHTMAP_ON
		ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	#endif

	return ambientOrLightmapUV;
}

// ------------------------------------------------------------------
//  Base forward pass (directional light, emission, lightmaps, ...)

struct VertexOutputForwardBase
{
	float4 pos							: SV_POSITION;
	float4 tex							: TEXCOORD0;
	half3 eyeVec 						: TEXCOORD1;
	half4 tangentToWorldAndParallax[3]	: TEXCOORD2;	// [3x3:tangentToWorld | 1x3:viewDirForParallax]
	half4 ambientOrLightmapUV			: TEXCOORD5;	// SH or Lightmap UV
	SHADOW_COORDS(6)

// Lux: Simple waste! Fog coords are only a float! So we redefine it using float4	
	#undef UNITY_FOG_COORDS
	#define UNITY_FOG_COORDS(idx) float4 fogCoord : TEXCOORD##idx;

	UNITY_FOG_COORDS(7)

	// next ones would not fit into SM2.0 limits, but they are always for SM3.0+
// Lux
//	#if UNITY_SPECCUBE_BOX_PROJECTION
		float4 posWorld					: TEXCOORD8;
//	#endif
	#if UNITY_OPTIMIZE_TEXCUBELOD
		//#if UNITY_SPECCUBE_BOX_PROJECTION
			half3 reflUVW				: TEXCOORD9;
		//#else
		//	half3 reflUVW				: TEXCOORD8;
		//#endif
	#endif
	//Lux
	fixed4 color 						: COLOR0;
};

VertexOutputForwardBase vertForwardBase (LuxVertexInput v)
{
	// Fix for dynamic batching. Credits: Tomasz Stobierski 
	v.normal = normalize(v.normal);
	#ifdef _TANGENT_TO_WORLD
		v.tangent.xyz = normalize(v.tangent.xyz);
	#endif

	VertexOutputForwardBase o;
	UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBase, o);

	float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
//	#if UNITY_SPECCUBE_BOX_PROJECTION
		o.posWorld.xyz = posWorld.xyz;
		o.posWorld.w = distance(_WorldSpaceCameraPos, posWorld);
//	#endif
	o.pos = UnityObjectToClipPos(v.vertex);
	o.tex = LuxTexCoords(v);
	o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
	float3 normalWorld = UnityObjectToWorldNormal(v.normal);
	#ifdef _TANGENT_TO_WORLD
		float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

		float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
		o.tangentToWorldAndParallax[0].xyz = tangentToWorld[0];
		o.tangentToWorldAndParallax[1].xyz = tangentToWorld[1];
		o.tangentToWorldAndParallax[2].xyz = tangentToWorld[2];
	#else
		o.tangentToWorldAndParallax[0].xyz = 0;
		o.tangentToWorldAndParallax[1].xyz = 0;
		o.tangentToWorldAndParallax[2].xyz = normalWorld;
	#endif
	//We need this for shadow receving
	TRANSFER_SHADOW(o);

	o.ambientOrLightmapUV = VertexGIForward(v, posWorld, normalWorld);
	
	#ifdef _PARALLAXMAP
		TANGENT_SPACE_ROTATION;
		half3 viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
		o.tangentToWorldAndParallax[0].w = viewDirForParallax.x;
		o.tangentToWorldAndParallax[1].w = viewDirForParallax.y;
		o.tangentToWorldAndParallax[2].w = viewDirForParallax.z;
	#endif

	#if UNITY_OPTIMIZE_TEXCUBELOD
		o.reflUVW 		= reflect(o.eyeVec, normalWorld);
	#endif

	UNITY_TRANSFER_FOG(o,o.pos);
//Lux: Above writes to the whole o.fogCoord variable. So any other values should be added afterwards.
	// Store Flow Direction
	o.fogCoord.yzw = 0;
	#if defined (_TANGENT_TO_WORLD)
		#if !defined (_PARALLAXMAP)
			TANGENT_SPACE_ROTATION;
		#endif
		o.fogCoord.yz = (mul(rotation, mul(unity_WorldToObject, float4(0,1,0,0)).xyz)).xy;
	#endif
	// Get and store object scale / Needed by water ripples to match POM offset
	float4 scaleX = mul(unity_ObjectToWorld, float4(1.0, 0.0, 0.0, 0.0));
	o.fogCoord.w = length(scaleX);

	// Lux
	o.color = v.color;

	return o;
}

half4 fragForwardBase (VertexOutputForwardBase i 
	#if defined(EFFECT_HUE_VARIATION)
	, float facing : VFACE
	#endif
	) : SV_Target
{

//	VFACE
	#if defined(EFFECT_HUE_VARIATION)
		#if UNITY_VFACE_FLIPPED
			facing = -facing;
		#endif
		#if UNITY_VFACE_AFFECTED_BY_PROJECTION
			facing *= _ProjectionParams.x; // take possible upside down rendering into account
	  	#endif
	  	//s.normalWorld *= facing;
	#else
		float facing = 1;
	#endif

	FRAGMENT_SETUP(s)

	#if UNITY_OPTIMIZE_TEXCUBELOD
		s.reflUVW		= i.reflUVW;
	#endif

//

	UnityLight mainLight = MainLight (s.normalWorld);
	// No shadows
	half atten = 1; //SHADOW_ATTENUATION(i);
	
	// Lux: occlusion and emission are calculated in FRAGMENT_SETUP
	half occlusion = s.occlusion;
	half3 emission = s.emission;
	
	UnityGI gi = FragmentGI (s, occlusion, i.ambientOrLightmapUV, atten, mainLight);

	//half4 c = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);
//	half4 c = AFS_BRDF1_FORWARD_Unity_PBS(s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect, _LightColor0.a);

//	///////////////////////////////////////	
//	Lux 
	half specularIntensity = 1.0f;
	fixed3 diffuseNormal = s.normalWorld;
	half3 diffuseLightDir = 0;
	half ndotlDiffuse = 0;

//	///////////////////////////////////////	
//	Lux Area lights
	#if defined(LUX_AREALIGHTS)
		// NOTE: Forward needs other inputs than deferred
		Lux_AreaLight (gi.light, specularIntensity, diffuseLightDir, ndotlDiffuse, gi.light.dir, _LightColor0.a, _WorldSpaceLightPos0.xyz, s.posWorld, -s.eyeVec, s.normalWorld, diffuseNormal, 1.0 - s.oneMinusRoughness);
	#else
		diffuseLightDir = gi.light.dir;
		ndotlDiffuse = gi.light.ndotl;
		// If area lights are disabled we still have to reduce specular intensity
		#if !defined(DIRECTIONAL) && !defined(DIRECTIONAL_COOKIE)
			specularIntensity = saturate(_LightColor0.a);
		#endif
	#endif
//	///////////////////////////////////////

//	Get the shadows
	half shadow = SHADOW_ATTENUATION(i);

	half3 viewDir = -s.eyeVec;

//	///////////////////////////////////////	
//	Translucent Lighting

	#if defined (LOD_FADE_PERCENTAGE)
		half3 transLightDir = gi.light.dir + diffuseNormal * _Lux_Tanslucent_Settings.x;
		// half transDot = pow (saturate ( dot ( -transLightDir, viewDir ) * s.translucency ), _Lux_Tanslucent_Settings.y);
		// get rid of the pow
		// https://seblagarde.wordpress.com/2012/06/03/spherical-gaussien-approximation-for-blinn-phong-phong-and-fresnel/
		half transDot = dot( -transLightDir, viewDir );
		transDot = exp2( -_Lux_Tanslucent_Settings.y * (1.0 - transDot)) * s.translucency;
		half shadowFactor = saturate(transDot) * _Lux_Tanslucent_Settings.z * s.translucency;
		half3 lightScattering = transDot * gi.light.color * lerp(shadow, 1, shadowFactor);
	#endif

	gi.light.color *= shadow;

//	///////////////////////////////////////	
//	Direct lighting uses the Lux BRDF

	half3 halfDir = normalize (gi.light.dir + viewDir);
	half	nh = BlinnTerm (s.normalWorld, halfDir);
	half	nv = DotClamped (s.normalWorld, viewDir);
	half	lv = DotClamped (gi.light.dir, viewDir);
	half	lh = DotClamped (gi.light.dir, halfDir);

	half4 c = Lux_BRDF1_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, viewDir,
				// Deferred expects these inputs to be calculates up front, forward does not. So we have to fill the input struct.
				halfDir, nh, nv, lv, lh,
				ndotlDiffuse,
				gi.light, gi.indirect, specularIntensity);

//	///////////////////////////////////////
//	Indirect and baked lighting uses the Lux BRDF
	c.rgb += UNITY_BRDF_GI (s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, occlusion, gi);

//	Translucent Lighting
	#if defined (LOD_FADE_PERCENTAGE)
		c.rgb += lightScattering * s.diffColor * 4.0;
	#endif


//	Lux: occlusion and emission are calculated in FRAGMENT_SETUP
	c.rgb += s.emission;

	UNITY_APPLY_FOG(i.fogCoord, c.rgb);
	return OutputForward (c, s.alpha);
}

// ------------------------------------------------------------------
//  Additive forward pass (one light per pass)
struct VertexOutputForwardAdd
{
	float4 pos							: SV_POSITION;
	float4 tex							: TEXCOORD0;
	half3 eyeVec 						: TEXCOORD1;
	half4 tangentToWorldAndLightDir[3]	: TEXCOORD2;	// [3x3:tangentToWorld | 1x3:lightDir]
	LIGHTING_COORDS(5,6)
// Lux: Simple waste! Fog coords are only a float! So we redefine it using float4	
	#undef UNITY_FOG_COORDS
	#define UNITY_FOG_COORDS(idx) float4 fogCoord : TEXCOORD##idx;
	UNITY_FOG_COORDS(7)

	// next ones would not fit into SM2.0 limits, but they are always for SM3.0+
	#if defined(_PARALLAXMAP)
		half3 viewDirForParallax		: TEXCOORD8;
	#endif
	// Lux:
	float4 posWorld						: TEXCOORD9;	// xyz: posWorld / w. Distance to camera
	//Lux
	fixed4 color 						: COLOR0;
};

VertexOutputForwardAdd vertForwardAdd (LuxVertexInput v)
{
	// Fix for dynamic batching. Credits: Tomasz Stobierski 
	v.normal = normalize(v.normal);
	#ifdef _TANGENT_TO_WORLD
		v.tangent.xyz = normalize(v.tangent.xyz);
	#endif

	VertexOutputForwardAdd o;
	UNITY_INITIALIZE_OUTPUT(VertexOutputForwardAdd, o);

	float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
	// Lux:
	o.posWorld = posWorld;
	o.posWorld.w = distance(_WorldSpaceCameraPos, posWorld);

	o.pos = UnityObjectToClipPos(v.vertex);
	o.tex = LuxTexCoords(v);
	o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
	float3 normalWorld = UnityObjectToWorldNormal(v.normal);
	#ifdef _TANGENT_TO_WORLD
		float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

		float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
		o.tangentToWorldAndLightDir[0].xyz = tangentToWorld[0];
		o.tangentToWorldAndLightDir[1].xyz = tangentToWorld[1];
		o.tangentToWorldAndLightDir[2].xyz = tangentToWorld[2];
	#else
		o.tangentToWorldAndLightDir[0].xyz = 0;
		o.tangentToWorldAndLightDir[1].xyz = 0;
		o.tangentToWorldAndLightDir[2].xyz = normalWorld;
	#endif
	//We need this for shadow receving
	TRANSFER_VERTEX_TO_FRAGMENT(o);

	float3 lightDir = _WorldSpaceLightPos0.xyz - posWorld.xyz * _WorldSpaceLightPos0.w;
	#ifndef USING_DIRECTIONAL_LIGHT
		lightDir = NormalizePerVertexNormal(lightDir);
	#endif
	o.tangentToWorldAndLightDir[0].w = lightDir.x;
	o.tangentToWorldAndLightDir[1].w = lightDir.y;
	o.tangentToWorldAndLightDir[2].w = lightDir.z;

	#ifdef _PARALLAXMAP
		TANGENT_SPACE_ROTATION;
		o.viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
	#endif
	
	UNITY_TRANSFER_FOG(o,o.pos);
//Lux: Above writes to the whole o.fogCoord variable. So any other values should be added afterwards.
	// Store Flow Direction
	o.fogCoord.yzw = 0;
	#if defined (_TANGENT_TO_WORLD)
		#if !defined (_PARALLAXMAP)
			TANGENT_SPACE_ROTATION;
		#endif
		o.fogCoord.yz = (mul(rotation, mul(unity_WorldToObject, float4(0,1,0,0)).xyz)).xy;
	#endif
	// Get and store object scale / Needed by water ripples to match POM offset
	float4 scaleX = mul(unity_ObjectToWorld, float4(1.0, 0.0, 0.0, 0.0));
	o.fogCoord.w = length(scaleX);

	// Lux
	o.color = v.color;

	return o;
}

half4 fragForwardAdd (VertexOutputForwardAdd i 
	#if defined(EFFECT_HUE_VARIATION)
	, float facing : VFACE
	#endif
	) : SV_Target
{

//	VFACE
	#if defined(EFFECT_HUE_VARIATION)
		#if UNITY_VFACE_FLIPPED
			facing = -facing;
		#endif
		#if UNITY_VFACE_AFFECTED_BY_PROJECTION
			facing *= _ProjectionParams.x; // take possible upside down rendering into account
	  	#endif
	  	//s.normalWorld *= facing;
	#else
		float facing = 1;
	#endif
//

	FRAGMENT_SETUP_FWDADD(s)

//	No shadows from LIGHT_ATTENUATION(i) – we read these separately
	UnityLight light = AdditiveLight (s.normalWorld, IN_LIGHTDIR_FWDADD(i), LIGHT_ATTENUATION(i));
	UnityIndirect noIndirect = ZeroIndirect ();

	//half4 c = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, light, noIndirect);
	//half4 c = AFS_BRDF1_FORWARD_Unity_PBS(s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, light, noIndirect, _LightColor0.a);


//	///////////////////////////////////////	
//	Lux
	half specularIntensity = 1.0f;
	fixed3 diffuseNormal = s.normalWorld;
	half3 diffuseLightDir = 0;
	half ndotlDiffuse = 0;

//light.color = half4(1,0,0,24);

//	///////////////////////////////////////	
//	Lux Area lights
	#if defined(LUX_AREALIGHTS)
		// NOTE: Forward needs other inputs than deferred
		Lux_AreaLight (light, specularIntensity, diffuseLightDir, ndotlDiffuse, light.dir, _LightColor0.a, _WorldSpaceLightPos0.xyz, s.posWorld, -s.eyeVec, s.normalWorld, diffuseNormal, 1.0 - s.oneMinusRoughness);
	#else
		diffuseLightDir = light.dir;
		ndotlDiffuse = light.ndotl;
		// If area lights are disabled we still have to reduce specular intensity
		#if !defined(DIRECTIONAL) && !defined(DIRECTIONAL_COOKIE)
			specularIntensity = saturate(_LightColor0.a);
		#endif
	#endif
//	///////////////////////////////////////	

//	Get the shadows
	half shadow = SHADOW_ATTENUATION(i);

	half3 viewDir = -s.eyeVec;


//	///////////////////////////////////////	
//	Translucent Lighting

	#if defined (LOD_FADE_PERCENTAGE)
		half3 transLightDir = diffuseLightDir + diffuseNormal * _Lux_Tanslucent_Settings.x;
		// half transDot = pow (saturate ( dot ( -transLightDir, viewDir ) * s.translucency ), _Lux_Tanslucent_Settings.y);
		// get rid of the pow
		// https://seblagarde.wordpress.com/2012/06/03/spherical-gaussien-approximation-for-blinn-phong-phong-and-fresnel/
		half transDot = dot( -transLightDir, viewDir );
		transDot = exp2( -_Lux_Tanslucent_Settings.y * (1.0 - transDot)) * s.translucency;
		half shadowFactor = saturate(transDot) * _Lux_Tanslucent_Settings.z * s.translucency;
		half3 lightScattering = transDot * light.color * lerp(shadow, 1, shadowFactor);
	#endif

	light.color *= shadow;

//	///////////////////////////////////////	
//	Direct lighting uses the Lux BRDF

	half3 halfDir = normalize (light.dir + viewDir);
	half	nh = BlinnTerm (s.normalWorld, halfDir);
	half	nv = DotClamped (s.normalWorld, viewDir);
	half	lv = DotClamped (light.dir, viewDir);
	half	lh = DotClamped (light.dir, halfDir);

	half4 c = Lux_BRDF1_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, viewDir,
				// Deferred expects these inputs to be calculates up front, forward does not. So we have to fill the input struct.
				halfDir, nh, nv, lv, lh,
				ndotlDiffuse,
				light, noIndirect, specularIntensity);	
//	///////////////////////////////////////



//	Translucent Lighting
	#if defined (LOD_FADE_PERCENTAGE)
		c.rgb += lightScattering * s.diffColor * 4.0;
	#endif

	UNITY_APPLY_FOG_COLOR(i.fogCoord, c.rgb, half4(0,0,0,0)); // fog towards black in additive pass
	return OutputForward (c, s.alpha);
}

// ------------------------------------------------------------------
//  Deferred pass

struct VertexOutputDeferred
{
	float4 pos							: SV_POSITION;
	float4 tex							: TEXCOORD0;
	half3 eyeVec 						: TEXCOORD1;	
	half4 tangentToWorldAndParallax[3]	: TEXCOORD2;	// [3x3:tangentToWorld | 1x3:viewDirForParallax]
	half4 ambientOrLightmapUV			: TEXCOORD5;	// SH or Lightmap UVs			
//	Lux: Always included and set to float4
//	#if UNITY_SPECCUBE_BOX_PROJECTION
		float4 posWorld					: TEXCOORD6;	// xyz: posWorld / w. Distance to camera
//	#endif
		#if UNITY_OPTIMIZE_TEXCUBELOD
		#if UNITY_SPECCUBE_BOX_PROJECTION
			half3 reflUVW				: TEXCOORD7;
		#else
			half3 reflUVW				: TEXCOORD6;
		#endif
	#endif

	//Lux
	float4 fogCoord 					: TEXCOORD9;	// fogCoord used to store custom outputs
	fixed4 color 						: COLOR0;		
};


VertexOutputDeferred vertDeferred (LuxVertexInput v)
{
	// Fix for dynamic batching. Credits: Tomasz Stobierski 
/*	v.normal = normalize(v.normal);
	#ifdef _TANGENT_TO_WORLD
		v.tangent.xyz = normalize(v.tangent.xyz);
	#endif
*/

	VertexOutputDeferred o;
	UNITY_INITIALIZE_OUTPUT(VertexOutputDeferred, o);

	float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
	//#if UNITY_SPECCUBE_BOX_PROJECTION
		o.posWorld.xyz = posWorld;
	//#endif
	// Lux
	o.posWorld.w = distance(_WorldSpaceCameraPos, posWorld); //saturate( (_Lux_DetailDistanceFade.x - distance(_WorldSpaceCameraPos, posWorld)) / _Lux_DetailDistanceFade.x);

	o.pos = UnityObjectToClipPos(v.vertex);
	o.tex = LuxTexCoords(v);
	o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
	float3 normalWorld = UnityObjectToWorldNormal(v.normal);
	#ifdef _TANGENT_TO_WORLD
		float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

		float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
		o.tangentToWorldAndParallax[0].xyz = tangentToWorld[0];
		o.tangentToWorldAndParallax[1].xyz = tangentToWorld[1];
		o.tangentToWorldAndParallax[2].xyz = tangentToWorld[2];
	#else
		o.tangentToWorldAndParallax[0].xyz = 0;
		o.tangentToWorldAndParallax[1].xyz = 0;
		o.tangentToWorldAndParallax[2].xyz = normalWorld;
	#endif

	o.ambientOrLightmapUV = 0;
	#ifndef LIGHTMAP_OFF
		o.ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
	#elif UNITY_SHOULD_SAMPLE_SH
		o.ambientOrLightmapUV.rgb = ShadeSHPerVertex (normalWorld, o.ambientOrLightmapUV.rgb);
	#endif
	#ifdef DYNAMICLIGHTMAP_ON
		o.ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	#endif

	#ifdef _PARALLAXMAP
		TANGENT_SPACE_ROTATION;
		half3 viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
		o.tangentToWorldAndParallax[0].w = viewDirForParallax.x;
		o.tangentToWorldAndParallax[1].w = viewDirForParallax.y;
		o.tangentToWorldAndParallax[2].w = viewDirForParallax.z;
	#endif

	#if UNITY_OPTIMIZE_TEXCUBELOD
		o.reflUVW		= reflect(o.eyeVec, normalWorld);
	#endif

	//Lux
	// Store Flow Direction
	o.fogCoord.yzw = 0;
	#if defined (_TANGENT_TO_WORLD)
		#if !defined (_PARALLAXMAP)
			TANGENT_SPACE_ROTATION;
		#endif
		o.fogCoord.yz = (mul(rotation, mul(unity_WorldToObject, float4(0,1,0,0)).xyz)).xy;
	#endif
	// Get and store object scale / Needed by water ripples to match POM offset
	float4 scaleX = mul(unity_ObjectToWorld, float4(1.0, 0.0, 0.0, 0.0));
	o.fogCoord.w = length(scaleX);

	o.color = v.color;
	
	return o;
}

void fragDeferred (
	VertexOutputDeferred i,
	out half4 outDiffuse : SV_Target0,			// RT0: diffuse color (rgb), occlusion (a)
	out half4 outSpecSmoothness : SV_Target1,	// RT1: spec color (rgb), smoothness (a)
	out half4 outNormal : SV_Target2,			// RT2: normal (rgb), --unused, very low precision-- (a) 
	out half4 outEmission : SV_Target3			// RT3: emission (rgb), --unused-- (a)
	#if defined(EFFECT_HUE_VARIATION)
	, float facing : VFACE
	#endif
)
{
	#if (SHADER_TARGET < 30)
		outDiffuse = 1;
		outSpecSmoothness = 1;
		outNormal = 0;
		outEmission = 0;
		return;
	#endif

//	VFACE
	#if defined(EFFECT_HUE_VARIATION)
		#if UNITY_VFACE_FLIPPED
			facing = -facing;
		#endif
		#if UNITY_VFACE_AFFECTED_BY_PROJECTION
			facing *= _ProjectionParams.x; // take possible upside down rendering into account
	  	#endif
	  	//s.normalWorld *= facing;
	#else
	float facing = 1;
	#endif

	FRAGMENT_SETUP(s)

#if UNITY_OPTIMIZE_TEXCUBELOD
	s.reflUVW		= i.reflUVW;
#endif

	// no analytic lights in this pass
	UnityLight dummyLight = DummyLight (s.normalWorld);
	half atten = 1;

	// only GI
	half occlusion = s.occlusion;
#if UNITY_ENABLE_REFLECTION_BUFFERS
	bool sampleReflectionsInDeferred = false;
#else
	bool sampleReflectionsInDeferred = true;
#endif

	UnityGI gi = FragmentGI (s, occlusion, i.ambientOrLightmapUV, atten, dummyLight, sampleReflectionsInDeferred);

	half3 color = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect).rgb;
	color += UNITY_BRDF_GI (s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, occlusion, gi);

	#ifdef _EMISSION
		color += s.emission;
	#endif

	#ifndef UNITY_HDR_ON
		color.rgb = exp2(-color.rgb);
	#endif

	outDiffuse = half4(s.diffColor, occlusion);
	outSpecSmoothness = half4(s.specColor, s.oneMinusRoughness);
	outNormal = half4(s.normalWorld*0.5+0.5,1);
	outEmission = half4(color, 1);
}					
			
#endif // UNITY_STANDARD_CORE_INCLUDED
