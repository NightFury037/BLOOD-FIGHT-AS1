extends Node2D

# BLOOD FIGHT - AS1 complete offline campaign prototype
const W := 1280.0
const H := 720.0
const ROUND_SECONDS := 99.0
const SAVE_PATH := "user://blood_fight_save.cfg"

const FIGHTERS := [
	{"name":"RUKHAN", "title":"BLOOD WOLF", "color":"#315a8a", "skin":"#d9a27c", "power":"WOLF RAGE"},
	{"name":"VAJRA", "title":"FIRE TIGER", "color":"#a63d27", "skin":"#c88c68", "power":"TIGER FLAME"},
	{"name":"KAIRO", "title":"IRON FIST", "color":"#65717c", "skin":"#e0ad86", "power":"IRON BREAKER"},
	{"name":"NYX", "title":"SHADOW STRIKE", "color":"#563c79", "skin":"#c88c91", "power":"SHADOW BLITZ"},
	{"name":"BRUTUS", "title":"THE WALL", "color":"#536b48", "skin":"#b98262", "power":"GROUND SMASH"},
	{"name":"MIRA", "title":"STORM KICK", "color":"#287b83", "skin":"#e4b28f", "power":"CYCLONE KICK"},
	{"name":"ZANE", "title":"RED VIPER", "color":"#9a343b", "skin":"#d49a77", "power":"VENOM RUSH"},
	{"name":"ORION", "title":"NIGHT HUNTER", "color":"#34465e", "skin":"#b77d60", "power":"NIGHTFALL"},
	{"name":"KALI", "title":"BLADE DANCER", "color":"#9b5b87", "skin":"#e2b08c", "power":"CRIMSON DANCE"},
	{"name":"TITAN", "title":"WAR MACHINE", "color":"#6e747b", "skin":"#b8876c", "power":"TITAN CRUSH"},
	{"name":"RAAZ", "title":"MAFIA KING", "color":"#a17a32", "skin":"#c38b6b", "power":"KING'S WRATH"},
	{"name":"DREAD", "title":"FINAL BOSS", "color":"#751f2b", "skin":"#b77b65", "power":"HELLFIRE"}
]

var screen := "menu"
var unlocked := 1
var selected := 0
var opponent := 1
var wins := 0
var losses := 0
var round_no := 1
var player_round_wins := 0
var enemy_round_wins := 0
var timer := ROUND_SECONDS
var p1_x := 350.0
var p2_x := 930.0
var p1_hp := 100.0
var p2_hp := 100.0
var p1_power := 0.0
var p2_power := 0.0
var p1_beast := false
var p2_beast := false
var p1_beast_time := 0.0
var p2_beast_time := 0.0
var p1_cd := 0.0
var p2_cd := 0.0
var p1_guard := false
var p2_guard := false
var p1_crouch := false
var p1_jump := 0.0
var p2_jump := 0.0
var message := ""
var message_time := 0.0
var round_busy := false
var keys := {"left":false,"right":false,"block":false}
var ui: Control
var buttons: Array[Button] = []
var save_config := ConfigFile.new()

func _ready() -> void:
	_load_progress()
	_build_ui()
	_show_menu()
	set_process(true)
	set_physics_process(true)

func _load_progress() -> void:
	if save_config.load(SAVE_PATH) == OK:
		unlocked = clampi(int(save_config.get_value("career", "unlocked", 1)), 1, 12)
		wins = int(save_config.get_value("career", "wins", 0))
		losses = int(save_config.get_value("career", "losses", 0))

func _save_progress() -> void:
	save_config.set_value("career", "unlocked", unlocked)
	save_config.set_value("career", "wins", wins)
	save_config.set_value("career", "losses", losses)
	save_config.save(SAVE_PATH)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)

func _clear_buttons() -> void:
	for b in buttons:
		if is_instance_valid(b): b.queue_free()
	buttons.clear()

