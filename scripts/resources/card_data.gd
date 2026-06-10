class_name CardData
extends Resource
## Base class for all card definitions. Pure data — no game logic here.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
