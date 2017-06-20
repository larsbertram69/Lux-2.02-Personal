#ifndef LUX_STANDARD_CORE_INCLUDED
#define LUX_STANDARD_CORE_INCLUDED

#include "UnityCG.cginc"
#include "UnityStandardConfig.cginc"
#include "UnityShaderVariables.cginc"
//#include "UnityStandardInput.cginc"
#include "../Lux Core/Lux Setup/LuxInputs.cginc"
#include "UnityPBSLighting.cginc"
#include "UnityStandardUtils.cginc"
#include "UnityStandardBRDF.cginc"

#include "AutoLight.cginc"

#include "../Lux Core/Lux Utils/LuxUtils.cginc"
#include "../Lux Core/Lux BRDFs/LuxStandardBRDF.cginc"
#include "../Lux Core/Lux Lighting/LuxAreaLights.cginc"

// We include thes files here as the rely on the functions above.
#include "../Lux Core/Lux Setup/LuxStructs.cginc"
#include "../Lux Core/Lux Features/LuxParallax.cginc"
#include "../Lux Core/Lux Features/LuxDynamicWeather.cginc"



//-------------------------------------------------------------------------------------
UnityLight MainLight ()
{
	UnityLight l;

	l.color = _LightColor0.rgb;
	l.dir = _WorldSpaceLightPos0.xyz;
	l.ndotl = 0; // needed to make area lights work
	return l;
}

UnityLight AdditiveLight (half3 lightDir, half atten)
{
	UnityLight l;

	l.color = _LightColor0.rgb;
	l.dir = lightDir;
	#ifndef USING_DIRECTIONAL_LIGHT
		l.dir = NormalizePerPixelNormal(l.dir);
	#endif
	l.ndotl = 0; // needed to make area lights work

	// shadow the light
	l.color *= atten;
	return l;
}

UnityLight DummyLight (half3 normalWorld)
{
	UnityLight l;
	l.color = 0;
	l.dir = half3 (0,1,0);
	l.ndotl = 0; // needed to make area lights work
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

half3 PerPixelWorldNormal(float4 i_tex, half4 tangentToWorld[3])
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

	half3 normalTangent = NormalInTangentSpace(i_tex);
	half3 normalWorld = NormalizePerPixelNormal(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z); // @TODO: see if we can squeeze this normalize on SM2.0 as well
#else
	half3 normalWorld = normalize(tangentToWorld[2].xyz);
#endif
	return normalWorld;
}

#ifdef _PARALLAXMAP
	#define IN_VIEWDIR4PARALLAX(i) NormalizePerPixelNormal(half3(i.tangentToWorldAndParallax[0].w,i.tangentToWorldAndParallax[1].w,i.tangentToWorldAndParallax[2].w))
	#define IN_VIEWDIR4PARALLAX_FWDADD(i) NormalizePerPixelNormal(i.viewDirForParallax.xyz)
#else
	#define IN_VIEWDIR4PARALLAX(i) half3(0,0,0)
	#define IN_VIEWDIR4PARALLAX_FWDADD(i) half3(0,0,0)
#endif

//#if UNITY_SPECCUBE_BOX_PROJECTION
//	Lux: posWorld is float4
	#define IN_WORLDPOS(i) i.posWorld.xyz
//#else
//	#define IN_WORLDPOS(i) half3(0,0,0)
//#endif

#define IN_LIGHTDIR_FWDADD(i) half3(i.tangentToWorldAndLightDir[0].w, i.tangentToWorldAndLightDir[1].w, i.tangentToWorldAndLightDir[2].w)

//	/////////////////////////////
//	Lux: Fill our custom fragment structur

//	TODO: lux.viewDepth might pick its value from fogCoord.r (x) errors
	#define FRAGMENT_SETUP(x) \
		LuxFragment lux = (LuxFragment)0; \
		lux.baseUV = i.tex; \
		lux.extrudedUV = i.tex; \
		lux.finalUV = i.tex; \
		lux.eyeVec = normalize(i.eyeVec); \
		lux.eyeVecTangent = IN_VIEWDIR4PARALLAX(i); \
		lux.tangentToWorld = i.tangentToWorldAndParallax; \
		lux.worldPos = IN_WORLDPOS(i); \
		lux.viewDepth = i.posWorld.w; \
		lux.worldNormalFace = i.tangentToWorldAndParallax[2].xyz; \
		lux.height = 1.0; \
		lux.vertexColor = i.color; \
		lux.waterFlowDir = i.fogCoord.yz; \
		lux.facingSign = facing; \
		lux.scale = i.fogCoord.w; \
		FragmentCommonData x = \
		FragmentSetup(lux);

	// dx9 does not like eyeVec in forwardadd using translucent lighting?!

	#if defined(SHADER_API_D3D9)
		#define FRAGMENT_SETUP_FWDADD(x) \
			LuxFragment lux = (LuxFragment)0; \
			lux.baseUV = i.tex; \
			lux.extrudedUV = i.tex; \
			lux.finalUV = i.tex; \
			lux.eyeVecTangent = IN_VIEWDIR4PARALLAX_FWDADD(i); \
			lux.tangentToWorld = i.tangentToWorldAndLightDir; \
			lux.worldPos = IN_WORLDPOS(i); \
			lux.eyeVec = normalize(lux.worldPos.xyz - _WorldSpaceCameraPos); \
			lux.viewDepth = i.posWorld.w; \
			lux.worldNormalFace = i.tangentToWorldAndLightDir[2].xyz; \
			lux.height = 1.0; \
			lux.vertexColor = i.color; \
			lux.waterFlowDir = i.fogCoord.yz; \
			lux.facingSign = facing; \
			lux.scale = i.fogCoord.w; \
			FragmentCommonData x = \
			FragmentSetup(lux);
	#else
		#define FRAGMENT_SETUP_FWDADD(x) \
			LuxFragment lux = (LuxFragment)0; \
			lux.baseUV = i.tex; \
			lux.extrudedUV = i.tex; \
			lux.finalUV = i.tex; \
			lux.eyeVec = normalize(i.eyeVec); \
			lux.eyeVecTangent = IN_VIEWDIR4PARALLAX_FWDADD(i); \
			lux.tangentToWorld = i.tangentToWorldAndLightDir; \
			lux.worldPos = IN_WORLDPOS(i); \
			lux.viewDepth = i.posWorld.w; \
			lux.worldNormalFace = i.tangentToWorldAndLightDir[2].xyz; \
			lux.height = 1.0; \
			lux.vertexColor = i.color; \
			lux.waterFlowDir = i.fogCoord.yz; \
			lux.facingSign = facing; \
			lux.scale = i.fogCoord.w; \
			FragmentCommonData x = \
			FragmentSetup(lux);
	#endif

	#define FRAGMENT_META_SETUP(x) \
		LuxFragment lux = (LuxFragment)0; \
		lux.baseUV = i.uv; \
		lux.extrudedUV = i.uv; \
		lux.finalUV = i.uv; \
		lux.eyeVecTangent = i.viewDir; \
		lux.vertexColor = i.color; \
		lux.worldNormalFace = i.normalWorld; \
		lux.worldPos = i.posWorld.xyz; \
		lux.viewDepth = i.posWorld.w; \
		FragmentCommonData x = \
		FragmentSetup(lux);

