extends SceneTree
## One-off: rewrite action/building `description` to PURE FLAVOUR (no numbers).
## The card UI shows this flavour on line 1 and the generated effects on line 2,
## so amounts live in exactly one place. Run once:
##   Godot --headless --path . -s tools/set_flavors.gd

const FLAVORS := {
	# Actions
	"adrenaline": "Przekrocz swoje granice.",
	"bandage": "Porządnie opatrz ranę.",
	"big_hunt": "Całodniowa wyprawa za grubym zwierzem.",
	"campfire": "Rozpal ognisko i odetchnij w cieple.",
	"craft_tools": "Skleć prymitywne narzędzia.",
	"deep_sleep": "Prześpij część dnia, by dojść do siebie.",
	"dried_meat": "Sięgnij po zapas suszonego mięsa.",
	"expedition": "Wyrusz na cały dzień w nieznane.",
	"explore": "Wyrusz w nieznane tereny.",
	"feast": "Najedz się raz a porządnie.",
	"find_water": "Nabierz wody ze strumienia.",
	"first_aid": "Opatrz się tym, co masz pod ręką.",
	"fishing": "Spędź kilka godzin nad wodą.",
	"forage": "Zbierz jagody i korzonki w okolicy.",
	"gather_sticks": "Pozbieraj suche gałęzie po drodze.",
	"gather_wood": "Narąb drewna na opał i budulec.",
	"herbs": "Wyszukaj zioła i przygotuj okład.",
	"huddle": "Owiń się wszystkim, co masz, i przeczekaj chłód.",
	"hunt": "Wyrusz na polowanie w głąb lasu.",
	"rest": "Złap oddech i zbierz siły.",
	"scavenge": "Przeszukaj okolicę za przydatnym złomem.",
	"scout": "Rozejrzyj się i zaplanuj dzień.",
	"snare_trap": "Zastaw wnyki na zwierzynę.",
	"survey": "Wespnij się i przepatrz okolicę.",
	"trail_snack": "Skub coś w biegu, bez tracenia czasu.",
	"waterskin": "Napełnij bukłak po brzegi.",
	"woodcraft": "Przerób drewno na użyteczne części.",
	# Signature
	"builder_signature": "Z desek składasz gotowe elementy.",
	"cook_signature": "Twoja specjalność — prawdziwy posiłek z zapasów.",
	"herbalist_signature": "Twój wywar stawia na nogi.",
	"hunter_signature": "Czytasz las jak otwartą księgę.",
	"informatyk_signature": "Porządkujesz plan i zyskujesz rozpęd.",
	"nomad_signature": "Zapasy ukryte na szlaku — w sam raz na teraz.",
	"planner_signature": "Rozpisujesz dzień co do minuty.",
	"scout_signature": "Przeczesujesz teren i wracasz z łupem.",
	"soldier_signature": "Dyscyplina daje drugi oddech.",
	# Corrupted
	"murky_water": "Cuchnąca kałuża po deszczu — lepsze to niż nic.",
	"tainted_hunt": "Mięso pachnie słodko i niedobrze.",
	# Buildings
	"building_bastion": "Z gruzów wznosisz twierdzę o grubych murach.",
	"building_campfire": "Ciepło ogniska niesie się po całej osadzie.",
	"building_cistern": "Zbiornik na wodę z ocalałych rur.",
	"building_farm": "Grządki obsiane na własne jedzenie.",
	"building_field_infirmary": "Punkt opatrunkowy z ocalałych zapasów.",
	"building_fishing_dock": "Pomost z sieciami pełnymi ryb.",
	"building_herbalist": "Chatka pełna leczniczych ziół.",
	"building_hut": "Dach nad głową na niespokojne noce.",
	"building_logging_camp": "Obóz drwali ze stałym dopływem drewna.",
	"building_palisade": "Ostre pale otaczają osadę.",
	"building_pantry": "Chłodna spiżarnia na zapasy.",
	"building_quarry": "Wyrobisko kamienia i rudy.",
	"building_reinforced_shelter": "Solidne legowisko zbite z gruzów.",
	"building_traps": "Sidła rozstawione wokół osady.",
	"building_watchtower": "Z wieży strażnicy wypatrują zagrożeń.",
	"building_water_filter": "Filtr daje czystą wodę bez wysiłku.",
	"building_well": "Studnia z czystą wodą na miejscu.",
	"building_wood_storage": "Suchy skład na opał i budulec.",
	"building_workshop": "Stół roboczy do obróbki surowców.",
}

const DIRS := [
	"res://data/cards/actions",
	"res://data/cards/actions/signature",
	"res://data/cards/actions/corrupted",
	"res://data/buildings",
]


func _init() -> void:
	var changed := 0
	for dir_path: String in DIRS:
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue
		for name in dir.get_files():
			if not name.ends_with(".tres"):
				continue
			var path := dir_path.path_join(name)
			var res = load(path)
			if res == null or not ("id" in res):
				continue
			if not FLAVORS.has(res.id):
				continue
			res.description = FLAVORS[res.id]
			ResourceSaver.save(res, path)
			changed += 1
	print("Ustawiono flavor dla %d kart." % changed)
	quit()
