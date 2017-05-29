Shader "Hidden/TerrainEngine/Details/WavingDoublePass" {
Properties {
	_WavingTint ("Fade Color", Color) = (.7,.6,.5, 0)
	_MainTex ("Base (RGB) Alpha (A)", 2D) = "white" {}
	_WaveAndDistance ("Wave and distance", Vector) = (12, 3.6, 1, 1)
	_Cutoff ("Cutoff", float) = 0.5
}

SubShader {
	Tags {
		"Queue" = "Geometry+200"
		"IgnoreProjector"="True"
		"RenderType"="Grass"
		"DisableBatching"="True"
	}
	Cull Off
	LOD 200
		
	CGPROGRAM
	#pragma surface surf LuxStandardSpecular vertex:WavingGrassVert addshadow
	#pragma target 3.0

	#if defined (UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD)
		#pragma multi_compile __ LUX_AREALIGHTS
	#endif

	#include "../Lux Core/Lux Config.cginc"
	#include "../Lux Core/Lux Lighting/LuxStandardPBSLighting.cginc"
	#include "TerrainEngine.cginc"

	sampler2D _MainTex;
	fixed _Cutoff;

	half _Lux_SnowAmount;
	fixed4 _Lux_SnowColor;
	sampler2D _Lux_SnowMask;
	float2 _Lux_SnowHeightParams;

	struct Input {
		float2 uv_MainTex;
		fixed4 color : COLOR;
		float3 worldPos;
	};

	void surf (Input IN, inout SurfaceOutputLuxStandardSpecular o) {
		fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * IN.color;
		o.Albedo = c.rgb;
		o.Alpha = c.a;
		clip (o.Alpha - _Cutoff);
		o.Alpha *= IN.color.a;
		
	//	Set lighting to "lambert" lighting to suppress all specular highlights from direct lighting
		o.Specular = 0.0;
		
	//	Add dynamic snow
		float2 dx = ddx(IN.uv_MainTex);
		float2 dy = ddy(IN.uv_MainTex);
		half snowMask = 0.0;

		UNITY_BRANCH
		if (_Lux_SnowAmount > 0.001) {

			half snowHeightFadeState = saturate((IN.worldPos.y - _Lux_SnowHeightParams.x) / _Lux_SnowHeightParams.y);
	        snowHeightFadeState = sqrt(snowHeightFadeState);

	        half snowAmount = _Lux_SnowAmount * snowHeightFadeState;
			snowMask = tex2Dgrad(_Lux_SnowMask, IN.uv_MainTex, dx, dy).b; // IN.uv_MainTex + IN.color.ra / <- would give us some animation...
			half snowFactor = snowAmount * IN.color.r;
			snowFactor *= snowFactor; // * snowHeightFadeState;
			snowMask = smoothstep(snowMask - snowAmount, snowMask, snowFactor );
			snowMask *= snowMask * snowHeightFadeState;
			o.Albedo = lerp(o.Albedo, _Lux_SnowColor.rgb, snowMask );
		}

	}
	ENDCG
	}
	Fallback Off
}
