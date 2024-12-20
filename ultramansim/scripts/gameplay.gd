extends Control

var is_lead : bool # Boolean signifying if the server is lead or not
@onready var action_button = $ActionButtonContainer/ActionButton
@onready var cancel_button = $ActionButtonContainer/CancelButton
@onready var battle_log = $BattleLog
@onready var card_preview = $CardPreview
@onready var load_deck_options = $GameEndNode/LoadDeckOptions
@onready var action_list = $ActionControl/ActionQueue/ActionList
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
var rematch_requests = [] # Used to count rematch requests
var level_up_complete = [] # Keeps track of which players have completed the level up phase
var can_level = [] # Array of indexes which can level
var player_action_queue = []
var opp_action_queue = []
var player_field_mod = []
var opp_field_mod = []
var open_actions_completed = [] #holds info about which players have finished open phase activation
var activate_actions_completed = []

var player_game_data = {
	"field": player_field,
	"field_vis": player_field_vis,
	"field_mod": player_field_mod,
	"action_queue": player_action_queue,
	"hand": GlobalData.player_hand,
	"deck": GlobalData.player_deck.deck,
	"scene_owner": ''
}


var opp_game_data = {
	"field": opp_field,
	"field_vis": opp_field_vis,
	"field_mod": opp_field_mod,
	"action_queue": opp_action_queue,
	"hand": GlobalData.opp_hand,
	"deck": GlobalData.opp_deck.deck,
	"scene_owner": ''
}

var stack_map = {
	1: "SINGLE",
	2: "DOUBLE",
	3: "TRIPLE"
}

# Battle Array is an int array containing the info about who won/lost
# -1: Opponent Win, 0: Tie, 1: Player Win
var battle_array = []

var CardScene = preload("res://scenes/card.tscn")
@export var local_test: bool = false

#Signals
signal phase_changed(new_phase: Phase)
signal lead_player_chosen()
signal hand_changed(player, hand)
signal field_changed(player, field, field_vis, field_mod)
signal start_mulligan
signal rematch_requested()
signal open_phase_ability(player_game_data, opp_game_data)
signal activate_phase_ability(player_game_data, opp_game_data)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if local_test:
		print("Setting up Local Test")
		print("Checking Decks")
		print(GlobalData.player_deck.deckdict)
		print(GlobalData.opp_deck.deckdict)
		configure_local_test()
		#Test Connection
	
	GlobalData.player_game_data = player_game_data
	GlobalData.opp_game_data = opp_game_data
		
	# Connecting Signals
	action_button.pressed.connect(_action_button_pressed)
	cancel_button.pressed.connect(_cancel_button_pressed)
	phase_changed.connect(_on_phase_changed)
	hand_changed.connect(_hand_changed_emitted)
	field_changed.connect(_field_changed_emitted)
	start_mulligan.connect(do_mulligan)
	$SceneButton.button_hovered.connect(_preview_card)
	
	$MainMenuButton.pressed.connect(_on_BackButton_pressed)
	$GameEndNode/MainMenuButton2.pressed.connect(_on_BackButton_pressed)
	$GameEndNode/RematchButton.pressed.connect(_on_rematch_button_pressed)
	$PlayerField.item_clicked.connect(highlight_clicked)
	$ActionControl/ActionQueue/ActionActivateButton.pressed.connect(activate_effect)
	$ActionControl.effect_finished.connect(effect_finished)

	
	#Hide some UI components
	action_buttons_hide()
	configure_hand_ui()
	$GameEndNode.hide()
	
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
					set_scene_phase("init", '')
				else:
					rpc("set_scene_phase", "init", '')
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
				level_up_phase("init")
				pass
			Phase.OPEN:
				var s = "OPEN PHASE"
				update_battle_log(s)
				open_phase()
				pass
			Phase.EFFECT_ACTIVATION:
				var s = "EFFECT ACTIVATION PHASE"
				update_battle_log(s)
				effect_activation_phase()
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
	GlobalData.player_hand = GlobalData.player_hand + GlobalData.player_deck.draw_card(1)
	GlobalData.opp_hand = GlobalData.opp_hand + GlobalData.opp_deck.draw_card(1)

	#Update hand UI
	emit_signal("hand_changed", "player", GlobalData.player_hand)
	emit_signal("hand_changed", "opponent", GlobalData.opp_hand)
	
	set_phase(Phase.LEAD_SCENE_SET)
	
