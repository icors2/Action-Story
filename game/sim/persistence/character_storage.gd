class_name CharacterStorage
extends RefCounted
## Persistence interface. Local files now; backend in Phase 11.


func load_character(_character_id: int) -> CharacterRecord:
	return null


func save_character(_record: CharacterRecord) -> bool:
	return true
