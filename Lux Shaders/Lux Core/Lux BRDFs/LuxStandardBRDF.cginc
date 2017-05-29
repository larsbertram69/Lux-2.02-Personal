#ifndef LUX_STANDARD_BRDF_INCLUDED
#define LUX_STANDARD_BRDF_INCLUDED

#include "UnityCG.cginc"
#include "UnityStandardConfig.cginc"
#include "UnityLightingCommon.cginc"

//	-------------------------------------------------------------------------------------
//	Standard BRDF for Unity > 5.3

	half4 Lux_BRDF1_PBS (half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
		half3 normal, half3 viewDir,
		// Lux
		half3 halfDir, half nh, half nv, half lv, half lh,
		half nl,
		half nl_diffuse,
		UnityLight light, UnityIndirect gi,
		// Lux
		half specularIntensity,
		half shadow)
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

		// Diffuse term
    	half diffuseTerm = DisneyDiffuse(nv, nl_diffuse, lh, perceptualRoughness) * nl_diffuse;
		
		#if UNITY_BRDF_GGX
		    half V = SmithJointGGXVisibilityTerm (nl, nv, roughness);
		    half D = GGXTerm (nh, roughness);
		#else
		    // Legacy
		    half V = SmithBeckmannVisibilityTerm (nl, nv, roughness);
		    half D = NDFBlinnPhongNormalizedTerm (nh, PerceptualRoughnessToSpecPower(perceptualRoughness));
		#endif

		half specularTerm = (V * D) * UNITY_PI;		

		#ifdef UNITY_COLORSPACE_GAMMA
			specularTerm = sqrt(max(1e-4h, specularTerm));
		#endif
		// specularTerm * nl can be NaN on Metal in some cases, use max() to make sure it's a sane value
    	specularTerm = max(0, specularTerm * nl) * specularIntensity;
		
		#if defined(_SPECULARHIGHLIGHTS_OFF)
    		specularTerm = 0.0;
		#endif

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

		return half4(color, 1.0h);
	}
#endif // LUX_STANDARD_BRDF_INCLUDED