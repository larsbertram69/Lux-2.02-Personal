using System;
using UnityEngine;

namespace UnityEditor
{
internal class LuxStandardShaderGUI : ShaderGUI
{
	private enum WorkflowMode
	{
		Specular,
		Metallic,
		Dielectric
	}

	public enum MixMapControl
	{
		VertexColorRed,
		DetailMask
	}

	public enum PuddleMask
	{
		VertexColorBlue,
		HeightMap
	}

	public enum CullingMode {
		Off,
		Front,
		Back
	}

	public enum BlendMode
	{
		Opaque,
		Cutout,
		Fade,		// Old school alpha-blending mode, fresnel does not affect amount of transparency
		Transparent // Physically plausible transparency mode, implemented as alpha pre-multiply
	}

	private static class Styles
	{
		public static GUIStyle optionsButton = "PaneOptions";
		public static GUIContent uvSetLabel = new GUIContent("UV Set");
		public static GUIContent[] uvSetOptions = new GUIContent[] { new GUIContent("UV channel 0"), new GUIContent("UV channel 1") };

		public static string emptyTootip = "";
		public static GUIContent albedoText = new GUIContent("Albedo", "Albedo (RGB) and Transparency (A)");
		public static GUIContent alphaCutoffText = new GUIContent("Alpha Cutoff", "Threshold for alpha cutoff");
		public static GUIContent specularMapText = new GUIContent("Specular", "Specular (RGB) and Smoothness (A)");
		public static GUIContent metallicMapText = new GUIContent("Metallic", "Metallic (R) and Smoothness (A)");
		public static GUIContent smoothnessText = new GUIContent("Smoothness", "");
		public static GUIContent normalMapText = new GUIContent("Normal Map", "Normal Map");
		public static GUIContent heightMapText = new GUIContent("Height Map", "Height Map (G)");
		public static GUIContent occlusionText = new GUIContent("Occlusion", "Occlusion (G)");
		public static GUIContent emissionText = new GUIContent("Emission", "Emission (RGB)");
		public static GUIContent detailMaskText = new GUIContent("Detail Mask (G)", "Mask for Secondary Maps (G)");
		public static GUIContent detailAlbedoText = new GUIContent("Detail Albedo x2", "Albedo (RGB) multiplied by 2");
		public static GUIContent detailNormalMapText = new GUIContent("Normal Map", "Normal Map");

		public static string whiteSpaceString = " ";
		public static string primaryMapsText = "Main Maps";
		public static string secondaryMapsText = "Secondary Maps";
		public static string renderingMode = "Rendering Mode";
		public static GUIContent emissiveWarning = new GUIContent ("Emissive value is animated but the material has not been configured to support emissive. Please make sure the material itself has some amount of emissive.");
		public static GUIContent emissiveColorWarning = new GUIContent ("Ensure emissive color is non-black for emission to have effect.");
		public static readonly string[] blendNames = Enum.GetNames (typeof (BlendMode));

		//Lux
		public static string cullingMode = "Culling";
		public static readonly string[] cullingNames = Enum.GetNames (typeof (CullingMode));
		public static GUIContent mixMappingControlText = new GUIContent("Control MixMapping");
		public static GUIContent detailAlbedoMixMappingText = new GUIContent("Albedo AO (A)", "Albedo (RGB) Occlusion (A)");
		public static GUIContent detailNormalMixMappingMapText = new GUIContent("Normal Map", "Normal Map");

		public static GUIContent heightMapMixMapText = new GUIContent("Heights (GA)", "1st Height Map (G) will be sampled using the base UVs.\n2nd Height Map (A) will be sampled using the detail UVs.");
		public static GUIContent heightMapMixMapMaskText = new GUIContent("Heights (GA) Mask (B)", "1st Height Map (G) will be sampled using the base UVs.\n2nd Height Map (A) will be sampled using the detail UVs.\nMaks in (B).");

public static GUIContent combineMapText = new GUIContent("Combined Map", "Detail Mask (G) Unused (B) Occlusion (A)");
			public static GUIContent combineMap_TranslucencyText = new GUIContent("", "");
		public static GUIContent detailMaskMixMappingText = new GUIContent("Mix Map (G)", "Equals the Detail Mask (G)");
		public static GUIContent enablePOMText = new GUIContent("Enable POM", "Use POM instead of Parallax Mapping.");
		public static GUIContent snowOpacityText = new GUIContent("Snow Opacity ●", "Snow Opacity suppresses Emission and Transluceny.");

	}

	MaterialProperty blendMode = null;
	MaterialProperty albedoMap = null;
	MaterialProperty albedoColor = null;
	MaterialProperty alphaCutoff = null;
	MaterialProperty specularMap = null;
	MaterialProperty specularColor = null;
	MaterialProperty metallicMap = null;
	MaterialProperty metallic = null;
	MaterialProperty smoothness = null;
	MaterialProperty bumpScale = null;
	MaterialProperty bumpMap = null;
	MaterialProperty occlusionStrength = null;
	MaterialProperty occlusionMap = null;
	MaterialProperty heigtMapScale = null;
	MaterialProperty heightMap = null;
	MaterialProperty heightMapTiling = null;
	MaterialProperty emissionColorForRendering = null;
	MaterialProperty emissionMap = null;
	MaterialProperty detailMask = null;
	MaterialProperty detailAlbedoMap = null;
	MaterialProperty detailNormalMapScale = null;
	MaterialProperty detailNormalMap = null;
	MaterialProperty uvSetSecondary = null;
	// Lux
	MaterialProperty cullingMode = null;
	MaterialProperty cullShadowPass = null;
	MaterialProperty doubleSided = null;
	MaterialProperty useMixMapping = null;
	MaterialProperty mixMappingControl = null;
	MaterialProperty useCombinedMap = null;
	MaterialProperty albedo2Color = null;
	MaterialProperty specularColor2 = null;
	MaterialProperty smoothness2 = null;
	MaterialProperty specularMap2 = null;

	MaterialProperty metallicMap2 = null;
	MaterialProperty metallic2 = null;

	MaterialProperty combinedMap = null;
	MaterialProperty UVRatio = null;
	MaterialProperty usePOM = null;
	MaterialProperty linearSteps = null;
	MaterialProperty lighting = null;

	MaterialProperty translucencyStrength = null;
	MaterialProperty scatteringPower = null;

	MaterialProperty diffuseScatteringEnabled = null;
	MaterialProperty diffuseScatteringCol = null;
	MaterialProperty diffuseScatterBias = null;
	MaterialProperty diffuseScatterContraction = null;
	MaterialProperty diffuseScatteringCol2 = null;
	MaterialProperty diffuseScatterBias2 = null;
	MaterialProperty diffuseScatterContraction2 = null;

	MaterialProperty snow = null;
	MaterialProperty snowMapping = null;
	MaterialProperty snowSlopeDamp = null;
	MaterialProperty snowTiling = null;
	MaterialProperty snowNormalStrength = null;
	MaterialProperty snowMaskTiling = null;
	MaterialProperty snowDetailTiling = null;
	MaterialProperty snowDetailStrength = null;
	MaterialProperty snowAccumulation = null;

	//MaterialProperty occlusionInfluence = null;
	//MaterialProperty heightMapInfluence = null;
	MaterialProperty snowOpacity = null;

	MaterialProperty wetness = null;
	MaterialProperty waterSlopeDamp = null;
	MaterialProperty lux_FlowNormalTiling = null;
	MaterialProperty lux_FlowSpeed = null;
	MaterialProperty lux_FlowInterval = null;
	MaterialProperty lux_FlowRefraction = null;
	MaterialProperty lux_FlowNormalStrength = null;

	MaterialProperty puddleMask = null;
	MaterialProperty puddleMaskTiling = null;
	MaterialProperty syncWaterOfMaterials = null;
	MaterialProperty waterAccumulationCracksPuddles = null;
	MaterialProperty waterAccumulationCracksPuddles2 = null;

	MaterialProperty waterColor = null;
	
	MaterialProperty waterColor2 = null;

