using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif
using System.Collections;

[ExecuteInEditMode]
public class LuxSetup : MonoBehaviour {

    [Header("Detail Distance")]
    [Space(2)]
    [Range(10.0f,100.0f)]
    public float DetailDistance = 50.0f;
    [Range(1.0f,25.0f)]
    public float DetailFadeRange = 15.0f;

    [Header("Area Lights")]
    [Space(2)]
    public bool enableAreaLights = false;

    [Header("Translucent Lighting")]
    [Space(2)]
    [Tooltip("Distort translucent lighting by surface normals.")]
    [CustomLabelRange(0.0f,1.0f,"Distortion")]
    public float BumpDistortion_T = 0.1f;
    [CustomLabelRange(1.0f,8.0f, "Scale")]
    public float Scale_T = 4.0f;
    [CustomLabelRange(0.0f,1.0f,"Shadow Strength")]
    public float ShadowStrength_T = 0.7f;
    [CustomLabelRange(0.0f,1.0f,"Shadow Strength NdotL")]
    public float ShadowStrength_NdotL = 0.7f;
    // We write 1.0 - ShadowStrength to shift some work from the shader :-)

    [Header("Skin Lighting")]
    [Space(2)]
    public Texture BRDFTexture;
	[Space(5)]
	public Color SubsurfaceColor = new Color(1.0f, 0.4f, .25f, 1.0f);
    [CustomLabelRange(1.0f,8.0f, "Power")]
    public float Power_S = 2.0f;
    [CustomLabelRange(0.0f,1.0f,"Distortion")]
    public float Distortion_S = 0.1f;
    [CustomLabelRange(0.0f,8.0f, "Scale")]
	public float Scale_S = 2.0f;

    [Space(5)]
    public bool EnableSkinLightingFade = false;
	[Range(0.0f,50.0f)]
	public float SkinLightingDistance = 20.0f;
    [Range(0.0f,20.0f)]
    public float SkinLightingFadeRange = 8.0f;

    [Header("Anisotropic Lighting")]
    [Space(2)]
    [Tooltip("Distort translucent lighting by surface normals.")]
    [CustomLabelRange(1.0f,8.0f, "Power")]
    public float Power_A = 2.0f;
    [CustomLabelRange(0.0f,1.0f,"Distortion")]
    public float BumpDistortion_A = 0.1f;
    [CustomLabelRange(1.0f,8.0f, "Scale")]
    public float Scale_A = 4.0f;
    [CustomLabelRange(0.0f,1.0f,"Shadow Strength")]
    public float ShadowStrength_A = 0.7f;
    // We write 1.0 - ShadowStrength to shift some work from the shader :-)
    

	void UpdateLuxGlobalShaderVariables () {
        Shader.SetGlobalVector("_Lux_DetailDistanceFade", new Vector2(DetailDistance, DetailFadeRange));
    //  Area Lights
        if(enableAreaLights)
        {
            Shader.EnableKeyword("LUX_AREALIGHTS");
        }
        else
        {
            Shader.DisableKeyword("LUX_AREALIGHTS");
        }
    //  Skin lighting
        #if UNITY_EDITOR
            if(BRDFTexture == null) {
                BRDFTexture = Resources.Load("DiffuseScatteringOnRing") as Texture;
            }
        #endif
        Shader.SetGlobalTexture("_BRDFTex", BRDFTexture);
        Shader.SetGlobalColor("_SubColor", SubsurfaceColor.linear);
        Shader.SetGlobalVector("_Lux_Skin_DeepSubsurface", new Vector4(Power_S, Distortion_S, Scale_S, 0.0f));
        if (EnableSkinLightingFade) {
            Shader.EnableKeyword("LUX_LIGHTINGFADE"); 
        }
        else {
            Shader.DisableKeyword("LUX_LIGHTINGFADE"); 
        }
        Shader.SetGlobalVector("_Lux_Skin_DistanceRange", new Vector2(SkinLightingDistance, SkinLightingFadeRange));
    //  Translucent Lighting
        Shader.SetGlobalVector("_Lux_Tanslucent_Settings", new Vector4(BumpDistortion_T, 0.0f, 1.0f - ShadowStrength_T, Scale_T));
        Shader.SetGlobalFloat("_Lux_Translucent_NdotL_Shadowstrength", 1.0f - ShadowStrength_NdotL);
    //  Anisotropic Lighting
        Shader.SetGlobalVector("_Lux_Anisotropic_Settings", new Vector4(BumpDistortion_A, Power_A, 1.0f - ShadowStrength_A, Scale_A));  
    }

    void Start () {
        UpdateLuxGlobalShaderVariables(); 
    }

    void OnValidate () {
        UpdateLuxGlobalShaderVariables(); 
    }

//  Would be needed if we faded translucent lighting according to the real time shadow distance.
//  Is needed to fade out point light shadows.
    void Update () {
        Shader.SetGlobalFloat("_Lux_ShadowDistance", QualitySettings.shadowDistance);
    }

}