@rpc("any_peer", "reliable")
func set_scene_phase(input, owner):
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
		player_game_data['scene_owner'] = selected_card_no
		opp_game_data['scene_owner'] = ''
		set_scene_phase_end()

	elif not is_lead:
		var selected_card_no = GlobalData.opp_hand[int(input)]
		set_scene_ui(selected_card_no)
		rpc("set_scene_ui", selected_card_no)
		GlobalData.opp_hand.pop_at(input)
		opp_game_data['scene_owner'] = selected_card_no
		player_game_data['scene_owner'] = ''
		GlobalData.opp_hand = GlobalData.opp_hand + GlobalData.opp_deck.draw_card(1)
		emit_signal("hand_changed", "opponent", GlobalData.opp_hand)
		set_scene_phase_end()
	

func set_scene_phase_end():
	action_buttons_hide()
	#if is_lead:
	set_phase(Phase.SET_CHARACTER)
	#else:
		#rpc("set_phase", Phase.SET_CHARACTER)
		
@rpc("any_peer", "reliable")
func set_scene_ui(selected_card_no):
	$SceneButton.set_button_icon(GlobalData.cards[selected_card_no].image)
	
@rpc("any_peer", "reliable")
func set_character_phase(input, caller):	
	'''Performs Set Character and visual update actions'''
	print("Set Char Phase ", multiplayer.is_server())

	if str(input) == "init":
		action_button.text = "Set Character"
		cancel_button.text = "Forfeit"
		action_buttons_show()
		
	#if len(player_field) == current_round + 1 and len(player_field) == len(opp_field):
		#action_buttons_hide()
		#if multiplayer.is_server():
			#set_phase(Phase.LEVEL_UP)	
		#else:
			#rpc("set_phase", Phase.LEVEL_UP)
		#return
	
	if str(input) != "init": #Input is the index from hand of the selected card
		if caller == "server":
			var selected_card_no = GlobalData.player_hand[int(input)]
			player_field.append([selected_card_no])
			player_field_vis.append(false)
			GlobalData.player_game_data['field_mod'].append({"power": {}, "bp_mod": {}})
			GlobalData.player_hand.pop_at(input)
			emit_signal("hand_changed", "player", GlobalData.player_hand)
			emit_signal("field_changed", "player", player_field, player_field_vis, player_field_mod)
			action_buttons_hide()
			if len(player_field) == current_round + 1 and len(player_field) == len(opp_field):
				set_phase(Phase.LEVEL_UP)
			else:
				rpc("set_character_phase", "init", "client")
			
		elif caller == "client":
			var selected_card_no = GlobalData.opp_hand[int(input)]
			opp_field.append([selected_card_no])
			opp_field_vis.append(false)
			GlobalData.opp_game_data['field_mod'].append({"power": {}, "bp_mod": {}})
			GlobalData.opp_hand.pop_at(input)
			emit_signal("hand_changed", "opponent", GlobalData.opp_hand)
			emit_signal("field_changed", "opponent", opp_field, opp_field_vis, opp_field_mod)
			action_buttons_hide()
			if len(player_field) == current_round + 1 and len(player_field) == len(opp_field):
				set_phase(Phase.LEVEL_UP)
			else:
				set_character_phase("init", "server")