	MaterialEditor m_MaterialEditor;
	WorkflowMode m_WorkflowMode = WorkflowMode.Specular;
	ColorPickerHDRConfig m_ColorPickerHDRConfig = new ColorPickerHDRConfig(0f, 99f, 1/99f, 3f);

	bool m_FirstTimeApply = true;

	// Indent that matches the indent of the mini fields
		int kIndent = MaterialEditor.kMiniTextureFieldLabelIndentLevel + 24;
		int kIndentHalf = (MaterialEditor.kMiniTextureFieldLabelIndentLevel + 24) / 2;
		//int kShiftLabel= -180;
		int kShiftUpLine = -20;
		int kIndentToMiniTextureField = 34;

	public void FindProperties (MaterialProperty[] props)
	{
		blendMode = FindProperty ("_Mode", props);
		albedoMap = FindProperty ("_MainTex", props);
		albedoColor = FindProperty ("_Color", props);
		alphaCutoff = FindProperty ("_Cutoff", props);
		specularMap = FindProperty ("_SpecGlossMap", props, false);
		specularColor = FindProperty ("_SpecColor", props, false);
		metallicMap = FindProperty ("_MetallicGlossMap", props, false);
		metallic = FindProperty ("_Metallic", props, false);
		if (specularMap != null && specularColor != null)
			m_WorkflowMode = WorkflowMode.Specular;
		else if (metallicMap != null && metallic != null)
			m_WorkflowMode = WorkflowMode.Metallic;
		else
			m_WorkflowMode = WorkflowMode.Dielectric;
		smoothness = FindProperty ("_Glossiness", props);
		bumpScale = FindProperty ("_BumpScale", props);
		bumpMap = FindProperty ("_BumpMap", props);
		heigtMapScale = FindProperty ("_Parallax", props);
		heightMap = FindProperty("_ParallaxMap", props);
		heightMapTiling = FindProperty("_ParallaxTiling", props);
		occlusionStrength = FindProperty ("_OcclusionStrength", props);
		occlusionMap = FindProperty ("_OcclusionMap", props);
		emissionColorForRendering = FindProperty ("_EmissionColor", props);
		emissionMap = FindProperty ("_EmissionMap", props);
		detailMask = FindProperty ("_DetailMask", props);
		detailAlbedoMap = FindProperty ("_DetailAlbedoMap", props);
		detailNormalMapScale = FindProperty ("_DetailNormalMapScale", props);
		detailNormalMap = FindProperty ("_DetailNormalMap", props);
		uvSetSecondary = FindProperty ("_UVSec", props);
		// Lux
		cullingMode = FindProperty ("_Cull", props);
		cullShadowPass = FindProperty ("_CullShadowPass", props);

		doubleSided = FindProperty ("_DoubleSided", props);
		useMixMapping = FindProperty ("_UseMixMapping", props);
		mixMappingControl = FindProperty ("_MixMappingControl", props);
		useCombinedMap = FindProperty ("_UseCombinedMap", props);
		albedo2Color = FindProperty ("_Color2", props);
		specularColor2 = FindProperty ("_SpecColor2", props, false);
		smoothness2 = FindProperty ("_Glossiness2", props);
		specularMap2 = FindProperty ("_SpecGlossMap2", props, false);
		metallicMap2 = FindProperty ("_MetallicGlossMap2", props, false);
		metallic2 = FindProperty ("_Metallic2", props, false);


		combinedMap = FindProperty ("_CombinedMap", props, false);
		UVRatio = FindProperty("_UVRatio", props);
		usePOM = FindProperty ("_UsePOM", props);
		linearSteps = FindProperty ("_LinearSteps", props);
		lighting = FindProperty("_Lighting", props, false);

		translucencyStrength = FindProperty("_TranslucencyStrength", props);
		scatteringPower = FindProperty("_ScatteringPower", props);

		diffuseScatteringEnabled = FindProperty("_DiffuseScatteringEnabled", props);
		diffuseScatteringCol = FindProperty("_DiffuseScatteringCol", props);
		diffuseScatterBias = FindProperty("_DiffuseScatteringBias", props);
		diffuseScatterContraction = FindProperty("_DiffuseScatteringContraction", props);
		diffuseScatteringCol2 = FindProperty("_DiffuseScatteringCol2", props);
		diffuseScatterBias2 = FindProperty("_DiffuseScatteringBias2", props);
		diffuseScatterContraction2 = FindProperty("_DiffuseScatteringContraction2", props);

		//Snow
		snow = FindProperty("_Snow", props);
		snowMapping = FindProperty("_SnowMapping", props);
		snowSlopeDamp = FindProperty("_SnowSlopeDamp", props);
		snowTiling = FindProperty("_SnowTiling", props);
		snowNormalStrength = FindProperty("_SnowNormalStrength", props);
		snowMaskTiling = FindProperty("_SnowMaskTiling", props);
		snowDetailTiling = FindProperty("_SnowDetailTiling", props);
		snowDetailStrength = FindProperty("_SnowDetailStrength", props);
		//occlusionInfluence = FindProperty("_OcclusionInfluence", props);
		//heightMapInfluence = FindProperty("_HeightMapInfluence", props);
		snowOpacity = FindProperty("_SnowOpacity", props);
		snowAccumulation = FindProperty("_SnowAccumulation", props);

		//Wetness
		wetness = FindProperty("_Wetness", props);

		lux_FlowNormalTiling = FindProperty("_Lux_FlowNormalTiling", props);
		lux_FlowSpeed = FindProperty("_Lux_FlowSpeed", props);
		lux_FlowInterval = FindProperty("_Lux_FlowInterval", props);
		lux_FlowRefraction = FindProperty("_Lux_FlowRefraction", props);
		lux_FlowNormalStrength = FindProperty("_Lux_FlowNormalStrength", props);

		waterAccumulationCracksPuddles = FindProperty("_WaterAccumulationCracksPuddles", props);
		waterAccumulationCracksPuddles2 = FindProperty("_WaterAccumulationCracksPuddles2", props);
		
		waterSlopeDamp = FindProperty("_WaterSlopeDamp", props);
		puddleMask = FindProperty("_PuddleMask", props);
		puddleMaskTiling = FindProperty("_PuddleMaskTiling", props);

		waterColor = FindProperty("_WaterColor", props);
		waterColor2 = FindProperty("_WaterColor2", props);

		syncWaterOfMaterials = FindProperty("_SyncWaterOfMaterials", props);



	}

	public override void OnGUI (MaterialEditor materialEditor, MaterialProperty[] props)
	{
		FindProperties (props); // MaterialProperties can be animated so we do not cache them but fetch them every event to ensure animated values are updated correctly
		m_MaterialEditor = materialEditor;
		Material material = materialEditor.target as Material;

		ShaderPropertiesGUI (material);

		// Make sure that needed keywords are set up if we're switching some existing
		// material to a standard shader.
		if (m_FirstTimeApply)
		{
			SetMaterialKeywords (material, m_WorkflowMode);
			m_FirstTimeApply = false;
		}
	}

