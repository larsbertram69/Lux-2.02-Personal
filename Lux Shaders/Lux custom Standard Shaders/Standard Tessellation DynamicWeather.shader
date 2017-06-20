    Shader "Lux/Standard Lighting/Tessellation/Dynamic Weather" {
        Properties {
            
        //  Lux primary texture set
            [Space(4)]
            [Header(Primary Texture Set _____________________________________________________ )]
            [Space(4)]
            _Color ("Color", Color) = (1,1,1,1)
            [Space(4)]
            _MainTex ("Albedo (RGB)", 2D) = "white" {}
            [NoScaleOffset] _BumpMap ("Normalmap", 2D) = "bump" {}
            [NoScaleOffset] _SpecGlossMap("Specular", 2D) = "black" {}

        //  Lux tessellation properties
            [Space(4)]
            [Header(Tessellation ____________________________________________________________ )]
            [Space(4)]
            [NoScaleOffset] _ParallaxMap ("Height (G) (Mix Mapping: Height2 (A) Mix Map (B)) PuddleMask (R)", 2D) = "white" {}
            // As we can't access MainTex_ST (Tiling) in surface shaders
            [Lux_TextureTilingDrawer] _ParallaxToBaseRatio ("MainTex Tiling", Vector) = (1,1,0,0)
            _ParallaxTiling ("Mask Tiling", Float) = 1
            _Parallax ("Height Scale", Range (0.0, 1.0)) = 0.02
            [Space(4)]
            _EdgeLength ("Edge Length Limit", Range(1, 40.0)) = 5
            _MinDist ("Near Distance", float) = 7
            _MaxDist ("Far Distance", float) = 25
            _Phong ("Phong Smoothing", Range(0, 20.0)) = 1
            // _Tess ("Tessellation", Range(1,32)) = 4
            
        //  Lux dynamic weather properties

        //  Lux Snow
            [Space(4)]
            [Header(Dynamic Snow ______________________________________________________ )]
            [Space(4)]
            [Enum(Local Space,0,World Space,1)] _SnowMapping ("Snow Mapping", Float) = 0
            [Lux_HelpDrawer] _HelpSnowMapping ("If 'Snow Mapping' is set to 'World Space‘ tiling and strength values have to be set up globally. You also should check 'UV Ratio' and 'Scale' in case you use POM.", Float) = 0
            [Space(4)]
            _SnowSlopeDamp("Snow Slope Damp", Range (0.0, 8.0)) = 1.0
            [Lux_SnowAccumulationDrawer] _SnowAccumulation("Snow Accumulation", Vector) = (0,1,0,0)
            [Space(4)]
            [Lux_TextureTilingDrawer] _SnowTiling ("Snow Tiling", Vector) = (2,2,0,0)
            _SnowNormalStrength ("Snow Normal Strength", Range (0.0, 2.0)) = 1.0
            [Lux_TextureTilingDrawer] _SnowMaskTiling ("Snow Mask Tiling", Vector) = (0.3,0.3,0,0)
            [Lux_TextureTilingDrawer] _SnowDetailTiling ("Snow Detail Tiling", Vector) = (4.0,4.0,0,0)
            _SnowDetailStrength ("Snow Detail Strength", Range (0.0, 1.0)) = 0.5
            _SnowOpacity("Snow Opacity", Range (0.0, 1.0)) = 0.5

        //  Lux Wetness
            [Space(4)]
            [Header(Dynamic Wetness ______________________________________________________ )]
            [Space(4)]
            _WaterSlopeDamp("Water Slope Damp", Range (0.0, 1.0)) = 0.5
            [Toggle(LUX_PUDDLEMASKTILING)] _EnableIndependentPuddleMaskTiling("Enable independent Puddle Mask Tiling", Float) = 0.0
            _PuddleMaskTiling ("- Puddle Mask Tiling", Float) = 1

            [Header(Texture Set 1)]
            _WaterColor("Water Color (RGB) Opacity (A)", Color) = (0,0,0,0)
            [Lux_WaterAccumulationDrawer] _WaterAccumulationCracksPuddles("Water Accumulation in Cracks and Puddles", Vector) = (0,1,0,1)
            // Mix mapping enabled so we need a 2nd Input
            [Header(Texture Set 2)]
            _WaterColor2("Water Color (RGB) Opacity (A)", Color) = (0,0,0,0)
            [Lux_WaterAccumulationDrawer] _WaterAccumulationCracksPuddles2("Water Accumulation in Cracks and Puddles", Vector) = (0,1,0,1)
            
            [Space(4)]
            _Lux_FlowNormalTiling("Flow Normal Tiling", Float) = 2.0
            _Lux_FlowSpeed("Flow Speed", Range (0.0, 2.0)) = 0.05
            _Lux_FlowInterval("Flow Interval", Range (0.0, 8.0)) = 1
            _Lux_FlowRefraction("Flow Refraction", Range (0.0, 0.1)) = 0.02
            _Lux_FlowNormalStrength("Flow Normal Strength", Range (0.0, 2.0)) = 1.0

        //  Lux diffuse Scattering properties
            [Header(Diffuse Scattering Texture Set 1 ______________________________________ )]
            [Space(4)]
            _DiffuseScatteringCol("Diffuse Scattering Color", Color) = (0,0,0,1)
            _DiffuseScatteringBias("Scatter Bias", Range(0.0, 0.5)) = 0.0
            _DiffuseScatteringContraction("Scatter Contraction", Range(1.0, 10.0)) = 8.0

        }

        SubShader {
            Tags { "RenderType"="Opaque" }
            LOD 300
            
            CGPROGRAM
            // As we aim for a minimal appdata struct lightmapping (including gi) is not supported, thus: nolightmap
            #pragma surface surf LuxStandardSpecular addshadow fullforwardshadows vertex:LuxTessellationDisplace nolightmap tessellate:LuxTessEdge tessphong:_Phong 
            #pragma target 4.6

            #if defined (UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD)
                #pragma multi_compile __ LUX_AREALIGHTS
            #endif
            
            #include "Tessellation.cginc"

            #define _PARALLAXMAP
            #define TESSELLATION_ON
            #define _SNOW
            #define _WETNESS_FULL

            // Enable independed puddle mask tiling
            #pragma shader_feature _ LUX_PUDDLEMASKTILING

        //  Important: We have to declare the appdata struct before doing the includes!
            struct appdata {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
                // Minimal struct, so lightmapping is not supported in this example
                // float4 texcoord1 : TEXCOORD1;
                // float2 texcoord2 : TEXCOORD2;
                fixed4 color : COLOR0;
            };

            #include "../Lux Core/Lux Config.cginc"
            #include "../Lux Core/Lux Lighting/LuxStandardPBSLighting.cginc"
            #include "../Lux Core/Lux Setup/LuxStructs.cginc"
            #include "../Lux Core/Lux Utils/LuxUtils.cginc"
            #include "../Lux Core/Lux Features/LuxParallax.cginc"
            #include "../Lux Core/Lux Features/LuxDynamicWeather.cginc"
            #include "../Lux Core/Lux Features/LuxDiffuseScattering.cginc"
            #include "../Lux Core/Lux Features/LuxTessellation.cginc"

            struct Input {
                float2 uv_MainTex;
                float3 viewDir;
                float3 worldPos;
                float3 worldNormal;
                INTERNAL_DATA
                // Lux
                fixed4 color : COLOR0;  // Important: declare color expilicitely as COLOR0 
            };

            // As we only use one texture set we will stay within the limit of 16 samplers and do not have to use UNITY_DECLARE_TEX2D etc.
            sampler2D _MainTex;
            sampler2D _BumpMap;
            sampler2D _SpecGlossMap;
            fixed4 _Color;
  
            void surf (Input IN, inout SurfaceOutputLuxStandardSpecular o) {
                
                // Initialize the Lux fragment structure. Always do this first:
                // LUX_SETUP(float2 main UVs, float2 secondary UVs, half3 view direction in tangent space, float3 world position, float distance to camera, float2 flow direction, fixed4 vertex color, float object scale)
                // As we can't calculate the distance to camera in the vertex shader we have to do it in the surface shader
                LUX_SETUP(IN.uv_MainTex, float2(0,0), IN.viewDir, IN.worldPos, distance(_WorldSpaceCameraPos, IN.worldPos), IN.color.rg, IN.color, 1.0)
                
                // We might set lux.height, lux.puddleMaskValue and lux.mipmapValue manually:
                // half4 heightsnowmask = tex2D(_ParallaxMap, IN.uv_MainTex);
                // LUX_SET_HEIGHT( heightsnowmask.g )
                // lux.puddleMaskValue = heightsnowmask.r

                // Or simply use the LUX_PARALLAX macro which only sets lux.height, lux.puddleMaskValue and lux.mipmapValue in this case
                LUX_PARALLAX

            //  ///////////////////////////////
            //  From now on we should use lux.finalUV (float4!) to do our texture lookups.

                // In case we have enabled independent pauddle mask tiling we have to do a 2nd texture lookup.
                #if defined (LUX_PUDDLEMASKTILING)
                    lux.puddleMaskValue = tex2D(_ParallaxMap, lux.finalUV.xy * _PuddleMaskTiling).r;
                #endif

                // As we want to to accumulate snow according to the per pixel world normal we have to get the per pixel normal in tangent space up front using extruded final uvs from LUX_PARALLAX
                o.Normal = UnpackNormal(tex2D(_BumpMap, lux.finalUV.xy));
                
                // Now we can calculate the snow and water distribution:
                // LUX_INIT_DYNAMICWEATHER(half puddle mask value, half snow mask value, half3 tangent space normal)
                LUX_INIT_DYNAMICWEATHER(lux.puddleMaskValue, 1, o.Normal)

            //  ///////////////////////////////
            //  Do your regular stuff:
                half4 c = tex2D(_MainTex, lux.finalUV.xy) * _Color;
                o.Albedo = c.rgb;
                half4 specGloss = tex2D(_SpecGlossMap, lux.finalUV.xy);
                o.Specular = specGloss.rgb;
                o.Smoothness = specGloss.a;
                o.Normal = UnpackNormal(tex2D(_BumpMap, lux.finalUV.xy));
                o.Alpha = c.a;
            //  ///////////////////////////////

                // Finally apply dynamic water and snow
                LUX_APPLY_DYNAMICWEATHER
                // Then add diffuse scattering
                LUX_DIFFUSESCATTERING(o.Albedo, o.Normal, IN.viewDir)
            }
            ENDCG
        }
        FallBack "Diffuse"
    }