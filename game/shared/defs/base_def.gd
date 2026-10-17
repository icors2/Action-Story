class_name BaseDef
extends RefCounted
## Base for all read-only content definitions loaded from JSON.

var id: StringName = &""
var source_path: String = ""


## Linear interpolation helper for skill/level tables: [at_min, at_max] or explicit per-level arrays.
static func level_value(values: Variant, level: int, max_level: int) -> float:
	if values is Array:
		var arr: Array = values
		if arr.size() == max_level and max_level != 2:
			return float(arr[clampi(level, 1, max_level) - 1])
		if arr.size() == 2:
			if max_level <= 1:
				return float(arr[0])
			var t: float = float(clampi(level, 1, max_level) - 1) / float(max_level - 1)
			return roundf(lerpf(float(arr[0]), float(arr[1]), t))
	elif values is float or values is int:
		return float(values)
	push_error("level_value: unsupported value %s" % [values])
	return 0.0
