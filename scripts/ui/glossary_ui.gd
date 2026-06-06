## glossary_ui.gd
## Borderless Freedom: A Dissident Adventure
## Glossário do Dissidente — entradas desbloqueadas ao evitar eventos
##
## Hierarquia esperada:
##   GlossaryUI (CanvasLayer)
##   ├── Panel
##   │   ├── LabelTitle (Label) — "GLOSSÁRIO DO DISSIDENTE"
##   │   ├── ItemList (ItemList) — lista de entradas desbloqueadas
##   │   ├── PanelEntry (PanelContainer) — painel de leitura da entrada
##   │   │   ├── LabelEntryTitle (Label)
##   │   │   └── LabelEntryText (RichTextLabel)
##   │   ├── LabelLocked (Label) — "X entradas ainda bloqueadas"
##   │   └── ButtonClose (Button)

extends CanvasLayer

@onready var item_list         := $Panel/ItemList
@onready var label_entry_title := $Panel/PanelEntry/LabelEntryTitle
@onready var label_entry_text  := $Panel/PanelEntry/LabelEntryText
@onready var label_locked      := $Panel/LabelLocked
@onready var btn_close         := $Panel/ButtonClose

var _unlocked_entries: Array[String] = []
var _all_entry_ids: Array[String] = []
var _prev_time_scale: float = 1.0

func _ready() -> void:
	hide()
	btn_close.pressed.connect(_on_close)
	item_list.item_selected.connect(_on_entry_selected)

	if RandomEventsSystem:
		RandomEventsSystem.glossary_entry_unlocked.connect(_on_entry_unlocked)

	# Carrega IDs de todas as entradas possíveis
	_all_entry_ids = [
		"not_your_keys",         # EVT-001 / EVT-007
		"too_good_to_be_true",   # EVT-002
		"guaranteed_returns_lie",# EVT-003
		"algo_stablecoin_lie",   # EVT-004
		"celebrity_exit_signal", # EVT-005
		"jpeg_not_asset",        # EVT-006
		"forks_dont_copy_network",# EVT-008
		"self_custody",          # EVT-009
		"sats_unit"              # EVT-010
	]

func open_glossary() -> void:
	_prev_time_scale = Engine.time_scale
	# Sync unlocked entries from the authoritative source before displaying
	if RandomEventsSystem:
		for entry_id in RandomEventsSystem.get_unlocked_glossary():
			if entry_id not in _unlocked_entries:
				_unlocked_entries.append(entry_id)
	_refresh_list()
	show()
	Engine.time_scale = 0.0

func _on_close() -> void:
	Engine.time_scale = _prev_time_scale
	hide()

func _on_entry_unlocked(entry_id: String) -> void:
	if entry_id not in _unlocked_entries:
		_unlocked_entries.append(entry_id)
		_refresh_list()

func _refresh_list() -> void:
	item_list.clear()

	for entry_id in _unlocked_entries:
		var entry := RandomEventsSystem.get_glossary_entry(entry_id)
		if entry.is_empty():
			continue
		item_list.add_item("📖 " + entry.get("title", entry_id))
		item_list.set_item_metadata(item_list.get_item_count() - 1, entry_id)

	var locked_count := _all_entry_ids.size() - _unlocked_entries.size()
	label_locked.text = "%d entradas ainda bloqueadas — evite mais armadilhas para desbloquear." % locked_count

	# Seleciona a primeira entrada se existir
	if item_list.get_item_count() > 0:
		item_list.select(0)
		_on_entry_selected(0)
	else:
		label_entry_title.text = "Nenhuma entrada desbloqueada ainda."
		label_entry_text.text  = "Evite os eventos crypto para desbloquear lições."

func _on_entry_selected(index: int) -> void:
	var entry_id: String = item_list.get_item_metadata(index)
	var entry := RandomEventsSystem.get_glossary_entry(entry_id)
	if entry.is_empty():
		return
	label_entry_title.text = entry.get("title", "")
	label_entry_text.text  = entry.get("text", "")

func load_from(entries: Array) -> void:
	_unlocked_entries.clear()
	for e in entries:
		_unlocked_entries.append(str(e))
	_refresh_list()
