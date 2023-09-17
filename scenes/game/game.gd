extends Node2D

const DesiredCardSize = Vector2(125, 175)
const ActualCardSize = Vector2(250,350)
const HandCardScale = DesiredCardSize / ActualCardSize
const CardBaseScene = preload("res://scenes/card/card_base.tscn")
const CardBase = preload("res://scenes/card/card_base.gd")

var chosen_deck = null
var NextCardId = 1

var CardIdToDef = {}

enum {
	GameState_PlayerTurn_PickAction,
}

@onready var CenterCardOval = Vector2(get_viewport().size) * Vector2(0.5, 1.25)
@onready var HorizontalRadius = get_viewport().size.x * 0.45
@onready var VerticalRadius = get_viewport().size.y * 0.4

# Called when the node enters the scene tree for the first time.
func _ready():
	chosen_deck = CardDefinitions.decks[0]
	for i in range(7):
		draw_card()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _input(event):
	if event is InputEventMouseButton:
		if event is InputEventMouseButton and event.is_released():
			pass


func draw_card():
	#for deck_card in chosen_deck['cards']:
	if NextCardId == 8: return
	var deck_card = chosen_deck['cards'][NextCardId-1]
	var card_definition_id = deck_card['definition_id']
	var card_def = CardDefinitions.get_card(card_definition_id)
	var id_for_card = NextCardId
	NextCardId += 1
	CardIdToDef[id_for_card] = card_def

	var new_card = add_new_card_to_hand(id_for_card, card_def, deck_card['image'])

	# Start the card at the deck.
	var deck_position = $Deck/DeckButton.position + DesiredCardSize/2
	new_card.position = deck_position
	
	layout_player_hand()

func add_new_card_to_hand(id, card_def, image) -> CardBase:
	var new_card : CardBase = CardBaseScene.instantiate()
	$PlayerHand.add_child(new_card)
	new_card.initialize_card(
		id,
		card_def['display_name'],
		HandCardScale,
		image,
		card_def['range_min'],
		card_def['range_max'],
		card_def['speed'],
		card_def['power'],
		card_def['armor'],
		card_def['guard'],
		CardDefinitions.get_effect_text(card_def['effects']),
		card_def['boost']['cost'],
		CardDefinitions.get_boost_text(card_def['effects'])
	)
	new_card.raised_card.connect(on_card_raised)
	new_card.lowered_card.connect(on_card_lowered)
	return new_card

func on_card_raised(card):
	# Get card's position in the PlayerHand node's children.
	if card.get_parent() == $PlayerHand:
		card.saved_hand_index = card.get_index()

		# Move card to the end of the children list.
		$PlayerHand.move_child(card, $PlayerHand.get_child_count() - 1)

func on_card_lowered(card):
	if card.saved_hand_index != -1:
		# Move card back to its saved position.
		$PlayerHand.move_child(card, card.saved_hand_index)
		card.saved_hand_index = -1

func layout_player_hand():
	var num_cards = len($PlayerHand.get_children())
	var angle = deg_to_rad(90)
	var HandAngleChange = 0.2
	angle += HandAngleChange * (num_cards - 1)/2
	for i in range(num_cards):
		var card : CardBase = $PlayerHand.get_child(i)

		var ovalAngleVector = Vector2(HorizontalRadius * cos(angle), -VerticalRadius * sin(angle))
		var dst_pos = CenterCardOval + ovalAngleVector # - size/2
		var dst_rot = (90 - rad_to_deg(angle)) / 4
		card.set_resting_position(dst_pos, dst_rot)

		angle -= 0.2