@rpc("any_peer", "reliable")
func level_up_phase(input):
	print(multiplayer.is_server(), " Level up complete ", level_up_complete)
	if level_up_complete.size() >= 2:
		level_up_complete = []
		highlight_none() #Undo Highlights from level up selection
		$ActionButtonContainer/ActionButton.show() #fix only having one button bug
		action_buttons_hide()
		set_phase(Phase.OPEN)
		return
	
	
	if str(input) == "init":
		level_up_complete = []
		if is_lead:
			level_up_phase("server")
		else:
			level_up_phase("client")
			
	elif str(input) == "client":
		level_up_complete.append("client")
		rpc("level_up_phase_rpc")
		
				
		
	elif str(input) == "server":
		level_up_complete.append("server")
		level_up_phase_rpc()
		

@rpc("any_peer", "reliable")
func level_up_phase_rpc():
	if multiplayer.is_server():
		pass
	else:
		current_phase = Phase.LEVEL_UP
	#If its level_up setup then populate can_level
	if can_level == []:
		for node in $PlayerField.get_children():
				can_level.append(true)	
		
	# Disable All Cards in hand
	for i in range($PlayerHand.get_item_count()):
		$PlayerHand.set_item_disabled(i, true)
	
	# Enable all cards usable for level up
	#for node in $PlayerField.get_children():
		#for i in range($PlayerHand.get_item_count()):
			#var card = node.get_child(0)
			#var hand_card = GlobalData.cards[$PlayerHand.get_item_metadata(i)]
			#if hand_card.level == card.level + 1 and hand_card.character == card.character and card.face_up:
				#$PlayerHand.set_item_disabled(i, false)
				
	# Enable all cards usable for level up
	for cl in range(can_level.size()):
		for i in range($PlayerHand.get_item_count()):
			var card = $PlayerField.get_child(cl).get_child(0)
			var hand_card = GlobalData.cards[$PlayerHand.get_item_metadata(i)]
			if hand_card.level == card.level + 1 and hand_card.character == card.character and can_level[cl]:
				$PlayerHand.set_item_disabled(i, false)
				
	cancel_button.text = "No Level Ups"
	action_buttons_show()
	$ActionButtonContainer/ActionButton.hide()

func level_phase_highlight(selected):
	#de highlight all
	highlight_none()
	#Highligh recommented
	if current_phase == Phase.LEVEL_UP:
		for i in range(can_level.size()):
		#for node in $PlayerField.get_children():
			var card = $PlayerField.get_child(i).get_child(0)
			var selected_card = GlobalData.cards[$PlayerHand.get_item_metadata(selected)]
			if card.level == selected_card.level - 1 && card.character == selected_card.character and can_level[i]:
				card.show_highlight()
		
# --- Effect Activation UI Stuff --- #


func activate_effect():
	'''This function sends the index of the selected card from ActionQueue to activate
	inputs: caller - determines server/client who is submitting the effect
	connected to $ActionControl.ActionQueue.ActionActivateButton pressed
	'''
	if multiplayer.is_server():
		activate_effect_rpc('server')
	else:
		rpc("activate_effect_rpc", "client")

	
@rpc("any_peer", "reliable")
func activate_effect_rpc(caller):
	if len($ActionControl/ActionQueue/ActionList.get_selected_items()) > 0:
		$ActionControl.activate_effect($ActionControl/ActionQueue/ActionList.get_selected_items()[0], caller)
	
func effect_activated():
	''' Unsure if I need this function but it might help with handling inputs'''
	pass
	
func effect_finished():
	''' Processes UI updates after an effect as finished resolving
	connected to signal $ActionConrol.effect_finished'''
	
	# Update Hand
	emit_signal("hand_changed", "player", GlobalData.player_hand)
	emit_signal("hand_changed", "opponent", GlobalData.opp_hand)
	# Update Field
	update_field('player', player_field, player_field_vis, GlobalData.player_game_data['field_mod'])
	rpc("update_field", "opponent", player_field, player_field_vis, GlobalData.player_game_data['field_mod'])
	update_field('opponent', opp_field, opp_field_vis, GlobalData.opp_game_data['field_mod'])
	rpc("update_field", "player", opp_field, opp_field_vis, GlobalData.opp_game_data['field_mod'])
	# Update ActionControls
	action_queue_refresh()

