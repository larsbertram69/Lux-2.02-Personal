Shader "Lux/Standard Lighting/Simple Metallic" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf LuxStandardSpecular vertex:vert fullforwardshadows
		#pragma target 3.0
		
		#if defined (UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD)
			#pragma multi_compile __ LUX_AREALIGHTS
		#endif

		#include "../Lux Core/Lux Config.cginc"
		#include "../Lux Core/Lux Lighting/LuxStandardPBSLighting.cginc"
		#include "../Lux Core/Lux Setup/LuxStructs.cginc"
		#include "../Lux Core/Lux Utils/LuxUtils.cginc"
		#include "../Lux Core/Lux Features/LuxSpecularAntiAliasing.cginc"

		sampler2D _MainTex;

		struct Input {
			float2 lux_uv_MainTex;			// Important: we must not use standard uv_MainTex as we need access to _MainTex_ST
			float3 worldNormal;
			INTERNAL_DATA 					// Needed by "LUX_SPECULARANITALIASING" 
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input,o);
			// Lux
			o.lux_uv_MainTex.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
		}

		void surf (Input IN, inout SurfaceOutputLuxStandardSpecular o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.lux_uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;

			o.Normal = half3(0,0,1); // We have to write to o.Normal

			// As Lux uses the specular worklflow we have to convert from metallic to specular.
			// Do this before calling any further Lux macros which write to the final specular output structure.
			LUX_METALLIC_TO_SPECULAR

			LUX_SPECULARANITALIASING 
		}
		ENDCG
	}
	FallBack "Diffuse"
}
