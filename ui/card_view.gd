class_name CardView
extends Button
## Visual representation of a single card (action, building or biome gather
## action). Dumb view: shows data, disables itself when the card can't be
## played. Clicks are handled via the inherited "pressed" signal.


@onready var _name_label: Label = $Margin/VBox/NameLabel
@onready var _cost_label: Label = $Margin/VBox/CostLabel
@onready var _desc_label: Label = $Margin/VBox/DescLabel


func setup(card: CardData, block_reason: String) -> void:
	_name_label.text = card.display_name
	_cost_label.text = _format_costs(card)
	_desc_label.text = card.description
	disabled = block_reason != ""
	tooltip_text = block_reason


func _format_costs(card: CardData) -> String:
	var parts: PackedStringArray = []
	if card is ActionCardData:
		var action := card as ActionCardData
		parts.append("Energia: %d" % action.energy_cost)
		if action.food_cost > 0:
			parts.append("Jedzenie: %d" % action.food_cost)
		if action.wood_cost > 0:
			parts.append("Drewno: %d" % action.wood_cost)
		if action.materials_cost > 0:
			parts.append("Materiały: %d" % action.materials_cost)
	elif card is BuildingCardData:
		var building := card as BuildingCardData
		parts.append("BUDYNEK (HP %d)" % building.max_hp)
		parts.append("Energia: %d" % building.energy_cost)
		if building.food_cost > 0:
			parts.append("Jedzenie: %d" % building.food_cost)
		if building.wood_cost > 0:
			parts.append("Drewno: %d" % building.wood_cost)
		if building.materials_cost > 0:
			parts.append("Materiały: %d" % building.materials_cost)
	return " | ".join(parts)
