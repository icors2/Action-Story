class_name RecordMigrations
extends RefCounted
## Upgrades CharacterRecord dicts from older record_version values.


static func upgrade(raw: Dictionary) -> Dictionary:
	return raw.duplicate(true)