//	/////////////////////////////////
//	Lux: occlusion, occlusion2, emission, translucency, translucencypower added
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
//	Lux: Translucent Lighting
#if defined (LUX_TRANSLUCENTLIGHTING)
	half translucency;
	half scatteringPower;
#endif
};

#ifndef UNITY_SETUP_BRDF_INPUT
	#define UNITY_SETUP_BRDF_INPUT SpecularSetup
#endif

inline FragmentCommonData SpecularSetup (LuxFragment lux)
{
	half4 specGloss = Lux_SpecularGloss(lux.mixmapValue, lux.finalUV);
	half3 specColor = specGloss.rgb;
	half oneMinusRoughness = specGloss.a;
	half oneMinusReflectivity = 1;
//	Lux
	half4 temp_albedo_2ndOcclusion = half4(lux.albedoAlpha.rgb, 1);
//	Lux: diffColor contains diffColor.rgb: the tweaked diffColor / diffColor.a: occlusion of the detail texture
//	We can't do Energyconservation here as spec and albedo gets tweaked!
	//half4 diffColor = Lux_EnergyConservationBetweenDiffuseAndSpecular (Lux_Albedo(lux.mixmapValue, temp_albedo_2ndOcclusion, lux.finalUV), specColor, /*out*/ oneMinusReflectivity);
	half4 diffColor = Lux_Albedo(lux.mixmapValue, temp_albedo_2ndOcclusion, lux.finalUV);
	FragmentCommonData o = (FragmentCommonData)0;
//	Lux:
	o.diffColor = diffColor.rgb;
	o.occlusion2 = diffColor.a;
//
	o.specColor = specColor;
	o.oneMinusReflectivity = oneMinusReflectivity;
	o.oneMinusRoughness = oneMinusRoughness;
	return o;
}

inline FragmentCommonData MetallicSetup (LuxFragment lux)
{
	half2 metallicGloss = Lux_MetallicGloss(lux.mixmapValue, lux.finalUV);
	half metallic = metallicGloss.x;
	half oneMinusRoughness = metallicGloss.y;		// this is 1 minus the square root of real roughness m.
//	Lux
	half4 temp_albedo_2ndOcclusion = half4(lux.albedoAlpha.rgb, 1);
	half oneMinusReflectivity;
	half3 specColor;
//	Lux: diffColor contains diffColor.rgb: the tweaked diffColor / diffColor.a: occlusion of the detail texture
	half4 diffColor = Lux_DiffuseAndSpecularFromMetallic (Lux_Albedo(lux.mixmapValue, temp_albedo_2ndOcclusion, lux.finalUV), metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);
	FragmentCommonData o = (FragmentCommonData)0;
//	Lux:
	o.diffColor = diffColor.rgb;
	o.occlusion2 = diffColor.a;
//
	o.specColor = specColor;
	o.oneMinusReflectivity = oneMinusReflectivity;
	o.oneMinusRoughness = oneMinusRoughness;
	return o;
} 

