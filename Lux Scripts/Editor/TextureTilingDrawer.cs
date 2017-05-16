using UnityEngine;
using System.Collections;
using UnityEditor;

public class Lux_TextureTilingDrawer : MaterialPropertyDrawer {
	override public void OnGUI (Rect position, MaterialProperty prop, string label, MaterialEditor editor)
	{
		Vector4 vec4value = prop.vectorValue;
		Vector2 tiling = new Vector2 (vec4value.x, vec4value.y);

		GUILayout.Space(-2);
		EditorGUI.BeginChangeCheck();
		EditorGUILayout.BeginVertical();
			EditorGUILayout.BeginHorizontal();
				EditorGUILayout.PrefixLabel(label);
				tiling = EditorGUILayout.Vector2Field("", tiling);
			EditorGUILayout.EndHorizontal();
		EditorGUILayout.EndVertical();
		GUILayout.Space(2);
		if (EditorGUI.EndChangeCheck ()) {
			prop.vectorValue = new Vector4(tiling.x, tiling.y, 0.0f, 0.0f);
		}
	}

	public override float GetPropertyHeight (MaterialProperty prop, string label, MaterialEditor editor)
	{
		return 0; //base.GetPropertyHeight (prop, label, editor);
	}
}