	public void ShaderPropertiesGUI (Material material)
	{
		Color guicontentColor = GUI.contentColor;
		Color guibackgroundColor = GUI.backgroundColor;
		
		Color LightingCol = Color.yellow;
		Color LightingColContent = LightingCol;
		
		Color MixmappingCol = Color.cyan;
		//MixmappingCol = new Color(0.4f,0.78f,1.0f,1.0f); // fine but not on labels
		Color MixmappingColContent = MixmappingCol;

		//Color HelpCol = Color.Lerp(GUI.contentColor, Color.black, 0.4f);
		//Color HelpCol = Color.Lerp(new Color(0.89f,0.40f,0.0f,1.0f), Color.black, 0.1f); //Color.Lerp(Color.green, Color.black, 0.5f);
//		Color HelpCol = new Color(0.2f,0.90f,0.0f,1.0f); //Color.Lerp(new Color(0.89f,0.70f,0.0f,1.0f), Color.black, 0.1f); //Color.Lerp(Color.green, Color.black, 0.5f);

//		Color HelpCol = new Color(0.25f,0.55f,1.0f,1.0f); // matches official blue
//		Color HelpCol = new Color(0.35f,0.5f,0.95f,1.0f); // matches highlight blue
//		Color HelpCol = new Color(0.30f,0.47f,1.0f,1.0f); // matches highlight blue

		Color HelpCol = new Color(0.32f,0.50f,1.0f,1.0f); // matches highlight blue


		//Color DisabledCol = HelpCol;

		Color WeatherBG = HelpCol;
		Color WeatherBGbright = GUI.backgroundColor;

		Color BoxColor = GUI.backgroundColor;

		// Colors for Indie
		if (!EditorGUIUtility.isProSkin) {

			LightingCol = new Color(1.0f,0.3f,0.0f,1.0f); // Orange
			MixmappingCol = new Color(0.1f,0.2f,0.9f,1.0f); // Blue
			HelpCol = new Color(0.18f,0.35f,0.85f,1.0f);
			WeatherBG = new Color(0.52f,0.63f,0.8f,1.0f);
			WeatherBG = Color.Lerp(guibackgroundColor, WeatherBG, 0.7f);
			// We can not tint in free?
			LightingColContent = guicontentColor;
			MixmappingColContent = guicontentColor;
			GUIStyle m_box = GUI.skin.box;
			m_box.normal.background = Texture2D.whiteTexture;
			GUI.skin.box = m_box;
			BoxColor = new Color (0.82f,0.82f,0.82f,1.0f);
			WeatherBGbright = Color.Lerp(BoxColor, WeatherBG, 0.45f );
		}

		// Custom Labels
		GUIStyle MixmappingLabel = new GUIStyle(EditorStyles.miniLabel);
		MixmappingLabel.normal.textColor = Color.Lerp(MixmappingCol, Color.black, 0.25f);
		MixmappingLabel.onNormal.textColor = MixmappingCol;
		
		GUIStyle LightingLabel = new GUIStyle(EditorStyles.miniLabel);
		LightingLabel.normal.textColor = Color.Lerp(LightingCol, Color.gray, 0.3f);
		LightingLabel.onNormal.textColor = LightingCol;

		GUIStyle HelpLabel = new GUIStyle(EditorStyles.miniLabel);
		HelpLabel.normal.textColor = HelpCol;
		HelpLabel.onNormal.textColor = HelpCol;


		// Use default labelWidth
		EditorGUIUtility.labelWidth = 0f;
		var MyGuiContent = new GUIContent ("Lable", "Tooltip");

		// Detect any changes to the material
		EditorGUI.BeginChangeCheck();
		{
			Color diffScatterCol;

			BlendModePopup();

			CullingModePopup();
			if (cullingMode.floatValue == (float)CullingMode.Off) {
				m_MaterialEditor.ShaderProperty(doubleSided, "Double Sided");
			}

			/*
			if (lighting.floatValue != 0){
				GUI.contentColor = LightingColContent;	
			}
			m_MaterialEditor.ShaderProperty(lighting, "Lighting");
			GUI.contentColor = guicontentColor;
			*/

			GUI.backgroundColor = BoxColor;				
			EditorGUILayout.BeginVertical("Box");
			GUI.backgroundColor = guibackgroundColor;

			GUILayout.Space(4);
			GUI.contentColor = MixmappingColContent;
				m_MaterialEditor.ShaderProperty(useMixMapping, "Enable MixMapping");
				if(useMixMapping.floatValue == 1.0f) {
					//MixModePopup();
					EditorGUI.indentLevel++;

						if (lighting.floatValue != 0){
							GUI.contentColor = LightingColContent;
							GUILayout.Label ("Translucent Lighting: Only first texture supports Translucency.", LightingLabel);
							GUILayout.Space(2);
							GUI.contentColor = guicontentColor;
						}

						if(mixMappingControl.floatValue == 1.0f) {
							GUILayout.Label ("MixMapping will be controlled by the assigned Detail Mask (G).", MixmappingLabel);
						}
						else {
							GUILayout.Label ("MixMapping will be controlled by Vertex Color Red by default.", MixmappingLabel);
						}
						if (detailAlbedoMap.textureValue == null && detailNormalMap.textureValue == null  ) {
							GUILayout.Space(-6);
							GUILayout.Label ("MixMapping will be disabled unless you assign secondary maps.", MixmappingLabel);
							GUILayout.Space(-6);
							GUILayout.Label ("Water and snow accumulation might be totally broken unless you do so though.", MixmappingLabel);	
						}
						GUI.contentColor = guicontentColor;

						m_MaterialEditor.ShaderProperty(mixMappingControl, "Use Detail Mask");
					EditorGUI.indentLevel--;

				}
			GUI.contentColor = guicontentColor;
			GUILayout.Space(4);
			EditorGUILayout.EndVertical();
			GUILayout.Space(4);
			

			// Primary properties
			GUI.backgroundColor = BoxColor;
			EditorGUILayout.BeginVertical("Box");
			GUI.backgroundColor = guibackgroundColor;
			
				if(useMixMapping.floatValue != 1.0f) {
					GUILayout.Label (Styles.primaryMapsText, EditorStyles.boldLabel);
				}
				else {
					GUILayout.Label ("Primary Texture Set (mix mapped)", EditorStyles.boldLabel);
				}
			//	EditorGUI.HelpBox
				
				GUILayout.Space(2);

//DrawShaderProperty_Tooltip (diffuseScatteringCol, Styles.combineMapText);

				DoAlbedoArea(material);

				m_MaterialEditor.ShaderProperty(diffuseScatteringCol, "Diffuse Scattering", MaterialEditor.kMiniTextureFieldLabelIndentLevel);
				m_MaterialEditor.ShaderProperty(diffuseScatterBias, "Scatter Bias", MaterialEditor.kMiniTextureFieldLabelIndentLevel);
				m_MaterialEditor.ShaderProperty(diffuseScatterContraction, "Scatter Power", MaterialEditor.kMiniTextureFieldLabelIndentLevel);
				GUILayout.Space(6);

				DoSpecularMetallicArea();
				m_MaterialEditor.TexturePropertySingleLine(Styles.normalMapText, bumpMap, bumpMap.textureValue != null ? bumpScale : null);


			//	Heightmaps
				// Detail Blending
				if(useMixMapping.floatValue == 0.0f) {
					m_MaterialEditor.TexturePropertySingleLine(Styles.heightMapText, heightMap, heightMap.textureValue != null ? heigtMapScale : null);
				}
				// Mix Mapping
				else {
					GUI.contentColor = MixmappingColContent;
					GUILayout.Space(2);
					if(mixMappingControl.floatValue != 1.0f) {
					// Vertex Colors
						GUILayout.Label ("MixMapping: You should assign a combined Height Map.", MixmappingLabel);
						if (puddleMask.floatValue == 1.0f && wetness.floatValue != 0.0f) {
							GUILayout.Space(-6);
							GUILayout.Label("Puddle Mask must be stored in (R).", MixmappingLabel);
						}
						m_MaterialEditor.TexturePropertySingleLine(Styles.heightMapMixMapText, heightMap, heightMap.textureValue != null ? heigtMapScale : null);
					}
					else {
						GUILayout.Label ("MixMapping: You should assign a combined Height and Mix Map.", MixmappingLabel);
						if (puddleMask.floatValue == 1.0f && wetness.floatValue != 0.0f) {
							GUILayout.Space(-6);
							GUILayout.Label("Puddle Mask must be stored in (R).", MixmappingLabel);
						}
						m_MaterialEditor.TexturePropertySingleLine(Styles.heightMapMixMapMaskText, heightMap, heightMap.textureValue != null ? heigtMapScale : null);
					}
					GUI.contentColor = guicontentColor;
				}
				if (heightMap.textureValue != null ) {
					m_MaterialEditor.ShaderProperty(heightMapTiling, "Mask Tiling", MaterialEditor.kMiniTextureFieldLabelIndentLevel);
GUILayout.Space(2);
					m_MaterialEditor.ShaderProperty(UVRatio, "UV Ratio (XY) Scale(Z) Baked(W)", MaterialEditor.kMiniTextureFieldLabelIndentLevel);
GUILayout.Space(-16);
					m_MaterialEditor.ShaderProperty(usePOM, "Enable POM", MaterialEditor.kMiniTextureFieldLabelIndentLevel);
					if (usePOM.floatValue != 0.0f ) {
						m_MaterialEditor.ShaderProperty(linearSteps, "Linear Steps", MaterialEditor.kMiniTextureFieldLabelIndentLevel);
						linearSteps.floatValue = (int)linearSteps.floatValue;
					}
					GUILayout.Space(6);
				}
				
			//	Occlusion
				if(lighting.floatValue == 0.0f) {
					m_MaterialEditor.TexturePropertySingleLine(Styles.occlusionText, occlusionMap, occlusionMap.textureValue != null ? occlusionStrength : null);
				}

			//	Occlusion and Translucency as combined map
				else {
					GUI.contentColor = LightingColContent;
						GUILayout.Label ("Translucent Lighting: You should combine Occlusion and Translucency.", LightingLabel);
						//m_MaterialEditor.ShaderProperty(useCombinedMap, "Use combined Map");
						DrawShaderProperty_Tooltip (useCombinedMap, Styles.combineMapText);
						GUILayout.Space(2);
					GUI.contentColor = guicontentColor;

					if(useCombinedMap.floatValue == 0.0f) {
						EditorGUILayout.BeginHorizontal();
							GUILayout.Label ("", GUILayout.Width(kIndent));
							EditorGUILayout.BeginVertical();
								m_MaterialEditor.TexturePropertySingleLine(Styles.occlusionText, occlusionMap, occlusionMap.textureValue != null ? occlusionStrength : null);
							//	if(lighting.floatValue == 1.0f) {
							//		GUILayout.Space(-2);
							//		m_MaterialEditor.ShaderProperty(translucencyStrength, "Translucency");
									//GUILayout.Space(6);
							//	}
							EditorGUILayout.EndVertical();
						EditorGUILayout.EndHorizontal();
					}
					else {
						EditorGUILayout.BeginHorizontal();
							GUILayout.Label ("", GUILayout.Width(kIndent-4));
							EditorGUILayout.BeginVertical();
								m_MaterialEditor.TexturePropertySingleLine(Styles.combineMap_TranslucencyText, combinedMap);
								GUILayout.Space(kShiftUpLine);
								EditorGUILayout.BeginHorizontal();
									GUILayout.Space(kIndentToMiniTextureField);
									GUI.contentColor = LightingColContent;
										GUILayout.Label ("Occlusion (G) Translucency (B)");
									GUI.contentColor = guicontentColor;
								EditorGUILayout.EndHorizontal();
							EditorGUILayout.EndVertical();
						EditorGUILayout.EndHorizontal();
						m_MaterialEditor.ShaderProperty(occlusionStrength, "Occlusion Strength", MaterialEditor.kMiniTextureFieldLabelIndentLevel);
						//GUILayout.Space(6);	
					}
					//GUILayout.Space(-2);
					m_MaterialEditor.ShaderProperty(translucencyStrength, "Translucency", MaterialEditor.kMiniTextureFieldLabelIndentLevel);
					m_MaterialEditor.ShaderProperty(scatteringPower, "Scattering Power", MaterialEditor.kMiniTextureFieldLabelIndentLevel);
					GUILayout.Space(6);
				}
				
			//	Emission
				DoEmissionArea(material);

			// 	Detail Mask
				// Warn about mix mapping
				if (useMixMapping.floatValue == 1.0f && mixMappingControl.floatValue == 1.0f && heightMap.textureValue == null ) {
					GUILayout.Space(2);
					GUI.contentColor = MixmappingColContent;
					GUILayout.Label ("MixMapping: Detail Mask only needed if no Height Maps are used.", MixmappingLabel);
					GUI.contentColor = guicontentColor;		
				}
				// No detail mask if mix mapping is selected and Height Map is assigned or vertex colors are choosen
			//	if (useMixMapping.floatValue == 0.0f || (useMixMapping.floatValue == 1.0f && heightMap.textureValue == null) || (useMixMapping.floatValue == 1.0f && mixMappingControl.floatValue == 1.0f) ) {	
				if (useMixMapping.floatValue != 1.0f || ( useMixMapping.floatValue == 1.0f && mixMappingControl.floatValue == 1.0f && heightMap.textureValue == null) ) {
					//if ( useMixMapping.floatValue == 1.0f && mixMappingControl.floatValue == 1.0f && )
					m_MaterialEditor.TexturePropertySingleLine(Styles.detailMaskText, detailMask);
				}
				if (useMixMapping.floatValue == 1.0f && mixMappingControl.floatValue == 1.0f && heightMap.textureValue != null) {
					GUI.contentColor = MixmappingColContent;
					GUILayout.Label ("MixMapping: Detail Mask to be added to the combined Height Maps.", MixmappingLabel);
					GUI.contentColor = guicontentColor;	
				}
				
				EditorGUI.BeginChangeCheck();
				GUILayout.Space(4);
					m_MaterialEditor.TextureScaleOffsetProperty(albedoMap);
				GUILayout.Space(2);

				if (EditorGUI.EndChangeCheck()) {
					emissionMap.textureScaleAndOffset = albedoMap.textureScaleAndOffset; // Apply the main texture scale and offset to the emission texture as well, for Enlighten's sake
				}
			EditorGUILayout.EndVertical();
			GUILayout.Space(4);

			// Secondary properties
			GUI.backgroundColor = BoxColor;
			EditorGUILayout.BeginVertical("Box");
			GUI.backgroundColor = guibackgroundColor;
				if(useMixMapping.floatValue != 1.0f) {
						GUILayout.Label(Styles.secondaryMapsText, EditorStyles.boldLabel);
						m_MaterialEditor.TexturePropertySingleLine(Styles.detailAlbedoText, detailAlbedoMap);
						m_MaterialEditor.TexturePropertySingleLine(Styles.detailNormalMapText, detailNormalMap, detailNormalMapScale);
						m_MaterialEditor.TextureScaleOffsetProperty(detailAlbedoMap);
						m_MaterialEditor.ShaderProperty(uvSetSecondary, Styles.uvSetLabel.text);
				}
				// Lux
				else {

					GUILayout.Space(4);
					
					GUILayout.Label("Secondary Texture Set (mix mapped)", EditorStyles.boldLabel);
					GUILayout.Space(-4);
					GUI.contentColor = MixmappingColContent;
						GUILayout.Label ("MixMapping: Albedo Map should contain Occlusion in (A).", MixmappingLabel);
						m_MaterialEditor.TexturePropertySingleLine(Styles.detailAlbedoMixMappingText, detailAlbedoMap, albedo2Color);
					GUI.contentColor = guicontentColor;
					//
					m_MaterialEditor.ShaderProperty(diffuseScatteringCol2, "Diffuse Scattering", MaterialEditor.kMiniTextureFieldLabelIndentLevel);
					m_MaterialEditor.ShaderProperty(diffuseScatterBias2, "Scatter Bias", MaterialEditor.kMiniTextureFieldLabelIndentLevel);
					m_MaterialEditor.ShaderProperty(diffuseScatterContraction2, "Scatter Power", MaterialEditor.kMiniTextureFieldLabelIndentLevel);
					GUILayout.Space(6);
					//
					DoSpecularMetallicArea2();
					m_MaterialEditor.TexturePropertySingleLine(Styles.detailNormalMixMappingMapText, detailNormalMap, detailNormalMapScale);

					GUILayout.Space(4);
					m_MaterialEditor.TextureScaleOffsetProperty(detailAlbedoMap);
					m_MaterialEditor.ShaderProperty(uvSetSecondary, Styles.uvSetLabel.text);
				}
			EditorGUILayout.EndVertical();
			GUILayout.Space(4);

		//	Dynamic Weather
			GUI.backgroundColor = WeatherBG;
			EditorGUILayout.BeginVertical("Box");
				GUI.backgroundColor = guibackgroundColor;
				GUILayout.Label("Dynamic Weather", EditorStyles.boldLabel);
				GUILayout.Space(4);
				GUI.backgroundColor = WeatherBGbright; //BoxColor;
				EditorGUILayout.BeginVertical("Box");
				GUI.backgroundColor = guibackgroundColor;
					m_MaterialEditor.ShaderProperty(snow, "Snow");
					if(snow.floatValue != 0) {
						GUILayout.Label("Snow is masked by vertex color blue.", HelpLabel);
						GUILayout.Space(4);
						m_MaterialEditor.ShaderProperty(snowMapping, "Snow Mapping");
						if (snowMapping.floatValue == 1) {
							GUILayout.Label("World Space Snow Mapping: Please check your 'UV Ratio'\nand 'Size' settings in case you use POM.", HelpLabel);
						}
						m_MaterialEditor.ShaderProperty(snowSlopeDamp, "Snow Slope Damp");
						GUILayout.Space(2);

						EditorGUI.BeginChangeCheck();
							var snowvalue = snowAccumulation.vectorValue;
							GUILayout.Label("Snow Accumulation");
							EditorGUILayout.BeginHorizontal();
								GUILayout.Label ("", GUILayout.Width(kIndentHalf));
								EditorGUILayout.BeginVertical();
									MyGuiContent = new GUIContent ("Material Constant ●", "Lets you specify a 'constant' snow amount per material.");
									var snowconstant = EditorGUILayout.Slider(MyGuiContent, snowvalue.x, 0.0f, 2.0f);
									MyGuiContent = new GUIContent ("Global Influence ●", "Lets you adjust how fast snow will accumulate according to the global script controlled snow amount.\nSet it to '0' in case you do not want any script driven snow accumulation.");
									var snowmultiplier = EditorGUILayout.Slider(MyGuiContent, snowvalue.y, 0.0f, 4.0f);
								EditorGUILayout.EndVertical();
							EditorGUILayout.EndHorizontal();
							GUILayout.Space(4);
							

						if (EditorGUI.EndChangeCheck ()) {
							snowAccumulation.vectorValue = new Vector4 (snowconstant, snowmultiplier, 0, 0); //constant1, multiplier1);
						}

						GUILayout.Label("Snow textures must be assigned globally.", HelpLabel);
						if (snowMapping.floatValue == 1) {
							GUILayout.Space(-2);
							GUILayout.Label("World Space Snow Mapping: tiling and stength values\nare controlled globally.", HelpLabel);
							GUILayout.Space(4);
						}
						else {
							Vector2 tiling = new Vector2 (0,0);
							//m_MaterialEditor.ShaderProperty(snowMaskTiling, "Snow Mask Tiling");
							tiling.x = snowMaskTiling.vectorValue.x;
							tiling.y = snowMaskTiling.vectorValue.y;
							GUILayout.Space(-2);
							EditorGUI.BeginChangeCheck();
							EditorGUILayout.BeginVertical();
								EditorGUILayout.BeginHorizontal();
									EditorGUILayout.PrefixLabel("Snow Mask Tiling");
									tiling = EditorGUILayout.Vector2Field("", tiling);
								EditorGUILayout.EndHorizontal();
							EditorGUILayout.EndVertical();
							GUILayout.Space(2);
							if (EditorGUI.EndChangeCheck ()) {
								snowMaskTiling.vectorValue = new Vector4(tiling.x, tiling.y, 0.0f, 0.0f);
							}
							//m_MaterialEditor.ShaderProperty(snowTiling, "Snow Tex Tiling");
							tiling.x = snowTiling.vectorValue.x;
							tiling.y = snowTiling.vectorValue.y;
							GUILayout.Space(2);
							EditorGUI.BeginChangeCheck();
							EditorGUILayout.BeginVertical();
								EditorGUILayout.BeginHorizontal();
									EditorGUILayout.PrefixLabel("Snow Tex Tiling");
									tiling = EditorGUILayout.Vector2Field("", tiling);
								EditorGUILayout.EndHorizontal();
							EditorGUILayout.EndVertical();
							GUILayout.Space(2);
							if (EditorGUI.EndChangeCheck ()) {
								snowTiling.vectorValue = new Vector4(tiling.x, tiling.y, 0.0f, 0.0f);
							}
							m_MaterialEditor.ShaderProperty(snowNormalStrength, "Snow Normal Strength");
							//m_MaterialEditor.ShaderProperty(snowDetailTiling, "Snow Detail Tiling");
							tiling.x = snowDetailTiling.vectorValue.x;
							tiling.y = snowDetailTiling.vectorValue.y;
							GUILayout.Space(2);
							EditorGUI.BeginChangeCheck();
							EditorGUILayout.BeginVertical();
								EditorGUILayout.BeginHorizontal();
									EditorGUILayout.PrefixLabel("Snow Detail Tiling");
									tiling = EditorGUILayout.Vector2Field("", tiling);
								EditorGUILayout.EndHorizontal();
							EditorGUILayout.EndVertical();
							GUILayout.Space(2);
							if (EditorGUI.EndChangeCheck ()) {
								snowDetailTiling.vectorValue = new Vector4(tiling.x, tiling.y, 0.0f, 0.0f);
							}
							m_MaterialEditor.ShaderProperty(snowDetailStrength, "Snow Detail Strength");
							GUILayout.Space(4);
						}

						DrawShaderProperty_Tooltip (snowOpacity, Styles.snowOpacityText);
					}
				EditorGUILayout.EndVertical();
				
				//GUILayout.Space(4);
				
				GUI.backgroundColor = WeatherBGbright; //BoxColor;
				EditorGUILayout.BeginVertical("Box");
				GUI.backgroundColor = guibackgroundColor;
					m_MaterialEditor.ShaderProperty(wetness, "Wetness");
					GUI.contentColor = guicontentColor;
					if (wetness.floatValue != 0.0f) {
						GUILayout.Space(4);
						m_MaterialEditor.ShaderProperty(waterSlopeDamp, "Water Slope Damp");
						PuddleMaskPopup();
						if (puddleMask.floatValue == 1.0f) {
							m_MaterialEditor.ShaderProperty(puddleMaskTiling, "Puddle Mask Tiling");	
						}
						GUILayout.Space(4);
						if (wetness.floatValue > 1.0f) {
							GUILayout.Space(2);
							GUILayout.Label("Ripple and flow bump textures must be assigned globally.", HelpLabel);
						}
						if (wetness.floatValue > 2.0f) {
							m_MaterialEditor.ShaderProperty(lux_FlowNormalTiling, "Flow Normal Tiling");
							m_MaterialEditor.ShaderProperty(lux_FlowSpeed, "Flow Animation Speed");
							m_MaterialEditor.ShaderProperty(lux_FlowInterval, "Flow Animation Interval");
							m_MaterialEditor.ShaderProperty(lux_FlowNormalStrength, "Flow Normal Strength");
							m_MaterialEditor.ShaderProperty(lux_FlowRefraction, "Flow Refraction ");
						}

						
						GUILayout.Space(4);
						GUILayout.Label("Primary Texture Set", EditorStyles.boldLabel);
						GUILayout.Space(4);
						MyGuiContent = new GUIContent ("Water Color ●", "Alpha controls opacity of Translucency and Emission as well.");
						DrawShaderProperty_Tooltip (waterColor, MyGuiContent);
						GUILayout.Space(4);
						EditorGUI.BeginChangeCheck();
							var value = waterAccumulationCracksPuddles.vectorValue;
							GUILayout.Label("Water Accumulation in Cracks");
							EditorGUILayout.BeginHorizontal();
								GUILayout.Label ("", GUILayout.Width(kIndentHalf));
								EditorGUILayout.BeginVertical();
									MyGuiContent = new GUIContent ("Material Constant ●", "Lets you specify a 'constant' wetness per material.");
									var constant = EditorGUILayout.Slider(MyGuiContent, value.x, 0.0f, 2.0f);
									MyGuiContent = new GUIContent ("Global Influence ●", "Lets you adjust how fast water will accumulate according to the global script controlled water level.\nSet it to '0' in case you do not want any script driven water accumulation.");
									var multiplier = EditorGUILayout.Slider(MyGuiContent,value.y,0.0f, 4.0f);
								EditorGUILayout.EndVertical();
							EditorGUILayout.EndHorizontal();
							GUILayout.Space(4);
							GUILayout.Label("Water Accumulation in Puddles");
							EditorGUILayout.BeginHorizontal();
								GUILayout.Label ("", GUILayout.Width(kIndentHalf));
								EditorGUILayout.BeginVertical();
									MyGuiContent = new GUIContent ("Material Constant ●", "Lets you specify a 'constant' wetness per material.");
									var constant1 = EditorGUILayout.Slider(MyGuiContent, value.z, 0.0f, 2.0f);
									MyGuiContent = new GUIContent ("Global Influence ●", "Lets you adjust how fast water will accumulate according to the global script controlled water level.\nSet it to '0' in case you do not want any script driven water accumulation.");
									var multiplier1 = EditorGUILayout.Slider(MyGuiContent,value.w,0.0f, 4.0f);
									//GUILayout.Space(-2);
									if (wetness.floatValue > 2.0f) {
										GUILayout.Label("The last parameter also controls flow speed according\nto the given temperature. If set to '0' temperature will\nnot have any influence on the flow speed.", HelpLabel);
									}
								EditorGUILayout.EndVertical();
							EditorGUILayout.EndHorizontal();

						if (EditorGUI.EndChangeCheck ()) {
							waterAccumulationCracksPuddles.vectorValue = new Vector4 (constant, multiplier, constant1, multiplier1);
						}
					//EditorGUILayout.EndVertical();

					//GUILayout.Space(4);
				
						if(useMixMapping.floatValue == 1.0f) {
							bool sync = (syncWaterOfMaterials.floatValue == 0.0) ? false : true;
							GUILayout.Space(8);
							
							//GUILayout.Space(-4);
							GUILayout.Label("Secondary Texture Set", EditorStyles.boldLabel);
							if (!sync) {
								GUILayout.Space(-4);
								GUI.contentColor = MixmappingColContent;
									GUILayout.Label ("MixMapping: Secondary texture set may use special settings.", MixmappingLabel);
								GUI.contentColor = guicontentColor;
							}

							EditorGUI.BeginChangeCheck();
							sync = EditorGUILayout.Toggle("Sync Settings", sync);
							if (EditorGUI.EndChangeCheck ()) {
								syncWaterOfMaterials.floatValue = (sync == true) ? 1.0f : 0.0f;	
							}
							GUILayout.Space(4);
							if(sync) {
								waterColor2.colorValue = waterColor.colorValue;
								waterAccumulationCracksPuddles2.vectorValue = waterAccumulationCracksPuddles.vectorValue;
							}
							else {
								MyGuiContent = new GUIContent ("Water Color ●", "Alpha controls opacity of Translucency and Emission as well.");
								DrawShaderProperty_Tooltip (waterColor2, MyGuiContent);
								GUILayout.Space(4);
								EditorGUI.BeginChangeCheck();
									var value2 = waterAccumulationCracksPuddles2.vectorValue;
									GUILayout.Label("Water Accumulation in Cracks");
									EditorGUILayout.BeginHorizontal();
										GUILayout.Label ("", GUILayout.Width(kIndentHalf));
										EditorGUILayout.BeginVertical();
											MyGuiContent = new GUIContent ("Material Constant ●", "Lets you specify a 'constant' wetness per material.");
											var constant2 = EditorGUILayout.Slider(MyGuiContent, value2.x, 0.0f, 2.0f);
											MyGuiContent = new GUIContent ("Global Influence ●", "Lets you adjust how fast water will accumulate according to the global script controlled water level.\nSet it to '0' in case you do not want any script driven water accumulation.");
											var multiplier2 = EditorGUILayout.Slider(MyGuiContent, value2.y, 0.0f, 4.0f);
										EditorGUILayout.EndVertical();
									EditorGUILayout.EndHorizontal();
									GUILayout.Space(4);
									GUILayout.Label("Water Accumulation in Puddles");
									EditorGUILayout.BeginHorizontal();
										GUILayout.Label ("", GUILayout.Width(kIndentHalf));
										EditorGUILayout.BeginVertical();
											MyGuiContent = new GUIContent ("Material Constant ●", "Lets you specify a 'constant' wetness per material.");
											var constant3 = EditorGUILayout.Slider(MyGuiContent, value2.z, 0.0f, 2.0f);
											MyGuiContent = new GUIContent ("Global Influence ●", "Lets you adjust how fast water will accumulate according to the global script controlled water level.\nSet it to '0' in case you do not want any script driven water accumulation.");
											var multiplier3 = EditorGUILayout.Slider(MyGuiContent, value2.w, 0.0f, 4.0f);
										EditorGUILayout.EndVertical();
									EditorGUILayout.EndHorizontal();
								if (EditorGUI.EndChangeCheck ()) {
									waterAccumulationCracksPuddles2.vectorValue = new Vector4 (constant2, multiplier2, constant3, multiplier3);
								}
							}
						}
					}
				EditorGUILayout.EndVertical(); // End Wetness
			EditorGUILayout.EndVertical(); // End Weather
			
			GUILayout.Space(4);

			// Check if Diffuse Scattering shall be enabled
			diffScatterCol = diffuseScatteringCol.colorValue;
			if(useMixMapping.floatValue == 1.0f) {
				diffScatterCol = diffScatterCol + diffuseScatteringCol2.colorValue;
			}
			diffScatterCol.a = 1.0f;
			if (diffScatterCol != Color.black) {
				diffuseScatteringEnabled.floatValue = 1.0f;
			}
			else {
				diffuseScatteringEnabled.floatValue = 0.0f;
			}
		}

		

		if (EditorGUI.EndChangeCheck())
		{	
			// Check if Diffuse Scattering shall be enabled
			Color diffScatterCol = diffuseScatteringCol.colorValue;
			if(useMixMapping.floatValue == 1.0f) {
				diffScatterCol = diffScatterCol + diffuseScatteringCol2.colorValue;
			}
			diffScatterCol.a = 1.0f;
			if (diffScatterCol != Color.black) {
				diffuseScatteringEnabled.floatValue = 1.0f;
			}
			else {
				diffuseScatteringEnabled.floatValue = 0.0f;
			}

			foreach (var obj in blendMode.targets)
				MaterialChanged((Material)obj, m_WorkflowMode);
		}
	}


