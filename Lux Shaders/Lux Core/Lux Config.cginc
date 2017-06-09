#ifndef LUX_CONFIG_INCLUDED
#define LUX_CONFIG_INCLUDED

	#if defined (LUX_STANDARDSHADER)
		// Define FogMode (Forward only)
		// #define FOG_LINEAR
		// #define FOG_EXP
		#define FOG_EXP2
	#endif

	// Enable Lazarov Environmental BRDF / Set it to 0 in case you want to use Unity's built in one.
	// Then reimport all shaders.
	#ifndef LUX_LAZAROV_ENVIRONMENTAL_BRDF
		#define LUX_LAZAROV_ENVIRONMENTAL_BRDF 1
	#endif

	// Enable HQ height map sampling in POM function / Set it to 1 to use tex2Dgrad, set it to 0 in case you want to use the faster tex2Dlod instead.
	// Then reimport all shaders.
	#ifndef LUX_POM_USES_TEX2DGRAD 
		#define LUX_POM_USES_TEX2DGRAD 1
	#endif

	// Enable specular anti aliasing in deferred rendering / Set it to 1 to enable it, set it to o to disbale it (which in fact is a bit faster).
	// Then reimport all shaders.
	#ifndef LUX_SPEC_ANITALIASING
		#define LUX_SPEC_ANITALIASING 1
		// Parameter definitions which might be tweaked:
		#define SCREEN_SPACE_VARIANCE 1.0
		#define SAATHRESHOLD 0.1
	#endif

	// Enable Horizon Occlusion / Set it to 1 to enable it, set it to o to disbale it (which in fact is a bit faster). 
	#ifndef LUX_HORIZON_OCCLUSION
		#define LUX_HORIZON_OCCLUSION 1
		// Parameter definitions which might be tweaked:
		#define HORIZON_FADE 1.3
	#endif


#endif // LUX_CONFIG_INCLUDED