using UnityEngine;
using System.Collections;

public class ReadOnlyRangeAttribute : PropertyAttribute {
	public float min;
	public float max;
	
	public ReadOnlyRangeAttribute (float min, float max) {
		this.min = min;
		this.max = max;
	}
}

public class CustomLabelRangeAttribute : PropertyAttribute {
	public float min;
	public float max;
	public string labeltext;
	
	public CustomLabelRangeAttribute (float min, float max, string labeltext) {
		this.min = min;
		this.max = max;
		this.labeltext = labeltext;
	}
}