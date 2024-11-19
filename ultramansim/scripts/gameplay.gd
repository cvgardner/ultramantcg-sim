extends Control

var is_lead : bool # Boolean signifying if the server is lead or not
@onready var action_button = $ActionButtonContainer/ActionButton
@onready var cancel_button = $ActionButtonContainer/CancelButton
@onready var battle_log = $BattleLog
@onready var card_preview = $CardPreview
var battle_log_text = "" # String battle log text
enum Phase { SETUP, START, DRAW, LEAD_SCENE_SET, SET_CHARACTER, LEVEL_UP, OPEN, EFFECT_ACTIVATION, JUDGEMENT, END}
var current_phase 
var current_round = 0
var server_mulligan_complete = false
var client_mulligan_complete = false
var current_scene  # The currently active scene's card_no
var player_field = [] # Player field specified as an array of array of nodes
var player_field_vis = [] # Which cards are face up and face down on the player field
var opp_field = [] # Opponent field specified as an array of array of nodes
var opp_field_vis = [] # Boolean Array representing which card are face up and face down.

# Battle Array is an int array containing the info about who won/lost
# -1: Opponent Win, 0: Tie, 1: Player Win
var battle_array = []

var CardScene = preload("res://scenes/card.tscn")
@export var local_test: bool = false

#Signals
signal phase_changed(new_phase: Phase)
signal lead_player_chosen()
signal hand_changed(player, hand)
signal field_changed(player, field, field_vis)
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
	field_changed.connect(_field_changed_emitted)
	start_mulligan.connect(do_mulligan)
	$SceneButton.button_hovered.connect(_preview_card)
	
	#Hide some UI components
	action_buttons_hide()
	configure_hand_ui()
	
	# Ready UI Components
	$PlayerId.text = GlobalData.player_id
	
	
	
	print("Player deck: ", GlobalData.player_deck, "Opp deck: ", GlobalData.opp_deck)
	print(GlobalData.player_deck, " opponent_deck ", GlobalData.opp_deck.deckdict)
	
	set_phase(Phase.SETUP)
	


@rpc("any_peer","reliable")
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
				var s = "Round {0} Start!".format([current_round])
				update_battle_log(s)
				start_phase()
			Phase.DRAW:
				var s = "Round {0} Draw Phase".format([current_round])
				draw_phase()
			Phase.LEAD_SCENE_SET:
				var s = "Lead Player Setting Scene"
				update_battle_log(s)
				if is_lead:
					set_scene_phase("init")
				else:
					rpc("set_scene_phase", "init")
				pass
			Phase.SET_CHARACTER:
				var s = "SET CHARACTER PHASE"
				update_battle_log(s)
				if is_lead:
					set_character_phase("init", "server")
				else:
					rpc("set_character_phase", "init", "client")
				pass
			Phase.LEVEL_UP:
				var s = "LEVEL UP PHASE"
				update_battle_log(s)
				set_phase(Phase.OPEN)
				pass
			Phase.OPEN:
				var s = "OPEN PHASE"
				update_battle_log(s)
				open_phase()
				rpc("open_phase")
				pass
			Phase.EFFECT_ACTIVATION:
				var s = "EFFECT ACTIVATION PHASE"
				update_battle_log(s)
				set_phase(Phase.JUDGEMENT)
				pass
			Phase.JUDGEMENT:
				var s = "JUDGEMENT PHASE"
				update_battle_log(s)
				judgement_phase()
				# TODO: Add Visual Aid for who won / is winning
				pass
			Phase.END:
				var s = "END PHASE"
				update_battle_log(s)
				end_phase()
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
	