	void DrawShaderProperty_Tooltip (MaterialProperty prop, GUIContent guicontent) {
		EditorGUILayout.BeginVertical();
			GUILayout.Label (new GUIContent ("", guicontent.tooltip) );
			GUILayout.Space(kShiftUpLine);
			m_MaterialEditor.ShaderProperty(prop, guicontent.text);
		EditorGUILayout.EndVertical();
	}


	internal void DetermineWorkflow(MaterialProperty[] props)
	{
		if (FindProperty("_SpecGlossMap", props, false) != null && FindProperty("_SpecColor", props, false) != null)
			m_WorkflowMode = WorkflowMode.Specular;
		else if (FindProperty("_MetallicGlossMap", props, false) != null && FindProperty("_Metallic", props, false) != null)
			m_WorkflowMode = WorkflowMode.Metallic;
		else
			m_WorkflowMode = WorkflowMode.Dielectric;
	}

	public override void AssignNewShaderToMaterial (Material material, Shader oldShader, Shader newShader)
	{
        // _Emission property is lost after assigning Standard shader to the material
        // thus transfer it before assigning the new shader
        if (material.HasProperty("_Emission"))
        {
            material.SetColor("_EmissionColor", material.GetColor("_Emission"));
        }

		base.AssignNewShaderToMaterial(material, oldShader, newShader);

		if (oldShader == null || !oldShader.name.Contains("Legacy Shaders/"))
			return;

		BlendMode blendMode = BlendMode.Opaque;
		if (oldShader.name.Contains("/Transparent/Cutout/"))
		{
			blendMode = BlendMode.Cutout;
		}
		else if (oldShader.name.Contains("/Transparent/"))
		{
			// NOTE: legacy shaders did not provide physically based transparency
			// therefore Fade mode
			blendMode = BlendMode.Fade;
		}
		material.SetFloat("_Mode", (float)blendMode);

		DetermineWorkflow( MaterialEditor.GetMaterialProperties (new Material[] { material }) );
		MaterialChanged(material, m_WorkflowMode);
	}