//inline FragmentCommonData FragmentSetup (float4 i_tex, half3 i_eyeVec, half3 i_viewDirForParallax, half4 tangentToWorld[3], half3 i_posWorld)
inline FragmentCommonData FragmentSetup (LuxFragment lux)
{

	lux.detailBlendState = saturate( (_Lux_DetailDistanceFade.x - lux.viewDepth) / _Lux_DetailDistanceFade.y);
	lux.detailBlendState *= lux.detailBlendState;

//	Lux: corect viewDir
	half3 facingFlip = half3( 1.0, 1.0, lux.facingSign);
	lux.eyeVecTangent *= facingFlip;

//	Lux: Get the Mix Map Blend value
	#if !defined (GEOM_TYPE_BRANCH_DETAIL)
		lux.mixmapValue = half2(1, 0);
	#else
		#if !defined(GEOM_TYPE_LEAF)
		//	Using Vertex Color Red
			lux.mixmapValue = half2(lux.vertexColor.r, 1.0 - lux.vertexColor.r);
		#else
		//	Using Mask Texture / Only Parallax Mapping needs the Mask, POM samples it itself
			half mixmap = 0;
			// Simple PM and the Meta Pass take this route
			// New: Only the Meta Pass takes this route – all other passes rely on the Parallax function
			#if defined (UNITY_PASS_META)
				half3 heightMixPuddleMask = tex2D (_ParallaxMap, lux.baseUV.xy).gbr;
				mixmap = heightMixPuddleMask.y;
				lux.height = heightMixPuddleMask.x;
				lux.puddleMaskValue = heightMixPuddleMask.z;
				// was commented??
				#define FIRSTHEIGHT_READ
			// Route for shader having no height map 
			#elif !defined (_PARALLAXMAP) && !defined(EFFECT_BUMP)
				mixmap = UNITY_SAMPLE_TEX2D_SAMPLER (_DetailMask, _MainTex, lux.baseUV.xy).g;
			#endif
			lux.mixmapValue = half2(mixmap, 1.0 - mixmap);
		#endif
	#endif

//	Lux: Call custom parallax functions which handle mix mapping and return height, offset and extrudedUV
	#if defined (_PARALLAXMAP)
		#if defined(EFFECT_BUMP) && !defined (UNITY_PASS_META)
			// Mixmapping
			#if defined (GEOM_TYPE_BRANCH_DETAIL)
				Lux_SimplePOM_MixMap (lux, _LinearSteps, _ParallaxMap);
			// Regular blending
			#else
				Lux_SimplePOM (lux, _LinearSteps, _ParallaxMap);
			#endif
		#else
			Lux_Parallax(lux);
		#endif
	#endif

	lux.finalUV = lux.extrudedUV;

	#if defined (_SNOW)
		lux.uniqueSnowMaskValue = lux.vertexColor.b;
		#if !defined (UNITY_PASS_META)
		// 	We have to calculate the worldNormal up front using a custom normal function which handles mix mapping
			lux.tangentNormal = Lux_NormalInTangentSpace(lux.mixmapValue, lux.extrudedUV);
			half3 smoothedNormalTangent = lerp(lux.tangentNormal, half3(0,0,1), saturate ((_Lux_SnowAmount * _SnowAccumulation.y + _SnowAccumulation.x) * 0.5) );
			lux.worldNormal = Lux_ConvertPerPixelWorldNormal (smoothedNormalTangent * facingFlip, lux.tangentToWorld);
		#endif
	#endif

	#if defined (_WETNESS_SIMPLE) || defined (_WETNESS_RIPPLES) || defined (_WETNESS_FLOW) || defined (_WETNESS_FULL)
		// Shall we sample the puddle mask from the heightmap?
		// Puddle Mask from heightmap but using custom tiling:
		#if defined (GEOM_TYPE_MESH)
			lux.puddleMaskValue = tex2D (_ParallaxMap, lux.extrudedUV.xy * _PuddleMaskTiling).r; 
		// Puddle Mask from vertex color – else we take the already sampled value
		#elif !defined(LUX_PUDDLEMASKTILING) && defined(_PARALLAXMAP)
			lux.puddleMaskValue = lux.vertexColor.g;
		#endif
	#endif

//	Lux: Calculate water and snow distribution and the final refractedUV
	#if defined (_WETNESS_SIMPLE) || defined (_WETNESS_RIPPLES) || defined (_WETNESS_FLOW) || defined (_WETNESS_FULL) || defined (_SNOW)
		Lux_DynamicWeather(lux);
	#endif

//	Lux: Do optimized alpha and albedo look up
	#if defined (_ALPHATEST_ON)
		#if defined (_WETNESS_RIPPLES) || defined (_WETNESS_FLOW) || defined (_WETNESS_FULL) || defined (EFFECT_BUMP)
			// Alpha must be sampled using the unrefracted simply extruded uvs // Albedo needs the refracted uvs
			half alpha = Alpha(lux.extrudedUV);
			clip (alpha - _Cutoff);
			half3 albedo = _Color.rgb * UNITY_SAMPLE_TEX2D (_MainTex, lux.finalUV).rgb;
			lux.albedoAlpha = half4(albedo, alpha);
		#else
			//	Lux: Sample main albedo and alpha in one single texture lookup
			lux.albedoAlpha = Lux_AlbedoAlpha(lux.finalUV.xy); 
			#if defined(_ALPHATEST_ON)
				clip (lux.albedoAlpha.a - _Cutoff);
			#endif
		#endif
	#else
		//	Lux: Sample main albedo and alpha in one single texture lookup
		lux.albedoAlpha = Lux_AlbedoAlpha(lux.finalUV.xy);
	#endif

//	Lux: Pass the already sampled albedo to the Setup Functions
	FragmentCommonData o = UNITY_SETUP_BRDF_INPUT (lux);

//	Lux: Do we have a combined Map?
	#if defined(GEOM_TYPE_BRANCH)
		half4 combined = UNITY_SAMPLE_TEX2D_SAMPLER (_CombinedMap, _MainTex, lux.extrudedUV.xy);
	#endif	
	
//	Lux: Calculate occlusion and emission in FragmentSetup to keep things together and simple
	#if !defined(LUX_FORWARDADD_PASS)
		// Lux Mix Mapping: Combine 1st and 2nd occlusion
		#if defined (GEOM_TYPE_BRANCH_DETAIL)
			// Do we have a combined map?
			#if defined(GEOM_TYPE_BRANCH)
				o.occlusion = Lux_Occlusion(lux.mixmapValue, o.occlusion2, combined.g );
			#else
				o.occlusion = Lux_Occlusion(lux.mixmapValue, o.occlusion2, lux.finalUV.zw );
			#endif
		#else
		// Regular detail blending does not have a 2nd occlusion map
			// Do we have a combined map?
			#if defined(GEOM_TYPE_BRANCH)
				o.occlusion = Lux_Occlusion(combined.g);
			#else
				o.occlusion = Occlusion(lux.finalUV );
			#endif
		#endif
		o.emission = Emission(lux.finalUV );
	#endif

//	Lux: Lighting Features – Translucent Lighting
	#if defined (LUX_TRANSLUCENTLIGHTING)
		// Mixmapping
		#if defined (GEOM_TYPE_BRANCH_DETAIL)
			// Combined maps?
			#if defined(GEOM_TYPE_BRANCH)
				o.translucency = combined.b * _TranslucencyStrength * lux.mixmapValue.x;
			#else
				o.translucency = _TranslucencyStrength * lux.mixmapValue.x;
			#endif
		#else
			// Combined maps?
			#if defined(GEOM_TYPE_BRANCH)
				o.translucency = combined.b * _TranslucencyStrength;
			#else
				o.translucency = _TranslucencyStrength;
			#endif
		#endif
		o.scatteringPower = _ScatteringPower;
	#endif

//	Lux: We have to resample the combined and blended normals using the refracted uvs
	lux.tangentNormal = Lux_NormalInTangentSpace(lux.mixmapValue, lux.finalUV);

//	Lux: Apply water and snow
	#if defined (_WETNESS_SIMPLE) || defined (_WETNESS_RIPPLES) || defined (_WETNESS_FLOW) || defined (_WETNESS_FULL) || defined (_SNOW)
		ApplySnowAndWetness(lux, o.diffColor, o.specColor, o.oneMinusRoughness, o.occlusion, o.emission
		#if defined (LUX_TRANSLUCENTLIGHTING)
			, o.translucency
		#endif
		);
	#endif

//#if defined (_WETNESS_SIMPLE) || defined (_WETNESS_RIPPLES) || defined (_WETNESS_FLOW) || defined (_WETNESS_FULL) || defined (_SNOW)
//	o.diffColor = lux.waterAmount.x;
//#endif

//	Lux: Now we can compute the final worldNormal
	#if !defined (UNITY_PASS_META)
		o.normalWorld = Lux_ConvertPerPixelWorldNormal(lux.tangentNormal * facingFlip, lux.tangentToWorld);
	//	World mapped snow
		#if defined(_SNOW)
			UNITY_BRANCH
			if (_SnowMapping == 1) {
				half3x3 SnowTangentToWorld = half3x3( half3(1, 0, 0), half3(0, 0, 1), lux.worldNormalFace);
				lux.snowNormal = mul( lux.snowNormal, SnowTangentToWorld);
				o.normalWorld = lerp(o.normalWorld, lux.snowNormal.xyz, lux.normalBlendFactor);
			}
		#endif
		o.eyeVec = /*NormalizePerPixelNormal(*/lux.eyeVec; //);
		o.posWorld = lux.worldPos;

	//	Lux: Diffuse Scattering // breaks GI if snow is enabled!! but it is not really needed so we skip it in meta pass
		half NdotV = dot(o.normalWorld, o.eyeVec);
		NdotV *= NdotV;
		half3 diffuseScatter = 0;
		// Mix Mapping
		#if defined(GEOM_TYPE_BRANCH_DETAIL)
			if(_DiffuseScatteringEnabled > 0.0) {
				fixed3 scatterColor = lerp(_DiffuseScatteringCol, _DiffuseScatteringCol2, lux.mixmapValue.y);
				half2 scatterBias_Contraction = lerp( half2(_DiffuseScatteringBias, _DiffuseScatteringContraction), half2(_DiffuseScatteringBias2, _DiffuseScatteringContraction2), lux.mixmapValue.y);
				diffuseScatter = scatterColor * (exp2(-(NdotV * scatterBias_Contraction.y)) + scatterBias_Contraction.x);
			}
		#else
		// Regular Detail Blending
			if (_DiffuseScatteringEnabled > 0.0) {
				diffuseScatter = _DiffuseScatteringCol * (exp2(-(NdotV * _DiffuseScatteringContraction)) + _DiffuseScatteringBias);
			}
		#endif
		// Snow Scattering
		#if defined (_SNOW)
			half3 snowScatter = _Lux_SnowScatterColor * (exp2(-(NdotV * _Lux_SnowScatteringContraction)) + _Lux_SnowScatteringBias);
			diffuseScatter = lerp(diffuseScatter, snowScatter, lux.snowAmount.x );
			
		#endif

		#if defined (_WETNESS_SIMPLE) || defined (_WETNESS_RIPPLES) || defined (_WETNESS_FLOW) || defined (_WETNESS_FULL) || defined (_SNOW)
			diffuseScatter *= 1.0 - lux.waterColor.a * lux.waterAmount.x;
		#endif

		o.diffColor += diffuseScatter;

	#endif

//  Lux: Energy Conservation
	o.diffColor = EnergyConservationBetweenDiffuseAndSpecular (o.diffColor, o.specColor, /*out*/ o.oneMinusReflectivity);


//	Lux: AlbedoAlpha used / NOTE: shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
	o.diffColor = PreMultiplyAlpha (o.diffColor, lux.albedoAlpha.a, o.oneMinusReflectivity, /*out*/ o.alpha);
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

	d.probeHDR[0] = unity_SpecCube0_HDR;
	d.probeHDR[1] = unity_SpecCube1_HDR;
	#if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
		d.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
	#endif
	#ifdef UNITY_SPECCUBE_BOX_PROJECTION
		d.boxMax[0] = unity_SpecCube0_BoxMax;
		d.probePosition[0] = unity_SpecCube0_ProbePosition;
		d.boxMax[1] = unity_SpecCube1_BoxMax;
		d.boxMin[1] = unity_SpecCube1_BoxMin;
		d.probePosition[1] = unity_SpecCube1_ProbePosition;
	#endif

	if(reflections)
	{
		Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.oneMinusRoughness, -s.eyeVec, s.normalWorld, s.specColor);
		// Replace the reflUVW if it has been compute in Vertex shader. Note: the compiler will optimize the calcul in UnityGlossyEnvironmentSetup itself
		#if UNITY_STANDARD_SIMPLE
			g.reflUVW = s.reflUVW;
		#endif
		return UnityGlobalIllumination (d, occlusion, s.normalWorld, g);
	}
	else {
		return UnityGlobalIllumination (d, occlusion, s.normalWorld);
	}
}