@rpc("any_peer", "reliable")
func open_phase():
	GlobalData.player_game_data['action_queue'] = []
	GlobalData.opp_game_data['action_queue'] = []
	$ActionControl.get_enters_play_effects()
	print("Player Action Queue: ", GlobalData.player_game_data['action_queue'])
	print("Opp Action Queue: ", GlobalData.opp_game_data['action_queue'])
	
	# TODO update everything with game_data instead of a list of the elements
	for game_data in [GlobalData.player_game_data, GlobalData.opp_game_data]:
	# [[player_field_vis, player_action_queue], [opp_field_vis, opp_action_queue]]:
		for i in range(0,player_field_vis.size()):
			#print(GlobalData.cards[game_data['field'][i][0]].abilities)
			# If card is being turned face up add its first ability is trigger = 'ENTER_PLAY' and stack_condition is met
			
			#if (game_data["field_vis"][i] == false and GlobalData.cards[game_data['field'][i][0]]['abilities'].size() > 0):
				#if (GlobalData.cards[game_data['field'][i][0]]['abilities'][0].get("trigger") == 'ENTER_PLAY'
					#and stack_map[game_data['field'][i].size()] in GlobalData.cards[game_data['field'][i][0]]['abilities'][0]["stack_condition"]
				#): # TODO update with multi abilities when they are released
					#game_data['action_queue'].append(game_data['field'][i][0]) 
			game_data['field_vis'][i] = true # Sets vis to true
			
	open_phase_rpc()
	rpc("open_phase_rpc")
	
	# TODO: Handle Enters Effects
	# Send all the data to the actionqueue object to help
	if is_lead:
		open_phase_action_ui('init', card_no_extract_action_queue(GlobalData.player_game_data['action_queue']))
	else:
		rpc("open_phase_action_ui", 'init', card_no_extract_action_queue(GlobalData.opp_game_data['action_queue']))
		
@rpc("any_peer", "reliable")
func open_phase_rpc():
	#Undisable all cards in hand from after level ups
	for i in range($PlayerHand.get_item_count()):
		$PlayerHand.set_item_disabled(i, false)
	
	$PlayerField.flip_all_face_up()
	$OppField.flip_all_face_up()
	for field in [$PlayerField, $OppField]:
		for wrapper in field.get_children():
			wrapper.get_child(0).card_hovered.connect(_preview_card)
	
@rpc('any_peer', 'reliable')
func open_phase_action_ui(input, action_queue):
	"handles UI for open phase ability activation and closure"
	# Handle no action queue + init
	if input == 'init' and action_queue.size() == 0:
		if multiplayer.is_server():
			open_phase_action_ui('finished', [])
			open_phase_action_end('server')
		else:
			open_phase_action_ui("finished", [])
			rpc("open_phase_action_end", "client")
		return
	
	if input == 'init':
		if multiplayer.is_server() == false:
			current_phase = Phase.OPEN
		cancel_button.text = "No Effects"
		action_buttons_show()
		
		$ActionButtonContainer/ActionButton.hide()
		
		# TODO pass action_queue to the $ActionControl
		print("Is Server?: ", multiplayer.is_server(), action_queue)
		action_queue_refresh_rpc(action_queue)
		$ActionControl/ActionQueue.show()
		
	elif input == 'finished':
		$ActionButtonContainer/ActionButton.show()
		action_buttons_hide()
		$ActionControl/ActionQueue.hide()
		

@rpc("any_peer",'reliable')	
func open_phase_action_end(input):
	'''Server based func to count which players have finish completing actions'''
	open_actions_completed.append(input)
	print("end actions", opp_action_queue)
	if open_actions_completed.size() >= 2: #If all players are done reset open_actions_completed and change phase
		open_actions_completed = []
		set_phase(Phase.EFFECT_ACTIVATION)
	elif input == 'server':
		rpc("open_phase_action_ui", 'init', card_no_extract_action_queue(GlobalData.opp_game_data['action_queue']))
	elif input == 'client':
		open_phase_action_ui('init', card_no_extract_action_queue(GlobalData.player_game_data['action_queue']))
		
