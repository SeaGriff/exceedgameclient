extends GutTest

const GameLogic = preload("res://scenes/game/gamelogic.gd")
var game_logic : GameLogic
var default_deck = CardDefinitions.decks[0]
const TestCardId1 = 50001
const TestCardId2 = 50002
const TestCardId3 = 50003

func default_game_setup():
	game_logic = GameLogic.new()
	game_logic.initialize_game(default_deck, default_deck)
	game_logic.draw_starting_hands_and_begin()
	game_logic.do_mulligan(game_logic.active_turn_player, [])
	game_logic.do_mulligan(game_logic.next_turn_player, [])

func give_player_specific_card(player, def_id, card_id):
	var card_def = CardDefinitions.get_card(def_id)
	var card = game_logic.Card.new(card_id, card_def, "image")
	game_logic._test_insert_card(card)
	player.hand.append(card)

func give_specific_cards(player1, id1, player2, id2):
	if player1:
		give_player_specific_card(player1, id1, TestCardId1)
	if player2:
		give_player_specific_card(player2, id2, TestCardId2)

func position_players(player1, loc1, player2, loc2):
	player1.arena_location = loc1
	player2.arena_location = loc2

func give_gauge(player, amount):
	for i in range(amount):
		player.add_to_gauge(player.deck[0])
		player.deck.remove_at(0)

func validate_has_event(events, event_type, event_player, number = null):
	for event in events:
		if event['event_type'] == event_type:
			assert_eq(event['event_player'], event_player)
			if number != null:
				assert_eq(event['number'], number)
			return
	fail_test("Event not found: %s" % event_type)

func before_each():
	default_game_setup()

	gut.p("ran setup", 2)

func after_each():
	game_logic.free()
	gut.p("ran teardown", 2)

func before_all():
	gut.p("ran run setup", 2)

func after_all():
	gut.p("ran run teardown", 2)

func do_and_validate_strike(player, card_id):
	assert_true(game_logic.can_do_strike(player))
	var events = game_logic.do_strike(player, card_id, false, -1)
	validate_has_event(events, game_logic.EventType.EventType_Strike_Started, player, card_id)
	assert_eq(game_logic.game_state, game_logic.GameState.GameState_Strike_Opponent_Response)

func do_strike_response(player, card_id, ex_card = -1):
	var events = game_logic.do_strike(player, card_id, false, ex_card)
	return events

func validate_gauge(player, amount, id):
	assert_eq(len(player.gauge), amount)
	if len(player.gauge) != amount: return
	if amount == 0: return
	for card in player.gauge:
		if card.id == id:
			return
	fail_test("Didn't have required card in gauge.")

func validate_discard(player, amount, id):
	assert_eq(len(player.discards), amount)
	if len(player.discards) != amount: return
	if amount == 0: return
	for card in player.discards:
		if card.id == id:
			return
	fail_test("Didn't have required card in discard.")

func validate_life(player, total):
	assert_eq(player.life, total)

func test_strike_initiator_wins_ties():
	var initiator = game_logic.player
	var defender = game_logic.opponent
	give_specific_cards(initiator, "gg_normal_grasp", defender, "gg_normal_grasp")
	position_players(initiator, 3, defender, 4)
	do_and_validate_strike(initiator, TestCardId1)
	var events = do_strike_response(defender, TestCardId2)
	# Expect grasp choice
	assert_eq(game_logic.game_state, game_logic.GameState.GameState_PlayerDecision)
	validate_has_event(events, game_logic.EventType.EventType_Strike_EffectChoice, initiator)
	events = game_logic.do_choice(initiator, 0) # push 1
	assert_eq(defender.arena_location, 5)
	assert_eq(game_logic.game_state, game_logic.GameState.GameState_PickAction)
	assert_eq(game_logic.active_turn_player, defender)
	validate_gauge(initiator, 1, TestCardId1)
	validate_gauge(defender, 0, TestCardId2)
	validate_discard(initiator, 0, TestCardId1)
	validate_discard(defender, 1, TestCardId2)
	validate_life(initiator, 30)
	validate_life(defender, 27)

func test_ex_grasp_mirror():
	var initiator = game_logic.player
	var defender = game_logic.opponent
	give_specific_cards(initiator, "gg_normal_grasp", defender, "gg_normal_grasp")
	give_player_specific_card(defender, "gg_normal_grasp", TestCardId3)
	position_players(initiator, 3, defender, 4)
	do_and_validate_strike(initiator, TestCardId1)
	var events = do_strike_response(defender, TestCardId2, TestCardId3)
	# Expect grasp choice
	assert_eq(game_logic.game_state, game_logic.GameState.GameState_PlayerDecision)
	validate_has_event(events, game_logic.EventType.EventType_Strike_EffectChoice, defender)
	events = game_logic.do_choice(defender, 3) # pull 2
	assert_eq(initiator.arena_location, 6)
	assert_eq(game_logic.game_state, game_logic.GameState.GameState_PickAction)
	assert_eq(game_logic.active_turn_player, defender)
	validate_gauge(initiator, 0, TestCardId1)
	validate_gauge(defender, 1, TestCardId2)
	validate_discard(initiator, 1, TestCardId1)
	validate_discard(defender, 1, TestCardId3)
	validate_life(initiator, 26)
	validate_life(defender, 30)




