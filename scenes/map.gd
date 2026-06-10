extends Control
## Expedition map screen: nodes as buttons in layers, connections drawn as
## lines, player position highlighted. Also hosts the interlude overlays
## (card reward, rest, encounter) — only day nodes switch to the run scene.
## Pure view over ExpeditionSystem.

const CARD_VIEW_SCENE := preload("res://ui/card_view.tscn")
const NODE_BUTTON_SIZE := Vector2(126, 46)
const TYPE_NAMES := {
	MapNodeData.TYPE_TERRAIN: "Teren",
	MapNodeData.TYPE_EVENT: "Zdarzenie",
	MapNodeData.TYPE_FIND: "Znalezisko",
	MapNodeData.TYPE_REST: "Odpoczynek",
	MapNodeData.TYPE_FINALE: "FINAŁ",
}

@onready var _day_label: Label = $Margin/Layout/TopBar/DayLabel
@onready var _stats_label: Label = $Margin/Layout/TopBar/StatsLabel
@onready var _map_area: Control = $Margin/Layout/MapArea
@onready var _deck_label: Label = $Margin/Layout/DeckLabel
@onready var _dim: ColorRect = $Dim

@onready var _reward_panel: PanelContainer = $RewardPanel
@onready var _reward_title: Label = $RewardPanel/RMargin/RVBox/RewardTitle
@onready var _reward_cards: HBoxContainer = $RewardPanel/RMargin/RVBox/RewardCards
@onready var _skip_button: Button = $RewardPanel/RMargin/RVBox/SkipButton

@onready var _rest_panel: PanelContainer = $RestPanel
@onready var _heal_button: Button = $RestPanel/RestMargin/RestVBox/HealButton
@onready var _remove_button: Button = $RestPanel/RestMargin/RestVBox/RemoveButton

@onready var _deck_panel: PanelContainer = $DeckPanel
@onready var _deck_list: VBoxContainer = $DeckPanel/DMargin/DVBox/DeckScroll/DeckList
@onready var _deck_cancel: Button = $DeckPanel/DMargin/DVBox/DeckCancel

@onready var _enc_panel: PanelContainer = $EncounterPanel
@onready var _enc_title: Label = $EncounterPanel/EMargin/EVBox/EncTitle
@onready var _enc_text: Label = $EncounterPanel/EMargin/EVBox/EncText
@onready var _enc_options: VBoxContainer = $EncounterPanel/EMargin/EVBox/EncOptions
@onready var _enc_continue: Button = $EncounterPanel/EMargin/EVBox/EncContinue

var _expedition: ExpeditionSystem
var _node_buttons: Dictionary = {}  # node id -> Button
var _pending_card_reward := false


func _ready() -> void:
	_expedition = GameManager.expedition
	if _expedition == null:
		push_error("Map scene started without an expedition; returning to menu.")
		GameManager.return_to_menu()
		return
	_expedition.state_changed.connect(_on_state_changed)
	_skip_button.pressed.connect(_close_panels)
	_heal_button.pressed.connect(_on_heal_pressed)
	_remove_button.pressed.connect(_open_deck_list)
	_deck_cancel.pressed.connect(_on_deck_cancel)
	_enc_continue.pressed.connect(_on_encounter_continue)

	_on_state_changed(_expedition.state)
	# Defer so MapArea has its final size before positioning buttons.
	_render_map.call_deferred()


func _on_state_changed(state: RunState) -> void:
	_day_label.text = "Mapa wyprawy — Dzień %d" % state.day
	_stats_label.text = "Zdrowie: %d/%d   Sytość: %d/%d   |   Jedzenie: %d   Drewno: %d   Materiały: %d   Schronienie: %d/%d" % [
		state.health, RunState.MAX_HEALTH, state.hunger, RunState.MAX_HUNGER,
		state.food, state.wood, state.materials,
		state.shelter_level, RunState.MAX_SHELTER,
	]
	_deck_label.text = "Talia: %d kart" % state.deck.size()


func _render_map() -> void:
	for button: Button in _node_buttons.values():
		button.queue_free()
	_node_buttons.clear()

	var state := _expedition.state
	var area := _map_area.size
	var margin_v := 36.0
	var usable_h := area.y - 2.0 * margin_v
	var available := _expedition.get_available_node_ids()

	for node in state.map.nodes:
		var layer_size := state.map.get_layer_nodes(node.layer).size()
		var x := area.x * float(node.index_in_layer + 1) / float(layer_size + 1)
		var y := area.y - margin_v - usable_h * float(node.layer) / float(state.map.layer_count - 1)

		var button := Button.new()
		button.text = TYPE_NAMES.get(node.type, node.type)
		button.custom_minimum_size = NODE_BUTTON_SIZE
		button.position = Vector2(x, y) - NODE_BUTTON_SIZE / 2.0
		button.disabled = not node.id in available
		if node.id == state.current_node_id:
			button.modulate = Color(1.0, 0.85, 0.3)
			button.text = "» %s «" % button.text
		elif node.id in available:
			button.modulate = Color(0.7, 1.0, 0.7)
		else:
			button.modulate = Color(0.55, 0.55, 0.6)
		button.pressed.connect(_on_node_pressed.bind(node.id))
		_map_area.add_child(button)
		_node_buttons[node.id] = button

	queue_redraw()


