// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

#ifndef UNITY_STANDARD_META_INCLUDED
#define UNITY_STANDARD_META_INCLUDED

// Functionality for Standard shader "meta" pass
// (extracts albedo/emission for lightmapper etc.)

// define meta pass before including other files; they have conditions
// on that in some places
#define UNITY_PASS_META 1

#include "UnityCG.cginc"
//#include "UnityStandardInput.cginc"
#include "../Lux Core/Lux Setup/LuxInputs.cginc"

//#include "../Lux Core/Lux Setup/LuxStructs.cginc"
//#include "../Lux Core/Lux Setup/LuxInputs.cginc"

#include "UnityMetaPass.cginc"
#include "Lux_StandardCore.cginc"

struct v2f_meta
{
	float4 uv		: TEXCOORD0;
	float4 pos		: SV_POSITION;
	fixed4 color	: COLOR0;
	half3 normalWorld : TEXCOORD1;
	float4 posWorld : TEXCOORD2;
	half3 viewDir	: TEXCOORD3;
};

// Lux: custom vertex input structure
v2f_meta vert_meta (LuxVertexInput v)
{
	v2f_meta o;
	o.pos = UnityMetaVertexPosition(v.vertex, v.uv1.xy, v.uv2.xy, unity_LightmapST, unity_DynamicLightmapST);
	//o.uv = TexCoords(v);
//	Lux
	o.uv = LuxTexCoords(v);
	o.color = v.color;
	o.normalWorld = UnityObjectToWorldNormal(v.normal);
	float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.posWorld.xyz = posWorld.xyz;
	o.posWorld.w = distance(_WorldSpaceCameraPos, posWorld);
	#if defined (_PARALLAXMAP)
		TANGENT_SPACE_ROTATION;
		o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
	#else
		o.viewDir = 0;
	#endif
	return o;
}

// Albedo for lightmapping should basically be diffuse color.
// But rough metals (black diffuse) still scatter quite a lot of light around, so
// we want to take some of that into account too.
half3 UnityLightmappingAlbedo (half3 diffuse, half3 specular, half oneMinusRoughness)
{
	half roughness = 1 - oneMinusRoughness;
	half3 res = diffuse;
	res += specular * roughness * roughness * 0.5;
	return res;
}

float4 frag_meta (v2f_meta i) : SV_Target
{
	// we're interested in diffuse & specular colors,
	// and surface roughness to produce final albedo.
//	FragmentCommonData s = UNITY_SETUP_BRDF_INPUT (i.uv);

	FRAGMENT_META_SETUP(s)

	UnityMetaInput o;
	UNITY_INITIALIZE_OUTPUT(UnityMetaInput, o);

	o.Albedo = UnityLightmappingAlbedo (s.diffColor, s.specColor, s.oneMinusRoughness);
	o.Emission = s.emission;

	return UnityMetaFragment(o);
}

#endif // UNITY_STANDARD_META_INCLUDED