func _button(label: String, rect: Rect2, callback: Callable, font_size := 22) -> Button:
	var b := Button.new()
	b.text = label
	b.position = rect.position
	b.size = rect.size
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color("#ffd27b"))
	b.add_theme_stylebox_override("normal", _button_style(Color("#242837")))
	b.add_theme_stylebox_override("hover", _button_style(Color("#49404a")))
	b.add_theme_stylebox_override("pressed", _button_style(Color("#87333c")))
	ui.add_child(b)
	b.pressed.connect(callback)
	buttons.append(b)
	return b

func _button_style(c: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.border_color = Color("#c18b4a")
	s.set_border_width_all(2)
	s.set_corner_radius_all(9)
	s.content_margin_left = 8
	s.content_margin_right = 8
	return s

func _show_menu() -> void:
	screen = "menu"
	_clear_buttons()
	_button("START CAMPAIGN", Rect2(455, 350, 370, 70), _show_roster, 28)
	_button("CONTINUE FIGHT", Rect2(455, 435, 370, 60), _continue_campaign, 23)
	_button("RESET PROGRESS", Rect2(455, 510, 370, 55), _reset_progress, 20)
	queue_redraw()

func _continue_campaign() -> void:
	opponent = mini(unlocked, 11)
	selected = 0
	_start_fight()

func _reset_progress() -> void:
	unlocked = 1
	wins = 0
	losses = 0
	_save_progress()
	_show_menu()

func _show_roster() -> void:
	screen = "roster"
	_clear_buttons()
	for i in range(12):
		var idx := i
		var col := i % 4
		var row := int(i / 4)
		var label := FIGHTERS[i].name + "\n" + FIGHTERS[i].title if i < unlocked else "LOCKED\nFIGHTER %02d" % (i + 1)
		var b := _button(label, Rect2(115 + col * 265, 190 + row * 125, 235, 100), func(): _select_fighter(idx), 17)
		b.disabled = i >= unlocked
	_button("BACK", Rect2(35, 35, 130, 52), _show_menu, 18)
	queue_redraw()

func _select_fighter(index: int) -> void:
	selected = index
	opponent = mini(maxi(1, unlocked), 11)
	_start_fight()

func _start_fight() -> void:
	screen = "fight"
	_clear_buttons()
	_reset_match()
	_build_fight_controls()
	message = "ROUND 1  -  FIGHT!"
	message_time = 2.2
	queue_redraw()

func _reset_match() -> void:
	round_no = 1
	player_round_wins = 0
	enemy_round_wins = 0
	timer = ROUND_SECONDS
	p1_hp = 100
	p2_hp = 100
	p1_power = 0
	p2_power = 0
	p1_x = 350
	p2_x = 930
	p1_beast = false
	p2_beast = false
	p1_beast_time = 0
	p2_beast_time = 0
	p1_cd = 0
	p2_cd = 0
	p1_guard = false
	p2_guard = false
	p1_crouch = false
	p1_jump = 0
	p2_jump = 0
	round_busy = false

func _build_fight_controls() -> void:
	_button("◀", Rect2(25, 575, 95, 105), func(): _hold_action("left"), 30).button_down.connect(func(): keys.left = true)
	buttons[-1].button_up.connect(func(): keys.left = false)
	_button("▶", Rect2(130, 575, 95, 105), func(): _hold_action("right"), 30).button_down.connect(func(): keys.right = true)
	buttons[-1].button_up.connect(func(): keys.right = false)
	_button("JUMP", Rect2(235, 575, 105, 105), _jump, 18)
	_button("BLOCK", Rect2(350, 575, 105, 105), func(): _set_guard(false), 18).button_down.connect(func(): p1_guard = true)
	buttons[-1].button_up.connect(func(): p1_guard = false)
	_button("CROUCH", Rect2(465, 575, 105, 105), func(): p1_crouch = false, 17).button_down.connect(func(): p1_crouch = true)
	buttons[-1].button_up.connect(func(): p1_crouch = false)
	_button("PUNCH", Rect2(875, 575, 105, 105), func(): _attack(12), 18)
	_button("KICK", Rect2(990, 575, 105, 105), func(): _attack(17), 18)
	_button("SPECIAL", Rect2(1105, 575, 150, 105), _special, 17)
	_button("MENU", Rect2(25, 20, 100, 45), _show_menu, 16)

func _hold_action(_which: String) -> void:
	pass
func _set_guard(value: bool) -> void:
	p1_guard = value
func _jump() -> void:
	if screen == "fight" and not round_busy: p1_jump = 1.0

func _attack(damage: float) -> void:
	if screen != "fight" or p1_cd > 0 or round_busy: return
	p1_cd = 0.48
	if absf(p2_x - p1_x) < 235:
		var dealt := damage * (1.5 if p1_beast else 1.0)
		p2_hp = maxf(0, p2_hp - dealt * (0.4 if p2_guard else 1.0))
		p1_power = minf(100, p1_power + damage * 2.2)
		if p2_hp <= 0: _finish_round(true)

func _special() -> void:
	if p1_power < 100 or p1_beast or round_busy: return
	p1_beast = true
	p1_beast_time = 15.0
	p1_power = 0
	message = FIGHTERS[selected].power + "!"
	message_time = 1.5
	if absf(p2_x - p1_x) < 300:
		p2_hp = maxf(0, p2_hp - (28 if selected == 11 else 24))
		if p2_hp <= 0: _finish_round(true)

func _physics_process(delta: float) -> void:
	if screen != "fight": return
	if message_time > 0: message_time -= delta
	p1_cd = maxf(0, p1_cd - delta)
	p2_cd = maxf(0, p2_cd - delta)
	if p1_beast:
		p1_beast_time -= delta
		if p1_beast_time <= 0: p1_beast = false
	if p2_beast:
		p2_beast_time -= delta
		if p2_beast_time <= 0: p2_beast = false
	if not round_busy:
		timer -= delta
		if keys.left: p1_x -= 310 * delta
		if keys.right: p1_x += 310 * delta
		p1_x = clampf(p1_x, 90, 1190)
		p1_jump = maxf(0, p1_jump - delta * 2.0)
		p2_jump = maxf(0, p2_jump - delta * 2.0)
		_ai_update(delta)
		if timer <= 0: _finish_round(p1_hp >= p2_hp)
	queue_redraw()

func _ai_update(delta: float) -> void:
	var dist := absf(p1_x - p2_x)
	var difficulty := 1.0 + float(opponent) * 0.075
	if dist > 155:
		p2_x += signf(p1_x - p2_x) * 118.0 * difficulty * delta
	else:
		if p2_cd <= 0 and not round_busy:
			p2_cd = maxf(0.42, 1.12 - float(opponent) * 0.045)
			if not p1_guard:
				p1_hp = maxf(0, p1_hp - (7.0 + opponent * 0.75) * (1.3 if p2_beast else 1.0) * (0.65 if p1_crouch else 1.0))
				p2_power = minf(100, p2_power + 14)
				if p1_hp <= 0: _finish_round(false)
	if p2_power >= 100 and not p2_beast:
		p2_beast = true
		p2_beast_time = 15
		p2_power = 0

func _finish_round(player_won: bool) -> void:
	if round_busy: return
	round_busy = true
	if player_won: player_round_wins += 1
	else: enemy_round_wins += 1
	message = "ROUND WON!" if player_won else "ROUND LOST!"
	message_time = 2.0
	await get_tree().create_timer(1.8).timeout
	if not is_inside_tree() or screen != "fight": return
	if player_round_wins >= 2:
		_finish_match(true)
	elif enemy_round_wins >= 2:
		_finish_match(false)
	else:
		round_no += 1
		timer = ROUND_SECONDS
		p1_hp = 100
		p2_hp = 100
		p1_power = 0
		p2_power = 0
		p1_x = 350
		p2_x = 930
		p1_beast = false
		p2_beast = false
		round_busy = false
		message = "ROUND %d - FIGHT!" % round_no
		message_time = 2.0

func _finish_match(player_won: bool) -> void:
	if player_won:
		wins += 1
		# Each defeated challenger is permanently unlocked. Final boss unlocks after
		# all ten standard challengers have been beaten.
		if opponent < 11:
			unlocked = maxi(unlocked, opponent + 1)
			message = "VICTORY! %s UNLOCKED" % FIGHTERS[opponent].name
		else:
			unlocked = 12
			message = "FINAL BOSS DEFEATED! ALL FIGHTERS UNLOCKED!"
	else:
		losses += 1
		message = "DEFEAT - TRAIN AND TRY AGAIN"
	_save_progress()
	screen = "result"
	_clear_buttons()
	_button("FIGHT AGAIN", Rect2(430, 445, 200, 60), _retry, 20)
	_button("FIGHTER ROSTER", Rect2(650, 445, 210, 60), _show_roster, 19)
	_button("MAIN MENU", Rect2(540, 525, 200, 55), _show_menu, 19)
	message_time = 999
	queue_redraw()

func _retry() -> void:
	_start_fight()

func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("#10121b"))
	if screen == "menu":
		_draw_menu()
	elif screen == "roster":
		_draw_roster()
	elif screen == "fight":
		_draw_arena()
	elif screen == "result":
		_draw_result()

