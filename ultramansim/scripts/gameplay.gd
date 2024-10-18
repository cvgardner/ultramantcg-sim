extends Control

var is_lead : bool # Boolean signifying if the server is lead or not
@onready var action_button = $ActionButtonContainer/ActionButton
@onready var cancel_button = $ActionButtonContainer/CancelButton
@onready var battle_log = $BattleLog
@onready var card_preview = $CardPreview
var battle_log_text = "" # String battle log text
enum Phase { SETUP, START, DRAW, LEAD_SCENE_SET, SET_CHARACTER, LEVEL_UP, OPEN, EFFECT_ACTIVATION, JUDGEMENT, END}
var current_phase 

var CardScene = preload("res://scenes/card.tscn")

#Signals
signal phase_changed(new_phase: Phase)
signal lead_player_chosen()
signal hand_changed(player, hand)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connecting Signals
	action_button.pressed.connect(_action_button_pressed)
	cancel_button.pressed.connect(_cancel_button_pressed)
	phase_changed.connect(_on_phase_changed)
	hand_changed.connect(_hand_changed_emitted)
	#Hide some UI components
	action_buttons_hide()
	configure_hand_ui()
	
	# Ready UI Components
	$PlayerId.text = GlobalData.player_id
	
	print("Player deck: ", GlobalData.player_deck, "Opp deck: ", GlobalData.opp_deck)
	print(GlobalData.player_deck, " opponent_deck ", GlobalData.opp_deck.deckdict)
	
	set_phase(Phase.SETUP)
	
func set_phase(phase: Phase):
	current_phase = phase
	emit_signal("phase_changed", current_phase)
	print("Phase changed to: ", str(phase))
	rpc("print_message", "Phase changed to: ", str(phase))
	
func _on_phase_changed(new_phase: Phase):
	match new_phase:
		Phase.SETUP:
			update_battle_log("Setting up Game", false)
			game_setup()
		Phase.START:
			pass
		Phase.DRAW:
			pass
		Phase.LEAD_SCENE_SET:
			pass
		Phase.SET_CHARACTER:
			pass
		Phase.LEVEL_UP:
			pass
		Phase.OPEN:
			pass
		Phase.EFFECT_ACTIVATION:
			pass
		Phase.JUDGEMENT:
			pass
		Phase.END:
			pass
	

func game_setup():	
	if multiplayer.is_server():
		current_phase = Phase.SETUP
		
		#Ready The Decks
		for deck in [GlobalData.player_deck, GlobalData.opp_deck]:
			deck.create_deck()
			deck.shuffle_deck() #This would desync the player and server. I think this is where I start having server pass all info to the client?
		
		# Choose Deciding Player
		randomize()
		var decider = randi() % 2 == 0
		
		# Deciding Player chooses whether to be lead or next
		if decider:
			choose_lead()
		else:
			rpc("choose_lead")
		
		await lead_player_chosen
		print("Lead Player Chosen signal received")
	
		# Draw Starting Hands
		print("Drawing Hands")
		GlobalData.player_hand = GlobalData.player_deck.draw_card(6)
		GlobalData.opp_hand = GlobalData.opp_deck.draw_card(6)
		print(GlobalData.player_hand, GlobalData.opp_hand)
		
		#Update hand UI
		emit_signal("hand_changed", "player", GlobalData.player_hand)
		emit_signal("hand_changed", "opponent", GlobalData.opp_hand)
		print("Updating Hands")
		
		#mulligan("init")
		#rpc("mulligan", "init")

func _hand_changed_emitted(player, hand):
	'''Processes RPC for hand updates'''
	update_hand(player, hand)
	rpc("update_hand", player, hand)

@rpc("any_peer", "reliable")
func update_hand(player, hand):
	'''Updates the hand UI based on the hand which is an array of card_no and player'''
	print(multiplayer.is_server(), player, hand)
	if player == "player":
		$PlayerHand.clear()
		var index = 0
		for card in hand:
			$PlayerHand.add_item("", GlobalData.cards[card].image)
			$PlayerHand.set_item_metadata(index, card)
			index += 1
		$PlayerHand.queue_redraw()
	else: # If player is opponent
		$OppHand.clear()
		var index = 0
		for card in hand:
			$OppHand.add_item("", ResourceLoader.load("res://images/assets/card_back.png"))
			$OppHand.set_item_metadata(index, card)
			index += 1
		$OppHand.queue_redraw()

