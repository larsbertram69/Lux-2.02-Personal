#ifndef LUX_PARALLAX_INCLUDED
#define LUX_PARALLAX_INCLUDED

//  Additional Inputs ------------------------------------------------------------------

half _ParallaxTiling;
float4 _UVRatio;

#ifndef LUX_STANDARD_CORE_INCLUDED
    float _Parallax;
    sampler2D _ParallaxMap;
    float4 _ParallaxMap_ST;
    #if defined (EFFECT_BUMP)
        float _LinearSteps;
    #endif
#endif


float2 LuxParallaxOffset1Step (float h, float height, float3 viewDir)
{
/*    h = h * height - height/2.0;
    half3 v = viewDir; //already normalized // normalize(viewDir);
    v.z += 0.42;
    return h * (v.xy / v.z);*/
//  Lets push down the pixels
    h = (1.0f- h) * height;
    float3 v = half3(-viewDir.xy, 1.0001f + viewDir.z);
    return h * (v.xy / v.z);
}

//  Get parallax offset and handle mix mapping as well as setting height ---------------
void Lux_Parallax (inout LuxFragment lux) {

    #if defined (LUX_STANDARD_CORE_INCLUDED) && (!defined(_PARALLAXMAP) || (SHADER_TARGET < 30))
        // SM20: instruction count limitation
        // SM20: no parallax
        lux.extrudedUV = lux.extrudedUV;
    
    #else

        lux.offsetWaterInWS = LuxParallaxOffset1Step (0, _Parallax, lux.eyeVecTangent);

    //  Regular Detail Blending
        #if !defined(GEOM_TYPE_BRANCH_DETAIL)
            half2 heightAndPuddleMask = tex2D (_ParallaxMap, lux.extrudedUV.xy * _ParallaxTiling).gr;
            lux.height = heightAndPuddleMask.x;
            #if !defined(TESSELLATION_ON)

                float4 uvScaled = lux.extrudedUV; // * _ParallaxTiling;

                #if defined (_DETAIL_MULX2)
                    // As we might have to deal with two different tilings here, we have to calculate the ratio between base and detail texture tiling and use it when offsetting.
                    float2 BaseToDetailFactor = lux.extrudedUV.zw/lux.extrudedUV.xy;
                #else
                    float2 BaseToDetailFactor = 1;
                #endif
                    lux.offset = LuxParallaxOffset1Step (lux.height, _Parallax, lux.eyeVecTangent);
                    lux.offset *= _MainTex_ST.xy / _UVRatio.xyxy;
                    lux.extrudedUV += float4(lux.offset, lux.offset * BaseToDetailFactor) / _ParallaxTiling;

                //  2nd read
                    heightAndPuddleMask = tex2D (_ParallaxMap, lux.extrudedUV.xy).gr;
                    float2 tempOffset = LuxParallaxOffset1Step (lux.height, _Parallax, lux.eyeVecTangent);
                    tempOffset *= _MainTex_ST.xyxy / _UVRatio.xyxy;

                //  blend both samples
                    lux.offset = (lux.offset + tempOffset) * 0.5;
                    lux.extrudedUV = uvScaled + float4(lux.offset, lux.offset) / _ParallaxTiling;

                    lux.height = (lux.height + heightAndPuddleMask.x) * 0.5;

                //  Get final height
                //  Why?
                /*
                #if defined (_WETNESS_SIMPLE) || defined (_WETNESS_RIPPLES) || defined (_WETNESS_FLOW) || defined (_WETNESS_FULL)
                    heightAndPuddleMask = tex2D (_ParallaxMap, lux.extrudedUV * _ParallaxTiling).gr;
                    lux.height = heightAndPuddleMask.x;                    
                #endif
                */
            #endif
            lux.puddleMaskValue = heightAndPuddleMask.y;
        
    //  Mix Mapping
        #else
            half3 h;
            float4 uvScaled = lux.extrudedUV; // * _ParallaxTiling;
            // Safe one texture lookup by using the already sampled height
            #ifdef FIRSTHEIGHT_READ
                h.x = height;
            #else
            // Read height, mask and puddle mask
                 h = tex2D (_ParallaxMap, uvScaled.xy).gbr;
            #endif
            // If called from surface shader mixmapping is not set up
//            #if !defined (LUX_STANDARD_CORE_INCLUDED)
//                lux.mixmapValue = half2(h.y, 1.0 - h.y);
//            #endif

        //  Only if we do not use vertex color red to define mixmapping
            #if defined(GEOM_TYPE_LEAF)
                half maskval = tex2D(_ParallaxMap, lux.extrudedUV.xy * _ParallaxTiling).b;
                lux.mixmapValue = half2(maskval, 1.0 - maskval);
            #else
                lux.mixmapValue = half2(lux.vertexColor.r, 1.0 - lux.vertexColor.r); 
            #endif

            h.y = tex2D (_ParallaxMap, uvScaled.zw).a;
            h.xy = saturate(h.xy + 0.001);
            // blend according to height and mixmapValue
            float2 blendValue = lux.mixmapValue;
            lux.mixmapValue *= float2( dot(h.x, lux.mixmapValue.x), dot(h.y, lux.mixmapValue.y));
            // sharpen mask
            lux.mixmapValue *= lux.mixmapValue;
            lux.mixmapValue *= lux.mixmapValue;
            lux.mixmapValue = lux.mixmapValue / dot(lux.mixmapValue, 1);
            lux.height = dot(lux.mixmapValue, h.xy);
            

            #if !defined(TESSELLATION_ON)
                lux.offset = LuxParallaxOffset1Step (lux.height, _Parallax, lux.eyeVecTangent);
                lux.offset *= _MainTex_ST.xyxy / _UVRatio.xyxy;
                lux.extrudedUV += float4(lux.offset, lux.offset) / _ParallaxTiling;

            //  2nd read
                h = tex2D (_ParallaxMap, lux.extrudedUV.xy).gbr;
                h.y = tex2D (_ParallaxMap, lux.extrudedUV.zw).a;
                h.xy = saturate(h.xy + 0.001);

                #if defined(GEOM_TYPE_LEAF)
                    maskval = tex2D(_ParallaxMap, lux.extrudedUV.xy * _ParallaxTiling).b;
                    lux.mixmapValue = half2(maskval, 1.0 - maskval);
                #endif

                // blend according to height and mixmapValue
                blendValue = lux.mixmapValue;
                lux.mixmapValue *= float2( dot(h.x, lux.mixmapValue.x), dot(h.y, lux.mixmapValue.y));
                // sharpen mask
                lux.mixmapValue *= lux.mixmapValue;
                lux.mixmapValue *= lux.mixmapValue;
                lux.mixmapValue = lux.mixmapValue / dot(lux.mixmapValue, 1);
                
                float tempHeight = dot(lux.mixmapValue, h.xy);
                
                float2 tempOffset = LuxParallaxOffset1Step (tempHeight, _Parallax, lux.eyeVecTangent);
                tempOffset *= _MainTex_ST.xyxy / _UVRatio.xyxy;

            //  blend both samples
                lux.offset = (lux.offset + tempOffset) * 0.5;
                lux.extrudedUV = uvScaled + float4(lux.offset, lux.offset) / _ParallaxTiling;

                lux.mixmapValue = (lux.mixmapValue + blendValue) * 0.5;
                lux.mixmapValue *= lux.mixmapValue;
                lux.mixmapValue *= lux.mixmapValue;
                lux.mixmapValue = lux.mixmapValue / dot(lux.mixmapValue, 1);
                lux.height = (lux.height + tempHeight) * 0.5;


            //  Get final height
            //  Why?
            /*    #if defined (_WETNESS_SIMPLE) || defined (_WETNESS_RIPPLES) || defined (_WETNESS_FLOW) || defined (_WETNESS_FULL)
                    half2 h1 = tex2D (_ParallaxMap, lux.extrudedUV.xy * _ParallaxTiling).ga;
                    h1.y = tex2D (_ParallaxMap, lux.extrudedUV.zw * _ParallaxTiling).a;
                    lux.height = dot(lux.mixmapValue, h1);
                #endif
            */
            #endif
            lux.puddleMaskValue = h.z;
        #endif
    #endif
}