func effect_activation_phase():
	# TODO: Handle Activate Effects
	# Clear Action Queues
	GlobalData.player_game_data['action_queue'] = []
	GlobalData.opp_game_data['action_queue'] = []
	
	# Put all field cards into action_queue that have trigger: ACTIVATE
	$ActionControl.get_activate_effects()
	print("Player Action Queue: ", GlobalData.player_game_data['action_queue'])
	print("Opp Action Queue: ", GlobalData.opp_game_data['action_queue'])
	
	
	if is_lead:
		effect_activation_phase_ui('init', card_no_extract_action_queue(GlobalData.player_game_data['action_queue']))
	else:
		rpc("effect_activation_phase_ui", 'init', card_no_extract_action_queue(GlobalData.opp_game_data['action_queue']))

func action_queue_refresh():
	''' Refresh both players action queue. This is fine because the non-active player's ui is hidden'''
	print("Player Action Queue: ", GlobalData.player_game_data['action_queue'])
	print("Opp Action Queue: ", GlobalData.opp_game_data['action_queue'])
	# Don't need to determine player to refresh action queue because the non-active player is hidden
	#Can't pass action_queue through because it contains card nodes. So we parse it for list of card_no
	action_queue_refresh_rpc(card_no_extract_action_queue(GlobalData.player_game_data['action_queue']))
	rpc("action_queue_refresh_rpc", card_no_extract_action_queue(GlobalData.opp_game_data['action_queue']))
	
func card_no_extract_action_queue(action_queue):
	var parsed_queue = []
	for item in action_queue:
		parsed_queue.append(item['card'].card_no)
	return parsed_queue
	
@rpc("any_peer", "reliable")
func action_queue_refresh_rpc(action_queue):
	action_list.clear()
	var index = 0
	for card_no in action_queue:
		#var card_no = action.get('card').card_no
		print("Action List: ", card_no)
		action_list.add_item("", GlobalData.cards[card_no].image)
		action_list.set_item_metadata(index, card_no)
		index += 1
	action_list.queue_redraw()
		
@rpc('any_peer', 'reliable')
func effect_activation_phase_ui(input, action_queue):
	"handles UI for open phase ability activation and closure"
	# Handle no action queue + init
	if input == 'init' and action_queue.size() == 0:
		if multiplayer.is_server():
			effect_activation_phase_ui('finished', [])
			effect_activation_phase_end('server')
		else:
			effect_activation_phase_ui("finished", [])
			rpc("effect_activation_phase_end", "client")
		return
	
	if input == 'init':
		if multiplayer.is_server() == false:
			current_phase = Phase.EFFECT_ACTIVATION
		cancel_button.text = "No Effects"
		action_buttons_show()
		$ActionButtonContainer/ActionButton.hide()
		
		# TODO pass action_queue to the $ActionControl
		print(action_queue)
		action_queue_refresh_rpc(action_queue)
		$ActionControl/ActionQueue.show()
		
	elif input == 'finished':
		$ActionButtonContainer/ActionButton.show()
		action_buttons_hide()
		$ActionControl/ActionQueue.hide()
		
@rpc("any_peer", 'reliable')
func effect_activation_phase_end(input):
	'''Will get connected to signals from ActionQueue/CancelButton for when the effect activation phase is complete'''
	activate_actions_completed.append(input)
	
	if activate_actions_completed.size() >= 2: #If all players are done reset open_actions_completed and change phase
		activate_actions_completed = []
		set_phase(Phase.JUDGEMENT)
	elif input == 'server':
		rpc("effect_activation_phase_ui", 'init', card_no_extract_action_queue(GlobalData.opp_game_data['action_queue']))
	elif input == 'client':
		effect_activation_phase_ui('init', card_no_extract_action_queue(GlobalData.player_game_data['action_queue']))
		


