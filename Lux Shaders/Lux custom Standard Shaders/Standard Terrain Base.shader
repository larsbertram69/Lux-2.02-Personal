// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Hidden/TerrainEngine/Splatmap/Lux-Standard-Base" {
	Properties {
		_MainTex ("Base (RGB) Smoothness (A)", 2D) = "white" {}

		// used in fallback on old cards
		_Color ("Main Color", Color) = (1,1,1,1)

		_SpecColor ("Specular Color", Color) = (0.2,0.2,0.2,1)


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
			"RenderType" = "Opaque"
			"Queue" = "Geometry-100"
		}
		LOD 200

		CGPROGRAM
		#pragma surface surf LuxStandardSpecular fullforwardshadows vertex:vert
		#pragma target 3.0
		#if defined (UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD)
			#pragma multi_compile __ LUX_AREALIGHTS
		#endif
		// needs more than 8 texcoords
		#pragma exclude_renderers gles

		#define _SNOW
		// Water flow is not supported as we have no space to store the flow direction.
		#define _WETNESS_SIMPLE

		#include "../Lux Core/Lux Config.cginc"
		#include "../Lux Core/Lux Lighting/LuxStandardPBSLighting.cginc"
		#include "../Lux Core/Lux Setup/LuxStructs.cginc"
		#include "../Lux Core/Lux Utils/LuxUtils.cginc"
		#include "../Lux Core/Lux Features/LuxDynamicWeather.cginc"
		#include "../Lux Core/Lux Features/LuxDiffuseScattering.cginc"

		sampler2D _MainTex;

		struct appdata {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
			float4 tangent : TANGENT;
            float2 texcoord : TEXCOORD0;
            float2 texcoord1 : TEXCOORD1;
            float2 texcoord2 : TEXCOORD2;
        };

		struct Input {
			float2 lux_uv_MainTex;			// Important: we must not use standard uv_MainTex as we need access to _MainTex_ST
			float3 viewDir;
			float4 lux_worldPosDistance;
			float3 worldNormal;
			INTERNAL_DATA
		};

		void vert (inout appdata v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input,o);
			// Lux
			o.lux_uv_MainTex.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
			v.tangent.xyz = cross(v.normal, float3(0,0,1));
			v.tangent.w = -1;
			// Store world position and distance to camera
			float3 worldPosition = mul(unity_ObjectToWorld, v.vertex);
			o.lux_worldPosDistance.xyz = worldPosition;
			o.lux_worldPosDistance.w = distance(_WorldSpaceCameraPos, worldPosition);
		}

		void surf (Input IN, inout SurfaceOutputLuxStandardSpecular o) {

			LUX_SETUP(IN.lux_uv_MainTex, float2(0,0), IN.viewDir, IN.lux_worldPosDistance.xyz, IN.lux_worldPosDistance.w, float2(0,0), half4(1,1,1,1), /*scale*/ 1)

			half4 c = tex2D (_MainTex, IN.lux_uv_MainTex);
			o.Albedo = c.rgb;
			o.Alpha = 1;
			o.Smoothness = c.a;
			o.Specular = _SpecColor;
			o.Normal = half3(0,0,1);
			//o.Metallic = tex2D (_MetallicTex, IN.uv_MainTex).r;
			
			LUX_SET_HEIGHT( o.Albedo.b )

			LUX_INIT_DYNAMICWEATHER(1, 1, half3(0,0,1))
			LUX_APPLY_DYNAMICWEATHER

			LUX_DIFFUSESNOWSCATTERING(o.Albedo, o.Normal, IN.viewDir)

		}

		ENDCG
	}

	FallBack "Diffuse"
}