inline UnityGI FragmentGI (FragmentCommonData s, half occlusion, half4 i_ambientOrLightmapUV, half atten, UnityLight light)
{
	return FragmentGI(s, occlusion, i_ambientOrLightmapUV, atten, light, true);
}

// Horizon Occlusion for Normal Mapped Reflections: http://marmosetco.tumblr.com/post/81245981087
float GetHorizonOcclusion(float3 V, float3 pixelNormal, float3 vertexNormal, float horizonFade)
{
    float3 R = reflect(V, pixelNormal);
    float specularOcclusion = saturate(1.0 + horizonFade * dot(R, vertexNormal));
    return specularOcclusion; // * specularOcclusion;
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

inline half4 VertexGIForward(LuxVertexInput v, float3 posWorld, half3 normalWorld) {
	half4 ambientOrLightmapUV = 0;
	// Static lightmaps
	#ifdef LIGHTMAP_ON
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
	UNITY_SHADOW_COORDS(6)
//	Lux: Simple waste! Fog coords are only a float! So we redefine it using float4	
	#undef UNITY_FOG_COORDS
	#define UNITY_FOG_COORDS(idx) float4 fogCoord : TEXCOORD##idx;
	UNITY_FOG_COORDS(7)
//	Lux: We always need world position
	float4 posWorld						: TEXCOORD8;
	//float2 somethingElse 				: TEXCOORD9;
	fixed4 color 						: COLOR0;

	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};

VertexOutputForwardBase vertForwardBase (LuxVertexInput v)
{
	UNITY_SETUP_INSTANCE_ID(v);
	VertexOutputForwardBase o;
	UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBase, o);
	UNITY_TRANSFER_INSTANCE_ID(v, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	o.pos = UnityObjectToClipPos(v.vertex);
	float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
//	Lux: We always need world position for e.g. area lights
	o.posWorld.xyz = posWorld.xyz;
	o.posWorld.w = o.pos.z; //o.posWorld.w = distance(_WorldSpaceCameraPos, posWorld);
//	Lux
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
	
	// We need this for shadow receving
	UNITY_TRANSFER_SHADOW(o, v.uv1);

	o.ambientOrLightmapUV = VertexGIForward(v, posWorld, normalWorld);
	
	#ifdef _PARALLAXMAP
		// Fix for dynamic batching. Credits: Tomasz Stobierski 
		v.normal = normalize(v.normal);
		v.tangent.xyz = normalize(v.tangent.xyz);
		//TANGENT_SPACE_ROTATION;
		float3 binormal = cross( v.normal, v.tangent.xyz ) * v.tangent.w;
		float3x3 rotation = float3x3( v.tangent.xyz, binormal, v.normal );
		half3 viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
		o.tangentToWorldAndParallax[0].w = viewDirForParallax.x;
		o.tangentToWorldAndParallax[1].w = viewDirForParallax.y;
		o.tangentToWorldAndParallax[2].w = viewDirForParallax.z;
	#endif

//	UNITY_TRANSFER_FOG(o,o.pos); // this only writes o.pos.z just like in our posWorld;
//	Lux: Above writes to the whole o.fogCoord variable. So any other values should be added afterwards.
	o.fogCoord.x = o.pos.z;
// 	Store Flow Direction
	o.fogCoord.yzw = 0;
	#if defined (_TANGENT_TO_WORLD)
		#if !defined (_PARALLAXMAP)
			TANGENT_SPACE_ROTATION;
		#endif
		o.fogCoord.yz = (mul(rotation, mul(unity_WorldToObject, float4(0,1,0,0)).xyz)).xy;
	#endif
	
//	Get and store object scale / Needed by water ripples to match POM offset
	#ifdef _PARALLAXMAP
		float4 scaleX = mul(unity_ObjectToWorld, float4(1.0, 0.0, 0.0, 0.0));
		o.fogCoord.w = length(scaleX);
	#endif

//	Lux: Get the vertex colors
	o.color = v.color;
	return o;
}

half4 fragForwardBase (VertexOutputForwardBase i
//	Lux: single sided shaders need vface
	#if defined(EFFECT_HUE_VARIATION)
	, float facing : VFACE
	#endif
	) : SV_Target
{
//	Lux: VFACE
	#if defined(EFFECT_HUE_VARIATION)
		#if UNITY_VFACE_FLIPPED
			facing = -facing;
		#endif
		#if UNITY_VFACE_AFFECTED_BY_PROJECTION
			facing *= _ProjectionParams.x; // take possible upside down rendering into account
	  	#endif
	#else
		float facing = 1;
	#endif
//

	FRAGMENT_SETUP(s)

	UnityLight mainLight = MainLight ();
//	Lux: We should not get light and shadow attenuation in once because of translucent lighting - but we have to due to baked shadow masks
	half i_shadow = 1;
	UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);
//	Lux: occlusion and emission are calculated in FRAGMENT_SETUP
	half occlusion = s.occlusion;

	UnityGI gi = FragmentGI (s, occlusion, i.ambientOrLightmapUV, atten, mainLight);

//	Lux 
	half specularIntensity = 1;
	fixed3 diffuseNormal = s.normalWorld;
	half3 diffuseLightDir = 0;
	half nl = saturate(dot(s.normalWorld, gi.light.dir));
	half ndotlDiffuse = nl;

//	Lux Area lights
	#if defined(LUX_AREALIGHTS)
		// NOTE: Forward needs other inputs than deferred
		Lux_AreaLight (gi.light, specularIntensity, diffuseLightDir, ndotlDiffuse, gi.light.dir, _LightColor0.a, _WorldSpaceLightPos0.xyz, s.posWorld, -s.eyeVec, s.normalWorld, diffuseNormal, 1.0 - s.oneMinusRoughness);
		nl = saturate(dot(s.normalWorld, gi.light.dir));
	#else
		diffuseLightDir = gi.light.dir;
		// If area lights are disabled we still have to reduce specular intensity
		#if !defined(DIRECTIONAL) && !defined(DIRECTIONAL_COOKIE)
			specularIntensity = saturate(_LightColor0.a);
		#endif
	#endif
	specularIntensity = (s.specColor.r == 0.0) ? 0.0 : specularIntensity;

	half3 viewDir = -s.eyeVec;

//	Lux: Direct lighting uses the Lux BRDF
	half3 halfDir = Unity_SafeNormalize (gi.light.dir + viewDir);
	half	nh = saturate(dot(s.normalWorld, halfDir));
	half	nv = abs(dot(s.normalWorld, viewDir));
	half	lv = saturate(dot(gi.light.dir, viewDir));
	half	lh = saturate(dot(gi.light.dir, halfDir));


//	Horizon Occlusion
	#if LUX_HORIZON_OCCLUSION
		float3 worldNormalFace = i.tangentToWorldAndParallax[2].xyz;
		gi.indirect.specular *= GetHorizonOcclusion(s.eyeVec, s.normalWorld, worldNormalFace, HORIZON_FADE);	
	#endif

	half4 c = Lux_BRDF1_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, viewDir,
		// Deferred expects these inputs to be calculates up front, forward does not. So we have to fill the input struct.
		halfDir, nh, nv, lv, lh,
		nl,
		ndotlDiffuse,
		gi.light,
		gi.indirect,
		specularIntensity,
		shadow);

	#if defined (LUX_TRANSLUCENTLIGHTING)
		half3 lightScattering = 0;
		UNITY_BRANCH
		if (s.scatteringPower < 0.001) {
			half wrap = 0.5;
			half wrappedNdotL = saturate( ( dot(-diffuseNormal, diffuseLightDir) + wrap ) / ( (1 + wrap) * (1 + wrap) ) );
			half VdotL = saturate( dot(viewDir, -diffuseLightDir) );
			half a2 = 0.7 * 0.7;
			half d = ( VdotL * a2 - VdotL ) * VdotL + 1;
			half GGX = (a2 / UNITY_PI) / (d * d);
			#if defined (DIRECTIONAL)
				lightScattering = wrappedNdotL * GGX * s.translucency * lerp(gi.light.color, _LightColor0.rgb, _Lux_Translucent_NdotL_Shadowstrength );
			#else
				lightScattering = wrappedNdotL * GGX * s.translucency * gi.light.color * lerp(shadow * atten, atten, _Lux_Translucent_NdotL_Shadowstrength);;
			#endif
		}
		UNITY_BRANCH
		if (s.scatteringPower > 0.001) {
			//	https://colinbarrebrisebois.com/2012/04/09/approximating-translucency-revisited-with-simplified-spherical-gaussian/
			half3 transLightDir = diffuseLightDir + diffuseNormal * _Lux_Tanslucent_Settings.x;
			half transDot = dot( -transLightDir, viewDir );
			transDot = exp2(saturate(transDot) * s.scatteringPower - s.scatteringPower) * s.translucency;
			half shadowFactor = /*saturate(transDot) */ _Lux_Tanslucent_Settings.z * s.translucency;
			#if defined (DIRECTIONAL)
			//|| defined (DIRECTIONAL_COOKIE)
				lightScattering = transDot * lerp(gi.light.color, _LightColor0.rgb, shadowFactor);
			#else
				lightScattering = transDot * gi.light.color * lerp(shadow * atten, atten, shadowFactor);
			#endif
		}
		c.rgb += lightScattering * s.diffColor * _Lux_Tanslucent_Settings.w;
	#endif

	c.rgb += UNITY_BRDF_GI (s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, occlusion, gi);
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
//	dx9 does not like eyeVec in ForwardAdd, so we shift it to the pixelshader
	#if defined(SHADER_API_D3D9)
	#else
		half3 eyeVec 					: TEXCOORD1;
	#endif
	half4 tangentToWorldAndLightDir[3]	: TEXCOORD2;	// [3x3:tangentToWorld | 1x3:lightDir]
	float4 posWorld					 	: TEXCOORD5;
	UNITY_SHADOW_COORDS(6)

