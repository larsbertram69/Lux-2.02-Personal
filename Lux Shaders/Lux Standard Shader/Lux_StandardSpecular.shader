Shader "Lux Standard (Specular setup)"
{

	Properties
	{
		// How to treat the detail texture
		[Toggle(GEOM_TYPE_BRANCH_DETAIL)] _UseMixMapping ("Use Mix Mapping", Float) = 0.0
		[Toggle(GEOM_TYPE_LEAF)] _MixMappingControl("Use Detail Map to controle Mix Mapping ", Float) = 0.0
		[Toggle(EFFECT_HUE_VARIATION)] _DoubleSided("Double Sided", Float) = 0.0

		// Lighting
	//	[MaterialEnum(Standard,0,Translucent,1,Anisotropic,2)] _Lighting ("Lighting", Range(0,2)) = 0
		_Lighting ("Lighting", Float) = 0

		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

		_DiffuseScatteringEnabled ("Diffuse Scattering Enabled", Float) = 0.0
		_DiffuseScatteringCol("Diffuse Scattering Color", Color) = (0,0,0,0)
		_DiffuseScatteringBias("Scatter Bias", Range(0.0, 0.5)) = 0.0
		_DiffuseScatteringContraction("Scatter Contraction", Range(1.0, 10.0)) = 8.0
		_DiffuseScatteringCol2("Diffuse Scattering Color2", Color) = (0,0,0,0)
		_DiffuseScatteringBias2("Scatter Bias", Range(0.0, 0.5)) = 0.0
		_DiffuseScatteringContraction2("Scatter Contraction", Range(1.0, 10.0)) = 8.0

		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_SpecColor("Specular", Color) = (0.2,0.2,0.2)
		_SpecGlossMap("Specular", 2D) = "white" {}

		_BumpScale("Scale", Float) = 1.0
		_BumpMap("Normal Map", 2D) = "bump" {}

		_Parallax ("Height Scale", Range (0.005, 0.1)) = 0.02
		_ParallaxMap ("Height Map", 2D) = "black" {}
		_UVRatio ("UV Ratio", Vector) = (1,1,0,0)
		_ParallaxTiling ("Parallax Tiling", Float) = 1
		[Toggle(EFFECT_BUMP)] _UsePOM("Use POM", Float) = 0.0
		_LinearSteps("Linear Steps", Range(4, 64.0)) = 20

		_OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
		_OcclusionMap("Occlusion", 2D) = "white" {}

		_EmissionColor("Color", Color) = (0,0,0)
		_EmissionMap("Emission", 2D) = "white" {}
		
		_DetailMask("Detail Mask", 2D) = "white" {}

		_DetailAlbedoMap("Detail Albedo x2", 2D) = "grey" {}
		_DetailNormalMapScale("Scale", Float) = 1.0
		_DetailNormalMap("Normal Map", 2D) = "bump" {}

		_Color2("Color 2", Color) = (1,1,1,1)
		_Glossiness2("Smoothness", Range(0.0, 1.0)) = 0.5
		_SpecColor2("Specular", Color) = (0.2,0.2,0.2)
		_SpecGlossMap2("Specular", 2D) = "white" {}

		[Enum(UV0,0,UV1,1)] _UVSec ("UV Set for secondary textures", Float) = 0


		[Toggle(GEOM_TYPE_BRANCH)] _UseCombinedMap ("Use combined Map", Float) = 0.0
		_CombinedMap("Combined Map", 2D) = "white" {}

		_TranslucencyStrength("Translucency", Range(0.0, 1.0)) = 0.5
		_ScatteringPower ("Scattering Power", Range(0,8)) = 4

		// Snow
		[Enum(Disabled,0,Enabled,1)] _Snow ("Snow", Float) = 0
		[Enum(Local Space,0,World Space,1)] _SnowMapping ("Mapping", Float) = 0
		_SnowAccumulation("Snow Accumulation", Vector) = (0,1,0,0)
		_SnowSlopeDamp("Snow Slope Damp", Range (0.0, 2.0)) = 0.75
		_SnowTiling ("Snow Tiling", Vector) = (2,2,0,0)
		_SnowNormalStrength ("Snow Normal Strength", Range (0.0, 2.0)) = 1.0
		_SnowMaskTiling ("Snow Mask Tiling", Vector) = (0.3,0.3,0,0)
		_SnowDetailTiling ("Snow Detail Tiling", Vector) = (4.0,4.0,0,0)
		_SnowDetailStrength ("Snow Detail Strength", Range (0.0, 1.0)) = 0.3
		_SnowOpacity("Snow Opacity", Range (0.0, 1.0)) = 0.5 

		// Wetness
		[Enum(None,0,Simple,1,Ripples,2,Flow,3,Full,4)] _Wetness ("Wetness and Rain", Float) = 0

		[Enum(Vertex Color,0,Heightmap(R),1)] _PuddleMask ("Puddlemask", Float) = 0
		_PuddleMaskTiling ("Puddle Mask Tiling", Float) = 1
		_WaterSlopeDamp("Water Slope Damp", Range (0.0, 1.0)) = 0.5

		_Lux_FlowNormalTiling("Flow Normal Tiling", Float) = 2.0
		_Lux_FlowSpeed("Flow Speed", Range (0.0, 2.0)) = 0.05
		_Lux_FlowInterval("Flow Interval", Range (0.0, 8.0)) = 1
		_Lux_FlowRefraction("Flow Refraction", Range (0.0, 0.1)) = 0.02
		_Lux_FlowNormalStrength("Flow Normal Strength", Range (0.0, 2.0)) = 1.0
		
		_WaterColor("Water Color", Color) = (0,0,0,0)
		_WaterAccumulationCracksPuddles("Water Accumulation in Cracks and Puddles", Vector) = (0,1,0,1)

		_WaterColor2("Water Color 2", Color) = (0,0,0,0)
		_WaterAccumulationCracksPuddles2("Water Accumulation in Cracks and Puddles", Vector) = (0,1,0,1)

		_SyncWaterOfMaterials("Sync Water Of Materials", Float) = 0

		// Blending state
		[HideInInspector] _Mode ("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend ("__src", Float) = 1.0
		[HideInInspector] _DstBlend ("__dst", Float) = 0.0
		[HideInInspector] _ZWrite ("__zw", Float) = 1.0

		// Culling
		[HideInInspector] _Cull ("__cull", Float) = 3.0
		[HideInInspector] _CullShadowPass ("__cull", Float) = 3.0
	}

	CGINCLUDE
		#define UNITY_SETUP_BRDF_INPUT SpecularSetup
	ENDCG

	SubShader
	{
		Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }
		LOD 300
	

		// ------------------------------------------------------------------
		//  Base forward pass (directional light, emission, lightmaps, ...)
		Pass
		{
			Name "FORWARD" 
			Tags { "LightMode" = "ForwardBase" }

			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			Cull [_Cull]

			CGPROGRAM
			#pragma target 3.0
			// TEMPORARY: GLES2.0 temporarily disabled to prevent errors spam on devices without textureCubeLodEXT
			#pragma exclude_renderers gles
			#pragma multi_compile_instancing

			// -------------------------------------
					
			//	#pragma shader_feature _NORMALMAP
			#define _NORMALMAP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _EMISSION
			#pragma shader_feature _SPECGLOSSMAP
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _PARALLAXMAP

			#pragma shader_feature _OCCLUSIONMAP

			// Lux uses speed tree's shader keywords
			// Do we use Mix Mapping?
			#pragma shader_feature _ GEOM_TYPE_BRANCH_DETAIL
			// Which mixmapping mode?
			#pragma shader_feature _ GEOM_TYPE_LEAF
			// Do we have a combined map?
			#pragma shader_feature _ GEOM_TYPE_BRANCH
			// Do we have a 2nd SpecGlossMap?
			#pragma shader_feature _ GEOM_TYPE_FROND
			// Double Sided?
			#pragma shader_feature _ EFFECT_HUE_VARIATION
			// POM?
			#pragma shader_feature _ EFFECT_BUMP
			// Lighting: Standard / Translucent / Anisotropic
			// #pragma shader_feature _ LUX_TRANSLUCENTLIGHTING 
			// LUX_PUDDLEMASKTILING
			// Wetness
			#pragma shader_feature _ _WETNESS_SIMPLE _WETNESS_RIPPLES _WETNESS_FLOW _WETNESS_FULL
			// Puddle Mask from vertex colors or height map? LUX_PUDDLEMASKTILING: puddle mask has same tiling as heigh map
			#pragma shader_feature _ GEOM_TYPE_MESH LUX_PUDDLEMASKTILING
			// Snow
			#pragma shader_feature _ _SNOW

			// Lux Area Lights
			#pragma multi_compile __ LUX_AREALIGHTS
			
			#pragma multi_compile_fwdbase
			//#pragma multi_compile_fog

			#pragma vertex vertForwardBase
			#pragma fragment fragForwardBase

			#define LUX_STANDARDSHADER
			#include "../Lux Core/Lux Config.cginc"
			#include "Lux_StandardCore.cginc"

			ENDCG
		}
		// ------------------------------------------------------------------
		//  Additive forward pass (one light per pass)
		Pass
		{
			Name "FORWARD_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend [_SrcBlend] One
			Fog { Color (0,0,0,0) } // in additive pass fog should be black
			ZWrite Off
			ZTest LEqual
			Cull [_Cull]

			CGPROGRAM
			#pragma target 4.6
			// GLES2.0 temporarily disabled to prevent errors spam on devices without textureCubeLodEXT
			#pragma exclude_renderers gles

			// -------------------------------------
		
			//	#pragma shader_feature _NORMALMAP
			#define _NORMALMAP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _SPECGLOSSMAP
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _PARALLAXMAP

			#pragma shader_feature _OCCLUSIONMAP

			// Lux uses spped tree's shader keywords
			// Do we use Mix Mapping?
			#pragma shader_feature _ GEOM_TYPE_BRANCH_DETAIL
			// Which mixmapping mode?
			#pragma shader_feature _ GEOM_TYPE_LEAF
			// Do we have a combined map?
			#pragma shader_feature _ GEOM_TYPE_BRANCH
			// Do we have a 2nd SpecGlossMap?
			#pragma shader_feature _ GEOM_TYPE_FROND
			// Double Sided?
			#pragma shader_feature _ EFFECT_HUE_VARIATION
			// POM?
			#pragma shader_feature _ EFFECT_BUMP
			// Lighting: Standard / Translucent / Anisotropic
			// #pragma shader_feature _ LUX_TRANSLUCENTLIGHTING 
			// LUX_PUDDLEMASKTILING
			// Wetness
			#pragma shader_feature _ _WETNESS_SIMPLE _WETNESS_RIPPLES _WETNESS_FLOW _WETNESS_FULL
			// Puddle Mask from vertex colors or height map? LUX_PUDDLEMASKTILING: puddle mask has same tiling as heigh map
			#pragma shader_feature _ GEOM_TYPE_MESH LUX_PUDDLEMASKTILING
			// Snow
			#pragma shader_feature _ _SNOW

			// Lux Area Lights
			#pragma multi_compile __ LUX_AREALIGHTS
			
			#pragma multi_compile_fwdadd_fullshadows
			//#pragma multi_compile_fog

			#pragma vertex vertForwardAdd
			#pragma fragment fragForwardAdd

			#define LUX_STANDARDSHADER
			#include "../Lux Core/Lux Config.cginc"
			#include "Lux_StandardCore.cginc"

			ENDCG
		}
		// ------------------------------------------------------------------
		//  Shadow rendering pass
		Pass {
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			
			ZWrite On ZTest LEqual
			// TODO: make this efficient
			Cull [_CullShadowPass]

			CGPROGRAM
			#pragma target 4.6
			// TEMPORARY: GLES2.0 temporarily disabled to prevent errors spam on devices without textureCubeLodEXT
			#pragma exclude_renderers gles
			
			// -------------------------------------

			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _PARALLAXMAP
			
			// Do we use Mix Mapping?
			#pragma shader_feature _ GEOM_TYPE_BRANCH_DETAIL
			// Which mixmapping mode?
			#pragma shader_feature _ GEOM_TYPE_LEAF
			// Do we have a combined map?
			#pragma shader_feature _ GEOM_TYPE_BRANCH
			// POM?
			#pragma shader_feature _ EFFECT_BUMP
			// Double Sided?
			#pragma shader_feature _ EFFECT_HUE_VARIATION
			
			#pragma multi_compile_shadowcaster

			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster

			#define LUX_STANDARDSHADER
			#include "../Lux Core/Lux Config.cginc"
			#include "LuxStandardShadow.cginc"

			ENDCG
		}
		// ------------------------------------------------------------------
		//  Deferred pass
		Pass
		{
			Name "DEFERRED"
			Tags { "LightMode" = "Deferred" }
			Cull [_Cull]

			CGPROGRAM
			#pragma target 4.6
			// TEMPORARY: GLES2.0 temporarily disabled to prevent errors spam on devices without textureCubeLodEXT
			#pragma exclude_renderers nomrt gles
			

			// -------------------------------------

			//	#pragma shader_feature _NORMALMAP
			#define _NORMALMAP
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature _EMISSION
			#pragma shader_feature _SPECGLOSSMAP
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _PARALLAXMAP

			#pragma shader_feature _OCCLUSIONMAP

			// Lux uses speed tree's shader keywords
			// Use Mix Mapping?
			#pragma shader_feature _ GEOM_TYPE_BRANCH_DETAIL
			#pragma shader_feature _ GEOM_TYPE_BRANCH
			// Do we have a 2nd SpecGlossMap?
			#pragma shader_feature _ GEOM_TYPE_FROND
			// Which mixmapping mode?
			#pragma shader_feature _ GEOM_TYPE_LEAF
			// Double Sided?
			#pragma shader_feature _ EFFECT_HUE_VARIATION
			// POM?
			#pragma shader_feature _ EFFECT_BUMP
			// Lighting
			// #pragma shader_feature _ LUX_TRANSLUCENTLIGHTING 
			// LUX_PUDDLEMASKTILING
			// Wetness
			#pragma shader_feature _ _WETNESS_SIMPLE _WETNESS_RIPPLES _WETNESS_FLOW _WETNESS_FULL
			// Puddle Mask from vertex colors or height map? LUX_PUDDLEMASKTILING: puddle mask has same tiling as heigh map
			#pragma shader_feature _ GEOM_TYPE_MESH LUX_PUDDLEMASKTILING
			// Snow
			#pragma shader_feature _ _SNOW

			#if UNITY_VERSION < 560
				#pragma multi_compile ___ UNITY_HDR_ON
				#pragma multi_compile ___ LIGHTMAP_ON
				#pragma multi_compile ___ DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE
				#pragma multi_compile ___ DYNAMICLIGHTMAP_ON
			#else
				#pragma multi_compile_prepassfinal
			#endif
			
			#pragma vertex vertDeferred
			#pragma fragment fragDeferred

			#define LUX_STANDARDSHADER
			#include "../Lux Core/Lux Config.cginc"
			#include "Lux_StandardCore.cginc"

			ENDCG
		}

		// ------------------------------------------------------------------
		// Extracts information for lightmapping, GI (emission, albedo, ...)
		// This pass it not used during regular rendering.
		Pass
		{
			Name "META" 
			Tags { "LightMode"="Meta" }

			Cull [_Cull]

			CGPROGRAM
			#pragma target 4.6
			#pragma vertex vert_meta
			#pragma fragment frag_meta

			#pragma shader_feature _EMISSION
			#pragma shader_feature _SPECGLOSSMAP
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature _PARALLAXMAP

			// Do we use Mix Mapping?
			#pragma shader_feature _ GEOM_TYPE_BRANCH_DETAIL
			// Which mixmapping mode?
			#pragma shader_feature _ GEOM_TYPE_LEAF
			// Do we have a 2nd SpecGlossMap?
			#pragma shader_feature _ GEOM_TYPE_FROND
			// Double Sided?
			#pragma shader_feature EFFECT_HUE_VARIATION
			// POM?
			#pragma shader_feature _ EFFECT_BUMP
			// Wetness
			#pragma shader_feature _ _WETNESS_SIMPLE _WETNESS_RIPPLES _WETNESS_FLOW _WETNESS_FULL
			// Puddle Mask from vertex colors or height map? LUX_PUDDLEMASKTILING: puddle mask has same tiling as heigh map
			#pragma shader_feature _ GEOM_TYPE_MESH LUX_PUDDLEMASKTILING
			// Snow
			#pragma shader_feature _ _SNOW

			#define LUX_STANDARDSHADER
			#include "../Lux Core/Lux Config.cginc"
			#include "LuxStandardMeta.cginc"
			ENDCG
		}
	}

	FallBack "VertexLit"
	CustomEditor "LuxStandardShaderGUI"
}
