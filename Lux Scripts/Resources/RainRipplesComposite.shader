Shader "Hidden/Lux RainRipplesComposite"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Lux_RainIntensity ("Rain Intensity", Range(0.0, 1)) = 0.5
		_Lux_RippleAnimSpeed ("Ripple Anim Speed", Range(0.0, 1)) = 0.5
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
            #pragma fragment frag
			
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;

			half3 _Lux_RainfallRainSnowIntensity;
			half _Lux_RippleAnimSpeed;

			//  Samples and returns animated ripple normals 
		    inline half3 ComputeRipple(float2 uv, float CurrentTime, half Weight)
		    {
				float4 Ripple = tex2D(_MainTex, uv);
				Ripple.yz = Ripple.yz * 2 - 1; // Decompress Normal
				half DropFrac = frac(Ripple.w + CurrentTime); // Apply time shift
				half TimeFrac = DropFrac - 1.0f + Ripple.x;
				half DropFactor = saturate(0.2f + Weight * 0.8f - DropFrac);
				half FinalFactor = DropFactor * Ripple.x * sin(clamp(TimeFrac * 9.0f, 0.0f, 3.0f) * UNITY_PI);
		        return half3(Ripple.yz * FinalFactor, 1);
		    }

			
			fixed4 frag(v2f_img i) : SV_Target
			{
				
				half4 Weights = _Lux_RainfallRainSnowIntensity.y - half4(0, 0.25, 0.5, 0.75);
				Weights = saturate(Weights * 4);
				
				float4 TimeMul = float4(1.0f, 0.85f, 0.93f, 1.13f); 
				float4 TimeAdd = float4(0.0f, 0.2f, 0.45f, 0.7f);
				float4 Times = (_Time.y * _Lux_RippleAnimSpeed * TimeMul + TimeAdd) * 1.6f;
				Times = frac(Times);

				half3 Ripple1 = ComputeRipple( i.uv + float2( 0.25f,0.0f), Times.x, Weights.x);
        		half3 Ripple2 = ComputeRipple( i.uv + float2(-0.55f,0.3f), Times.y, Weights.y);
        		half3 Ripple3 = ComputeRipple( i.uv + float2(0.6f, 0.85f), Times.z, Weights.z);
        		half3 Ripple4 = ComputeRipple( i.uv + float2(0.5f,-0.75f), Times.w, Weights.w);

        		float4 Z = lerp(1, float4(Ripple1.z, Ripple2.z, Ripple3.z, Ripple4.z), Weights);

        		half3 rippleNormal = normalize( half3(
        			Weights.x * Ripple1.xy + 
        			Weights.y * Ripple2.xy +
        			Weights.z * Ripple3.xy + 
                    Weights.w * Ripple4.xy, 
                    Z.x * Z.y * Z.z * Z.w) );

				return fixed4(rippleNormal * 0.5 + 0.5, 1);
			}
			ENDCG
		}
	}
}