	void BlendModePopup()
	{
		EditorGUI.showMixedValue = blendMode.hasMixedValue;
		var mode = (BlendMode)blendMode.floatValue;

		EditorGUI.BeginChangeCheck();
		mode = (BlendMode)EditorGUILayout.Popup(Styles.renderingMode, (int)mode, Styles.blendNames);
		if (EditorGUI.EndChangeCheck())
		{
			m_MaterialEditor.RegisterPropertyChangeUndo("Rendering Mode");
			blendMode.floatValue = (float)mode;
		}

		EditorGUI.showMixedValue = false;
	}

	void CullingModePopup()
	{
		EditorGUI.showMixedValue = cullingMode.hasMixedValue;
		var cmode = (CullingMode)cullingMode.floatValue;

		EditorGUI.BeginChangeCheck();
		cmode = (CullingMode)EditorGUILayout.Popup(Styles.cullingMode, (int)cmode, Styles.cullingNames);
		if (EditorGUI.EndChangeCheck())
		{
			m_MaterialEditor.RegisterPropertyChangeUndo("Culling Mode");
			cullingMode.floatValue = (float)cmode;
			cullShadowPass.floatValue = (float)cmode;
		}

		EditorGUI.showMixedValue = false;
	}

	void MixModePopup()
	{
		EditorGUI.showMixedValue = mixMappingControl.hasMixedValue;
		var mixmode = (MixMapControl)mixMappingControl.floatValue;
		EditorGUI.BeginChangeCheck();
		EditorGUI.indentLevel++;
			mixmode = (MixMapControl)EditorGUILayout.Popup(new GUIContent("Control Mixing"), (int)mixmode, new GUIContent[2]{new GUIContent("by VertexColor Red"), new GUIContent("by Detail Mask (G)")} );
		EditorGUI.indentLevel--;
		if (EditorGUI.EndChangeCheck())
		{
			m_MaterialEditor.RegisterPropertyChangeUndo("Mix Map Control");
			mixMappingControl.floatValue = (float)mixmode;
		}
	}

