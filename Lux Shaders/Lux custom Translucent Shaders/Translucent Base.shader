Shader "Lux/Translucent Lighting/Base" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_SpecColor("Specular Color", Color) = (0.2,0.2,0.2)

		// Lux translucent lighting properties
		[Space(4)]
		[Header(Translucent Lighting ______________________________________________________ )]
		[Space(4)]
		[NoScaleOffset] _TranslucencyOcclusion ("Lokal Thickness (B) Occlusion (G)", 2D) = "white" {}
		_TranslucencyStrength ("Translucency Strength", Range(0,1)) = 1
		_ScatteringPower ("Scattering Power", Range(0,8)) = 4

	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf LuxTranslucentSpecular fullforwardshadows addshadow
		#pragma multi_compile __ LUX_AREALIGHTS
		#include "../Lux Core/Lux Config.cginc"
		#include "../Lux Core/Lux Lighting/LuxTranslucentPBSLighting.cginc"
		#pragma target 3.0

		struct Input {
			float2 uv_MainTex;		// As we do not include "LuxStructs.cginc" and "LuxParallax.cginc" we can use "uv_MainTex"
		};

		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _TranslucencyOcclusion;
		half _Glossiness;
		fixed4 _Color;

		void surf (Input IN, inout SurfaceOutputLuxTranslucentSpecular o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Specular = _SpecColor;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
			o.Normal = UnpackNormal( tex2D(_BumpMap, IN.uv_MainTex));

		//	Lux: Occlusion and Translucency are stored in a combined map
			half4 transOcclusion = tex2D(_TranslucencyOcclusion, IN.uv_MainTex);
			o.Occlusion = transOcclusion.g;
		//	Lux: Write translucent lighting parameters to the output struct 
			o.Translucency = transOcclusion.b * _TranslucencyStrength;
			o.ScatteringPower = _ScatteringPower;
		}
		ENDCG
	}
//	FallBack "Diffuse"
}
