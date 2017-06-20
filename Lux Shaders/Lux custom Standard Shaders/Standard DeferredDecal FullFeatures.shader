// Based on the work of bac9-flcl and Dolkar
// http://forum.unity3d.com/threads/how-do-i-write-a-normal-decal-shader-using-a-newly-added-unity-5-2-finalgbuffer-modifier.356644/page-2

Shader "Lux/Deferred Decals/Standard Lighting/Full Features" 
{
	Properties 
	{

	//	Lux primary texture set
		[Space(4)]
		[Header(Primary Texture Set _____________________________________________________ )]
		[Space(4)]
		_Color ("Color", Color) = (1,1,1,1)
		[Space(4)]
		_MainTex ("Albedo (RGB) Alpha (A)", 2D) = "white" {}
		[NoScaleOffset] _BumpMap ("Normalmap", 2D) = "bump" {}
		[NoScaleOffset] _SpecGlossMap("Specular (RGB) Smoothness (A)", 2D) = "black" {}
		[NoScaleOffset] _OcclusionMap("Occlusion", 2D) = "white" {}

	//	Lux parallax extrusion properties
		[Space(4)]
		[Header(Parallax Extrusion ______________________________________________________ )]
		[Space(4)]
		[NoScaleOffset] _ParallaxMap ("Height (G) (Mix Mapping: Height2 (A) Mix Map (B)) PuddleMask (R)", 2D) = "white" {}
		_UVRatio("UV Ratio (XY) Scale(Z)", Vector) = (1, 1, 1, 0)
		_ParallaxTiling ("Mask Tiling", Float) = 1
		_Parallax ("Height Scale", Range (0.005, 0.1)) = 0.02
		[Space(4)]
		[Toggle(EFFECT_BUMP)] _EnablePOM("Enable POM", Float) = 0.0
		_LinearSteps("- Linear Steps", Range(4, 40.0)) = 20

	//	Lux dynamic weather properties

	//	Lux Snow
		[Space(4)]
		[Header(Dynamic Snow ______________________________________________________ )]
		[Space(4)]
		[Enum(Local Space,0,World Space,1)] _SnowMapping ("Mapping", Float) = 0
		_SnowSlopeDamp("Snow Slope Damp", Range (0.0, 8.0)) = 1.0
		[Lux_SnowAccumulationDrawer] _SnowAccumulation("Snow Accumulation", Vector) = (0,1,0,0)
		[Space(4)]
		[Lux_TextureTilingDrawer] _SnowTiling ("Snow Tiling", Vector) = (2,2,0,0)
		_SnowNormalStrength ("Snow Normal Strength", Range (0.0, 2.0)) = 1.0
		[Lux_TextureTilingDrawer] _SnowMaskTiling ("Snow Mask Tiling", Vector) = (0.3,0.3,0,0)
		[Lux_TextureTilingDrawer] _SnowDetailTiling ("Snow Detail Tiling", Vector) = (4.0,4.0,0,0)
		_SnowDetailStrength ("Snow Detail Strength", Range (0.0, 1.0)) = 0.5
		_SnowOpacity("Snow Opacity", Range (0.0, 1.0)) = 0.5

	//	Lux Wetness
		[Space(4)]
		[Header(Dynamic Wetness ______________________________________________________ )]
		[Space(4)]
		_WaterSlopeDamp("Water Slope Damp", Range (0.0, 1.0)) = 0.5
		[Toggle(LUX_PUDDLEMASKTILING)] _EnableIndependentPuddleMaskTiling("Enable independent Puddle Mask Tiling", Float) = 0.0
		_PuddleMaskTiling ("- Puddle Mask Tiling", Float) = 1

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
	
	SubShader 
	{
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="Opaque" "ForceNoShadowCasting"="True"}
		LOD 300
		Offset -1, -1


//	First pass blends albedo, specular color, normal and emission into the gbuffer based on the alpha mask
//	But it also influences the alpha channels of the given outputs:
//	diffuse.a 	= occlusion
//	specular.a 	= smoothness
//	normal.a 	= material ID
//	So we have to "correct" the alpha values in a second pass

		Blend SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
		Zwrite Off
		CGPROGRAM

		#pragma surface surf LuxStandardSpecular finalgbuffer:DecalFinalGBuffer vertex:vert exclude_path:forward exclude_path:prepass noshadow noforwardadd keepalpha
		#pragma target 3.0

		// Distinguish between simple parallax mapping and parallax occlusion mapping
		#pragma shader_feature _ EFFECT_BUMP
		#define _SNOW
		#define _WETNESS_FULL
		// Allow independed puddle mask tiling
//		#pragma shader_feature _ LUX_PUDDLEMASKTILING

		#include "../Lux Core/Lux Config.cginc"
		#include "../Lux Core/Lux Lighting/LuxStandardPBSLighting.cginc"
		#include "../Lux Core/Lux Setup/LuxStructs.cginc"
		#include "../Lux Core/Lux Utils/LuxUtils.cginc"
		#include "../Lux Core/Lux Features/LuxParallax.cginc"
		#include "../Lux Core/Lux Features/LuxDynamicWeather.cginc"

		struct Input {
			float4 lux_uv_MainTex;			// Here we have 2 channels left
			float3 viewDir;
			float3 worldNormal;
			float3 worldPos;
			INTERNAL_DATA
			// Lux
			float4 color : COLOR0;			// Important: declare color expilicitely as COLOR0
			float2 lux_DistanceScale;		// needed by various functions
			float2 lux_flowDirection;		// needed by Water_Flow			
		};

		half4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _SpecGlossMap;

		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input,o);
			// Lux
			o.lux_uv_MainTex.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
			// As decals most likely will have very simple geometry we have to fix Unity's dynamic batching bug
			LUX_FIX_BATCHINGBUG
	    	o.color = v.color;
	    	// Calc Tangent Space Rotation
			float3 binormal = cross( v.normal, v.tangent.xyz ) * v.tangent.w;
			float3x3 rotation = float3x3( v.tangent.xyz, binormal, v.normal.xyz );
			// Store FlowDirection
			o.lux_flowDirection = ( mul(rotation, mul(unity_WorldToObject, float4(0,1,0,0)).xyz) ).xy;
			// Store world position and distance to camera
			float3 worldPosition = mul(unity_ObjectToWorld, v.vertex);
			o.lux_DistanceScale.x = distance(_WorldSpaceCameraPos, worldPosition);
			o.lux_DistanceScale.y = length( mul(unity_ObjectToWorld, float4(1.0, 0.0, 0.0, 0.0)) );
		}


		void surf (Input IN, inout SurfaceOutputLuxStandardSpecular o) 
		{

			// Initialize the Lux fragment structure. Always do this first.
            // LUX_SETUP(float2 main UVs, float2 secondary UVs, half3 view direction in tangent space, float3 world position, float distance to camera, float2 flow direction, fixed4 vertex color)
			LUX_SETUP(IN.lux_uv_MainTex.xy, float2(0,0), IN.viewDir, IN.worldPos, IN.lux_DistanceScale.x, IN.lux_flowDirection, IN.color, IN.lux_DistanceScale.y)

			// We use the LUX_PARALLAX macro which handles PM or POM and sets lux.height, lux.puddleMaskValue and lux.mipmapValue
			LUX_PARALLAX

		//  ///////////////////////////////
        //  From now on we should use lux.finalUV (float4!) to do our texture lookups.

        	// As we want to to accumulate snow according to the per pixel world normal we have to get the per pixel normal in tangent space up front using extruded final uvs from LUX_PARALLAX
			o.Normal = UnpackNormal (tex2D (_BumpMap, lux.finalUV.xy));

			// Calculate Snow and Water Distrubution and get the refracted UVs in case water ripples and/or water flow are enabled
			// LUX_INIT_DYNAMICWEATHER(half puddle mask value, half snow mask value, half3 tangent space normal)
			LUX_INIT_DYNAMICWEATHER(1.0, 1.0, o.Normal)	


		//  ///////////////////////////////
        //  Do your regular stuff:
			fixed4 c = tex2D (_MainTex, lux.finalUV.xy) * _Color;
			o.Albedo = c.rgb;
			o.Alpha = c.a;
			o.Normal = UnpackNormal (tex2D (_BumpMap, lux.finalUV.xy));
			half4 specGloss = tex2D (_SpecGlossMap, lux.finalUV.xy);
			o.Specular = specGloss.rgb;

		//	Please note: We do not have to write to o.Smoothness or o.Occlusion in this pass as these would be coruppted anyway.
		//	We will do so in the 2nd pass

		//  ///////////////////////////////

			// Apply dynamic water and snow
			LUX_APPLY_DYNAMICWEATHER

		}

		void DecalFinalGBuffer (Input IN, SurfaceOutputLuxStandardSpecular o, inout half4 diffuse, inout half4 specSmoothness, inout half4 normal, inout half4 emission)
		{
			diffuse.a = o.Alpha;
			specSmoothness.a = o.Alpha;
			normal.a = o.Alpha;
			emission.a = o.Alpha;
		}

		ENDCG