	void PuddleMaskPopup()
	{
		EditorGUI.showMixedValue = puddleMask.hasMixedValue;
		var puddlemask = (PuddleMask)puddleMask.floatValue;
		EditorGUI.BeginChangeCheck();
		puddlemask = (PuddleMask)EditorGUILayout.Popup(new GUIContent("Puddle Mask"), (int)puddlemask, new GUIContent[2]{new GUIContent("VertexColor Green"), new GUIContent("Height Map (R)")} );
		if (EditorGUI.EndChangeCheck())
		{
			m_MaterialEditor.RegisterPropertyChangeUndo("Puddle Mask");
			puddleMask.floatValue = (float)puddlemask;
		}
	}

	void DoAlbedoArea(Material material)
	{
		m_MaterialEditor.TexturePropertySingleLine(Styles.albedoText, albedoMap, albedoColor);
		if (((BlendMode)material.GetFloat("_Mode") == BlendMode.Cutout))
		{
			m_MaterialEditor.ShaderProperty(alphaCutoff, Styles.alphaCutoffText.text, MaterialEditor.kMiniTextureFieldLabelIndentLevel);
		}
	}

	void DoEmissionArea(Material material)
	{
		float brightness = emissionColorForRendering.colorValue.maxColorComponent;
		bool showHelpBox = !HasValidEmissiveKeyword(material);
		bool showEmissionColorAndGIControls = brightness > 0.0f;
		
		bool hadEmissionTexture = emissionMap.textureValue != null;

		// Texture and HDR color controls
		m_MaterialEditor.TexturePropertyWithHDRColor(Styles.emissionText, emissionMap, emissionColorForRendering, m_ColorPickerHDRConfig, false);

		// If texture was assigned and color was black set color to white
		if (emissionMap.textureValue != null && !hadEmissionTexture && brightness <= 0f)
			emissionColorForRendering.colorValue = Color.white;

		// Dynamic Lightmapping mode
		if (showEmissionColorAndGIControls)
		{
			bool shouldEmissionBeEnabled = ShouldEmissionBeEnabled(emissionColorForRendering.colorValue);
			EditorGUI.BeginDisabledGroup(!shouldEmissionBeEnabled);

			m_MaterialEditor.LightmapEmissionProperty (MaterialEditor.kMiniTextureFieldLabelIndentLevel + 1);

			EditorGUI.EndDisabledGroup();
		}

		if (showHelpBox)
		{
			EditorGUILayout.HelpBox(Styles.emissiveWarning.text, MessageType.Warning);
		}
	}

