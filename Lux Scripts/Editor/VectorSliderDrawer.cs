using UnityEngine;
using System.Collections;
using UnityEditor;

public class VectorSliderDrawer : MaterialPropertyDrawer {

	override public void OnGUI (Rect position, MaterialProperty prop, string label, MaterialEditor editor)
	{
		//bool state = EditorGUI.Toggle(position, label, (prop.floatValue==1));
		//if (state != (prop.floatValue==1)) {
		//	prop.floatValue = state ? 1 : 0;
		//}

float quarterHeight = (position.height - 12) * 0.25f;



Rect pos_1 = new Rect(position.position.x, position.position.y, position.width, quarterHeight);
Rect pos_2 = new Rect(position.position.x, position.position.y + quarterHeight + 4, position.width, quarterHeight);
Rect pos_3 = new Rect(position.position.x, position.position.y + quarterHeight * 2 + 8, position.width, quarterHeight);
Rect pos_4 = new Rect(position.position.x, position.position.y + quarterHeight * 3 + 12, position.width, quarterHeight);

		Vector4 vec4value = prop.vectorValue;
//		vec4value.x = EditorGUI.Slider(position, new GUIContent("X"), vec4value.x, 0.0f, 1.0f); // );


//var mylabel = EditorGUI.PrefixLabel (pos_1, new GUIContent ("Select a mesh"));

vec4value.x = EditorGUI.Slider(pos_1, vec4value.x, 0.0f, 1.0f);
vec4value.y = EditorGUI.Slider(pos_2, vec4value.y, 0.0f, 1.0f);
vec4value.z = EditorGUI.Slider(pos_3, vec4value.z, 0.0f, 1.0f);
vec4value.w = EditorGUI.Slider(pos_4, vec4value.w, 0.0f, 1.0f);

prop.vectorValue = vec4value;



	}
	override public void Apply (MaterialProperty prop)
	{
//		base.Apply (prop);
	}
	public override float GetPropertyHeight (MaterialProperty prop, string label, MaterialEditor editor)
	{
		return base.GetPropertyHeight (prop, label, editor) * 4.0f + 12;
	}
}