//  Simple POM functions ---------------------------------------------------------------

//  Base function for just a single texture
void Lux_SimplePOM (
    inout LuxFragment lux,
    int POM_Linear_Steps,
    sampler2D heightmap )
{
    // Lux
    float slopeDamp = 1.0 - saturate (dot(lux.eyeVecTangent, float3(0,0,1)));
    // Calculate the parallax offset vector max length.
    float2 vMaxOffset =
        (lux.eyeVecTangent.xy / -lux.eyeVecTangent.z) * 
        _Parallax * lux.detailBlendState * (1.0 - (slopeDamp * slopeDamp));

lux.offsetWaterInWS = vMaxOffset.xy;

    POM_Linear_Steps = (lux.detailBlendState == 0) ? 1 : POM_Linear_Steps;
    // Specify the view ray step size. Each sample will shift the current view ray by this amount.
    float2 fStepSize = 1.0 / (float)POM_Linear_Steps;
    // Calculate the texture coordinate partial derivatives in screen space for the tex2Dgrad texture sampling instruction.
    float4 uvScaled = lux.extrudedUV; // * _ParallaxTiling;
    float2 dx = ddx(uvScaled.xy);
    float2 dy = ddy(uvScaled.xy);
    #if !LUX_POM_USES_TEX2DGRAD
        float d = max( dot(dx, dy ), dot(dx, dy ) );
        float mip = max(0, 0.5 * log2(d));
    #endif
    // Initialize the starting view ray height and the texture offsets.
    float fCurrRayHeight = 1.0; 
    float2 vCurrOffset = 0.0;
    float2 vLastOffset = 0.0;
    float fLastSampledHeight = 1;
    float fCurrSampledHeight = 1;
    float h0;
    float h1;

    // Lux: As we might have to deal with two different tilings here, we have to calculate the ratio between base and detail texture tiling and use it when offsetting.
    float2 BaseToDetailFactor = lux.extrudedUV.zw/lux.extrudedUV.xy;
    
    float2 finalStepSize = fStepSize * vMaxOffset 
    #if !defined(TESSELLATION_ON) 
        * _MainTex_ST.xyxy /* new: UVRatio */ / _UVRatio.xyxy
    #endif
    * float4(1,1,BaseToDetailFactor);

    bool hit = false;

    for (int nCurrSample = 0; nCurrSample < POM_Linear_Steps; ++nCurrSample) {
        // Sample the heightmap at the current texcoord offset.
        #if LUX_POM_USES_TEX2DGRAD
            fCurrSampledHeight = tex2Dgrad(heightmap, lux.extrudedUV.xy + vCurrOffset, dx.xy, dy.xy ).g;
        #else
            fCurrSampledHeight = tex2Dlod(heightmap, float4(lux.extrudedUV.xy + vCurrOffset, mip, mip)).g;
        #endif
        // Test if the view ray has intersected the surface.
        if ( fCurrSampledHeight > fCurrRayHeight ) {
            break; // end the loop
        }
        // take the next view ray height step,
        fCurrRayHeight -= fStepSize;
        // save the current texture coordinate offset and increment to the next sample location, 
        vLastOffset = vCurrOffset;
        vCurrOffset += finalStepSize;
        // and finally save the current heightmap height.
        fLastSampledHeight = fCurrSampledHeight;
    }

    UNITY_BRANCH
    if(lux.detailBlendState > 0) {
        float pt0 = fCurrRayHeight + fStepSize;
        float pt1 = fCurrRayHeight;
        float delta0 = pt0 - fLastSampledHeight;
        float delta1 = pt1 - fCurrSampledHeight;
        float delta;
        // intersectionHeight is the height [0..1] for the intersection between view ray and heightfield line
        for (int i = 0; i < 3; ++i)
        {
            float intersectionHeight = (pt0 * delta1 - pt1 * delta0) / (delta1 - delta0);
            // Retrieve offset require to find this intersectionHeight
            vCurrOffset = (1 - intersectionHeight) * finalStepSize * POM_Linear_Steps;
            #if LUX_POM_USES_TEX2DGRAD
                fCurrSampledHeight = tex2Dgrad(heightmap, uvScaled.xy + vCurrOffset, dx.xy, dy.xy ).g;
            #else
                fCurrSampledHeight = tex2Dlod(heightmap, float4(lux.extrudedUV.xy + vCurrOffset, mip, mip)).g;
            #endif
            delta = intersectionHeight - fCurrSampledHeight;
            if (delta < 0.0) {
                delta1 = delta;
                pt1 = intersectionHeight;
            }
            else {
               delta0 = delta;
               pt0 = intersectionHeight; 
            }
        }
    }

    // Calculate the final texture coordinate at the intersection point
    lux.extrudedUV.zw += vCurrOffset.xy * BaseToDetailFactor; // / _ParallaxTiling;
    lux.extrudedUV.xy += vCurrOffset.xy; // / _ParallaxTiling;
    // Set height
    lux.height = saturate(fCurrSampledHeight);
    // Set offset
    lux.offset = vCurrOffset.xy; 
}


