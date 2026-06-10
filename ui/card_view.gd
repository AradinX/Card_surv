class_name CardView
extends Button
## Visual representation of a single action card in hand.
## Dumb view: shows data, disables itself when the card can't be played.
## Clicks are handled via the inherited "pressed" signal.

@onready var _name_label: Label = $Margin/VBox/NameLabel
@onready var _cost_label: Label = $Margin/VBox/CostLabel
@onready var _desc_label: Label = $Margin/VBox/DescLabel


func setup(card: ActionCardData, block_reason: String) -> void:
	_name_label.text = card.display_name
	_cost_label.text = _format_costs(card)
	_desc_label.text = card.description
	disabled = block_reason != ""
	tooltip_text = block_reason


func _format_costs(card: ActionCardData) -> String:
	var parts: PackedStringArray = []
	parts.append("Energia: %d" % card.energy_cost)
	if card.food_cost > 0:
		parts.append("Jedzenie: %d" % card.food_cost)
	if card.wood_cost > 0:
		parts.append("Drewno: %d" % card.wood_cost)
	if card.materials_cost > 0:
		parts.append("Materiały: %d" % card.materials_cost)
	return " | ".join(parts)