//	Lux: Simple waste! Fog coords are only a float! So we redefine it using float4	
	#undef UNITY_FOG_COORDS
	#define UNITY_FOG_COORDS(idx) float4 fogCoord : TEXCOORD##idx;
	UNITY_FOG_COORDS(7)

	// next ones would not fit into SM2.0 limits, but they are always for SM3.0+
	#if defined(_PARALLAXMAP)
		half3 viewDirForParallax		: TEXCOORD8;
	#endif
//	Lux
	//float2 somethingElse				: TEXCOORD9;
	fixed4 color 						: COLOR0;

	UNITY_VERTEX_OUTPUT_STEREO
};

VertexOutputForwardAdd vertForwardAdd (LuxVertexInput v)
{	
	UNITY_SETUP_INSTANCE_ID(v);
	VertexOutputForwardAdd o;
	UNITY_INITIALIZE_OUTPUT(VertexOutputForwardAdd, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	o.pos = UnityObjectToClipPos(v.vertex);
	float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
//	Lux:
	o.posWorld = posWorld;
	o.posWorld.w = o.pos.z; //o.posWorld.w = distance(_WorldSpaceCameraPos, posWorld);
//	Lux
	o.tex = LuxTexCoords(v);
//	dx9 does not like eyeVec in ForwardAdd, so we shift it to the pixelshader
	#if !defined(SHADER_API_D3D9)
		o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
	#endif
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
	//We need this for shadow receiving
	UNITY_TRANSFER_SHADOW(o, v.uv1);

	float3 lightDir = _WorldSpaceLightPos0.xyz - posWorld.xyz * _WorldSpaceLightPos0.w;
	#ifndef USING_DIRECTIONAL_LIGHT
		lightDir = NormalizePerVertexNormal(lightDir);
	#endif
	o.tangentToWorldAndLightDir[0].w = lightDir.x;
	o.tangentToWorldAndLightDir[1].w = lightDir.y;
	o.tangentToWorldAndLightDir[2].w = lightDir.z;

	#ifdef _PARALLAXMAP
		// Fix for dynamic batching. Credits: Tomasz Stobierski 
		v.normal = normalize(v.normal);
		v.tangent.xyz = normalize(v.tangent.xyz);
		//TANGENT_SPACE_ROTATION;
		float3 binormal = cross( v.normal, v.tangent.xyz ) * v.tangent.w;
		float3x3 rotation = float3x3( v.tangent.xyz, binormal, v.normal );
		o.viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
	#endif
	
	UNITY_TRANSFER_FOG(o,o.pos);
//	Lux: Above writes to the whole o.fogCoord variable. So any other values should be added afterwards.
//	Store Flow Direction
	o.fogCoord.yzw = 0;
	#if defined (_TANGENT_TO_WORLD)
		#if !defined (_PARALLAXMAP)
			TANGENT_SPACE_ROTATION;
		#endif
		o.fogCoord.yz = (mul(rotation, mul(unity_WorldToObject, float4(0,1,0,0)).xyz)).xy;
	#endif
//	Get and store object scale / Needed by water ripples to match POM offset
	#ifdef _PARALLAXMAP
		float4 scaleX = mul(unity_ObjectToWorld, float4(1.0, 0.0, 0.0, 0.0));
		o.fogCoord.w = length(scaleX);
	#endif
//	Lux: Get the vertex colors
	o.color = v.color;
	return o;
}

half4 fragForwardAdd (VertexOutputForwardAdd i
//	Lux: single sided shaders need vface
	#if defined(EFFECT_HUE_VARIATION)
	, float facing : VFACE
	#endif
	) : SV_Target
{
//	Lux: VFACE
	#if defined(EFFECT_HUE_VARIATION)
		#if UNITY_VFACE_FLIPPED
			facing = -facing;
		#endif
		#if UNITY_VFACE_AFFECTED_BY_PROJECTION
			facing *= _ProjectionParams.x; // take possible upside down rendering into account
	  	#endif
	#else
		float facing = 1;
	#endif
//
	FRAGMENT_SETUP_FWDADD(s)

//	Lux: No shadows from LIGHT_ATTENUATION(i) – we read these separately
	UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld)

	UnityLight light = AdditiveLight (IN_LIGHTDIR_FWDADD(i), atten);
	UnityIndirect noIndirect = ZeroIndirect ();

//	Lux
	half specularIntensity = 1;
	fixed3 diffuseNormal = s.normalWorld;
	half3 diffuseLightDir = 0;
	half nl = saturate(dot(s.normalWorld, light.dir));
	half ndotlDiffuse = nl;

//	Lux Area lights
	#if defined(LUX_AREALIGHTS)
		// NOTE: Forward needs other inputs than deferred
		Lux_AreaLight (light, specularIntensity, diffuseLightDir, ndotlDiffuse, light.dir, _LightColor0.a, _WorldSpaceLightPos0.xyz, s.posWorld, -s.eyeVec, s.normalWorld, diffuseNormal, 1.0 - s.oneMinusRoughness);
		nl = saturate(dot(s.normalWorld, light.dir));
	#else
		diffuseLightDir = light.dir;
		// If area lights are disabled we still have to reduce specular intensity
		#if !defined(DIRECTIONAL) && !defined(DIRECTIONAL_COOKIE)
			specularIntensity = saturate(_LightColor0.a);
		#endif
	#endif
	specularIntensity = (s.specColor.r == 0.0) ? 0.0 : specularIntensity;

	half3 viewDir = -s.eyeVec;

//	Lux: Direct lighting uses the Lux BRDF
	half3 halfDir = Unity_SafeNormalize (light.dir + viewDir);
	half	nh = saturate(dot(s.normalWorld, halfDir));
	half	nv = abs(dot(s.normalWorld, viewDir));
	half	lv = saturate(dot(light.dir, viewDir));
	half	lh = saturate(dot(light.dir, halfDir));

	half4 c = Lux_BRDF1_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, viewDir,
		// Deferred expects these inputs to be calculates up front, forward does not. So we have to fill the input struct.
		halfDir, nh, nv, lv, lh,
		nl,
		ndotlDiffuse,
		light,
		noIndirect,
		specularIntensity,
		shadow);