func _draw_menu() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("#171722"))
	for i in range(8):
		draw_line(Vector2(i * 180, 0), Vector2(i * 180 - 220, H), Color("#282635"), 3)
	draw_string(ThemeDB.fallback_font, Vector2(640, 150), "BLOOD FIGHT", HORIZONTAL_ALIGNMENT_CENTER, 700, 76, Color("#c13d43"))
	draw_string(ThemeDB.fallback_font, Vector2(640, 205), "AS1  •  OFFLINE FIGHTING CHAMPIONSHIP", HORIZONTAL_ALIGNMENT_CENTER, 700, 23, Color("#e6c58b"))
	_draw_fighter(Vector2(360, 430), true, false, false, 0)
	_draw_fighter(Vector2(920, 430), false, true, false, 11)
	draw_string(ThemeDB.fallback_font, Vector2(640, 315), "UNLOCKED %d / 12     •     WINS %d     •     LOSSES %d" % [unlocked, wins, losses], HORIZONTAL_ALIGNMENT_CENTER, 750, 21, Color.WHITE)

func _draw_roster() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("#171722"))
	draw_string(ThemeDB.fallback_font, Vector2(640, 105), "CHOOSE YOUR FIGHTER", HORIZONTAL_ALIGNMENT_CENTER, 700, 40, Color("#e6c58b"))
	draw_string(ThemeDB.fallback_font, Vector2(640, 145), "UNLOCKED: %d / 12" % unlocked, HORIZONTAL_ALIGNMENT_CENTER, 400, 20, Color.WHITE)

