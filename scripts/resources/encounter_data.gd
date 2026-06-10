class_name EncounterData
extends Resource
## A special-event node's content: narrative text plus 2-3 options with
## consequences. Pure data, authored in data/encounters/*.tres.

@export var id: String = ""
@export var title: String = ""
@export_multiline var text: String = ""
@export var options: Array[EncounterOptionData] = []
