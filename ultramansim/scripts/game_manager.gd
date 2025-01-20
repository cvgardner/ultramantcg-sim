extends Control
'''
The Rules and gamestate of the UltramanTCG-Sim will all be managed here.

Should be emitting a signal with gamestate whenever a gamestate change occurs
'''

'''
Example Gamestate

gamestate = {
	"server": {
		"hand": [ Array of card_no string],
		"discard": [ Array of card_no string],
		"field":[
			{
				"stack": [ Array of card_no string],
				"power": int,
				"type": [ Array of string],	
			},
			...
		]
	},
	"client": {
		server info
	}
}

decks = {
	"server": [ Array of card_no],
	"client": [ Array of card_no]
}

'''

var game_state
enum Phase { SETUP, START, DRAW, LEAD_SCENE_SET, SET_CHARACTER, LEVEL_UP, OPEN, EFFECT_ACTIVATION, JUDGEMENT, END}
var current_phase
var current_round
var is_lead # Stores the lead player true = server, false = client

signal game_state_changed(game_state)
signal phase_changed(phase)
signal update_battle_log_signal(text)
signal choose_lead(decider) # decider true if server is lead false if not
signal lead_player_chosen(lead) # lead is true if server false if client


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_state = {
		"server": {
			"hand": [],
			"discard": [],
			"field":[
				#{
					#"stack": [],
					#"power": 0,
					#"type": [],	
				#},
			]
		},
		"client": {
			"hand": [],
			"discard": [],
			"field":[
				#{
					#"stack": [],
					#"power": 0,
					#"type": [],	
				#},
			]
		},
	}
	
	# --- Connect Signals ---
	phase_changed.connect(_on_phase_changed)
	pass # Replace with function body.

func set_phase(phase: Phase):
	current_phase = phase
	emit_signal("phase_changed", current_phase)
	
func _on_phase_changed(new_phase: Phase):
		match new_phase:
			Phase.SETUP:
				game_setup()
				pass
			Phase.START:
				pass
				#start_phase()
			Phase.DRAW:
				pass
				#draw_phase()
			Phase.LEAD_SCENE_SET:
				pass
				#if is_lead:
					#set_scene_phase("init", '')
				#else:
					#rpc("set_scene_phase", "init", '')
				#pass
			Phase.SET_CHARACTER:
				pass
				#if is_lead:
					#set_character_phase("init", "server")
				#else:
					#rpc("set_character_phase", "init", "client")
				#pass
			Phase.LEVEL_UP:
				pass
				#level_up_phase("init")
				pass
			Phase.OPEN:
				#open_phase()
				pass
			Phase.EFFECT_ACTIVATION:
				#effect_activation_phase()
				pass
			Phase.JUDGEMENT:
				#judgement_phase()
				# TODO: Add Visual Aid for who won / is winning
				pass
			Phase.END:
				#end_phase()
				pass

# --- Phase Functions ---

func game_setup():	
	current_phase = Phase.SETUP
	_wait(5)
	
	#Ready The Decks
	for deck in [GlobalData.player_deck, GlobalData.opp_deck]:
		deck.create_deck()
		deck.shuffle_deck() #This would desync the player and server. I think this is where I start having server pass all info to the client?
	
	# Choose Deciding Player
	randomize()
	var decider = randi() % 2 == 0
	
	if get_parent().local_test:
		decider = true
	
	# Deciding Player chooses whether to be lead or next
	choose_lead.emit(decider)
	
	# wait for lead_player_chosen signal
	await lead_player_chosen
	
	print("Lead Player Chosen signal received")

	# Draw Starting Hands
	print("Drawing Hands")
	game_state['server']['hand'] = GlobalData.player_deck.draw_card(6)
	game_state['client']['hand'] = GlobalData.opp_deck.draw_card(6)
	
	#Update hand UI
	game_state_changed.emit(game_state)

	emit_signal("start_mulligan")

# --- Utilities ---
func set_lead_player(boolean):
	is_lead = boolean
	if boolean:
		$LeadNextLabel.text = "LEAD"
	else:
		$LeadNextLabel.text = "NEXT"
	emit_signal("lead_player_chosen")
	
func update_battle_log(text, server_only = true):
	update_battle_log_signal.emit(text)

func _wait(x):
	''' wait X seconds'''
	var timer = get_tree().create_timer(2.0)  # Wait for 2 seconds
	await timer.timeout
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
