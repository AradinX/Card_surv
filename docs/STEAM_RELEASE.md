# Wydanie na Steam — instrukcja i szablony

Stan: 2026-07-04. Gra buduje się w CI (`.github/workflows/godot-ci.yml`,
`--export-release Windows`); wrapper konsoli jest tylko w buildach debug, więc
release `Dzien50.exe` + `Dzien50.pck` jest gotowy do wysyłki bez zmian.

Decyzja v1: **bez Steamworks SDK** (bez achievementów/overlay API). Steam tego
nie wymaga. Cloud save włączamy po stronie Steamworks (Auto-Cloud, sekcja niżej)
— zero zmian w kodzie. GodotSteam można dodać w patchu.

## Kroki (tylko właściciel konta)

1. https://partner.steamgames.com → rejestracja, opłata $100 (Steam Direct),
   dane podatkowe/bankowe. Czas weryfikacji: zwykle 1–3 dni robocze.
2. Utwórz aplikację → dostajesz **AppID** oraz automatycznie jeden **DepotID**
   (zwykle AppID+1). Wpisz je do `steam/app_build.vdf` poniżej.
3. Strona sklepu: wgraj assety z `assets/art/promotional/steam/` (rozmiary już
   docięte), opisy PL/EN z `docs/STEAM_STORE_TEXTS.md`, min. 5 screenshotów
   1920×1080. Wypełnij kwestionariusz ratingowy (gra bez przemocy wobec ludzi,
   bez hazardu — przejdzie jako „Everyone/Teen").
4. Ustaw cenę i datę; strona „Coming soon" wymaga review Valve (~2–5 dni).
5. Build: patrz niżej. Po wgraniu ustaw branch `default` na nowy build
   (Steamworks → SteamPipe → Builds) i zrób „Release".
6. Auto-Cloud (opcjonalnie): Steamworks → Application → Steam Cloud →
   root `WinAppDataRoaming`, path `Godot/app_userdata/Dzień 50`, pattern `*.json`.

## Upload buildu (SteamPipe)

Jednorazowo: pobierz Steamworks SDK → `sdk/tools/ContentBuilder/builder/steamcmd.exe`.

Struktura (poza repo albo w `steam/`, zignorowana w gicie):

```
steam/
  app_build.vdf
  content/            <- tu wrzuć Dzien50.exe + Dzien50.pck z CI/eksportu
  output/             <- logi/cache SteamPipe
```

`steam/app_build.vdf` (podmień 1230000/1230001 na swoje AppID/DepotID):

```
"AppBuild"
{
	"AppID" "1230000"
	"Desc" "Dzien 50 v1.0.0"
	"ContentRoot" "content\"
	"BuildOutput" "output\"
	"Depots"
	{
		"1230001"
		{
			"FileMapping"
			{
				"LocalPath" "*"
				"DepotPath" "."
				"Recursive" "1"
			}
		}
	}
}
```

Upload:

```
steamcmd.exe +login <konto> +run_app_build ..\steam\app_build.vdf +quit
```

## Checklista przed „Release"

- [ ] Testy CI zielone na tagu wydania; build z CI (nie lokalny „demo").
- [ ] `export_presets.cfg`: file/product_version zaktualizowane do finalnej wersji.
- [ ] Dowód subskrypcji Suno Pro zarchiwizowany (patrz `assets/audio/LICENSES.txt`).
- [ ] Pełny ręczny run na buildzie z depotu (nowa gra + kontynuacja + ustawienia).
- [ ] Strona sklepu zaakceptowana przez Valve, cena/data ustawione.
