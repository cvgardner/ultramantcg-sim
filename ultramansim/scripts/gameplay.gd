extends Control

var is_lead : bool # Boolean signifying if the server is lead or not
@onready var action_button = $ActionButtonContainer/ActionButton
@onready var cancel_button = $ActionButtonContainer/CancelButton
@onready var battle_log = $BattleLog
@onready var card_preview = $CardPreview
var battle_log_text = "" # String battle log text
enum Phase { SETUP, START, DRAW, LEAD_SCENE_SET, SET_CHARACTER, LEVEL_UP, OPEN, EFFECT_ACTIVATION, JUDGEMENT, END}
var current_phase 
var round = 0
var server_mulligan_complete = false
var client_mulligan_complete = false
var current_scene : String # The currently active scene's card_no
var player_field = [] # Player field specified as an array of array of nodes
var opp_field = [] # Opponent field specified as an array of array of nodes

var CardScene = preload("res://scenes/card.tscn")
@export var local_test: bool = false

#Signals
signal phase_changed(new_phase: Phase)
signal lead_player_chosen()
signal hand_changed(player, hand)
signal start_mulligan
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if local_test:
		configure_local_test()
		#Test Connection
		
	# Connecting Signals
	action_button.pressed.connect(_action_button_pressed)
	cancel_button.pressed.connect(_cancel_button_pressed)
	phase_changed.connect(_on_phase_changed)
	hand_changed.connect(_hand_changed_emitted)
	start_mulligan.connect(do_mulligan)
	#Hide some UI components
	action_buttons_hide()
	configure_hand_ui()
	
	# Ready UI Components
	$PlayerId.text = GlobalData.player_id
	
	
	
	print("Player deck: ", GlobalData.player_deck, "Opp deck: ", GlobalData.opp_deck)
	print(GlobalData.player_deck, " opponent_deck ", GlobalData.opp_deck.deckdict)
	
	set_phase(Phase.SETUP)
	


	
func set_phase(phase: Phase):
	if multiplayer.is_server():
		current_phase = phase
		emit_signal("phase_changed", current_phase)
		print("Phase changed to: ", str(phase))
		rpc("print_message", "Phase changed to: ", str(phase))
	
func _on_phase_changed(new_phase: Phase):
	if multiplayer.is_server():
		match new_phase:
			Phase.SETUP:
				update_battle_log("Setting up Game")
				game_setup()
			Phase.START:
				var s = "Round {0} Start!".format([round])
				update_battle_log(s)
				start_phase()
			Phase.DRAW:
				var s = "Round {0} Draw Phase".format([round])
				draw_phase()
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
	
func start_phase():
	var lead_player 
	if is_lead:
		lead_player = GlobalData.player_id
	else:
		lead_player = GlobalData.opp_id
	var s = "The Lead Player is {0}".format([lead_player])
	update_battle_log(s)
	set_phase(Phase.DRAW)
	
func draw_phase():
	# Draw Phase
	print(GlobalData.player_deck.draw_card(1))
	GlobalData.player_hand = GlobalData.player_hand + GlobalData.player_deck.draw_card(1)
	GlobalData.opp_hand = GlobalData.opp_hand + GlobalData.opp_deck.draw_card(1)

	#Update hand UI
	emit_signal("hand_changed", "player", GlobalData.player_hand)
	emit_signal("hand_changed", "opponent", GlobalData.opp_hand)
	
	set_phase(Phase.LEAD_SCENE_SET)
	
func game_setup():	
	if multiplayer.is_server():
		current_phase = Phase.SETUP
		_wait(5)
		print("Waiting Local Done")
		rpc("receive_rpc_call")
		#Ready The Decks
		for deck in [GlobalData.player_deck, GlobalData.opp_deck]:
			deck.create_deck()
			deck.shuffle_deck() #This would desync the player and server. I think this is where I start having server pass all info to the client?
		
		# Choose Deciding Player
		randomize()
		var decider = randi() % 2 == 0
		if local_test:
			decider = true
		
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

		emit_signal("start_mulligan")
	
func do_mulligan():
	mulligan("init")
	rpc("mulligan", "init")
		
@rpc("any_peer", "call_local")
func receive_rpc_call():
	print("Received RPC call")

func _hand_changed_emitted(player, hand):
	'''Processes RPC for hand updates'''
	if player == "player":
		update_hand(player, hand)
		rpc("update_hand", "opponent", hand)
	if player == "opponent":
		update_hand(player, hand)
		rpc("update_hand", "player", hand)

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
	