//	Second Pass
// 	As the first pass blend gbuffer values according to the alpha mask alpha values in the gbuffer are not correct.
//	So the second pass fixes them.

		Blend One One
		ColorMask A

		CGPROGRAM

		#pragma surface surf LuxStandardSpecular finalgbuffer:DecalFinalGBuffer vertex:vert exclude_path:forward exclude_path:prepass noshadow noforwardadd keepalpha
		#pragma target 3.0

		// Distinguish between simple parallax mapping and parallax occlusion mapping
		#pragma shader_feature _ EFFECT_BUMP
		#define _SNOW
		// Second pass does not really need water flow or rain ripples - so we go with simple wetness
		#define _WETNESS_SIMPLE

		#include "../Lux Core/Lux Config.cginc"
		#include "../Lux Core/Lux Lighting/LuxStandardPBSLighting.cginc"
		#include "../Lux Core/Lux Setup/LuxStructs.cginc"
		#include "../Lux Core/Lux Utils/LuxUtils.cginc"
		#include "../Lux Core/Lux Features/LuxParallax.cginc"
		#include "../Lux Core/Lux Features/LuxDynamicWeather.cginc"

		struct Input {
			float4 lux_uv_MainTex;			// Here we have 2 channels left
			float3 viewDir;
			float3 worldNormal;
			float3 worldPos;
			INTERNAL_DATA
			// Lux
			float4 color : COLOR0;			// Important: declare color expilicitely as COLOR0
			float2 lux_DistanceScale;		// needed by various functions
			float2 lux_flowDirection;		// needed by Water_Flow			
		};

		half4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _SpecGlossMap;
		sampler2D _OcclusionMap;

		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input,o);
			// Lux
			o.lux_uv_MainTex.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
			// As decals most likely will have very simple geometry we have to fix Unity's dynamic batching bug
			LUX_FIX_BATCHINGBUG
	    	o.color = v.color;
	    	// Calc Tangent Space Rotation
			float3 binormal = cross( v.normal, v.tangent.xyz ) * v.tangent.w;
			float3x3 rotation = float3x3( v.tangent.xyz, binormal, v.normal.xyz );
			// Store FlowDirection
			o.lux_flowDirection = ( mul(rotation, mul(unity_WorldToObject, float4(0,1,0,0)).xyz) ).xy;
			// Store world position and distance to camera
			float3 worldPosition = mul(unity_ObjectToWorld, v.vertex);
			o.lux_DistanceScale.x = distance(_WorldSpaceCameraPos, worldPosition);
			o.lux_DistanceScale.y = length( mul(unity_ObjectToWorld, float4(1.0, 0.0, 0.0, 0.0)) );
		}

		void surf (Input IN, inout SurfaceOutputLuxStandardSpecular o) 
		{
			// Initialize the Lux fragment structure. Always do this first.
            // LUX_SETUP(float2 main UVs, float2 secondary UVs, half3 view direction in tangent space, float3 world position, float distance to camera, float2 flow direction, fixed4 vertex color)
			LUX_SETUP(IN.lux_uv_MainTex.xy, float2(0,0), IN.viewDir, IN.worldPos, IN.lux_DistanceScale.x, IN.lux_flowDirection, IN.color, IN.lux_DistanceScale.y)

			// We use the LUX_PARALLAX macro which handles PM or POM and sets lux.height, lux.puddleMaskValue and lux.mipmapValue
			LUX_PARALLAX

			// As we want to to accumulate snow according to the per pixel world normal we have to get the per pixel normal in tangent space up front using extruded final uvs from LUX_PARALLAX
			o.Normal = UnpackNormal (tex2D (_BumpMap, lux.finalUV.xy));

			// Calculate Snow and Water Distribution and get the refracted UVs in case water ripples and/or water flow are enabled
			// LUX_INIT_DYNAMICWEATHER(half puddle mask value, half snow mask value, half3 tangent space normal)
			LUX_INIT_DYNAMICWEATHER(1.0, 1.0, o.Normal)	

		//  ///////////////////////////////
        //  Do your regular stuff:
			fixed4 c = tex2D (_MainTex, lux.finalUV.xy) * _Color;
			o.Alpha = c.a;
		//	Important: We have to write to o.Normal as otherwise Parallax will be corrupted due to missing matrices
			o.Normal = half3(0,0,1);
			o.Smoothness = tex2D (_SpecGlossMap, lux.finalUV.xy).a;
			o.Occlusion = tex2D (_OcclusionMap, lux.finalUV.xy).g;
		//  ///////////////////////////////

			// Apply dynamic water and snow
			LUX_APPLY_DYNAMICWEATHER

		}

		void DecalFinalGBuffer (Input IN, SurfaceOutputLuxStandardSpecular o, inout half4 diffuse, inout half4 specSmoothness, inout half4 normal, inout half4 emission)
		{
			diffuse.a *= o.Alpha; 			// final Occlusion
			specSmoothness.a *= o.Alpha;	// final Smoothness
			normal.a = 1; 					// Material
		}

		ENDCG
	} 
}