func _draw_arena() -> void:
	draw_rect(Rect2(0, 0, W, 390), Color("#1d2030"))
	for i in range(9): draw_rect(Rect2(i * 160, 150, 5, 235), Color("#34364a"))
	draw_rect(Rect2(0, 390, W, 330), Color("#29232a"))
	for i in range(13): draw_line(Vector2(i * 110, 390), Vector2(640 + (i - 6) * 155, 720), Color("#463843"), 2)
	draw_line(Vector2(0, 390), Vector2(W, 390), Color("#b04a42"), 5)
	_draw_fighter(Vector2(p1_x, 430 - p1_jump * 75), true, p1_beast, p1_cd > 0.25, selected)
	_draw_fighter(Vector2(p2_x, 430 - p2_jump * 75), false, p2_beast, p2_cd > 0.65, opponent)
	draw_string(ThemeDB.fallback_font, Vector2(40, 40), FIGHTERS[selected].name + " / " + FIGHTERS[selected].title, HORIZONTAL_ALIGNMENT_LEFT, 460, 23, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(1240, 40), FIGHTERS[opponent].name + " / " + FIGHTERS[opponent].title, HORIZONTAL_ALIGNMENT_RIGHT, 460, 23, Color.WHITE)
	_draw_bar(Rect2(40, 55, 480, 25), p1_hp / 100, Color("#b72d37"))
	_draw_bar(Rect2(760, 55, 480, 25), p2_hp / 100, Color("#b72d37"))
	_draw_bar(Rect2(40, 88, 300, 12), p1_power / 100, Color("#e7a32d"))
	_draw_bar(Rect2(940, 88, 300, 12), p2_power / 100, Color("#e7a32d"))
	draw_string(ThemeDB.fallback_font, Vector2(640, 54), "%02d" % int(ceil(timer)), HORIZONTAL_ALIGNMENT_CENTER, 90, 32, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(640, 115), "ROUND %d     %d - %d" % [round_no, player_round_wins, enemy_round_wins], HORIZONTAL_ALIGNMENT_CENTER, 300, 20, Color("#e6d6c5"))
	if message_time > 0: draw_string(ThemeDB.fallback_font, Vector2(640, 230), message, HORIZONTAL_ALIGNMENT_CENTER, 800, 34, Color("#ffd27b"))
	if p1_beast: draw_string(ThemeDB.fallback_font, Vector2(40, 125), "SPECIAL %.1fs" % p1_beast_time, HORIZONTAL_ALIGNMENT_LEFT, 250, 18, Color("#ff785e"))