@rpc("any_peer", "reliable")
func mulligan(step):
	'''Changes the mulligan button and implements mulligan based on the step string parameter'''
	if step == 'init':
		print("Mulligan Init")
		# Mulligan
		action_button.text = "Mulligan"
		cancel_button.text = "Cancel"
		action_buttons_show()
		
	elif step == "server":
		print("Mulligan Server")
		GlobalData.player_deck.bottom_cards(GlobalData.player_hand)
		GlobalData.player_hand = GlobalData.player_deck.draw_card(6)
		GlobalData.player_deck.shuffle_deck()
		emit_signal("hand_changed", "player", GlobalData.player_hand)
		server_mulligan_complete = true

	elif step == "client":
		print("Mulligan Client")
		GlobalData.opp_deck.bottom_cards(GlobalData.opp_hand)
		GlobalData.opp_hand = GlobalData.opp_deck.draw_card(6)
		GlobalData.opp_deck.shuffle_deck()
		emit_signal("hand_changed", "opponent", GlobalData.opp_hand)
		client_mulligan_complete = true
		
	elif step == "server_pass":
		server_mulligan_complete = true
	elif step == "client_pass":
		client_mulligan_complete = true
		
	if client_mulligan_complete and server_mulligan_complete:
		set_phase(Phase.START)
		
		
	
				
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
		action_button.text = "NULL"
		if multiplayer.is_server():
			update_battle_log("{0} has chosen to be Lead Player".format([GlobalData.player_id]))
			set_lead_player(true)
			rpc("set_lead_player", false)

		else:
			update_battle_log("{0} has chosen to be Lead Player".format([GlobalData.player_id]))
			set_lead_player(false)
			rpc("set_lead_player", true)
		
	elif action_button.text == "Mulligan":
		action_buttons_hide()
		if multiplayer.is_server():
			update_battle_log("{0} has chosen to mulligan".format([GlobalData.player_id]))
			mulligan("server")
			
		else:
			update_battle_log("{0} has chosen to mulligan".format([GlobalData.player_id]))
			rpc_id(1, "mulligan", "client")
			
	


	
func _cancel_button_pressed():
	if cancel_button.text == "Next Player":
		action_buttons_hide()
		if multiplayer.is_server():
			set_lead_player(false)
			rpc_id(1, "set_lead_player", true)
			update_battle_log("{0} has chosen to be Next Player".format([GlobalData.player_id]))
		else:
			set_lead_player(false)
			rpc_id(1, "set_lead_player", true)
			update_battle_log("{0} has chosen to be Next Player".format([GlobalData.player_id]))
	
	elif cancel_button.text == "Cancel":
		action_buttons_hide()
		if multiplayer.is_server():
			mulligan("server_pass")
		else:
			rpc_id(1, "mulligan", "client_pass")
	
@rpc("any_peer", "reliable")
func set_lead_player(boolean):
	is_lead = boolean
	if boolean:
		$LeadNextLabel.text = "LEAD"
	else:
		$LeadNextLabel.text = "NEXT"
	emit_signal("lead_player_chosen")
	
@rpc("any_peer", "reliable")
func action_buttons_hide():
	action_button.text = "NULL"
	cancel_button.text = "NULL"
	$ActionButtonContainer.hide()
	
@rpc("any_peer", "reliable")
func action_buttons_show():
	$ActionButtonContainer.show()
	

	
@rpc("any_peer")
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
	$PlayerHand.fixed_icon_size = Vector2(50, 75)
	$PlayerHand.set_allow_reselect(true)
	$PlayerHand.set_allow_rmb_select(true)
	$PlayerHand.set_icon_mode(0)
	$PlayerHand.hovered_item.connect(_preview_card)
	
	$OppHand.auto_height = true
	$OppHand.set_max_columns(0)
	$OppHand.fixed_icon_size = Vector2(50, 75)
	$OppHand.set_allow_reselect(true)
	$OppHand.set_allow_rmb_select(true)
	$OppHand.set_icon_mode(0)
	#$OppHand.hovered_item.connect(_preview_card)

func _clear_hbox_container(hbox):
	for child in hbox.get_children():
		child.queue_free()

func _preview_card(item):
	if item != 'none':
		card_preview.set_visible(true)
		card_preview.set_texture(GlobalData.cards[item].image)
		
func _wait(x):
	''' wait X seconds'''
	var timer = get_tree().create_timer(2.0)  # Wait for 2 seconds
	await timer.timeout
	
func configure_local_test():
	var is_server = "--server" in OS.get_cmdline_args()
	var IP_ADDRESS = "127.0.0.1"
	var PORT = 54321
	if is_server:
		GlobalData.player_deck.deckdict = {"SD01-001":1,"SD01-002":1,"SD01-003":1,"SD01-004":4,"SD01-006":1,"SD01-007":2,"SD01-008":3,"SD01-009":1,"SD01-010":2}
		GlobalData.opp_deck.deckdict = {"SD01-001":1,"SD01-002":1,"SD01-003":1,"SD01-004":4,"SD01-006":1,"SD01-007":2,"SD01-008":3,"SD01-009":1,"SD01-010":2}
		GlobalData.player_id = "Server"
		GlobalData.opp_id = "Client"
		var peer = ENetMultiplayerPeer.new()
		peer.create_server(PORT, 2)
		get_tree().get_multiplayer().set_multiplayer_peer(peer)
		print("Setup server", multiplayer.is_server())
	else:
		_wait(1)
		GlobalData.player_id = "Client"
		GlobalData.opp_id = "Server"
		var peer = ENetMultiplayerPeer.new()
		peer.create_client(IP_ADDRESS, PORT)
		get_tree().get_multiplayer().set_multiplayer_peer(peer)
		print("Setup client", multiplayer.is_server())

		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
