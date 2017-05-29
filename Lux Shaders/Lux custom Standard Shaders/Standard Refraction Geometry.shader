Shader "Lux/Standard Lighting/Refractive/Geometry Refraction" {
	Properties {

	//	Lux primary texture set
		[Space(4)]
		[Header(Primary Texture Set _____________________________________________________ )]
		[Space(4)]
		_Color ("Color", Color) = (1,1,1,1)
		[Space(4)]
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_SpecColor("Specular", Color) = (.2,.2,.2,1)
		[NoScaleOffset] _BumpMap("Normalmap", 2D) = "bump" {}

		[Space(4)]
		[Header(Refraction Settings _____________________________________________________ )]
		[Space(4)]
		_Refraction("Refraction", Range(0,128)) = 10
		_GeoInfluence("- Geometry", Range(0,1)) = 1
		_BumpInfluence("- Normalmap", Range(0,1)) = 1

		[Space(4)]
		_FresnelFactor("Fresnel Factor", Range(0.1, 5.0)) = 5
	}

	SubShader {
	//	In order to be able to use Grabpass the shader has to be "transparent"
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
		LOD 200

	//	We declare a specific "_GrabTexture" which can be used by other objects or materials as well
		GrabPass{ "_GrabTexture" }
	//	GrabPass{ }
		
		CGPROGRAM
		#pragma surface surf LuxStandardSpecular fullforwardshadows vertex:vert
		#pragma target 3.0

		#if defined (UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD)
			#pragma multi_compile __ LUX_AREALIGHTS
		#endif

		#include "../Lux Core/Lux Lighting/LuxStandardPBSLighting.cginc"
		#include "../Lux Core/Lux Setup/LuxStructs.cginc"
		
		struct Input {
			float2 lux_uv_MainTex;			// Important: we must not use standard uv_MainTex as we need access to _MainTex_ST
			float4 grabUV;
			float4 viewSpaceNormal_ProjPos; // We have to combine the projected normal and ProjPos.z

			float3 viewDir;
			float3 worldNormal;
			float3 worldPos;
			INTERNAL_DATA
		};

		
		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _BumpMap;
		half _Glossiness;

		sampler2D _GrabTexture;
		float4 _GrabTexture_TexelSize;
		sampler2D _CameraDepthTexture;
		
		half _Refraction;
		half _GeoInfluence;
		half _BumpInfluence;
		half _FresnelFactor;

		void vert(inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.lux_uv_MainTex.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
			float4 hpos = UnityObjectToClipPos(v.vertex);
			o.grabUV = ComputeGrabScreenPos(hpos);
			float3 worldPosProjPos = ComputeScreenPos(hpos);
			COMPUTE_EYEDEPTH(worldPosProjPos.z);
			// transform the normal into view space
			o.viewSpaceNormal_ProjPos.xyz = UnityObjectToClipPos(float4(v.normal, 0)).xyz; //mul((float3x3)UNITY_MATRIX_MVP, v.normal);
			o.viewSpaceNormal_ProjPos.w = worldPosProjPos.z;
		}

		void surf (Input IN, inout SurfaceOutputLuxStandardSpecular o) {
			fixed4 c = tex2D (_MainTex, IN.lux_uv_MainTex.xy) * _Color;
			o.Albedo = _Color.rgb * _Color.a;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
			o.Specular = _SpecColor;

			half4 normalSample = tex2D(_BumpMap, IN.lux_uv_MainTex.xy);
			o.Normal = UnpackNormal(normalSample);

			float NdotV = dot(normalize(IN.viewDir), float3(0, 0, 1));
			
			float4 distortedGrabUVs = IN.grabUV;
			half3 viewSpaceNormal = normalize(IN.viewSpaceNormal_ProjPos.xyz) * ( 1.0 - NdotV*NdotV);
			viewSpaceNormal = viewSpaceNormal * _GeoInfluence + o.Normal * _BumpInfluence;
			
			half2 offset = viewSpaceNormal.xy * _GrabTexture_TexelSize.xy;
			distortedGrabUVs.xy = IN.grabUV.xy + offset * (_Refraction * ( 
				#if defined(UNITY_REVERSED_Z)
					1.0 - 
				#endif
				IN.grabUV.z));

		//	Do not grab pixels from foreground	
			float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(distortedGrabUVs)));
			if (sceneZ <= (IN.viewSpaceNormal_ProjPos.w)) {
				distortedGrabUVs = IN.grabUV;
			}
			float fresnel = pow(1.0 - max(0.0, dot(o.Normal, normalize(IN.viewDir))), _FresnelFactor);
			half4 background = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(distortedGrabUVs));
		
		//	Energy Conservation
			o.Emission += background * (1.0 - fresnel) * (1.0 - _SpecColor) * lerp(half3(1.0, 1.0, 1.0), o.Albedo, c.a); // lerp fixed for ps4
		}
		ENDCG


		// ------------------------------------------------------------------
		//	As the shader uses alpha blending and we want to have "transparent shadows" we will have to declare our own shadow caster pass

		// ------------------------------------------------------------------
		//  Shadow rendering pass

		Pass {
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			
			ZWrite On ZTest LEqual
		//	Culling must match the culling used by the shader
			Cull Back

			CGPROGRAM
			#pragma target 3.0
			#pragma exclude_renderers gles
			
		//	Next we will have to set up all keywords so they match the keywords used by the surface shader.
		//	As we use physically based alpha blending.
			#define _ALPHAPREMULTIPLY_ON

			#pragma multi_compile_shadowcaster

			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster

		//	Simply include the "LuxStandardShadow.cginc" which handles everything else.
			#include "../Lux Standard Shader/LuxStandardShadow.cginc"

			ENDCG
		}
	}
}
