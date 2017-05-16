using UnityEngine;
using System.Collections;
using UnityEditor;

public class Lux_FloatToggleDrawer : MaterialPropertyDrawer {

	override public void OnGUI (Rect position, MaterialProperty prop, string label, MaterialEditor editor)
	{
		bool status = EditorGUI.Toggle(position, label, (prop.floatValue == 1));
		if (status != (prop.floatValue == 1)) {
			prop.floatValue = status ? 1 : 0;
		}
	}
	public override float GetPropertyHeight (MaterialProperty prop, string label, MaterialEditor editor)
	{
		return base.GetPropertyHeight (prop, label, editor);
	}
}