func judgement_phase():
	var player_wins = 0
	var opp_wins = 0
	for ind in range(0, player_field.size()):
		var player_power = $PlayerField.get_child(ind).get_child(0).curr_power
		var opp_power = $OppField.get_child(ind).get_child(0).curr_power
		
		print("Player Power: {0} vs Opp Power: {1}".format([player_power, opp_power]))
		if player_power > opp_power:
			player_wins += 1
		elif player_power == opp_power:
			pass
		elif player_power < opp_power:
			opp_wins += 1
	
	print("Judgement ", player_wins, " ", opp_wins)
	
	# Determine Winner
	if player_wins >= 3:
		print("Server Wins!")
		game_end(true)
		rpc("game_end", false)
	elif opp_wins >= 3:
		print("Client Wins")
		game_end(false)
		rpc("game_end", true)
	
	# Determine Lead
	if player_wins > opp_wins:
		is_lead = true # player/server is winning
	elif player_wins < opp_wins:
		is_lead = false # opponent/client is winning
	else:
		pass #No Changes to Lead
	
	set_phase(Phase.END)
		
func end_phase():
	# TODO: End of Turn Effects
	# TODO: Reset Card power
	increase_round()
	rpc("increase_round")
	set_phase(Phase.START)
	pass

@rpc("any_peer", 'reliable')
func increase_round():
	current_round += 1
	
@rpc("any_peer", "reliable")
func game_end(is_winner):
	'''Takes a boolean is_winner and runs end of game procedure'''
	if is_winner:
		$GameEndNode/GameEndImage.texture = ResourceLoader.load("res://images/assets/youwin.png")
	else:
		$GameEndNode/GameEndImage.texture = ResourceLoader.load("res://images/assets/youlose.png")
	
	$GameEndNode.show()
	action_buttons_hide()
	populate_load_deck_options()
	
	
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
	