@rpc("any_peer", "reliable")
func set_scene_phase(input):
	if str(input) == "init":
		action_button.text = "Set Scene"
		cancel_button.text = "Cancel"
		action_buttons_show()
	elif is_lead:
		var selected_card_no = GlobalData.player_hand[int(input)]
		set_scene_ui(selected_card_no)
		rpc("set_scene_ui", selected_card_no)
		GlobalData.player_hand.pop_at(input)
		GlobalData.player_hand = GlobalData.player_hand + GlobalData.player_deck.draw_card(1)
		emit_signal("hand_changed", "player", GlobalData.player_hand)
	elif not is_lead:
		var selected_card_no = GlobalData.opp_hand[int(input)]
		set_scene_ui(selected_card_no)
		rpc("set_scene_ui", selected_card_no)
		GlobalData.opp_hand.pop_at(input)
		GlobalData.opp_hand = GlobalData.opp_hand + GlobalData.opp_deck.draw_card(1)
		emit_signal("hand_changed", "opponent", GlobalData.opp_hand)
		
		
	if str(input) != "init":
		action_buttons_hide()
		set_phase(Phase.SET_CHARACTER)
		rpc("set_phase", Phase.SET_CHARACTER)
		
		
@rpc("any_peer", "reliable")
func set_scene_ui(selected_card_no):
	$SceneButton.set_button_icon(GlobalData.cards[selected_card_no].image)
	
@rpc("any_peer", "reliable")
func set_character_phase(input, caller):	
	'''Performs Set Character and visual update actions'''
	
	if str(input) == "init":
		action_button.text = "Set Character"
		cancel_button.text = "Forfeit"
		action_buttons_show()
	
	if str(input) != "init": #Input is the index from hand of the selected card
		if caller == "server":
			var selected_card_no = GlobalData.player_hand[int(input)]
			player_field.append([selected_card_no])
			player_field_vis.append(false)
			GlobalData.player_hand.pop_at(input)
			print(player_field, opp_field)
			emit_signal("hand_changed", "player", GlobalData.player_hand)
			emit_signal("field_changed", "player", player_field, player_field_vis)
			action_buttons_hide()
			rpc("set_character_phase", "init", "client")
			
		elif caller == "client":
			var selected_card_no = GlobalData.opp_hand[int(input)]
			opp_field.append([selected_card_no])
			opp_field_vis.append(false)
			GlobalData.opp_hand.pop_at(input)
			emit_signal("hand_changed", "opponent", GlobalData.opp_hand)
			emit_signal("field_changed", "opponent", opp_field, opp_field_vis)
			action_buttons_hide()
			set_character_phase("init", "server")

	
	if len(player_field) == current_round + 1 and len(player_field) == len(opp_field):
		action_buttons_hide()
		if multiplayer.is_server():
			set_phase(Phase.LEVEL_UP)	
		else:
			rpc("set_phase", Phase.LEVEL_UP)
		return
		
	
@rpc("any_peer", "reliable")
func open_phase():
	$PlayerField.flip_all_face_up()
	$OppField.flip_all_face_up()
	for field in [$PlayerField, $OppField]:
		for wrapper in field.get_children():
			wrapper.get_child(0).card_hovered.connect(_preview_card)
	if multiplayer.is_server():
		set_phase(Phase.JUDGEMENT)

func judgement_phase():
	battle_array = []
	for ind in range(0, player_field.size()):
		var player_power = $PlayerField.get_child(ind).get_child(0).curr_power
		var opp_power = $OppField.get_child(ind).get_child(0).curr_power
		
		print("Player Power: {0} vs Opp Power: {1}".format([player_power, opp_power]))
		if player_power > opp_power:
			battle_array.append(1)
		elif player_power == opp_power:
			battle_array.append(0)
		elif player_power < opp_power:
			battle_array.append(-1)
			
	var judgement = 0
	for result in battle_array:
		judgement += result
	
	# Determine Winner
	if judgement >= 3:
		print("Server Wins!")
	elif judgement <= -3:
		print("Client Wins")
	
	# Determine Lead
	if judgement > 0:
		is_lead = true # player/server is winning
	elif judgement == 0:
		pass #No Changes to Lead
	elif judgement < 0:
		is_lead = false # opponent/client is winning
	set_phase(Phase.END)
		