//  ------------------------------------------------------------------
//  Mixing textures

//  Computes Parallax Occlusion Mapping texture offset and mixmapValue
//  inout heigh             needs no "real" input, outputs height
//  inout unIN              base uvs for texture1 and texture2
//  inout mixmapValue       needs no "real" input, outputs the final mixmapValue
//  in viewDir              viewDir in tangent space
//  in POM_Linear_Steps     maximum number of samples in the height maps per pixel
//  in heightmap            combined heightmaps (GA) and mask (B)

#if defined (GEOM_TYPE_BRANCH_DETAIL)

void Lux_SimplePOM_MixMap (
    inout LuxFragment lux,
    int POM_Linear_Steps,
    sampler2D heightmap )
{
    
    // Lux
    float slopeDamp = 1.0 - saturate (dot(lux.eyeVecTangent, float3(0,0,1)));
    // Calculate the parallax offset vector max length.
    float4 vMaxOffset = 
        (lux.eyeVecTangent.xyxy / -lux.eyeVecTangent.z) *
         _Parallax * lux.detailBlendState * (1.0 - (slopeDamp * slopeDamp));
    
lux.offsetWaterInWS = vMaxOffset.xy;

    POM_Linear_Steps = (lux.detailBlendState == 0) ? 1 : POM_Linear_Steps;
    // Specify the view ray step size. Each sample will shift the current view ray by this amount.
    float fStepSize = 1.0 / (float)POM_Linear_Steps;
    // Calculate the texture coordinate partial derivatives in screen space for the tex2Dgrad texture sampling instruction.
    float4 uvScaled = lux.extrudedUV; // * _ParallaxTiling;
    float4 uvMask =   lux.extrudedUV * _ParallaxTiling;
    float4 dx = ddx( uvScaled.xyzw);
    float4 dy = ddy( uvScaled.xyzw);
    //#if !LUX_POM_USES_TEX2DGRAD
    // needed for mask texture look ups in any way - so no if
        float d = max( dot(dx, dy ), dot(dx, dy ) );
        float mip = max(0, 0.5 * log2(d));
    //#endif
    // Initialize the starting view ray height and the texture offsets.
    float fCurrRayHeight = 1.0; 
    float4 vCurrOffset = 0.0;
    float4 vLastOffset = 0.0;
    float fLastSampledHeight = 1.0;
    float fCurrSampledHeight = 1.0;
    #if defined(GEOM_TYPE_LEAF)
        half3 heightAndMask;
    #endif
    float h0;
    float h1;

    // Lux: As we might have to deal with two different tilings here, we have to calculate the ratio between base and detail texture tiling and use it when offsetting.
    float2 BaseToDetailFactor = lux.extrudedUV.zw/lux.extrudedUV.xy;

    float4 finalStepSize = fStepSize * vMaxOffset 
    #if !defined(TESSELLATION_ON)
        * _MainTex_ST.xyxy /* new: UVRatio */ / _UVRatio.xyxy
    #endif
    * float4(1,1,BaseToDetailFactor);

    float2 finalHeights = float2(1.0, 1.0);

    bool hit = false;
    half maskval;
    const half pTiling = _ParallaxTiling;

    for (int nCurrSample = 0; nCurrSample < POM_Linear_Steps; ++nCurrSample) {
        // Sample the heightmap at the current texcoord offset.
        // Using Mask texture
        #if defined(GEOM_TYPE_LEAF)
            // read height, mask and puddle mask
            #if LUX_POM_USES_TEX2DGRAD
                heightAndMask = tex2Dgrad(heightmap, uvScaled.xy + vCurrOffset.xy, dx.xy, dy.xy).gbr;
                h1 = tex2Dgrad(heightmap, uvScaled.zw + vCurrOffset.zw, dx.zw, dy.zw).a;
            #else
                heightAndMask = tex2Dlod(heightmap, float4(uvScaled.xy + vCurrOffset.xy, mip, mip)).gbr;
                h1 = tex2Dlod(heightmap, float4(uvScaled.zw + vCurrOffset.zw, mip, mip)).a;
            #endif
            h0 = heightAndMask.x;
            
        // Using vertex colors
        #else
            #if LUX_POM_USES_TEX2DGRAD
                h0 = tex2Dgrad(heightmap, uvScaled.xy + vCurrOffset.xy, dx.xy, dy.xy).g;
                h1 = tex2Dgrad(heightmap, uvScaled.zw + vCurrOffset.zw, dx.xy, dy.xy).a;
            #else
                h0 = tex2Dlod(heightmap, float4(uvScaled.xy + vCurrOffset.xy, mip, mip)).g;
                h1 = tex2Dlod(heightmap, float4(uvScaled.zw + vCurrOffset.zw, mip, mip)).a;
            #endif
        #endif

        // Adjust the mixmapValue when using Mask texture
        #if defined(GEOM_TYPE_LEAF)
            maskval = (pTiling == 0) ? heightAndMask.y : tex2Dlod(heightmap, float4( (uvMask + vCurrOffset.xy * pTiling), mip, mip)).b;
            lux.mixmapValue = half2(maskval, 1.0 - maskval);
        //  lux.mixmapValue = half2(heightAndMask.y, 1.0 - heightAndMask.y);
            lux.mixmapValue = max( half2(0.0001, 0.0001), lux.mixmapValue * float2(dot(h0, lux.mixmapValue.x), dot(h1, lux.mixmapValue.y)));
            lux.mixmapValue *= lux.mixmapValue;
            lux.mixmapValue *= lux.mixmapValue;
            lux.mixmapValue = lux.mixmapValue / dot(lux.mixmapValue, half2(1.0, 1.0));
        #endif

        // Calculate height according to mixmapValue
        fCurrSampledHeight = lerp(h0, h1, lux.mixmapValue.y);

        // Test if the view ray has intersected the surface.
        if ( fCurrSampledHeight > fCurrRayHeight ) {
            break; // end the loop
        }
        // take the next view ray height step,
        fCurrRayHeight -= fStepSize;
        // save the current texture coordinate offset and increment to the next sample location, 
        vLastOffset = vCurrOffset;
        vCurrOffset += finalStepSize; //fStepSize * vMaxOffset;
        // and finally save the current heightmap height.
        fLastSampledHeight = fCurrSampledHeight;
    }

    UNITY_BRANCH
    if(lux.detailBlendState > 0) {
        float pt0 = fCurrRayHeight + fStepSize;
        float pt1 = fCurrRayHeight;
        float delta0 = pt0 - fLastSampledHeight;
        float delta1 = pt1 - fCurrSampledHeight;
        float delta;

        for (int i = 0; i < 3; ++i)
        {
            float intersectionHeight = (pt0 * delta1 - pt1 * delta0) / (delta1 - delta0);
            // Retrieve offset require to find this intersectionHeight
            vCurrOffset = (1 - intersectionHeight) * finalStepSize * POM_Linear_Steps;

            // Using Mask texture
            #if defined(GEOM_TYPE_LEAF)
                // read height, mask and puddle mask
                #if LUX_POM_USES_TEX2DGRAD
                    heightAndMask = tex2Dgrad(heightmap, uvScaled.xy + vCurrOffset.xy, dx.xy, dy.xy).gbr;
                    h1 = tex2Dgrad(heightmap, uvScaled.zw + vCurrOffset.zw, dx.zw, dy.zw).a;
                #else
                    heightAndMask = tex2Dlod(heightmap, float4(uvScaled.xy + vCurrOffset.xy, mip, mip)).gbr;
                    h1 = tex2Dlod(heightmap, float4(uvScaled.zw + vCurrOffset.zw, mip, mip)).a;
                #endif
                h0 = heightAndMask.x;
            // Using vertex colors
            #else
                #if LUX_POM_USES_TEX2DGRAD
                    h0 = tex2Dgrad(heightmap, uvScaled.xy + vCurrOffset.xy, dx.xy, dy.xy).g;
                    h1 = tex2Dgrad(heightmap, uvScaled.zw + vCurrOffset.zw, dx.xy, dy.xy).a;
                #else
                    h0 = tex2Dlod(heightmap, float4(uvScaled.xy + vCurrOffset.xy, mip, mip)).g;
                    h1 = tex2Dlod(heightmap, float4(uvScaled.zw + vCurrOffset.zw, mip, mip)).a;
                #endif
            #endif

            // Adjust the mixmapValue when using Mask texture
            #if defined(GEOM_TYPE_LEAF)
                maskval = (pTiling == 0) ? heightAndMask.y : tex2Dlod(heightmap, float4( (uvMask + vCurrOffset.xy * pTiling), mip, mip)).b;
                lux.mixmapValue = half2(maskval, 1.0 - maskval);
                lux.mixmapValue = max( half2(0.0001, 0.0001), lux.mixmapValue * float2(dot(h0, lux.mixmapValue.x), dot(h1, lux.mixmapValue.y)));
                lux.mixmapValue *= lux.mixmapValue;
                lux.mixmapValue *= lux.mixmapValue;
                lux.mixmapValue = lux.mixmapValue / dot(lux.mixmapValue, half2(1.0, 1.0));
            #endif

            fCurrSampledHeight = lerp(h0, h1, lux.mixmapValue.y);
            
            delta = intersectionHeight - fCurrSampledHeight;
            if (delta < 0.0) {
                delta1 = delta;
                pt1 = intersectionHeight;
            }
            else {
               delta0 = delta;
               pt0 = intersectionHeight; 
            }
        }
    }

    //  Calculate the final texture coordinate at the intersection point.
    lux.extrudedUV += vCurrOffset; // / _ParallaxTiling;
    //  Adjust the mixmapValue when using vertex colors
    #if !defined(GEOM_TYPE_LEAF)
        float2 blendVal = max( 0.0001, float2 ( dot(finalHeights.x, lux.mixmapValue.x), dot(finalHeights.y, lux.mixmapValue.y))) ;
        blendVal *= blendVal;
        blendVal *= blendVal;
        blendVal = blendVal / dot(blendVal, 1.0);
        lux.mixmapValue = lerp(lux.mixmapValue, blendVal, lux.detailBlendState);
    #else
        lux.puddleMaskValue = heightAndMask.z;
    #endif
    // Set height
    lux.height = saturate(fCurrSampledHeight);
    // Set offset
    lux.offset = vCurrOffset.xy;
}
#endif


