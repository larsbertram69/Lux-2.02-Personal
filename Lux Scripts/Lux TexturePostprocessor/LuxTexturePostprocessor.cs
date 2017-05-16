// LUX TEXTURPOSTPROCESSOR 

// both textures have to be in the same folder
// both textures have to have the "same" name
// both textures have to have the same extension
// both textures have to have the same size

#if UNITY_EDITOR

using System;
using System.IO;
using UnityEditor;
using UnityEngine;

internal class LuxTexturePostprocessor : AssetPostprocessor {

	public const string SpecSuffix = "_LuxSPEC";
	public const string SpecShortSuffix = "LuxSPEC";
	public const string NormalSuffix = "_LuxNRM";
	public const string NormalShortSuffix = "LuxNRM";

	public void OnPostprocessTexture (Texture2D specMap) {
		if (assetPath.Contains(SpecSuffix)) {
			string filename = Path.GetFileNameWithoutExtension(assetPath);
			string[] arr = filename.Split('_');
			var origFilename = System.String.Empty;
			for (int i = 0; i < arr.Length; i++) {
				if (arr[i] == SpecShortSuffix) {
					break;
				}
				else {
					origFilename+=arr[i]+'_';
				}
			}
			origFilename += NormalShortSuffix;
			var normalpath = Path.Combine(Path.GetDirectoryName(assetPath), Path.GetFileNameWithoutExtension(origFilename));
			normalpath += Path.GetExtension(assetPath);
			
			if (File.Exists(normalpath)) {

				// Unlock Normal texture
				TextureImporter ti = (TextureImporter) TextureImporter.GetAtPath(normalpath) as TextureImporter;
				if (!ti.isReadable) {
					Debug.Log("Normal texture has to be reimported as readable. Please reimport the _SPEC texture as well.");
					ti.isReadable = true;
					AssetDatabase.ImportAsset(normalpath, ImportAssetOptions.ForceUpdate);
					return;
				}

				Debug.Log("Filtering Texture: " + filename);

				// Unlock SpecSmoothness Texture and set it to trilinear
				TextureImporter tiSmoothness = (TextureImporter) TextureImporter.GetAtPath(assetPath) as TextureImporter;
				tiSmoothness.isReadable = true;
				tiSmoothness.filterMode = FilterMode.Trilinear;

				var normal = AssetDatabase.LoadAssetAtPath(normalpath, typeof (Texture2D) ) as Texture2D;

				int width = specMap.width;
				int height = specMap.height;
				int mipmapCount = specMap.mipmapCount;
				
				// Start with mip level 1
				for (int mipLevel = 1; mipLevel < mipmapCount; mipLevel++) {
					ProcessMipLevel(ref specMap, normal, width, height, mipLevel);
				}
				specMap.Apply(false, false);
				normal = null;
			}
			else {
				Debug.Log("No corresponding normal map found at:" + normalpath);
				Debug.Log(Path.GetFileNameWithoutExtension(origFilename) + Path.GetExtension(assetPath));
			}
		}	
	}


	private static void ProcessMipLevel(ref Texture2D specMap, Texture2D bumpMap, int maxwidth, int maxheight, int mipLevel)
	{
		// Create color array which will hold the processed texels for the given MipLevel
		Color32[] colors = specMap.GetPixels32(mipLevel);

		// Get NormalMap MipLevel 0
		Color32[] BumpMap = bumpMap.GetPixels32(0);

		// Calculate Width and Height for the given mipLevel
		int width = Mathf.Max(1, specMap.width >> mipLevel);
		int height = Mathf.Max(1, specMap.height >> mipLevel);

		int pointer = 0;
		int texelFootprint = 1 << mipLevel;

		// Declare all vars outside the loop!
		Vector3 sampleNormal;
		Color32 normalSample;
		float texelPosX;
		float texelPosY;
		int texelPointerX;
		int texelPointerY;
		int samplePosX;
		int samplePosY;
		float roughness;

		for (int row = 0; row < height; row++)
			{
			for (int col = 0; col < width; col++)
				{

					texelPosX = (float)col/width;														// equals U
					texelPosY = (float)row/height;														// equals V
					texelPointerX = Mathf.FloorToInt(texelPosX * maxwidth);								// remap to mipLevel 0
					texelPointerY = Mathf.FloorToInt( (texelPosY) * maxheight);							// remap to mipLevel 0
				
				//	Sample all normal map texels from the base mip level that are within the footprint of the current mipmap texel
					Vector3 avgNormal = Vector3.zero;
					for(int y = 0; y < texelFootprint; y++)
						{
						for(int x = 0; x < texelFootprint; x++)
						{
							samplePosX = texelPointerX + x;
							samplePosY = texelPointerY + y;
							// Read Pixel from BumpMap out of Array
			             	normalSample = BumpMap[ samplePosY * maxheight + samplePosX];
							// Decode Normal
							sampleNormal = new Vector3(normalSample.a/255.0f * 2.0f - 1.0f, normalSample.g/255.0f * 2.0f - 1.0f, 0.0f);
							sampleNormal.z = Mathf.Sqrt(1.0f - sampleNormal.x * sampleNormal.x - sampleNormal.y * sampleNormal.y);
							sampleNormal.Normalize();
							avgNormal += sampleNormal;
						}
					}
					avgNormal /= (float)(texelFootprint * texelFootprint);

					// http://blog.selfshadow.com/publications/s2013-shading-course/rad/s2013_pbs_rad_notes.pdf
					float r = ((Vector3)avgNormal).magnitude;
	        		float kappa = 10000.0f;
			        if(r < 1.0f)
			        {
			            kappa = (3.0f * r - r * r * r) / (1.0f - r * r);
			        }
			        // Get Roughness
					roughness = 1.0f - (float) (colors[pointer].a / 255.0f);
			    	// Compute the new roughness value and covert to smoothness
					colors[pointer].a = (byte)( Mathf.Clamp01( 1.0f - Mathf.Sqrt( roughness * roughness + (1.0f / kappa) ) )  * 255.0f  );
                pointer++;
				}
			}
		// Apply modified mipLevel
		specMap.SetPixels32(colors, mipLevel);
	}
}
#endif