func _draw_result() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("#171722"))
	draw_string(ThemeDB.fallback_font, Vector2(640, 170), "CAMPAIGN RESULT", HORIZONTAL_ALIGNMENT_CENTER, 700, 46, Color("#e6c58b"))
	draw_string(ThemeDB.fallback_font, Vector2(640, 265), message, HORIZONTAL_ALIGNMENT_CENTER, 1100, 30, Color("#ffd27b"))
	draw_string(ThemeDB.fallback_font, Vector2(640, 330), "FIGHTER PROGRESS: %d / 12" % unlocked, HORIZONTAL_ALIGNMENT_CENTER, 700, 25, Color.WHITE)
	_draw_fighter(Vector2(640, 420), true, false, false, selected)

func _draw_bar(rect: Rect2, value: float, fill: Color) -> void:
	draw_rect(rect, Color("#45404a"))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(value, 0, 1), rect.size.y)), fill)

func _draw_fighter(pos: Vector2, player: bool, beast: bool, attacking: bool, fighter_id: int) -> void:
	var f: Dictionary = FIGHTERS[clampi(fighter_id, 0, 11)]
	var skin := Color(f.skin)
	var outfit := Color(f.color)
	if beast: outfit = outfit.lightened(0.32)
	var facing := 1.0 if player else -1.0
	var x := pos.x
	var y := pos.y
	draw_colored_polygon(PackedVector2Array([Vector2(x-75,438),Vector2(x-55,430),Vector2(x+55,430),Vector2(x+75,438),Vector2(x+55,445),Vector2(x-55,445)]), Color(0,0,0,0.35))
	draw_line(Vector2(x-15,y-15), Vector2(x-28,y+52), outfit, 19)
	draw_line(Vector2(x+15,y-15), Vector2(x+28,y+52), outfit, 19)
	draw_line(Vector2(x,y-110), Vector2(x,y-20), outfit, 43)
	draw_circle(Vector2(x,y-135), 27, skin)
	draw_line(Vector2(x-17,y-92), Vector2(x-42,y-55), skin, 17)
	var arm_end := Vector2(x + facing * (88 if attacking else 53), y-83 if attacking else y-62)
	draw_line(Vector2(x+17,y-92), arm_end, skin, 18)
	draw_circle(arm_end, 12, Color("#e5b08c"))
	if beast:
		draw_colored_polygon(PackedVector2Array([Vector2(x-24,y-158),Vector2(x-38,y-190),Vector2(x-5,y-168)]), outfit)
		draw_colored_polygon(PackedVector2Array([Vector2(x+24,y-158),Vector2(x+38,y-190),Vector2(x+5,y-168)]), outfit)
		draw_circle(Vector2(x-10,y-140), 4, Color("#ffcf43"))
		draw_circle(Vector2(x+10,y-140), 4, Color("#ffcf43"))
	else:
		draw_line(Vector2(x-18,y-158), Vector2(x+18,y-158), Color("#17151b"), 9)