	void DoSpecularMetallicArea()
	{
		if (m_WorkflowMode == WorkflowMode.Specular)
		{
			if (specularMap.textureValue == null) {
				//m_MaterialEditor.TexturePropertyTwoLines(Styles.specularMapText, specularMap, specularColor, Styles.smoothnessText, smoothness);
				m_MaterialEditor.TexturePropertySingleLine(Styles.specularMapText, specularMap, specularColor);
				m_MaterialEditor.ShaderProperty(smoothness, Styles.smoothnessText.text, MaterialEditor.kMiniTextureFieldLabelIndentLevel);
				GUILayout.Space(4);
			}
			else {
				m_MaterialEditor.TexturePropertySingleLine(Styles.specularMapText, specularMap);
			}

		}
		else if (m_WorkflowMode == WorkflowMode.Metallic)
		{
			if (metallicMap.textureValue == null)
				m_MaterialEditor.TexturePropertyTwoLines(Styles.metallicMapText, metallicMap, metallic, Styles.smoothnessText, smoothness);
			else
				m_MaterialEditor.TexturePropertySingleLine(Styles.metallicMapText, metallicMap);
		}
	}

	void DoSpecularMetallicArea2()
	{
		if (m_WorkflowMode == WorkflowMode.Specular)
		{
			if (specularMap2.textureValue == null) {
				//m_MaterialEditor.TexturePropertyTwoLines(Styles.specularMapText, specularMap2, specularColor2, Styles.smoothnessText, smoothness2);
				m_MaterialEditor.TexturePropertySingleLine(Styles.specularMapText, specularMap2, specularColor2);
				m_MaterialEditor.ShaderProperty(smoothness2, Styles.smoothnessText.text, MaterialEditor.kMiniTextureFieldLabelIndentLevel);
				GUILayout.Space(4);
			}
			else {
				m_MaterialEditor.TexturePropertySingleLine(Styles.specularMapText, specularMap2);
			}

		}
		else if (m_WorkflowMode == WorkflowMode.Metallic)
		{
			if (metallicMap2.textureValue == null)
				m_MaterialEditor.TexturePropertyTwoLines(Styles.metallicMapText, metallicMap2, metallic2, Styles.smoothnessText, smoothness2);
			else
				m_MaterialEditor.TexturePropertySingleLine(Styles.metallicMapText, metallicMap2);
		}
	}

	public static void SetupMaterialWithCullingMode(Material material, CullingMode cull) {
		switch (cull) {
			case CullingMode.Back:
				material.SetFloat("_Cull", (int)UnityEngine.Rendering.CullMode.Back);
				break;
			case CullingMode.Front:	
				material.SetFloat("_Cull", (int)UnityEngine.Rendering.CullMode.Front);
				break;
			case CullingMode.Off:
				material.SetFloat("_Cull", (int)UnityEngine.Rendering.CullMode.Off);
				break;
		}
	}

	public static void SetupMaterialWithLightingMode(Material material, int lighting) {
		switch (lighting) {
			// Standard
			case 0:
				material.DisableKeyword("LUX_TRANSLUCENTLIGHTING");
				material.DisableKeyword("LUX_PUDDLEMASKTILING");
				break;
			// Translucent
			case 1:
				material.EnableKeyword("LUX_TRANSLUCENTLIGHTING");
				material.DisableKeyword("LUX_PUDDLEMASKTILING");
				break;
			// Anisotropic
			case 2:
				material.DisableKeyword("LUX_TRANSLUCENTLIGHTING");
				material.EnableKeyword("LUX_PUDDLEMASKTILING");
				break;
		}
	}

