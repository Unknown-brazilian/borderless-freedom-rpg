# CLAUDE.md — Borderless Freedom RPG
## Instruções para Claude Code

Leia este arquivo antes de qualquer coisa.

---

## Estilo visual: Game Boy / Pokémon Gen 1-2

Tiles de **64×64 px**. Viewport **1080×1920** portrait.
Área de jogo: topo da tela (1080×1280 px).
Controles touch: parte inferior (1080×640 px).

Visual monocromático/retro (paleta limitada sugerida):
- Fundo escuro: `Color(0.05, 0.05, 0.07)`
- Tile grama: `Color(0.18, 0.38, 0.18)`
- Tile caminho: `Color(0.55, 0.48, 0.35)`
- Tile parede: `Color(0.25, 0.22, 0.18)`
- Player: `Color(0.969, 0.576, 0.102)` (amarelo Bitcoin)
- NPC/fiscal: `Color(0.72, 0.18, 0.18)` (vermelho)
- Boss: `Color(0.85, 0.15, 0.15)` (vermelho vivo)

---

## Plataforma alvo: ANDROID

**Sem teclado. Sem mouse. Apenas touch.**

| Controle | Ação |
|---|---|
| D-Pad ▲▼◀▶ | Mover player no mapa |
| Botão A | Interagir / Confirmar / Atacar |
| Botão B | Cancelar / Fechar menu |
| Botão START | Abrir menu de pausa/mochila |
| Tap em NPC | Também inicia interação |

**Nunca use:**
- `InputEventKey`, `Input.is_key_pressed()`
- Atalhos de teclado em botões

---

## AutoLoads — ordem obrigatória

```
SatEconomy          → scripts/systems/sat_economy.gd
RandomEventsSystem  → scripts/systems/random_events_system.gd
WorldManager        → scripts/systems/world_manager.gd
BattleManager       → scripts/systems/battle_manager.gd
DialogueManager     → scripts/systems/dialogue_manager.gd
GameStats           → scripts/systems/game_stats.gd
SaveSystem          → scripts/systems/save_system.gd
AutonomyBar         → scripts/systems/autonomy_bar.gd
PlayerStats         → scripts/player/player_stats.gd
PlayerInventory     → scripts/systems/player_inventory.gd
PlayerCustomization → scripts/player/player_customization.gd
SeedPhraseSystem    → scripts/systems/seed_phrase_system.gd
SceneTransition     → scripts/systems/scene_transition.gd
AudioManager        → scripts/systems/audio_manager.gd
```

---

## Arquitetura do jogo

### Fluxo principal
```
MainMenu → PlayerCustomization → SeedPhraseScreen
→ WorldMap D1 (Bostil) → batalhas/eventos → BossD1
→ BossWordChallenge → WorldMap D2 → ... → D9 → Ending
```

### Estrutura de mapa
Cada dungeon tem **1 mapa de mundo** (`.tscn` + `.gd`).
O mapa contém:
- `TileMap` com tiles de 64×64
- Nós filhos: `PlayerStart`, NPCs, `FiscalEnemy`s, `EventTrigger`s, `BossMarker`

### Sistema de batalha (turn-based)
```
Estado: PLAYER_TURN | ENEMY_TURN | VICTORY | DEFEAT | ESCAPE
Ações do player: Atacar | Item | Furtividade | Persuasão | Fugir
Cada turno: Player age → Enemy age → repete
Boss: palavra-challenge após derrota (BossWordChallenge)
```

### Diálogo
`DialogueManager.start(lines: Array[String])` — mostra caixa de diálogo.
`DialogueManager.dialogue_finished` — sinal quando termina.

### Sistema de inimigos patrulheiros
`spawn_patrol_enemy(tile, name, hp, atk, reward, bribe, weakness, spread)` — inimigo visível que patrulha e persegue (raio 192px) ao ver o player. Todos os dungeons usam isso.

### Mini-games (Saltillo)
`scripts/minigames/minigame_base.gd` — base: seta `BattleManager.locked=true`, desativa AutonomyBar, bloqueia player, emite `minigame_completed(sats)`.
Cada mini-game é uma `CanvasLayer` adicionada via `add_child()` no mapa. Retorno via `await mg.minigame_completed`.
- Desossa: tap na zona iluminada em 2.5s
- Empilhadeira: Sokoban 7×5, empurrar 3 paletes aos alvos
- Caminhão: navegar mapa 10×8, 5 entregas em 90s
- Limpeza: mover sobre 40 tiles sujos (intencional tédio + 4 histórias de imigrantes)

### Sistema de Crypto NPCs (sem timeout)
`spawn_crypto_npc(tile, event_id)` — NPC que se aproxima e oferece scam sem timer.
`CryptoOfferUI.tscn` — UI de oferta convincente. Aceitar=perde sats+educação; Recusar=nota discreta.

### WorldManager — sequência de cenas
`WorldManager.SCENE_SEQUENCE` — Array ordenado de 13 entradas (D1-D9 + sub-mapas D5/D6).
`WorldManager.sequence_index` — índice atual (salvo no SaveSystem).
Sub-mapas D6: tapachula_detencao → mexistao → torreon_detencao → saltillo.

---

## Mapa de dungeons / regiões

| # | Nome | País fictício | Fases equivalentes do runner |
|---|---|---|---|
| D1 | Bostil | Brasil | 10 seções (tutorial, fiscais, bosses) |
| D2 | Bolivária | Bolívia | 4 seções |
| D3 | Perulândia | Peru | 5 seções |
| D4 | Panamia | Panamá+Darién | 3 seções + escolha |
| D5 | Centrolândia | América Central | 7 seções |
| D6 | Mexistão | México | 12 seções |
| D7 | Bostil (retorno) | Brasil/deportação | 4 seções |
| D8 | Paraguassu | Paraguai | 5 seções |
| D9 | Bélgique | Bélgica/EU | 7 seções |

---

## Regras invioláveis

- Nunca usar nomes reais de países — sempre os fictícios
- Nome do personagem sempre via `PlayerStats.player_name`
- Sats nunca se desvalorizam — 1 sat = 1 sat
- Default de evento crypto = IGNORAR
- Seeds sempre com aviso: "SEED DO JOGO — NUNCA USE SEEDS REAIS AQUI"

---

## Nomenclatura de arquivos

- Mapas mundo: `scenes/world/d{N}_{nome}.tscn`
- Scripts de mapa: `scripts/world/d{N}_{nome}.gd`
- NPCs por dungeon: `scripts/world/npcs/d{N}_*.gd`
- Batalhas boss: `scripts/battle/boss_d{N}.gd`
- Diálogos: `data/dialogues/d{N}_dialogues.json`
- Mapas tile: `data/maps/d{N}_{nome}.json`
