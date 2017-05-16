using UnityEngine;
using UnityEditor;

[CustomPropertyDrawer (typeof (CustomLabelRangeAttribute))]
public class RangeCustomLabel : PropertyDrawer {
	
	// Draw the property inside the given rect
	public override void OnGUI (Rect position, SerializedProperty property, GUIContent label) {
		CustomLabelRangeAttribute range = attribute as CustomLabelRangeAttribute;
		if (property.propertyType == SerializedPropertyType.Float) {
			EditorGUI.Slider (position, property, range.min, range.max, range.labeltext);
		}
	}
}