	public static void SetupMaterialWithWetnessMode(Material material, int wetness) {
		switch (wetness) {
			// None
			case 0:
				material.DisableKeyword("_WETNESS_SIMPLE");
				material.DisableKeyword("_WETNESS_RIPPLES");
				material.DisableKeyword("_WETNESS_FLOW");
				material.DisableKeyword("_WETNESS_FULL");
				break;
			// Simple
			case 1:
				material.EnableKeyword("_WETNESS_SIMPLE");
				material.DisableKeyword("_WETNESS_RIPPLES");
				material.DisableKeyword("_WETNESS_FLOW");
				material.DisableKeyword("_WETNESS_FULL");
				break;
			// Ripples
			case 2:
				material.DisableKeyword("_WETNESS_SIMPLE");
				material.EnableKeyword("_WETNESS_RIPPLES");
				material.DisableKeyword("_WETNESS_FLOW");
				material.DisableKeyword("_WETNESS_FULL");
				break;
			// Flow
			case 3:
				material.DisableKeyword("_WETNESS_SIMPLE");
				material.DisableKeyword("_WETNESS_RIPPLES");
				material.EnableKeyword("_WETNESS_FLOW");
				material.DisableKeyword("_WETNESS_FULL");
				break;
			// Full
			case 4:
				material.DisableKeyword("_WETNESS_SIMPLE");
				material.DisableKeyword("_WETNESS_RIPPLES");
				material.DisableKeyword("_WETNESS_FLOW");
				material.EnableKeyword("_WETNESS_FULL");
				break;
		}
	}

	public static void SetupMaterialWithPuddleMask(Material material, int puddleMask, float puddleMaskTiling, bool useParallax) {
		switch (puddleMask) {
			// vertex color
			case 0:
				material.DisableKeyword("LUX_PUDDLEMASKTILING");
				material.DisableKeyword("GEOM_TYPE_MESH"); // GEOM_TYPE_MESH --> puddlemask from heightmap but using custom tiling
//Debug.Log("vertexcol");
				break;
			// height map
			case 1:
				if (puddleMaskTiling == 1.0 && useParallax) {
					material.DisableKeyword("GEOM_TYPE_MESH");
					material.EnableKeyword("LUX_PUDDLEMASKTILING");
				}
				else {
					material.EnableKeyword("GEOM_TYPE_MESH");
				}
				break;
		}
		//material.DisableKeyword("BILLBOARD_FACE_CAMERA_POS");
	}

	public static void SetupMaterialWithSnowMode(Material material, int snow) {
		switch (snow) {
			// Disabled
			case 0:
				material.DisableKeyword("_SNOW");
				break;
			// enabled
			case 1:
				material.EnableKeyword("_SNOW");
				break;
		}
	}

	public static void SetupMaterialWithBlendMode(Material material, BlendMode blendMode)
	{
		switch (blendMode)
		{
			case BlendMode.Opaque:
				material.SetOverrideTag("RenderType", "");
				material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
				material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
				material.SetInt("_ZWrite", 1);
				material.DisableKeyword("_ALPHATEST_ON");
				material.DisableKeyword("_ALPHABLEND_ON");
				material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
				material.renderQueue = -1;
				break;
			case BlendMode.Cutout:
				material.SetOverrideTag("RenderType", "TransparentCutout");
				material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
				material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.Zero);
				material.SetInt("_ZWrite", 1);
				material.EnableKeyword("_ALPHATEST_ON");
				material.DisableKeyword("_ALPHABLEND_ON");
				material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
				material.renderQueue = 2450;
				break;
			case BlendMode.Fade:
				material.SetOverrideTag("RenderType", "Transparent");
				material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
				material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
				material.SetInt("_ZWrite", 0);
				material.DisableKeyword("_ALPHATEST_ON");
				material.EnableKeyword("_ALPHABLEND_ON");
				material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
				material.renderQueue = 3000;
				break;
			case BlendMode.Transparent:
				material.SetOverrideTag("RenderType", "Transparent");
				material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.One);
				material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
				material.SetInt("_ZWrite", 0);
				material.DisableKeyword("_ALPHATEST_ON");
				material.DisableKeyword("_ALPHABLEND_ON");
				material.EnableKeyword("_ALPHAPREMULTIPLY_ON");
				material.renderQueue = 3000;
				break;
		}
	}
	
	static bool ShouldEmissionBeEnabled (Color color)
	{
		return color.maxColorComponent > (0.1f / 255.0f);
	}

	static void SetMaterialKeywords(Material material, WorkflowMode workflowMode)
	{
		// Note: keywords must be based on Material value not on MaterialProperty due to multi-edit & material animation
		// (MaterialProperty value might come from renderer material property block)
		SetKeyword (material, "_NORMALMAP", material.GetTexture ("_BumpMap") || material.GetTexture ("_DetailNormalMap"));
		if (workflowMode == WorkflowMode.Specular) {
			SetKeyword (material, "_SPECGLOSSMAP", material.GetTexture ("_SpecGlossMap"));
			SetKeyword (material, "GEOM_TYPE_FROND", material.GetTexture ("_SpecGlossMap2"));
		}
		else if (workflowMode == WorkflowMode.Metallic) {
			SetKeyword (material, "_METALLICGLOSSMAP", material.GetTexture ("_MetallicGlossMap"));
			SetKeyword (material, "GEOM_TYPE_FROND", material.GetTexture ("_MetallicGlossMap2"));
		}
		
		SetKeyword (material, "_PARALLAXMAP", material.GetTexture ("_ParallaxMap"));
		SetKeyword (material, "_DETAIL_MULX2", material.GetTexture ("_DetailAlbedoMap") || material.GetTexture ("_DetailNormalMap"));
		SetKeyword (material, "_OCCLUSIONMAP", material.GetTexture ("_OcclusionMap"));
		
		bool shouldEmissionBeEnabled = ShouldEmissionBeEnabled (material.GetColor("_EmissionColor"));
		SetKeyword (material, "_EMISSION", shouldEmissionBeEnabled);

		// Setup lightmap emissive flags
		MaterialGlobalIlluminationFlags flags = material.globalIlluminationFlags;
		if ((flags & (MaterialGlobalIlluminationFlags.BakedEmissive | MaterialGlobalIlluminationFlags.RealtimeEmissive)) != 0)
		{
			flags &= ~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
			if (!shouldEmissionBeEnabled)
				flags |= MaterialGlobalIlluminationFlags.EmissiveIsBlack;

			material.globalIlluminationFlags = flags;
		}

	}

	bool HasValidEmissiveKeyword (Material material)
	{
		// Material animation might be out of sync with the material keyword.
		// So if the emission support is disabled on the material, but the property blocks have a value that requires it, then we need to show a warning.
		// (note: (Renderer MaterialPropertyBlock applies its values to emissionColorForRendering))
		bool hasEmissionKeyword = material.IsKeywordEnabled ("_EMISSION");
		if (!hasEmissionKeyword && ShouldEmissionBeEnabled (emissionColorForRendering.colorValue))
			return false;
		else
			return true;
	}

	static void MaterialChanged(Material material, WorkflowMode workflowMode)
	{
		if ( (float)(CullingMode)material.GetFloat("_Cull") > 2.0f ){
			material.SetFloat("_Cull", 2.0f);
		}
		SetupMaterialWithCullingMode (material, (CullingMode)material.GetFloat("_Cull"));
		SetupMaterialWithLightingMode (material, (int)material.GetFloat("_Lighting"));
		SetupMaterialWithWetnessMode (material, (int)material.GetFloat("_Wetness"));
		SetupMaterialWithPuddleMask (material, (int)material.GetFloat("_PuddleMask"), (float)material.GetFloat("_PuddleMaskTiling"), (bool)material.GetTexture ("_ParallaxMap") );
		SetupMaterialWithSnowMode (material, (int)material.GetFloat("_Snow"));
		SetupMaterialWithBlendMode (material, (BlendMode)material.GetFloat("_Mode"));


		SetMaterialKeywords(material, workflowMode);
	}

	static void SetKeyword(Material m, string keyword, bool state)
	{
		if (state)
			m.EnableKeyword (keyword);
		else
			m.DisableKeyword (keyword);
	}
}

} // namespace UnityEditor
