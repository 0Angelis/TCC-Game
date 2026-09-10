extends Node


# ==========================================
# MOEDAS / SCORE / VIDAS
# ==========================================

var coins := 0
var score := 0
var player_life := 5

# ==========================================
# VIDA NO INÍCIO DA FASE ATUAL
# ==========================================
# Usado pelo RESTART do pause.
# O restart volta para a quantidade de vidas que existia
# quando o jogador entrou na fase, sem contar as vidas perdidas nela.
var lives_before_level := 5

# Caminho da cena usada para criar o snapshot acima.
# Impede que o _ready() do player sobrescreva o snapshot
# quando a mesma fase for apenas recarregada pelo RESTART.
var life_snapshot_scene := ""

# ==========================================
# ÚLTIMO MUNDO ANTES DA LOJA
# ==========================================

# 1 = mundo 01 -> loja -> mundo 02
# 2 = mundo 02 -> loja -> mundo 03
# 3 = mundo 03 -> loja -> mundo 04 (boss final)
var last_world_before_shop := 0


# ==========================================
# MOEDAS ANTES DO MAPA ATUAL
# ==========================================

var coins_before_level := 0


# ==========================================
# DADOS DA FASE ATUAL
# ==========================================

var level_coins := 0
var level_score := 0


# ==========================================
# FRAGMENTOS
# ==========================================

var raciocinio_fragments := 0
var atencao_fragments := 0
var memoria_fragments := 0
