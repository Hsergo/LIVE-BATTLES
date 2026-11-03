extends RefCounted
## Catalogue des quinze missions. Une partie LIVE complete depasse deux heures
## si les 15 missions atteignent leur duree maximale (les victoires peuvent accelerer).
## Five actual 3D sites, with 15 levels, hazards and targets.

const LEVELS := [
	{"id":"bridge-01","title":"LE PONT DU DERNIER ESPOIR","site_type":"bridge","site":"PONT","objective":"SAUVER 12 HABITANTS","target":12,"duration":450,"hazard":1,"hazard_kind":"crue","event_text":"Premiere vague de crue","special":"!escort","special_label":"ESCORTE","material":"BOIS"},
	{"id":"bridge-02","title":"LE CONVOI MEDICAL","site_type":"bridge","site":"PONT","objective":"FAIRE PASSER LE CONVOI","target":10,"duration":470,"hazard":1.12,"hazard_kind":"glissement","event_text":"La montagne s'effondre","special":"!escort","special_label":"ESCORTE","material":"BOIS"},
	{"id":"bridge-03","title":"LE PONT SUSPENDU","site_type":"bridge","site":"PONT","objective":"SAUVER LE DERNIER GROUPE","target":16,"duration":480,"hazard":1.25,"hazard_kind":"vent","event_text":"Rafales sur les passerelles","special":"!escort","special_label":"ESCORTE","material":"ACIER"},
	{"id":"dike-04","title":"LA PREMIERE DIGUE","site_type":"dike","site":"DIGUE","objective":"PROTEGER LE VILLAGE","target":14,"duration":460,"hazard":1.1,"hazard_kind":"crue","event_text":"Le niveau du fleuve monte","special":"!pump","special_label":"POMPAGE","material":"PIERRE"},
	{"id":"dike-05","title":"LE QUARTIER SUBMERGE","site_type":"dike","site":"DIGUE","objective":"EVACUER LE QUARTIER","target":18,"duration":490,"hazard":1.28,"hazard_kind":"inondation","event_text":"L'eau passe les defenses","special":"!pump","special_label":"POMPAGE","material":"PIERRE"},
	{"id":"dike-06","title":"LE TSUNAMI DU PORT","site_type":"dike","site":"DIGUE","objective":"SAUVER LE PORT","target":20,"duration":510,"hazard":1.48,"hazard_kind":"tsunami","event_text":"Vague geante vers le port","special":"!pump","special_label":"POMPAGE","material":"BETON"},
	{"id":"lighthouse-07","title":"LE PHARE DES NAUFRAGES","site_type":"lighthouse","site":"PHARE","objective":"GUIDER LES BATEAUX","target":10,"duration":470,"hazard":1.14,"hazard_kind":"brouillard","event_text":"Le brouillard se ferme","special":"!signal","special_label":"SIGNAL","material":"PIECES"},
	{"id":"lighthouse-08","title":"LA NUIT SANS COURANT","site_type":"lighthouse","site":"PHARE","objective":"RALLUMER LE PHARE","target":12,"duration":500,"hazard":1.27,"hazard_kind":"blackout","event_text":"Le courant est coupe","special":"!signal","special_label":"SIGNAL","material":"PIECES"},
	{"id":"lighthouse-09","title":"L'OURAGAN DES PECHEURS","site_type":"lighthouse","site":"PHARE","objective":"SAUVER LES EQUIPAGES","target":18,"duration":520,"hazard":1.42,"hazard_kind":"ouragan","event_text":"L'ouragan frappe le phare","special":"!signal","special_label":"SIGNAL","material":"PIECES"},
	{"id":"dam-10","title":"LE BARRAGE DE LA VALLEE","site_type":"dam","site":"BARRAGE","objective":"PROTEGER LES FAMILLES","target":16,"duration":490,"hazard":1.35,"hazard_kind":"pression","event_text":"La pression augmente","special":"!valve","special_label":"VANNES","material":"BETON"},
	{"id":"dam-11","title":"LES FAILLES SISMIQUES","site_type":"dam","site":"BARRAGE","objective":"STABILISER LE BARRAGE","target":18,"duration":530,"hazard":1.55,"hazard_kind":"seisme","event_text":"Repliques sismiques","special":"!valve","special_label":"VANNES","material":"BETON"},
	{"id":"dam-12","title":"LES VANNES EN PANNE","site_type":"dam","site":"BARRAGE","objective":"EVITER LA RUPTURE","target":20,"duration":540,"hazard":1.6,"hazard_kind":"panne","event_text":"Les vannes se bloquent","special":"!valve","special_label":"VANNES","material":"ACIER"},
	{"id":"helipad-13","title":"LES FLAMMES DE LA FORET","site_type":"helipad","site":"HELIPORT","objective":"EVACUER LA FORET","target":14,"duration":500,"hazard":1.32,"hazard_kind":"incendie","event_text":"Le front de flammes progresse","special":"!launch","special_label":"DECOLLAGE","material":"CARBURANT"},
	{"id":"helipad-14","title":"BLIZZARD EN MONTAGNE","site_type":"helipad","site":"HELIPORT","objective":"SAUVER LES ALPINISTES","target":17,"duration":540,"hazard":1.44,"hazard_kind":"blizzard","event_text":"Tempete de neige","special":"!launch","special_label":"DECOLLAGE","material":"CARBURANT"},
	{"id":"helipad-15","title":"LE CYCLONE FINAL","site_type":"helipad","site":"HELIPORT","objective":"SAUVER TOUS LES REFUGIES","target":24,"duration":600,"hazard":1.75,"hazard_kind":"cyclone","event_text":"Le cyclone atteint la base","special":"!launch","special_label":"DECOLLAGE","material":"CARBURANT"}
]

static func validate() -> bool:
	var ids: Dictionary = {}
	for level in LEVELS:
		if ids.has(level["id"]):
			return false
		ids[level["id"]] = true
		if int(level["target"]) < 1 or int(level["duration"]) < 180 or float(level["hazard"]) <= 0.0:
			return false
	return LEVELS.size() == 15
