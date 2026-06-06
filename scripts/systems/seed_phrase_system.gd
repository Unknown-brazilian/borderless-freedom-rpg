## seed_phrase_system.gd
## Borderless Freedom: A Dissident Adventure
## AutoLoad — gerencia a seed phrase de 24 palavras do jogo.
##
## ⚠️  ESTA É UMA SEED DO JOGO, NÃO UMA SEED REAL DE BITCOIN.
##      NUNCA DIGITE SUA SEED REAL COM SALDO EM APLICATIVOS.
##
## Fluxo:
##   Nova jornada → generate_seed() → SeedPhraseScreen mostra as 24 palavras
##   Cada chefe   → get_boss_challenge_positions(boss_id) → 4 palavras aleatórias
##                  check_boss_words(boss_id, answers) → true → 30% bônus de loot
##   Deportação   → check_deportation_words(answers) → true → libera o player
##
## As posições das palavras por chefe são geradas uma vez e memorizadas
## para que o mesmo chefe exija sempre as mesmas posições na mesma run.

extends Node

# ─── Sinais ───────────────────────────────────────────────────────────────────
signal seed_generated
signal boss_challenge_passed(boss_id: String, bonus_sats: int)
signal boss_challenge_failed(boss_id: String)
signal deportation_passed
signal deportation_failed

# ─── Constantes ───────────────────────────────────────────────────────────────
const WORD_COUNT:       int   = 24
const BOSS_WORD_COUNT:  int   = 4
const BONUS_MULTIPLIER: float = 0.30   # 30 % sobre o loot base do chefe

# ─── Estado ───────────────────────────────────────────────────────────────────
var words: Array[String] = []                  # as 24 palavras desta run
var _wordlist: Array                           # lista BIP39 carregada do arquivo
var _boss_positions: Dictionary = {}           # boss_id → Array[int] 1-indexed
var _boss_bonus_awarded: Dictionary = {}       # boss_id → bool

# ─── Inicialização ────────────────────────────────────────────────────────────
func _ready() -> void:
	_load_wordlist()

func _load_wordlist() -> void:
	var file := FileAccess.open("res://data/bip39_en.json", FileAccess.READ)
	if not file:
		push_error("[SeedPhraseSystem] Falha ao abrir bip39_en.json")
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_error("[SeedPhraseSystem] Falha ao parsear bip39_en.json")
		file.close()
		return
	_wordlist = json.get_data()
	file.close()

# ─── API pública — geração ────────────────────────────────────────────────────

## Gera 24 palavras aleatórias da wordlist BIP39. Chame ao iniciar nova jornada.
func generate_seed() -> void:
	if _wordlist.is_empty():
		push_error("[SeedPhraseSystem] Wordlist vazia — bip39_en.json não carregado.")
		return
	words.clear()
	_boss_positions.clear()
	_boss_bonus_awarded.clear()
	var pool: Array = _wordlist.duplicate()
	pool.shuffle()
	for i in range(WORD_COUNT):
		words.append(str(pool[i]))
	emit_signal("seed_generated")

# ─── API pública — desafio de chefe ──────────────────────────────────────────

## Retorna as 4 posições (1-indexed) exigidas para o boss_id.
## As posições são geradas uma vez por run e reutilizadas.
func get_boss_challenge_positions(boss_id: String) -> Array[int]:
	if not _boss_positions.has(boss_id):
		var available: Array = range(1, WORD_COUNT + 1)
		available.shuffle()
		var positions: Array[int] = []
		for i in range(BOSS_WORD_COUNT):
			positions.append(available[i])
		positions.sort()
		_boss_positions[boss_id] = positions
	return _boss_positions[boss_id]

## Verifica se as 4 respostas batem com as palavras nas posições exigidas.
func check_boss_words(boss_id: String, answers: Array[String]) -> bool:
	var positions := get_boss_challenge_positions(boss_id)
	for i in range(positions.size()):
		var expected: String = words[positions[i] - 1].to_lower().strip_edges()
		var given:    String = answers[i].to_lower().strip_edges()
		if expected != given:
			return false
	return true

## Calcula o bônus de 30% sobre o loot base e registra que foi concedido.
func award_boss_bonus(boss_id: String, base_loot: int) -> int:
	var bonus := int(base_loot * BONUS_MULTIPLIER)
	_boss_bonus_awarded[boss_id] = true
	SatEconomy.add_sats(bonus, "boss_seed_bonus_%s" % boss_id)
	emit_signal("boss_challenge_passed", boss_id, bonus)
	return bonus

## Informa se o bônus deste chefe já foi concedido.
func boss_bonus_awarded(boss_id: String) -> bool:
	return _boss_bonus_awarded.get(boss_id, false)

## Retorna `count` palavras aleatórias da wordlist, excluindo `exclude_word`.
func get_random_decoys(count: int, exclude_word: String) -> Array[String]:
	if _wordlist.is_empty(): return []
	var pool: Array = _wordlist.duplicate()
	pool.shuffle()
	var result: Array[String] = []
	for w in pool:
		if w != exclude_word and result.size() < count:
			result.append(str(w))
	return result

# ─── API pública — deportação ─────────────────────────────────────────────────

## Verifica se todas as 24 palavras foram digitadas corretamente (D7).
func check_deportation_words(answers: Array[String]) -> bool:
	if answers.size() != WORD_COUNT:
		return false
	for i in range(WORD_COUNT):
		if words[i].to_lower().strip_edges() != answers[i].to_lower().strip_edges():
			return false
	return true

# ─── Persistência ─────────────────────────────────────────────────────────────
func save() -> Dictionary:
	return {
		"words":   words,
		"boss_pos": _boss_positions,
		"bonuses":  _boss_bonus_awarded
	}

func load_from(data: Dictionary) -> void:
	var w: Array = data.get("words", [])
	words.clear()
	for word in w:
		words.append(str(word))
	_boss_bonus_awarded = data.get("bonuses", {})
	_boss_positions = {}
	for boss_id in data.get("boss_pos", {}).keys():
		var raw: Array = data["boss_pos"][boss_id]
		var positions: Array[int] = []
		for v in raw:
			positions.append(int(v))
		_boss_positions[boss_id] = positions