//	Lux: Translucent Lighting
	#if defined (LUX_TRANSLUCENTLIGHTING)
		half3 lightScattering = 0;
		UNITY_BRANCH
		if (s.scatteringPower < 0.001) {
			half wrap = 0.5;
			half wrappedNdotL = saturate( ( dot(-diffuseNormal, diffuseLightDir) + wrap ) / ( (1 + wrap) * (1 + wrap) ) );
			half VdotL = saturate( dot(viewDir, -diffuseLightDir) );
			half a2 = 0.7 * 0.7;
			half d = ( VdotL * a2 - VdotL ) * VdotL + 1;
			half GGX = (a2 / UNITY_PI) / (d * d);
			#if defined (DIRECTIONAL)
				lightScattering = wrappedNdotL * GGX * s.translucency * lerp(light.color, _LightColor0.rgb, _Lux_Translucent_NdotL_Shadowstrength );
			#else
				lightScattering = wrappedNdotL * GGX * s.translucency * light.color * lerp(shadow * atten, atten, _Lux_Translucent_NdotL_Shadowstrength);;
			#endif
		}
		UNITY_BRANCH
		if (s.scatteringPower > 0.001) {
			//	https://colinbarrebrisebois.com/2012/04/09/approximating-translucency-revisited-with-simplified-spherical-gaussian/
			half3 transLightDir = diffuseLightDir + diffuseNormal * _Lux_Tanslucent_Settings.x;
			half transDot = dot( -transLightDir, viewDir );
			transDot = exp2(saturate(transDot) * s.scatteringPower - s.scatteringPower) * s.translucency;
			half shadowFactor = /*saturate(transDot) */ _Lux_Tanslucent_Settings.z * s.translucency;
			#if defined (DIRECTIONAL)
			//|| defined (DIRECTIONAL_COOKIE)
				lightScattering = transDot * lerp(light.color, _LightColor0.rgb, shadowFactor);
			#else
				lightScattering = transDot * light.color * lerp(shadow * atten, atten, shadowFactor);
			#endif
		}
		c.rgb += lightScattering * s.diffColor * _Lux_Tanslucent_Settings.w;
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
	float4 posWorld						: TEXCOORD6;	// xyz: posWorld / w. Distance to camera

