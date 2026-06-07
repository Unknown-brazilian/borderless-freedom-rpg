## lpc_character.gd — sprite de personagem LPC (32-bit JRPG) com caminhada por
## direção. Detecta movimento pela mudança de posição do pai (serve p/ player,
## NPCs e patrulheiros sem fiação extra). Sheet: 9 colunas × 4 linhas (64px),
## linhas = cima/esquerda/baixo/direita (ordem do walkcycle LPC).
extends Sprite2D

const SHEET := "res://assets/lpc/player_walk.png"
const COLS := 9
const ROWS := 4

@export var anim_fps: float = 8.0
@export var face_row: int = 2   # começa virado pra baixo

var _t: float = 0.0
var _last_pos: Vector2

func _ready() -> void:
	if texture == null and ResourceLoader.exists(SHEET):
		texture = load(SHEET)
	hframes = COLS
	vframes = ROWS
	frame = face_row * COLS
	centered = true
	offset = Vector2(0, -16)   # pés no chão do tile
	_last_pos = global_position

func _process(delta: float) -> void:
	var d := global_position - _last_pos
	_last_pos = global_position
	if d.length() > 0.5:
		if absf(d.x) > absf(d.y):
			face_row = 3 if d.x > 0.0 else 1
		else:
			face_row = 2 if d.y > 0.0 else 0
		_t += delta * anim_fps
		frame = face_row * COLS + 1 + (int(_t) % (COLS - 1))
	else:
		frame = face_row * COLS   # parado = quadro idle
