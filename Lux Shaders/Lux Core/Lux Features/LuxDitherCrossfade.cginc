#ifndef LUX_LODCROSSFADE_INCLUDED
#define LUX_LODCROSSFADE_INCLUDED

    //#include "UnityCG.cginc"

    //sampler2D _DitherMaskLOD2D;

    void LuxApplyDitherCrossFade(half3 ditherScreenPos)
    {
        half2 projUV = ditherScreenPos.xy / ditherScreenPos.z;
        projUV.y = frac(projUV.y) * 0.0625 /* 1/16 */ + unity_LODFade.y; // quantized lod fade by 16 levels
        clip(tex2D(_DitherMaskLOD2D, projUV).a - 0.5);
    }


#endif