//	Lux
	float4 fogCoord 					: TEXCOORD7;	// fogCoord used to store custom outputs
	//float2 somethingElse 				: TEXCOORD8;
	fixed4 color 						: COLOR0;
	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO	
};


VertexOutputDeferred vertDeferred (LuxVertexInput v)
{
	UNITY_SETUP_INSTANCE_ID(v);
	VertexOutputDeferred o;
	UNITY_INITIALIZE_OUTPUT(VertexOutputDeferred, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	o.pos = UnityObjectToClipPos(v.vertex);
	float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.posWorld.xyz = posWorld;
	o.posWorld.w = o.pos.z; //o.posWorld.w = distance(_WorldSpaceCameraPos, posWorld);

//	Lux
	o.tex = LuxTexCoords(v);
	o.eyeVec = posWorld.xyz - _WorldSpaceCameraPos;
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
	#ifdef LIGHTMAP_ON
		o.ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
	#elif UNITY_SHOULD_SAMPLE_SH
		o.ambientOrLightmapUV.rgb = ShadeSHPerVertex (normalWorld, o.ambientOrLightmapUV.rgb);
	#endif
	#ifdef DYNAMICLIGHTMAP_ON
		o.ambientOrLightmapUV.zw = v.uv2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
	#endif
	
	#ifdef _PARALLAXMAP
		// Fix for dynamic batching. Credits: Tomasz Stobierski 
		v.normal = normalize(v.normal);
		v.tangent.xyz = normalize(v.tangent.xyz);
		//TANGENT_SPACE_ROTATION;
		float3 binormal = cross( v.normal, v.tangent.xyz ) * v.tangent.w;
		float3x3 rotation = float3x3( v.tangent.xyz, binormal, v.normal );
		half3 viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
		o.tangentToWorldAndParallax[0].w = viewDirForParallax.x;
		o.tangentToWorldAndParallax[1].w = viewDirForParallax.y;
		o.tangentToWorldAndParallax[2].w = viewDirForParallax.z;
	#endif

//	Lux: Store Flow Direction
	o.fogCoord.yzw = 0;
	#if defined (_TANGENT_TO_WORLD)
		#if !defined (_PARALLAXMAP)
			TANGENT_SPACE_ROTATION;
		#endif
		o.fogCoord.yz = (mul(rotation, mul(unity_WorldToObject, float4(0,1,0,0)).xyz)).xy;
	#endif
//	Get and store object scale / Needed by water ripples to match POM offset
	#ifdef _PARALLAXMAP
		float4 scaleX = mul(unity_ObjectToWorld, float4(1.0, 0.0, 0.0, 0.0));
		o.fogCoord.w = length(scaleX);
	#endif
	o.color = v.color;
	return o;
}

void fragDeferred (
	VertexOutputDeferred i,
	out half4 outDiffuse : SV_Target0,			// RT0: diffuse color (rgb), occlusion (a)
	out half4 outSpecSmoothness : SV_Target1,	// RT1: spec color (rgb), smoothness (a)
	out half4 outNormal : SV_Target2,			// RT2: normal (rgb), --unused, very low precision-- (a) 
	out half4 outEmission : SV_Target3			// RT3: emission (rgb), --unused-- (a)

#if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
	, out half4 outShadowMask : SV_Target4	   // RT4: shadowmask (rgba)
#endif

//	Lux: vface
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

//	Lux: VFACE
	#if defined(EFFECT_HUE_VARIATION)
		#if UNITY_VFACE_FLIPPED
			facing = -facing;
		#endif
		#if UNITY_VFACE_AFFECTED_BY_PROJECTION
			facing *= _ProjectionParams.x; // take possible upside down rendering into account
	  	#endif
	#else
		float facing = 1;
	#endif

	FRAGMENT_SETUP(s)

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


// spec anti aliasing
// http://jp.square-enix.com/tech/library/pdf/Error%20Reduction%20and%20Simplification%20for%20Shading%20Anti-Aliasing.pdf

#if LUX_SPEC_ANITALIASING
	float3 worldNormalFace = i.tangentToWorldAndParallax[2].xyz;
	float roughness = 1.0 - s.oneMinusRoughness;
	float3 deltaU = ddx( worldNormalFace );
	float3 deltaV = ddy( worldNormalFace );
	float variance = SCREEN_SPACE_VARIANCE * ( dot ( deltaU , deltaU ) + dot ( deltaV , deltaV ) );
	float kernelSquaredRoughness = min( 2.0 * variance , SAATHRESHOLD );
	float squaredRoughness = saturate( roughness * roughness + kernelSquaredRoughness );
	s.oneMinusRoughness = 1.0 - sqrt(squaredRoughness);
#endif

	UnityGI gi = FragmentGI (s, occlusion, i.ambientOrLightmapUV, atten, dummyLight, sampleReflectionsInDeferred);

//	Horizon Occlusion – legacy reflections
	#if !UNITY_ENABLE_REFLECTION_BUFFERS
		#if LUX_HORIZON_OCCLUSION
			gi.indirect.specular *= GetHorizonOcclusion(s.eyeVec, s.normalWorld, worldNormalFace, HORIZON_FADE);
		#endif
	#endif

	half3 color = UNITY_BRDF_PBS (s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect).rgb;
	color += UNITY_BRDF_GI (s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, occlusion, gi);

	#ifdef _EMISSION
		color += s.emission;
	#endif

	#ifndef UNITY_HDR_ON
		color.rgb = exp2(-color.rgb);
	#endif

//	Horizon Occlusion – deferred reflections
	#if UNITY_ENABLE_REFLECTION_BUFFERS
		#if LUX_HORIZON_OCCLUSION
			occlusion *= GetHorizonOcclusion(s.eyeVec, s.normalWorld, worldNormalFace, HORIZON_FADE);
		#endif
	#endif

	outDiffuse = half4(s.diffColor, occlusion);
	outSpecSmoothness = half4(s.specColor, s.oneMinusRoughness);
	outNormal = half4(s.normalWorld * 0.5 + 0.5, 1);
	
	outEmission = half4(color, 1);

	// Baked direct lighting occlusion if any
	#if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
		outShadowMask = UnityGetRawBakedOcclusions(i.ambientOrLightmapUV.xy, IN_WORLDPOS(i));
	#endif
}


//
// Old FragmentGI signature. Kept only for backward compatibility and will be removed soon
//

inline UnityGI FragmentGI(
	float3 posWorld,
	half occlusion, half4 i_ambientOrLightmapUV, half atten, half oneMinusRoughness, half3 normalWorld, half3 eyeVec,
	UnityLight light,
	bool reflections)
{
	// we init only fields actually used
	FragmentCommonData s = (FragmentCommonData)0;
	s.oneMinusRoughness = oneMinusRoughness;
	s.normalWorld = normalWorld;
	s.eyeVec = eyeVec;
	s.posWorld = posWorld;
#if UNITY_OPTIMIZE_TEXCUBELOD
	s.reflUVW = reflect(eyeVec, normalWorld);
#endif
	return FragmentGI(s, occlusion, i_ambientOrLightmapUV, atten, light, reflections);
}
inline UnityGI FragmentGI (
	float3 posWorld,
	half occlusion, half4 i_ambientOrLightmapUV, half atten, half oneMinusRoughness, half3 normalWorld, half3 eyeVec,
	UnityLight light)
{
	return FragmentGI (posWorld, occlusion, i_ambientOrLightmapUV, atten, oneMinusRoughness, normalWorld, eyeVec, light, true);
}

#endif // LUX_STANDARD_CORE_INCLUDED
