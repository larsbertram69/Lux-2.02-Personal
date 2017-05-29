#ifndef LUX_ANISO_BRDF_INCLUDED
#define LUX_ANISO_BRDF_INCLUDED

#include "UnityCG.cginc"
#include "UnityStandardConfig.cginc"
#include "UnityLightingCommon.cginc"

#define LUX_INV_PI 0.31830988618379f

//	http://blog.selfshadow.com/publications/s2013-shading-course/rad/s2013_pbs_rad_notes.pdf
float D_GGXAniso(float TdotH, float BdotH, float mt, float mb, float nh) {
	float d = TdotH * TdotH / (mt * mt) + BdotH * BdotH / (mb * mb) + nh * nh;
	return (1.0 / ( UNITY_PI * mt*mb * d*d));
}

// Ref: https://cedec.cesa.or.jp/2015/session/ENG/14698.html The Rendering Materials of Far Cry 4
float Lux_SmithJointGGXAniso(float TdotV, float BdotV, float NdotV, float TdotL, float BdotL, float NdotL, float roughnessT, float roughnessB) {
    // Expects roughnessT and roughnessB to be squared.
    float lambdaV = NdotL * sqrt(roughnessT * TdotV * TdotV + roughnessB * BdotV * BdotV + NdotV * NdotV);
    float lambdaL = NdotV * sqrt(roughnessT * TdotL * TdotL + roughnessB * BdotL * BdotL + NdotL * NdotL);
    // As it might error on dx11 using forward lighting:
    #if defined (UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD)
    	return 0.5 / max(1e-5f, (lambdaV + lambdaL) );
    #else
    	return 0.5 / (lambdaV + lambdaL);
    #endif
}


//	-------------------------------------------------------------------------------------

	half4 Lux_ANISO_BRDF (half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness, half3 normal, half3 viewDir,
		half3 halfDir, half nh, half nv, half lv, half lh,
		float3 T,
		float3 B,
		half RoughnessT,
		half RoughnessB,
		half nl,
		half nl_diffuse,
		UnityLight light, UnityIndirect gi, half specularIntensity, half shadow)
	{

		light.color *= shadow;

		half perceptualRoughness = SmoothnessToPerceptualRoughness (smoothness);
		half roughness = PerceptualRoughnessToRoughness(perceptualRoughness);

		// BRDF expects all other inputs to be calculated up front!
		#if defined (UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD)
			halfDir = Unity_SafeNormalize (light.dir + viewDir);
			nh = saturate(dot(normal, halfDir));
			nv = abs(dot(normal, viewDir)); 
			lv = saturate(dot(light.dir, viewDir));
			lh = saturate(dot(light.dir, halfDir));
		#endif
/*
RoughnessT = 0.45;
RoughnessB = 0.45;
*/
		float mt = RoughnessT * RoughnessT;
		float mb = RoughnessB * RoughnessB;
		float TdotH = dot(T, halfDir );
		float BdotH = dot(B, halfDir );
		float TdotV = dot(T, viewDir);
		float BdotV = dot(B, viewDir);
		float TdotL = dot(T, light.dir);
		float BdotL = dot(B, light.dir);

		half D = D_GGXAniso(TdotH, BdotH, mt, mb, nh);
		half V = Lux_SmithJointGGXAniso( TdotV, BdotV, nv, TdotL, BdotL, nl, mt, mb);

		// Diffuse term 
		half3 diffuseTerm = DisneyDiffuse(nv, nl_diffuse, lh, perceptualRoughness) * nl_diffuse;

		half specularTerm = (V * D) * UNITY_PI;		

		#ifdef UNITY_COLORSPACE_GAMMA
			specularTerm = sqrt(max(1e-4h, specularTerm));
		#endif
		// specularTerm * nl can be NaN on Metal in some cases, use max() to make sure it's a sane value
    	specularTerm = max(0, specularTerm * nl) * specularIntensity;

		#if LUX_LAZAROV_ENVIRONMENTAL_BRDF
			const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
			const half4 c1 = { 1, 0.0425, 1.04, -0.04 };
			half4 r = perceptualRoughness * c0 + c1;
			half a004 = min( r.x * r.x, exp2( -9.28 * nv ) ) * r.x + r.y;
			half2 AB = half2( -1.04, 1.04 ) * a004 + r.zw;
			half3 F_L = specColor * AB.x + AB.y;
		#else
	    	half surfaceReduction;
			#ifdef UNITY_COLORSPACE_GAMMA
	        	surfaceReduction = 1.0-0.28*roughness*perceptualRoughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
			#else
	        	surfaceReduction = 1.0 / (roughness*roughness + 1.0);           // fade \in [0.5;1]
			#endif
			half grazingTerm = saturate(smoothness + (1-oneMinusReflectivity));
		#endif

		half3 color = diffColor * (gi.diffuse + light.color * diffuseTerm)
					+ specularTerm * light.color * FresnelTerm (specColor, lh)
				#if LUX_LAZAROV_ENVIRONMENTAL_BRDF
					+ gi.specular * F_L;
				#else
					+ surfaceReduction * gi.specular * FresnelLerp(specColor, grazingTerm, nv);
				#endif

		return half4(color, 1);
	}
#endif // LUX_ANISO_BRDF_INCLUDED