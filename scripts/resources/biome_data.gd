class_name BiomeData
extends Resource
## Definition of a biome tile — one of the 6 board tiles drawn at run start
## (Dzien 50 concept, README section 3). Pure data, no logic.
## Each biome has a normal face (Act I) and a corrupted face (after BUM).

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

## Building slots on this tile (design range 2-4, Laki: 4, Gory: 2).
@export_range(2, 4) var building_slots: int = 3

## Gathering cards available only while the player stands on this tile.
@export var gather_cards: Array[ActionCardData] = []
## Event cards this biome shuffles into the day event deck (biome hazards:
## Gory — harsher winter, Wybrzeze — storms...).
@export var extra_event_cards: Array[EventCardData] = []

@export_group("Camp modifiers (where you sleep tonight)")
## Harsh biomes make "where to camp" a real decision, not just "where to gather".
## These apply at night based on the tile the player ENDS the day on. A shelter
## (night_protection building) on that same tile softens warmth loss and sickness,
## rewarding building where you sleep.
## Extra warmth lost overnight when camped here (cold biomes: Gory, Jaskinie).
@export var camp_warmth_loss: int = 0
## Extra thirst lost overnight when camped here (dry biomes: Pustkowie).
@export var camp_thirst_loss: int = 0
## Chance (0..1) of a sickness flare overnight when camped here (Bagno).
@export_range(0.0, 1.0, 0.05) var camp_sickness_chance: float = 0.0
## Health lost when a camp sickness flare triggers.
@export var camp_sickness_damage: int = 0

@export_group("Corrupted face (after BUM)")
@export var corrupted_display_name: String = ""
@export_multiline var corrupted_description: String = ""
@export var corrupted_gather_cards: Array[ActionCardData] = []
@export var corrupted_extra_event_cards: Array[EventCardData] = []

const DISASTER_CORRUPTED_NAMES := {
	"plague": {
		"forest": "Martwy Las",
		"meadows": "Zgniłe Łąki",
		"mountains": "Wyjące Góry",
		"swamp": "Trujące Mokradła",
		"river": "Czarna Rzeka",
		"wasteland": "Spopielone Pustkowie",
		"caves": "Zatrute Jaskinie",
		"coast": "Martwe Wybrzeże",
	},
	"eclipse": {
		"forest": "Las Długiego Cienia",
		"meadows": "Zamarznięte Łąki",
		"mountains": "Czarne Góry",
		"swamp": "Skuwane Bagno",
		"river": "Lodowa Rzeka",
		"wasteland": "Blade Pustkowie",
		"caves": "Jaskinie Mroku",
		"coast": "Zimne Wybrzeże",
	},
	"flood": {
		"forest": "Zalany Las",
		"meadows": "Podtopione Łąki",
		"mountains": "Osuwające się Góry",
		"swamp": "Rozlane Bagno",
		"river": "Wściekła Rzeka",
		"wasteland": "Błotne Pustkowie",
		"caves": "Zalane Jaskinie",
		"coast": "Zatopione Wybrzeże",
	},
	"rift": {
		"forest": "Popękany Las",
		"meadows": "Rozdarte Łąki",
		"mountains": "Pęknięte Góry",
		"swamp": "Zapadłe Bagno",
		"river": "Rozszczepiona Rzeka",
		"wasteland": "Szczelinowe Pustkowie",
		"caves": "Rozwarte Jaskinie",
		"coast": "Rozbite Wybrzeże",
	},
}

const DISASTER_CORRUPTED_DESCRIPTIONS := {
	"plague": {
		"forest": "Drzewa stoją czarne i nagie. Coś porusza się między pniami.",
		"meadows": "Trawa gnije na stojąco, a ziemia mlaszcze pod stopami.",
		"mountains": "Wiatr w szczelinach brzmi jak głosy. Nie schodź w doliny.",
		"swamp": "Woda zaszła zgnilizną, a spod mułu sączy się czarna maź.",
		"river": "Woda płynie gęsta i ciemna, niosąc trupi odór z górnego biegu.",
		"wasteland": "Ziemia spieczona na popiół, a w powietrzu wisi gryzący, trujący pył.",
		"caves": "Ze szczelin sączy się czarna maź, a echo niesie nieludzkie skrzeki.",
		"coast": "Morze wyrzuca na brzeg zgniłe ryby, a fale niosą tłustą, czarną pianę.",
	},
	"eclipse": {
		"forest": "Korony drzew łapią czarny szron. Między pniami leży nienaturalny półmrok.",
		"meadows": "Kwiaty zamarzły w pełnym rozkwicie, a trawa chrzęści jak cienkie szkło.",
		"mountains": "Skały gasną pod lodowym cieniem. Każdy podmuch zabiera resztki ciepła.",
		"swamp": "Bagno przykrywa cienki lód, ale pod spodem coś nadal oddycha.",
		"river": "Nurt niesie kry i martwe światło. Woda parzy zimnem przy dotyku.",
		"wasteland": "Popiół pobielał od szronu, a horyzont zniknął w bladym mroku.",
		"caves": "Ciemność w jaskiniach zgęstniała. Echo wraca zimniejsze niż oddech.",
		"coast": "Fale biją cicho o oblodzone kamienie. Nad wodą wisi czarne niebo.",
	},
	"flood": {
		"forest": "Korzenie stoją w brudnej wodzie, a mokre pnie pękają od ciężaru.",
		"meadows": "Łąki zmieniły się w płytkie jezioro pełne gnijących kęp trawy.",
		"mountains": "Stoki osuwają się po ulewach. Kamienie jadą w dół razem z błotem.",
		"swamp": "Bagno rozlało się bez granic. Każdy krok znika w zimnej mazi.",
		"river": "Rzeka wystąpiła z brzegów i niesie wszystko, czego nie zdążyła pochłonąć.",
		"wasteland": "Kurz stał się ciężkim błotem, a resztki ruin zapadają się pod wodą.",
		"caves": "Korytarze wypełnia lodowata woda. Z głębi słychać puste bulgotanie.",
		"coast": "Morze weszło na ląd. Plaża jest tylko pasem piany i porwanych szczątków.",
	},
	"rift": {
		"forest": "Między drzewami otwierają się szczeliny, z których bucha gorący pył.",
		"meadows": "Darń rozdarły świeże rysy. Ziemia drży pod każdym krokiem.",
		"mountains": "Grzbiety skał popękały jak glina. Z dolin dobiega głuchy huk.",
		"swamp": "Muł zapada się w czarne rozpadliny, a para pachnie siarką.",
		"river": "Nurt ginie w pęknięciach i wraca gorący, mętny, niepewny.",
		"wasteland": "Pustka pocięta jest szczelinami. W dole żarzy się coś niestabilnego.",
		"caves": "Stare tunele rozwarły się głębiej, niż powinny. Strop jęczy bez przerwy.",
		"coast": "Klify pękają nad morzem, a fale wpadają w świeże rany skał.",
	},
}


func corrupted_name_for(disaster_id: String) -> String:
	var names: Dictionary = DISASTER_CORRUPTED_NAMES.get(disaster_id, {})
	return tr(str(names.get(id, corrupted_display_name)))


func corrupted_description_for(disaster_id: String) -> String:
	var descriptions: Dictionary = DISASTER_CORRUPTED_DESCRIPTIONS.get(disaster_id, {})
	return tr(str(descriptions.get(id, corrupted_description)))