//  Surface shader Macro Definitions ---------------------------------------------------

//  POM // Meta Pass always uses simple parallax mapping
#if defined(EFFECT_BUMP) && !defined (UNITY_PASS_META)

    #if !defined(TESSELLATION_ON) 
        // Mixmapping
        #if defined (GEOM_TYPE_BRANCH_DETAIL)
            #define LUX_PARALLAX \
                Lux_SimplePOM_MixMap (lux, _LinearSteps, _ParallaxMap); \
                lux.finalUV = lux.extrudedUV; \
                float2 objectScale_TextureScale_Ratio = lux.scale / _MainTex_ST.xy; \
                lux.offsetInWS_Surface = WorldNormalVector(IN, float3(lux.offset.xy * objectScale_TextureScale_Ratio , 0) ).xz;
        // Regular blending 
        #else
            #define LUX_PARALLAX \
                Lux_SimplePOM (lux, _LinearSteps, _ParallaxMap); \
                lux.finalUV = lux.extrudedUV; \
                float2 objectScale_TextureScale_Ratio = lux.scale / _MainTex_ST.xy; \
                lux.offsetInWS_Surface = WorldNormalVector(IN, float3(lux.offset.xy * objectScale_TextureScale_Ratio , 0) ).xz;

             #define LUX_PARALLAX_SCALED \
                lux.finalUV = lux.finalUV;

        #endif

    // when using tessellation _MainTex_ST is NOT defined
    #endif



//  Simple Parallax
#else
    #if !defined(TESSELLATION_ON) 
        #define LUX_PARALLAX \
            Lux_Parallax (lux); \
            lux.finalUV = lux.extrudedUV; \
            float2 objectScale_TextureScale_Ratio = lux.scale / _MainTex_ST.xy; \
            lux.offsetInWS_Surface = WorldNormalVector(IN, float3(lux.offset.xy * objectScale_TextureScale_Ratio , 0) ).xz;
    
    // when using tessellation _MainTex_ST is NOT defined
    #else
        #define LUX_PARALLAX \
            Lux_Parallax (lux); \
            lux.finalUV = lux.extrudedUV; \
            float2 objectScale_TextureScale_Ratio = 1.0; \
            lux.offsetInWS_Surface = 0;
    #endif
#endif


#endif