func _draw() -> void:
	# Connection lines, drawn before children so they end up under buttons.
	if _expedition == null or _node_buttons.is_empty():
		return
	var to_local := get_global_transform().affine_inverse()
	for node in _expedition.state.map.nodes:
		if not _node_buttons.has(node.id):
			continue
		var from: Vector2 = to_local * (_node_buttons[node.id] as Button).get_global_rect().get_center()
		for next_id in node.next_ids:
			if _node_buttons.has(next_id):
				var to: Vector2 = to_local * (_node_buttons[next_id] as Button).get_global_rect().get_center()
				draw_line(from, to, Color(0.45, 0.45, 0.5), 2.0)


func _on_node_pressed(node_id: int) -> void:
	var node := _expedition.enter_node(node_id)
	if node == null:
		return
	match node.type:
		MapNodeData.TYPE_TERRAIN, MapNodeData.TYPE_FINALE:
			GameManager.go_to_day()
			return
		MapNodeData.TYPE_FIND:
			_show_card_rewards("Znalezisko", "Wybierz kartę, którą dodasz do talii:")
		MapNodeData.TYPE_REST:
			_open_rest()
		MapNodeData.TYPE_EVENT:
			_open_encounter()
	_render_map()


# --- Card reward overlay ---


func _show_card_rewards(title: String, _subtitle: String) -> void:
	_reward_title.text = title
	for child in _reward_cards.get_children():
		child.queue_free()
	for card in _expedition.roll_card_rewards():
		var view: CardView = CARD_VIEW_SCENE.instantiate()
		_reward_cards.add_child(view)
		view.setup(card, "")
		view.pressed.connect(_on_reward_picked.bind(card))
	_dim.show()
	_reward_panel.show()


func _on_reward_picked(card: ActionCardData) -> void:
	_expedition.add_card_to_deck(card)
	_close_panels()


# --- Rest overlay ---


func _open_rest() -> void:
	_heal_button.text = "Odpocznij (+%d zdrowia)" % ExpeditionSystem.REST_HEAL
	_dim.show()
	_rest_panel.show()


func _on_heal_pressed() -> void:
	_expedition.rest_heal()
	_close_panels()


func _open_deck_list() -> void:
	_rest_panel.hide()
	for child in _deck_list.get_children():
		child.queue_free()
	for i in _expedition.state.deck.size():
		var card := _expedition.state.deck[i]
		var button := Button.new()
		button.text = "%s  (energia: %d)" % [card.display_name, card.energy_cost]
		button.pressed.connect(_on_deck_card_removed.bind(i))
		_deck_list.add_child(button)
	_deck_panel.show()


func _on_deck_card_removed(index: int) -> void:
	_expedition.remove_card_from_deck(index)
	_close_panels()


func _on_deck_cancel() -> void:
	_deck_panel.hide()
	_rest_panel.show()


# --- Encounter overlay ---


func _open_encounter() -> void:
	var encounter := _expedition.roll_encounter()
	_enc_title.text = encounter.title
	_enc_text.text = encounter.text
	_enc_continue.hide()
	for child in _enc_options.get_children():
		child.queue_free()
	for option in encounter.options:
		var button := Button.new()
		button.text = option.label
		button.disabled = not _expedition.can_choose_option(option)
		button.pressed.connect(_on_encounter_option.bind(option))
		_enc_options.add_child(button)
	_dim.show()
	_enc_panel.show()


func _on_encounter_option(option: EncounterOptionData) -> void:
	_expedition.apply_encounter_option(option)
	_enc_text.text = option.result_text
	_pending_card_reward = option.grants_card_choice
	for child in _enc_options.get_children():
		child.queue_free()
	_enc_continue.show()


func _on_encounter_continue() -> void:
	_enc_panel.hide()
	if _pending_card_reward:
		_pending_card_reward = false
		_show_card_rewards("Nagroda", "Wybierz kartę, którą dodasz do talii:")
	else:
		_close_panels()


func _close_panels() -> void:
	_dim.hide()
	_reward_panel.hide()
	_rest_panel.hide()
	_deck_panel.hide()
	_enc_panel.hide()
	_render_map()