func end_phase():
	# TODO: End of Turn Effects
	# TODO: Reset Card power
	current_round += 1
	set_phase(Phase.START)
	pass
	
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
	
func _field_changed_emitted(player, field, field_vis):
	'''Process RPC for field updates'''
	if player == "player":
		update_field(player, field, field_vis)
		rpc("update_field", "opponent", field, field_vis)
	if player == "opponent":
		update_field(player, field, field_vis)
		rpc("update_field", "player", field, field_vis)

@rpc("any_peer", "reliable")
func update_hand(player, hand):
	'''Updates the hand UI based on the hand which is an array of card_no and player'''
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
func update_field(player, field, field_vis):
	if player == "player":
		$PlayerField.visualize(field, field_vis)
		for ind in range(0, field_vis.size()):
			$PlayerField.get_child(ind).get_child(0).card_hovered.connect(_preview_card)
	else: #If player is opponent
		$OppField.visualize(field, field_vis)
		for ind in range(0, field_vis.size()):
			if field_vis[ind]:
				$OppField.get_child(ind).get_child(0).card_hovered.connect(_preview_card)


@rpc("any_peer", "reliable")
func mulligan(step):
	'''Changes the mulligan button and implements mulligan based on the step string parameter'''
	if step == 'init':
		print("Mulligan Init")
		# Mulligan
		action_button.text = "Mulligan"
		cancel_button.text = "No Mulligan"
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
	
	elif action_button.text == "Set Scene":
		if len($PlayerHand.get_selected_items()) > 0:

			var selected_item_index = $PlayerHand.get_selected_items()[0]
			var selected_card = GlobalData.cards[$PlayerHand.get_item_metadata(selected_item_index)]
			if multiplayer.is_server() and selected_card.feature == "Scene" and selected_card.level == current_round:
				set_scene_phase(selected_item_index)
			elif selected_card.feature == "Scene" and selected_card.level == current_round:
				rpc("set_scene_phase", selected_item_index)
			
	elif action_button.text == "Set Character":
		if len($PlayerHand.get_selected_items()) > 0:
			var selected_item_index = $PlayerHand.get_selected_items()[0]
			var selected_card = GlobalData.cards[$PlayerHand.get_item_metadata(selected_item_index)]
			if selected_card.feature in ['Ultra Hero', 'Ultra Kaiju']:
				action_buttons_hide()
				if multiplayer.is_server():
					set_character_phase(selected_item_index, "server")
				else:		
					rpc("set_character_phase", selected_item_index, "client")
			
	


	
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
	
	elif cancel_button.text == "No Mulligan":
		action_buttons_hide()
		if multiplayer.is_server():
			mulligan("server_pass")
		else:
			rpc_id(1, "mulligan", "client_pass")
	
	elif cancel_button.text == "Cancel" and Phase.LEAD_SCENE_SET:
		action_buttons_hide()
		if multiplayer.is_server():
			set_phase(Phase.SET_CHARACTER)
		else: 
			rpc("set_phase", Phase.SET_CHARACTER)
	
	elif cancel_button.text == "Forfeit":
		#TODO: Update this with code to lose the match later.
		pass
	
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
	if item == "scene_entered":
		card_preview.set_visible(true)
		card_preview.set_texture($SceneButton.icon)
	elif item != 'none':
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
		GlobalData.player_deck.deckdict = {"SD01-001":1,"SD01-002":1,"SD01-003":1,"SD01-004":4,"SD01-006":1,"SD01-007":2,"SD01-008":3,"SD01-009":1,"SD01-010":2, "SD02-014": 4}
		GlobalData.opp_deck.deckdict = {"SD01-001":1,"SD01-002":1,"SD01-003":1,"SD01-004":4,"SD01-006":1,"SD01-007":2,"SD01-008":3,"SD01-009":1,"SD01-010":2, "SD02-014": 4}
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

func update_stack():
	'''Function to update the Single/Double/Triple values of curr_stack and update the associated icon'''
	#TODO
	pass
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
