using UnityEngine;
using System.Collections;
using UnityEditor;

public class Lux_Vector3DDrawer : MaterialPropertyDrawer {

	override public void OnGUI (Rect position, MaterialProperty prop, string label, MaterialEditor editor)
	{
		EditorGUILayout.BeginHorizontal();
			EditorGUILayout.PrefixLabel(new GUIContent (label));
			prop.vectorValue =  EditorGUILayout.Vector3Field("", prop.vectorValue);
		EditorGUILayout.EndHorizontal();
	}

	public override float GetPropertyHeight (MaterialProperty prop, string label, MaterialEditor editor)
	{
		return base.GetPropertyHeight (prop, label, editor) * 0.0f;
	}
}
