using UnityEngine;
using UnityEditor;

[CustomPropertyDrawer (typeof (ReadOnlyRangeAttribute))]
public class RangeDrawer : PropertyDrawer {
	
	// Draw the property inside the given rect
	public override void OnGUI (Rect position, SerializedProperty property, GUIContent label) {
		ReadOnlyRangeAttribute range = attribute as ReadOnlyRangeAttribute;
		GUI.enabled = false;
		if (property.propertyType == SerializedPropertyType.Float) {
			EditorGUI.Slider (position, property, range.min, range.max, "- " + label.text);
		}
		GUI.enabled = true;
	}
}
