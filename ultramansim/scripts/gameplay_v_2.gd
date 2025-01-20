extends Control
'''
This file will connect all the managers together via emitted signals.
It will also manage intialization of the scene from matchmaking/room creation.

UI inputs -> Game State
Game Stat -> Server
Server -> UI Refresh

'''

@export var local_test: bool = false
enum Phase { SETUP, START, DRAW, LEAD_SCENE_SET, SET_CHARACTER, LEVEL_UP, OPEN, EFFECT_ACTIVATION, JUDGEMENT, END}




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Initializing Gameplay Scene")
	print("Testing Inputs")
	print(GlobalData.player_id, GlobalData.opp_id)
	print(GlobalData.player_deck, GlobalData.opp_deck)
	
	if local_test:
		print("Setting up Local Test")
		print("Checking Decks")
		print(GlobalData.player_deck.deckdict)
		print(GlobalData.opp_deck.deckdict)
		configure_local_test()
		#Test Connection
		
	# --- Connect Signals ---
	# Connect choose lead signal to UI/Server
	# Connect game_state_changed UI/Server
	# Start Game
	$GameManager.set_phase(Phase.SETUP)


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



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
