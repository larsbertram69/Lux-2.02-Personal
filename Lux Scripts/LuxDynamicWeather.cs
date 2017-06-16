using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class LuxDynamicWeather : MonoBehaviour {


//	WETNESS
[Header("Dynamic Weather")]
	[Space(4)]
	public bool ScriptControlledWeather = true;
	
	[Space(10)]
	[Range(0.1f, 4.0f)]
	public float TimeScale = 1.0f;
	[Tooltip("Next to 'Rainfall' 'Temperature' is the most important input as it decides whether it rains or snows.'")]
	[Range(-40.0f, 40.0f)]
	public float Temperature = 20.0f;
	[Tooltip("Controls rain and snow intensity according to the given temperature.")]
	[Range(0.0f, 1.0f)]
	public float Rainfall = 0.0f;			// Snow and Rain
	
	[ReadOnlyRange(0.0f, 1.0f)]
	public float RainIntensity = 0.0f;		// Rain only
	[ReadOnlyRange(0.0f, 1.0f)]
	public float SnowIntensity = 0.0f;		// Snow only
	
	[Space(10)]
	[Range(0.0f, 1.0f)]
	public float WetnessInfluenceOnAlbedo = 0.85f;
	[Range(0.0f, 1.0f)]
	public float WetnessInfluenceOnSmoothness = 0.5f;
	[Range(0.0f, 1.0f)]
	public float AccumulationRateWetness = 0.35f;
	[Range(0.0f, 0.5f)]
	public float EvaporationRateWetness = 0.075f;

	[Space(10)]
	[Range(0.0f, 1.0f)]
	public float AccumulationRateCracks = 0.25f;
	[Range(0.0f, 1.0f)]
	public float AccumulationRatePuddles = 0.2f;

	[Range(0.0f, 0.5f)]
	public float EvaporationRateCracks = 0.20f;
	[Range(0.0f, 0.5f)]
	public float EvaporationRatePuddles = 0.1f;

	[Space(5)]
	[Range(0.0f, 0.5f)]
	public float AccumulationRateSnow = 0.10f;

	[Space(15)]
	[Range(0.0f, 1.0f)]
	public float AccumulatedWetness = 0.0f;
	[Range(0.0f, 1.0f)]
	public float AccumulatedCracks = 0.0f;
	[Range(0.0f, 1.0f)]
	public float AccumulatedPuddles = 0.0f;
	[ReadOnlyRange(0.0f, 1.0f)]
	public float AccumulatedWater = 0.0f;
	[Space(5)]
	[Range(0.0f, 1.0f)]
	public float AccumulatedSnow = 0.0f;

	[Space(5)]
	[Range(0.0f, 1.0f)]
	public float WaterToSnow = 0.01f;

	[Space(15)]
	[Range(0.01f, 1.0f)]
	public float WaterToSnowTimeScale = 1.0f;
	public AnimationCurve WaterToSnowCurve = new AnimationCurve(new Keyframe(0, 0.25f), new Keyframe(1, 1));

[ReadOnlyRange(0.0f, 1.0f)]
public float SnowMelt = 0.0f;

[Header("Snow")]
	[Space(4)]
	[ColorUsageAttribute(false/*no alpha*/,true,0f,2f,0.125f,3f)] public Color SnowColor = Color.white;
	public Color SnowSpecularColor = new Color (0.2f,0.2f,0.2f,1.0f);
	public Color SnowScatterColor;
	[Range(0.0f, 1.0f)]
	public float SnowDiffuseScatteringBias = 0.0f;
	[Range(1.0f, 10.0f)]
	public float SnowDiffuseScatteringContraction = 8.0f;
	[Space(5)]
	[Tooltip("Mask in (G) Normal in (BA)")]
	public Texture2D SnowMask;
	[Tooltip("Snow and Water Bump in (GA) Snow Smoothness in (B)")]
	public Texture2D SnowAndWaterBump;

	[Range(-100.0f,8000.0f)]
	public float SnowStartHeight = -100.0f;
	[Range(0.0f,1.0f)]
	public float SnowHeightBlending = 0.01f;
		private float Lux_adjustedSnowAmount;

[Header("World mapped Snow")]
	[Space(4)]
	public float SnowTiling = 0.2f;
	public float SnowDetailTiling = 0.5f;
	public float SnowMaskTiling = 0.01f;
	public float SnowMaskDetailTiling = 0.37f;
	public float SnowNormalStregth = 1.0f;
	public float SnowNormalDetailStrength= 0.3f;


	[Space(10)]
	public ParticleSystem SnowParticleSystem;
	#if UNITY_5_5_OR_NEWER
	#else
		private ParticleSystem.EmissionModule SnowEmissionModule;
	#endif
	public int MaxSnowParticlesEmissionRate = 3000;

[Header("Rain")]
	[Space(4)]
	public Texture2D RainRipples;
	public float RippleTiling = 4.0f;
	public float RippleAnimSpeed = 1.0f;
	[Range(0.0f,1.0f)]
	public float RippleRefraction = 0.5f;
	//	Offscreen rain ripples
	public int RenderTextureSize = 512;
	//public Shader RainRippleCompositeShader;
	public RenderTexture RainRipplesRenderTexture;
	private Material m_material;

	[Space(10)]
	public ParticleSystem RainParticleSystem;
	#if UNITY_5_5_OR_NEWER
	#else
		private ParticleSystem.EmissionModule RainEmissionModule;
	#endif
	public int MaxRainParticlesEmissionRate = 3000;


//	PIDs	
	private int RainSnowIntensityPID;
	private int WaterFloodLevelPID;
	private int RainRipplesPID; // deprecated ripple texture
	private int RippleAnimSpeedPID;
	private int RippleTilingPID;
	private int RippleRefractionPID;
	
	private int SnowHeightParamsPID;
	private int WaterToSnowPID;
	private int SnowMeltPID;
	private int SnowAmountPID;
	private int SnowColorPID;
	private int SnowSpecColorPID;
	private int SnowScatterColorPID;
	private int SnowScatteringBiasPID;
	private int SnowSnowScatteringContractionPID;
	private int WorldMappedSnowTilingPID;
	private int WorldMappedSnowStrengthPID;

	private int SnowMaskPID;
	private int SnowWaterBumpPID;

[Header("GI")]
	[Space(4)]
	[Tooltip("When using dynamic GI you may attach one renderer per GI System in order to make GI being synced automatically to the given amount of snow.")]
	public Renderer[] SnowGIMasterRenderers;

//

	void OnEnable () {
		SetupRippleRT ();
	}

	void SetupRippleRT () {
		if (RainRipplesRenderTexture == null || m_material == null)
        {
            RainRipplesRenderTexture = new RenderTexture(RenderTextureSize, RenderTextureSize, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear );
            RainRipplesRenderTexture.useMipMap = true;
            RainRipplesRenderTexture.wrapMode = TextureWrapMode.Repeat;
            m_material = new Material(Shader.Find("Hidden/Lux RainRipplesComposite")); //new Material(RainRippleCompositeShader);

            GetPIDs();
        }
	}

	void GetPIDs () {
		// Rain
		RainSnowIntensityPID = Shader.PropertyToID("_Lux_RainfallRainSnowIntensity");
		WaterFloodLevelPID = Shader.PropertyToID("_Lux_WaterFloodlevel");
		RainRipplesPID = Shader.PropertyToID("_Lux_RainRipples");
		RippleAnimSpeedPID = Shader.PropertyToID("_Lux_RippleAnimSpeed");
		RippleTilingPID = Shader.PropertyToID("_Lux_RippleTiling");
		RippleRefractionPID = Shader.PropertyToID("_Lux_RippleRefraction");

		// Snow
		SnowHeightParamsPID = Shader.PropertyToID("_Lux_SnowHeightParams");
		WaterToSnowPID = Shader.PropertyToID("_Lux_WaterToSnow");
		SnowMeltPID = Shader.PropertyToID("_Lux_SnowMelt");
		SnowAmountPID = Shader.PropertyToID("_Lux_SnowAmount");
		SnowColorPID = Shader.PropertyToID("_Lux_SnowColor");
		SnowSpecColorPID = Shader.PropertyToID("_Lux_SnowSpecColor");

		SnowScatterColorPID = Shader.PropertyToID("_Lux_SnowScatterColor");
		SnowScatteringBiasPID = Shader.PropertyToID("_Lux_SnowScatteringBias");
		SnowSnowScatteringContractionPID = Shader.PropertyToID("_Lux_SnowScatteringContraction");
		WorldMappedSnowTilingPID = Shader.PropertyToID("_Lux_WorldMappedSnowTiling");
		WorldMappedSnowStrengthPID = Shader.PropertyToID("_Lux_WorldMappedSnowStrength");

		SnowMaskPID = Shader.PropertyToID("_Lux_SnowMask");
		SnowWaterBumpPID = Shader.PropertyToID("_Lux_SnowWaterBump");
	}

	void Start () {
		#if UNITY_5_5_OR_NEWER
		#else
			if(SnowParticleSystem != null) {
				SnowEmissionModule = SnowParticleSystem.emission;
			}
			if(SnowParticleSystem != null) {
				RainEmissionModule = RainParticleSystem.emission;
			}
		#endif
	}
	
	void Update () {
		if(ScriptControlledWeather) {

			var temp_EvaporationRateWetness = Mathf.Lerp(0.0f, EvaporationRateWetness, Temperature / 40.0f );
			var temp_EvaporationRateCracks = Mathf.Lerp(0.0f, EvaporationRateCracks, Temperature / 40.0f );
			var temp_EvaporationRatePuddles = Mathf.Lerp(0.0f, EvaporationRatePuddles, Mathf.Abs(Temperature) / 40.0f );

			float waterToSnow = Mathf.Abs(Temperature);
			waterToSnow = Mathf.Lerp(0.0f, 1.0f, waterToSnow / 40.0f );

			if(Temperature > 0.0f) {

				WaterToSnow -= waterToSnow * Time.deltaTime * TimeScale * WaterToSnowTimeScale;
				WaterToSnow = Mathf.Clamp01(WaterToSnow);

				var meltWater =	Mathf.Clamp01( (1.0f - WaterToSnow) * AccumulatedSnow * Time.deltaTime * TimeScale * WaterToSnowTimeScale * 4.0f );
				var waterAcculumulation = RainIntensity * Time.deltaTime * TimeScale;
								 		//+ (1.0f - WaterToSnow) * Mathf.Clamp01(AccumulatedSnow - AccumulatedWater) * Time.deltaTime * TimeScale * WaterToSnow_TimeScale * 4.0f;
				AccumulatedWetness += waterAcculumulation * AccumulationRateWetness + meltWater;
				AccumulatedCracks += waterAcculumulation * AccumulationRateCracks; //+ meltWater * 4.0f * AccumulationRateCracks;
				AccumulatedPuddles += waterAcculumulation * AccumulationRatePuddles; //+ meltWater * 2.0f * AccumulationRatePuddles;

				// Dry / only if it is not raining - not accurate but easier to adjust
				if (Rainfall == 0.0f) {
					AccumulatedWetness -= temp_EvaporationRateWetness * Time.deltaTime * TimeScale;
					AccumulatedCracks -= temp_EvaporationRateCracks * Time.deltaTime * TimeScale;
					AccumulatedPuddles -= temp_EvaporationRatePuddles * Time.deltaTime * TimeScale;
				}
				// Always melt snow
				AccumulatedSnow = AccumulatedSnow - meltWater;
			}

			else {

				WaterToSnow += waterToSnow * Time.deltaTime * TimeScale * WaterToSnowTimeScale;
				WaterToSnow = Mathf.Clamp01(WaterToSnow);
				AccumulatedSnow += SnowIntensity * AccumulationRateSnow * Time.deltaTime * TimeScale
								+ WaterToSnow * Mathf.Clamp01(AccumulatedWater) * Time.deltaTime * TimeScale * WaterToSnowTimeScale;
				AccumulatedWetness 	-= WaterToSnow * Time.deltaTime * TimeScale * WaterToSnowTimeScale;
				AccumulatedCracks 	-= WaterToSnow * Time.deltaTime * TimeScale * WaterToSnowTimeScale;
				AccumulatedPuddles 	-= WaterToSnow * Time.deltaTime * TimeScale * WaterToSnowTimeScale;
			}

			AccumulatedSnow = Mathf.Clamp01(AccumulatedSnow);
			AccumulatedWetness = Mathf.Clamp01(AccumulatedWetness);
			AccumulatedCracks = Mathf.Clamp01(AccumulatedCracks);
			AccumulatedPuddles = Mathf.Clamp01(AccumulatedPuddles);
			AccumulatedWater = Mathf.Max(AccumulatedCracks, AccumulatedPuddles);
			SnowMelt = 1.0f - WaterToSnow;
			// Fade from Rain to Snow
			SnowIntensity = Rainfall * (WaterToSnow);
			RainIntensity = Rainfall - SnowIntensity;
		}

		else {
			SnowIntensity = Rainfall;
			RainIntensity = Rainfall;	
		}
		float WaterToSnow_Lookup = WaterToSnowCurve.Evaluate(WaterToSnow);
		WaterToSnow = Mathf.Clamp(WaterToSnow, 0.0f, 1.0f);

		Shader.SetGlobalVector(WaterToSnowPID,
				new Vector4(WaterToSnow,
					 1.0f - Mathf.Pow(2.0f, -10.0f * WaterToSnow), // * Lux_SnowAmount ),	// final Lux_SnowMelt = 2^(-10 * (Lux_SnowMelt)), 
					 0.0f, 0.0f));

		Shader.SetGlobalVector(SnowMeltPID,
				new Vector4(1.0f - WaterToSnow_Lookup,
					 1.0f - Mathf.Pow(2.0f, -10.0f * (1.0f - WaterToSnow_Lookup)), // * Lux_SnowAmount ),	// final Lux_SnowMelt = 2^(-10 * (Lux_SnowMelt)), 
					 0.0f, 0.0f));

		Shader.SetGlobalVector(RainSnowIntensityPID, new Vector3 (Rainfall, RainIntensity, SnowIntensity));
		Shader.SetGlobalVector(WaterFloodLevelPID, new Vector4(AccumulatedCracks, AccumulatedPuddles, AccumulatedWetness * WetnessInfluenceOnAlbedo * (1.0f - WaterToSnow), AccumulatedWetness * WetnessInfluenceOnSmoothness * (1.0f - WaterToSnow) ));
		
		// Textures and texture settings
		Shader.SetGlobalTexture(SnowMaskPID, SnowMask);
		Shader.SetGlobalTexture(SnowWaterBumpPID, SnowAndWaterBump);
		// Deprecated
		if(RainRipples) {
			Shader.SetGlobalTexture(RainRipplesPID, RainRipples);
		}
		Shader.SetGlobalFloat(RippleAnimSpeedPID, RippleAnimSpeed);	
		Shader.SetGlobalFloat(RippleTilingPID, RippleTiling);
		Shader.SetGlobalFloat(RippleRefractionPID, RippleRefraction);

		// Snow
		Shader.SetGlobalVector(SnowHeightParamsPID, new Vector4(SnowStartHeight, SnowHeightBlending * 1000.0f, 0.0f, 0.0f));
		Shader.SetGlobalFloat(SnowAmountPID, AccumulatedSnow * WaterToSnow );
		Shader.SetGlobalColor(SnowColorPID, SnowColor);
		Shader.SetGlobalColor(SnowSpecColorPID, SnowSpecularColor);
		// Snow Scattering
		Shader.SetGlobalVector(SnowScatterColorPID, SnowScatterColor);
		Shader.SetGlobalFloat(SnowScatteringBiasPID, SnowDiffuseScatteringBias);
		Shader.SetGlobalFloat(SnowSnowScatteringContractionPID, SnowDiffuseScatteringContraction);
		// World mapped snow tiling
		Shader.SetGlobalVector(WorldMappedSnowTilingPID, new Vector4(SnowTiling, SnowDetailTiling, SnowMaskTiling, SnowMaskDetailTiling) );
		Shader.SetGlobalVector(WorldMappedSnowStrengthPID, new Vector2(SnowNormalStregth, SnowNormalDetailStrength) );

		// Dynamic Snow Accumulation will influence the Albedo of the effected surfaces thus it should also update GI
		if (SnowGIMasterRenderers != null) {
			if (SnowGIMasterRenderers.Length > 0) {
				for (int i = 0; i < SnowGIMasterRenderers.Length; i++) {
					if (SnowGIMasterRenderers[i] != null) {
						RendererExtensions.UpdateGIMaterials(SnowGIMasterRenderers[i]);	
					}
				}
			}
		}
		if(SnowParticleSystem != null) {
			#if UNITY_5_5_OR_NEWER
				var SnowEmission = SnowParticleSystem.emission;
				SnowEmission.rateOverTimeMultiplier = MaxSnowParticlesEmissionRate * SnowIntensity;
			#else
				SnowEmissionModule.rate = new ParticleSystem.MinMaxCurve(MaxSnowParticlesEmissionRate * SnowIntensity);
			#endif
		}
		if(RainParticleSystem != null) {
			#if UNITY_5_5_OR_NEWER
				var RainEmission = RainParticleSystem.emission;
				RainEmission.rateOverTimeMultiplier = MaxRainParticlesEmissionRate * RainIntensity;
			#else
				RainEmissionModule.rate = new ParticleSystem.MinMaxCurve(MaxRainParticlesEmissionRate * RainIntensity);
			#endif
		}

		// Offsceen rain ripples
		if (RainRipples) {
			GL.sRGBWrite = true; // we need linear colors as we render a normal map
			m_material.SetFloat(RainSnowIntensityPID, RainIntensity);
			m_material.SetFloat(RippleAnimSpeedPID, RippleAnimSpeed);
			Graphics.Blit(RainRipples, RainRipplesRenderTexture, m_material);
			RainRipplesRenderTexture.SetGlobalShaderProperty("_Lux_RainRipplesRT"); // only accepts strings...
		}
	}
}