func _field_changed_emitted(player, field, field_vis, field_mod):
	'''Process RPC for field updates'''
	# Process CONT effects before sending out updates
	$ActionControl.update_cont_effects()
	print("Global Player Data", GlobalData.player_game_data)
	print("Global Opp Data", GlobalData.opp_game_data)
	
	#Always update All Fields
	update_field('player', player_field, player_field_vis, GlobalData.player_game_data['field_mod'])
	rpc("update_field", "opponent", player_field, player_field_vis, GlobalData.player_game_data['field_mod'])
	update_field('opponent', opp_field, opp_field_vis, GlobalData.opp_game_data['field_mod'])
	rpc("update_field", "player", opp_field, opp_field_vis, GlobalData.opp_game_data['field_mod'])
	
	#if player == "player":
		#update_field(player, field, field_vis, GlobalData.player_game_data['field_mod'])
		#rpc("update_field", "opponent", field, field_vis, GlobalData.player_game_data['field_mod'])
	#if player == "opponent":
		#update_field(player, field, field_vis, GlobalData.opp_game_data['field_mod'])
		#rpc("update_field", "player", field, field_vis, GlobalData.opp_game_data['field_mod'])

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
func update_field(player, field, field_vis, field_mod):
	if field.size() < 1:
		
		return
	print(field, field_vis, field_mod)
	if player == "player":
		$PlayerField.visualize(field, field_vis, field_mod)
		for ind in range(0, field_vis.size()):
			var card = $PlayerField.get_child(ind).get_child(0)
			card.card_hovered.connect(_preview_card)

			
	else: #If player is opponent
		$OppField.visualize(field, field_vis, field_mod)
		for ind in range(0, field_vis.size()):
			if field_vis[ind]:
				var card = $OppField.get_child(ind).get_child(0)
				card.card_hovered.connect(_preview_card)



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
			print("Current Round: ", current_round)
			var selected_item_index = $PlayerHand.get_selected_items()[0]
			var selected_card = GlobalData.cards[$PlayerHand.get_item_metadata(selected_item_index)]
			if multiplayer.is_server() and selected_card.feature == "Scene" and selected_card.level <= current_round:
				set_scene_phase(selected_item_index, 'Server')
			elif selected_card.feature == "Scene" and selected_card.level <= current_round:
				rpc("set_scene_phase", selected_item_index, 'Client')
			
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
		game_end(false)
		rpc("game_end", true)
		
	elif cancel_button.text == "No Level Ups" and current_phase == Phase.LEVEL_UP:
		highlight_none()
		action_buttons_hide()
		can_level = []
		if multiplayer.is_server():
			level_up_phase("client")
		else:
			$ActionButtonContainer/ActionButton.show() #fix only having one button bug
			current_phase = Phase.OPEN
			rpc("level_up_phase", "server")
			
	elif cancel_button.text == 'No Effects' and current_phase == Phase.OPEN:
		if multiplayer.is_server():
			open_phase_action_ui('finished', [])
			open_phase_action_end('server')
		else:
			open_phase_action_ui("finished", [])
			rpc("open_phase_action_end", "client")
			
	elif cancel_button.text == 'No Effects' and current_phase == Phase.EFFECT_ACTIVATION:
		if multiplayer.is_server():
			effect_activation_phase_ui('finished', [])
			effect_activation_phase_end('server')
		else:
			effect_activation_phase_ui("finished", [])
			rpc("effect_activation_phase_end", "client")
	
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
	$PlayerHand.item_selected.connect(level_phase_highlight)
	
	$OppHand.auto_height = true
	$OppHand.set_max_columns(0)
	$OppHand.fixed_icon_size = Vector2(50, 75)
	$OppHand.set_allow_reselect(true)
	$OppHand.set_allow_rmb_select(true)
	$OppHand.set_icon_mode(0)
	
	action_list.auto_height = true
	action_list.set_max_columns(0)
	action_list.fixed_icon_size = Vector2(50, 75)
	action_list.set_allow_reselect(true)
	action_list.set_allow_rmb_select(true)
	action_list.set_icon_mode(0)
	action_list.hovered_item.connect(_preview_card)

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
		# Test Activate
		GlobalData.player_deck.deckdict = {"SD01-002":4,"SD01-004":4,"SD01-005":4,"SD01-014":4,"SD02-014":4}
		GlobalData.opp_deck.deckdict = {"SD01-002":4,"SD01-004":4,"SD01-005":4,"SD01-014":4,"SD02-014":4}
		# Test Auto 
		#GlobalData.player_deck.deckdict = {"SD01-003":4,"SD01-011":4,"SD01-013":4,"SD01-014":4,"SD02-013":4,"SD02-014":4}
		#GlobalData.opp_deck.deckdict = {"SD01-003":4,"SD01-011":4,"SD01-013":4,"SD01-014":4,"SD02-013":4,"SD02-014":4}
		
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
		
func populate_load_deck_options():
	'''Populates the option buttion LoadDeckOptions with decks from res://decks'''
	load_deck_options.clear()
	load_deck_options.add_item("Change Deck")
	var dir = DirAccess.open('res://decks')
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				load_deck_options.add_item(file_name.replace(".json", ""))
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("ERROR: Failed to open directory res://Decks")
	make_option_button_items_non_radio_checkable(load_deck_options)
	
func make_option_button_items_non_radio_checkable(option_button: OptionButton) -> void:
	var pm: PopupMenu = option_button.get_popup()
	for i in pm.get_item_count():
		if pm.is_item_radio_checkable(i):
			pm.set_item_as_radio_checkable(i, false)
			
func _on_BackButton_pressed():
	''' Return to Main Menu Screen'''
	disconnect_server()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	
	
@rpc("any_peer", "reliable")
func disconnect_server():
	get_tree().get_multiplayer().set_multiplayer_peer(null)
	