@rpc
func mulligan(step):
	'''Changes the mulligan button and implements mulligan based on the step string parameter'''
	if step == 'init':
		# Mulligan
		action_button.show()
		action_button.text = "Mulligan"
	
				
func update_battle_log(text, server_only = true):
	if server_only:
		_update_battle_log(text)
		rpc("_update_battle_log", text)
	else:
		_update_battle_log(text)

@rpc("any_peer", "reliable")
func _update_battle_log(text):
	battle_log_text += text + "\n"
	battle_log.text = battle_log_text
		
@rpc("any_peer", "reliable")
func choose_lead():
	action_buttons_show()
	action_button.text = "Lead Player"
	cancel_button.text = "Next Player"

func _action_button_pressed():
	if action_button.text == "Lead Player":
		if multiplayer.is_server():
			set_lead_player(true)
			update_battle_log("{0} has chosen to be Lead Player".format([GlobalData.player_id]))

		else:
			rpc_id(1, "set_lead_player", false)
			update_battle_log("{0} has chosen to be Lead Player".format([GlobalData.player_id]))
		action_buttons_hide()
		

	
func _cancel_button_pressed():
	if cancel_button.text == "Next Player":
		if multiplayer.is_server():
			set_lead_player(false)
			update_battle_log("{0} has chosen to be Next Player".format([GlobalData.player_id]))
		else:
			rpc_id(1, "set_lead_player", true)
			update_battle_log("{0} has chosen to be Next Player".format([GlobalData.player_id]))
		action_buttons_hide()
	
@rpc("any_peer", "reliable")
func set_lead_player(boolean):
	is_lead = boolean
	emit_signal("lead_player_chosen")
	
@rpc("any_peer", "reliable")
func action_buttons_hide():
	$ActionButtonContainer.hide()
	
@rpc("any_peer", "reliable")
func action_buttons_show():
	$ActionButtonContainer.show()
	

	
@rpc
func print_message(message: String):
	print(message)

func instantiate_card(card_no, back=false):
	'''Insantiates a cardscene with the given card_no string'''
	var new_card
	if back:
		new_card = CardScene.instantiate().card_back(GlobalData.cards[card_no].card_name, GlobalData.cards[card_no].card_no, GlobalData.cards[card_no].character, GlobalData.cards[card_no].feature, GlobalData.cards[card_no].level, GlobalData.cards[card_no].type, GlobalData.cards[card_no].bp, GlobalData.cards[card_no].abilities, GlobalData.cards[card_no].image_path)
	else:
		new_card = CardScene.instantiate().with_data(GlobalData.cards[card_no].card_name, GlobalData.cards[card_no].card_no, GlobalData.cards[card_no].character, GlobalData.cards[card_no].feature, GlobalData.cards[card_no].level, GlobalData.cards[card_no].type, GlobalData.cards[card_no].bp, GlobalData.cards[card_no].abilities, GlobalData.cards[card_no].image_path)
	return new_card
	
func configure_hand_ui():
	''' Configures itemlist UI for displaying Hands'''
	$PlayerHand.auto_height = true
	$PlayerHand.set_max_columns(0)
	$PlayerHand.fixed_icon_size = Vector2(96, 96)
	$PlayerHand.set_allow_reselect(true)
	$PlayerHand.set_allow_rmb_select(true)
	$PlayerHand.set_icon_mode(0)
	$PlayerHand.hovered_item.connect(_preview_card)
	
	$OppHand.auto_height = true
	$OppHand.set_max_columns(0)
	$OppHand.fixed_icon_size = Vector2(96, 96)
	$OppHand.set_allow_reselect(true)
	$OppHand.set_allow_rmb_select(true)
	$OppHand.set_icon_mode(0)
	#$OppHand.hovered_item.connect(_preview_card)

func _preview_card(item):
	if item != 'none':
		card_preview.set_visible(true)
		card_preview.set_texture(GlobalData.cards[item].image)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
