Shader "Lux/Standard Lighting/Nature/Terrain/Standard" {
	Properties {
		_SpecColor ("Specular Color", Color) = (0.2,0.2,0.2,1)

		// set by terrain engine
		[HideInInspector] _Control ("Control (RGBA)", 2D) = "red" {}
		[HideInInspector] _Splat3 ("Layer 3 (A)", 2D) = "white" {}
		[HideInInspector] _Splat2 ("Layer 2 (B)", 2D) = "white" {}
		[HideInInspector] _Splat1 ("Layer 1 (G)", 2D) = "white" {}
		[HideInInspector] _Splat0 ("Layer 0 (R)", 2D) = "white" {}
		[HideInInspector] _Normal3 ("Normal 3 (A)", 2D) = "bump" {}
		[HideInInspector] _Normal2 ("Normal 2 (B)", 2D) = "bump" {}
		[HideInInspector] _Normal1 ("Normal 1 (G)", 2D) = "bump" {}
		[HideInInspector] _Normal0 ("Normal 0 (R)", 2D) = "bump" {}
		// used in fallback on old cards & base map
		[HideInInspector] _MainTex ("BaseMap (RGB)", 2D) = "white" {}
		[HideInInspector] _Color ("Main Color", Color) = (1,1,1,1)


		// Lux dynamic weather properties
		[Space(4)]
		[Header(Dynamic Snow ______________________________________________________ )]
		[Space(4)]
		_SnowSlopeDamp("Snow Slope Damp", Range (0.0, 8.0)) = 1.0
		[Lux_SnowAccumulationDrawer] _SnowAccumulation("Snow Accumulation", Vector) = (0,1,0,0)
		[Space(4)]
		[Lux_TextureTilingDrawer] _SnowTiling ("Snow Tiling", Vector) = (2,2,0,0)
		_SnowNormalStrength ("Snow Normal Strength", Range (0.0, 2.0)) = 1.0
		[Lux_TextureTilingDrawer] _SnowMaskTiling ("Snow Mask Tiling", Vector) = (0.3,0.3,0,0)
		[Lux_TextureTilingDrawer] _SnowDetailTiling ("Snow Detail Tiling", Vector) = (4.0,4.0,0,0)
		_SnowDetailStrength ("Snow Detail Strength", Range (0.0, 1.0)) = 0.5
		_SnowOpacity("Snow Opacity", Range (0.0, 1.0)) = 0.5
		
		[Space(4)]
		[Header(Dynamic Wetness ______________________________________________________ )]
		[Space(4)]
		_WaterSlopeDamp("Water Slope Damp", Range (0.0, 1.0)) = 0.5
		
		[Header(Texture Set 1)]
		_WaterColor("Water Color (RGB) Opacity (A)", Color) = (0,0,0,0)
		[Lux_WaterAccumulationDrawer] _WaterAccumulationCracksPuddles("Water Accumulation in Cracks and Puddles", Vector) = (0,1,0,1)

		[Space(4)]
		_Lux_FlowNormalTiling("Flow Normal Tiling", Float) = 2.0
		_Lux_FlowSpeed("Flow Speed", Range (0.0, 2.0)) = 0.05
		_Lux_FlowInterval("Flow Interval", Range (0.0, 8.0)) = 1
		_Lux_FlowRefraction("Flow Refraction", Range (0.0, 0.1)) = 0.02
		_Lux_FlowNormalStrength("Flow Normal Strength", Range (0.0, 2.0)) = 1.0

	}

	SubShader {
		Tags {
			"Queue" = "Geometry-100"
			"RenderType" = "Opaque"
		}

		CGPROGRAM
		#pragma surface surf LuxStandardSpecular vertex:SplatmapVert finalcolor:SplatmapFinalColor finalgbuffer:SplatmapFinalGBuffer fullforwardshadows
		#pragma multi_compile_fog
		#if defined (UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD)
			#pragma multi_compile __ LUX_AREALIGHTS
		#endif
		#pragma target 3.0
		// needs more than 8 texcoords
		#pragma exclude_renderers gles


		#define _SNOW
		// Water flow is not supported as we have no space to store the flow direction.
		#define _WETNESS_RIPPLES
		// As we calculate wetness and snow accumulation after having sampled albedo and normal we do not need refracted uvs
		#define DO_NOT_REFRACT_UVS

		#include "../Lux Core/Lux Config.cginc"
		#include "../Lux Core/Lux Lighting/LuxStandardPBSLighting.cginc"
		#include "../Lux Core/Lux Setup/LuxStructs.cginc"
		#include "../Lux Core/Lux Utils/LuxUtils.cginc"
		#include "../Lux Core/Lux Features/LuxDynamicWeather.cginc"
		#include "../Lux Core/Lux Features/LuxDiffuseScattering.cginc"

		#pragma multi_compile __ _TERRAIN_NORMAL_MAP

		//#define TERRAIN_STANDARD_SHADER
		#define TERRAIN_SURFACE_OUTPUT SurfaceOutputLuxStandardSpecular
		#include "Includes/Lux TerrainSplatmapCommon.cginc"

		void surf (Input IN, inout SurfaceOutputLuxStandardSpecular o) {

			LUX_SETUP(IN.tc_Control, float2(0,0), IN.viewDir, IN.lux_worldPosDistance.xyz, IN.lux_worldPosDistance.w, float2(0,0), half4(1,1,1,1), /*scale*/ 1)

			half4 splat_control;
			half weight;
			fixed4 mixedDiffuse;
			SplatmapMix(IN, splat_control, weight, mixedDiffuse, o.Normal);
			o.Albedo = mixedDiffuse.rgb;
			o.Alpha = weight;
			o.Smoothness = mixedDiffuse.a;
			o.Specular = _SpecColor;

			// As we can't or better: do not want to do the splatting twice we can not calculate refraction from water and include all Lux functions afterwards.

			// We have no height maps, so we simply assign some value
			LUX_SET_HEIGHT( o.Albedo.b )
			// We neither have a puddle nor a snow mask, so both values are set to 1
			LUX_INIT_DYNAMICWEATHER(1, 1, o.Normal)
			LUX_APPLY_DYNAMICWEATHER
			// Add diffuse scattering only to snow
			LUX_DIFFUSESNOWSCATTERING(o.Albedo, o.Normal, IN.viewDir)

		}
		ENDCG
	}

	Dependency "AddPassShader" = "Hidden/Lux/Terrain/Lux-Standard-AddPass"
	Dependency "BaseMapShader" = "Hidden/TerrainEngine/Splatmap/Lux-Standard-Base"

	Fallback "Nature/Terrain/Diffuse"
}