func _on_rematch_button_pressed():
	'''Sets the new deck from deckload options if selected'''
	if multiplayer.is_server():
		load_deck_list_json()
		request_rematch(GlobalData.player_id)
	else:
		load_deck_list_json()
		print("Rematch Client Deck ", GlobalData.player_deck.deckdict)
		rpc("send_opp_deck", GlobalData.player_deck.deckdict)
		rpc("request_rematch", GlobalData.player_id)

@rpc("any_peer", "reliable")
func send_opp_deck(deckdict):
	GlobalData.opp_deck.deckdict = deckdict

@rpc("any_peer", 'reliable')
func request_rematch(player_id):
	if player_id not in rematch_requests:
		rematch_requests.append(player_id)

	if rematch_requests.size() >= 2:
		rpc("start_rematch")
		start_rematch()
		

@rpc("any_peer", 'reliable')	
func start_rematch():
	var current_scene = get_tree().current_scene 
	get_tree().reload_current_scene()

@rpc("any_peer", "reliable")
func load_deck_list_json():
	'''Loads decklist from json file in res://decks'''
	var file_name = $GameEndNode/LoadDeckOptions.text
	if file_name == "Change Deck":
		return
	var file_path = 'res://decks/' + file_name + '.json'
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var json_result = JSON.parse_string(json_text)
		GlobalData.player_deck.deckdict = json_result


	else:
		print("ERROR: Failed to open file ", file_path)

func highlight_all():
	for node in $PlayerField.get_children():
			var card = node.get_child(0)
			card.show_highlight()
				
func highlight_none():
	for node in $PlayerField.get_children():
			var card = node.get_child(0)
			card.hide_highlight()
			
func highlight_clicked(clicked_index):
	'''Processes level up logic when clicking a card that satisfies the level up'''
	if current_phase != Phase.LEVEL_UP: #Skip code if its not the level up phase
		return
	if $PlayerHand.get_selected_items().size() > 0:
		var selected_ind = $PlayerHand.get_selected_items()[0]
		var selected_card = GlobalData.cards[$PlayerHand.get_item_metadata(selected_ind)]
		print("Clicked Index: ", clicked_index)
		var clicked_wrapper = $PlayerField.get_child(clicked_index)
		var clicked_card = clicked_wrapper.get_child(0)
		
		if selected_card.character == clicked_card.character && selected_card.level - 1 == clicked_card.level && can_level[clicked_index]:
			can_level[clicked_index] = false
			if multiplayer.is_server():
				highlight_clicked_rpc('server', selected_ind, selected_card.card_no, clicked_index, clicked_card)
			else:
				rpc("highlight_clicked_rpc", 'client', selected_ind, selected_card.card_no, clicked_index, clicked_card)

		
@rpc("any_peer", "reliable")
func highlight_clicked_rpc(caller, selected_ind, selected_card, clicked_index, clicked_card):
	'''Does level up logic based on the caller'''
	if caller == 'server':
		#Get the selected index from playerfield to update player_field list
		player_field[clicked_index] = [selected_card] + player_field[clicked_index]
		player_field_vis[clicked_index] = false
		#Remove Card from hand
		GlobalData.player_hand.pop_at(selected_ind)
		
		emit_signal("hand_changed", "player", GlobalData.player_hand)
		emit_signal("field_changed", "player", player_field, player_field_vis, player_field_mod)
		level_up_phase_rpc()
		
	elif caller == 'client':
		#Get the selected index from playerfield to update player_field list
		opp_field[clicked_index] = [selected_card] + opp_field[clicked_index]
		opp_field_vis[clicked_index] = false
		#Remove Card from hand
		GlobalData.opp_hand.pop_at(selected_ind)
		
		emit_signal("hand_changed", "opponent", GlobalData.opp_hand)
		emit_signal("field_changed", "opponent", opp_field, opp_field_vis, opp_field_mod)
		rpc("level_up_phase_rpc")
	
	
	
			
func update_stack():
	'''Function to update the Single/Double/Triple values of curr_stack and update the associated icon'''
	#TODO
	pass
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
