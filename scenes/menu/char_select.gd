extends Control

signal select_character(char_id)
signal close_character_select
signal carmine_unlocked

@onready var hover_label : Label = $HoverBox/HBoxContainer/VBoxContainer/Label
@onready var hover_portrait : TextureRect = $HoverBox/HBoxContainer/VBoxContainer/Portrait

@onready var charselect_s3 = $CenterContainer/SFCharacterSelect
@onready var charselect_s4 = $CenterContainer/SKCharacterSelect
@onready var charselect_s5 = $CenterContainer/BBCharacterSelect
@onready var charselect_s6 = $CenterContainer/UNICharacterSelect
@onready var charselect_s7 = $CenterContainer/GGCharacterSelect

@onready var season_button_s3 = $TabSelect/CategoriesHBox/Season3
@onready var season_button_s4 = $TabSelect/CategoriesHBox/Season4
@onready var season_button_s5 = $TabSelect/CategoriesHBox/Season5
@onready var season_button_s6 = $TabSelect/CategoriesHBox/Season6
@onready var season_button_s7 = $TabSelect/CategoriesHBox/Season7

@onready var carmine_portrait = $CenterContainer/UNICharacterSelect/Rows/Row5/Carmine
@onready var carmine_button = $CenterContainer/UNICharacterSelect/Rows/Row5/Carmine/Button

var default_char_id : String = "random"
var char_id_history : Array = []

@onready var label_font_normal = 42
@onready var label_font_small = 32
@onready var label_length_threshold = 15

func _ready():
	update_carmine_visibility()
	show_season(charselect_s7, season_button_s7)

func update_carmine_visibility():
	if not GlobalSettings.CarmineUnlocked:
		carmine_portrait.modulate = Color(1, 1, 1, 0)
		carmine_button.mouse_filter = MOUSE_FILTER_IGNORE
	else:
		carmine_portrait.modulate = Color(1, 1, 1, 1)
		carmine_button.mouse_filter = MOUSE_FILTER_STOP

func update_hover(char_id):
	if char_id == "random_s7":
		hover_label.text = "Random (S7)"
		hover_portrait.texture = load("res://assets/portraits/random.png")
	elif char_id == "random_s6":
		hover_label.text = "Random (S6)"
		hover_portrait.texture = load("res://assets/portraits/unilogo.png")
	elif char_id == "random_s5":
		hover_label.text = "Random (S5)"
		hover_portrait.texture = load("res://assets/portraits/blazbluelogo2.png")
	elif char_id == "random_s4":
		hover_label.text = "Random (S4)"
		hover_portrait.texture = load("res://assets/portraits/sklogo.png")
	elif char_id == "random_s3":
		hover_label.text = "Random (S3)"
		hover_portrait.texture = load("res://assets/portraits/sflogo.png")
	elif char_id == "random":
		hover_label.text = "Random (All)"
		hover_portrait.texture = load("res://assets/portraits/exceedrandom.png")
	else:
		var deck = CardDefinitions.get_deck_from_str_id(char_id)
		hover_label.text = deck['display_name']
		hover_portrait.texture = load("res://assets/portraits/" + char_id + ".png")

	if len(hover_label.text) <= label_length_threshold:
		hover_label.set("theme_override_font_sizes/font_size", label_font_normal)
	else:
		hover_label.set("theme_override_font_sizes/font_size", label_font_small)

func show_char_select(char_id : String):
	update_carmine_visibility()
	default_char_id = char_id
	update_hover(char_id)

func _on_background_button_pressed():
	close_character_select.emit()

func show_season(node, selector_button):
	charselect_s3.visible = false
	charselect_s4.visible = false
	charselect_s5.visible = false
	charselect_s6.visible = false
	charselect_s7.visible = false
	node.visible = true

	season_button_s3.set_selected(false)
	season_button_s4.set_selected(false)
	season_button_s5.set_selected(false)
	season_button_s6.set_selected(false)
	season_button_s7.set_selected(false)
	selector_button.set_selected(true)

func _on_char_button_on_pressed(character_id : String):
	if character_id.begins_with("season"):
		# Get the int season from the last character of the str.
		if character_id == "season3":
			show_season(charselect_s3, season_button_s3)
		if character_id == "season4":
			show_season(charselect_s4, season_button_s4)
		if character_id == "season5":
			show_season(charselect_s5, season_button_s5)
		elif character_id == "season6":
			show_season(charselect_s6, season_button_s6)
		elif character_id == "season7":
			show_season(charselect_s7, season_button_s7)
	else:
		if not GlobalSettings.CarmineUnlocked:
			if character_id.begins_with("random"):
				if character_id == "random_s6" and check_carmine_unlocked():
					GlobalSettings.set_carmine_unlocked(true)
					update_carmine_visibility()
					character_id = "carmine"
					carmine_unlocked.emit()
				char_id_history = []
			else:
				char_id_history.append(character_id)

		select_character.emit(character_id)

func check_carmine_unlocked():
	var password = "carmine"
	if len(char_id_history) < len(password):
		return false

	for i in range(len(password)):
		var check_char_id = char_id_history[i]
		if not check_char_id.to_lower().begins_with(password[i]):
			return false
	return true

func _on_char_hover(char_id : String, enter : bool):
	if char_id.begins_with("season"):
		return

	if enter:
		update_hover(char_id)
	else:
		update_hover(default_char_id)
