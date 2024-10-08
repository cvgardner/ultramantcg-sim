extends Control


func _on_MainMenuButton_pressed():
	'''Returns to main menu''' 
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# ---- CODE from Microsoft COPILOT for pvp connection --- #

# Define constants for the server and client roles
const SERVER = true
const CLIENT = false

# Define the port for the connection
const PORT = 4242

# Variables to store the network peer and role
var network_peer : ENetMultiplayerPeer
var role
var room_code = ""
var hole_puncher
var player_id

var own_port
var host_address
var host_port
var players_joined = 0
var num_players

# UI elements
@onready var host_button = $LobbyContainer/HostJoinContainer/HostButton
@onready var join_button = $LobbyContainer/HostJoinContainer/JoinButton
@onready var copy_connect_button = $LobbyContainer/RoomCodeContainer/CopyConnectButton
@onready var room_code_input = $LobbyContainer/RoomCodeContainer/RoomCode
@onready var cancel_button = $LobbyContainer/LobbyInfoContainer/VBoxContainer/CancelButton
@onready var ready_start_button = $LobbyContainer/LobbyInfoContainer/VBoxContainer/ReadyStartButton
@onready var lobby = $LobbyContainer
@onready var host_join_container = $LobbyContainer/HostJoinContainer
@onready var room_code_container = $LobbyContainer/RoomCodeContainer
@onready var lobby_info_container = $LobbyContainer/LobbyInfoContainer
@onready var deck_select_button = $LobbyContainer/LobbyInfoContainer/VBoxContainer/DeckSelectButton

func _ready():
	room_code_container.hide()
	lobby_info_container.hide()
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	copy_connect_button.pressed.connect(_on_copy_connect_button_pressed)
	#Connect Signals
	$MainMenuButton.pressed.connect(_on_MainMenuButton_pressed)
	
	populate_deck_options()
	setup_hole_punch()
	
func setup_hole_punch():
	#Ready hole puncher
	hole_puncher = preload('res://addons/Holepunch/holepunch_node.gd').new()
	print(hole_puncher)
	add_child(hole_puncher)
	hole_puncher.rendevouz_address = '18.222.16.213'
	hole_puncher.rendevouz_port = 3000
	hole_puncher.session_registered.connect(_on_session_registered)
	hole_puncher.hole_punched.connect(_on_HolePunch_hole_punched)
	
	player_id = OS.get_unique_id()
	print(player_id)


func _on_host_button_pressed():	
	role = SERVER
	room_code = generate_room_code()
	print("Room code: ",room_code)
	#Start Hole Punch
	hole_puncher.start_traversal(room_code, role, player_id)
	
	#update lobby UI
	copy_connect_button.text = "Copy"
	room_code_input.text = room_code
	room_code_input.editable = false
	
	host_join_container.hide()
	room_code_container.show()
	lobby_info_container.show()

func _on_join_button_pressed():
	role = CLIENT
	#update lobby UI
	copy_connect_button.text = "Connect"
	room_code_input.placeholder_text = "Room Code Here"
	room_code_input.editable = true
	
	host_join_container.hide()
	room_code_container.show()
	lobby_info_container.show()

	
func _on_copy_connect_button_pressed():
	var input_code = room_code_input.text
	if hole_puncher.is_host:
		DisplayServer.clipboard_set(input_code)
		print("Code copied to clipboard: " + DisplayServer.clipboard_get())
	else:
		if input_code == "":
			print("Please enter a room code.")
			return
		#for testing purposes
		player_id = player_id + "1"
		print(player_id)
		hole_puncher.start_traversal(input_code, role, player_id)
	
func _on_cancel_button_pressed():
	if hole_puncher.is_host:
		hole_puncher._exit_tree()
	else:
		hole_puncher._exit_tree()
		
	host_join_container.show()
	room_code_container.hide()
	lobby_info_container.hide()
	

func generate_room_code():
	# use a local randomized RNG to keep the global RNG reproducible
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var length = 5
	var result = ''
	for _n in range(length):
		var ascii = rng.randi_range(0, 25) + 65
		result += '%c' % ascii
	return result
	
func _on_HolePunch_hole_punched(my_port, hosts_port, hosts_address):
	print("ready to join: "+str(hosts_address)+":"+str(hosts_port)+" / "+str(my_port))
	own_port = my_port
	host_address = hosts_address
	host_port = hosts_port
	print("Status: Connection successful, starting game!")
	players_joined = 0
	
	if hole_puncher.is_host:
		var peer = ENetMultiplayerPeer.new()
		peer.create_server(own_port, 1)
		get_tree().set_network_peer(peer)
	else:
		var peer = ENetMultiplayerPeer.new()
		peer.create_client(host_address, host_port, 0, 0, 0 ,own_port)
		get_tree().set_network_peer(peer)
		
func populate_deck_options():
	'''Populates the option buttion LoadDeckOptions with decks from res://decks'''
	deck_select_button.clear()
	#Load deckselect info
	deck_select_button.add_item("Select Deck")
	deck_select_button.set_item_disabled(0, true)
	
	var dir = DirAccess.open('res://decks')
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				deck_select_button.add_item(file_name.replace(".json", ""))
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("ERROR: Failed to open directory res://Decks")
	make_option_button_items_non_radio_checkable(deck_select_button)
	deck_select_button.selected = 0

func make_option_button_items_non_radio_checkable(option_button: OptionButton) -> void:
	var pm: PopupMenu = option_button.get_popup()
	for i in pm.get_item_count():
		if pm.is_item_radio_checkable(i):
			pm.set_item_as_radio_checkable(i, false)	

func _on_session_registered():
	print("Session Registered")
	


func _on_peer_connected(id):
	print("Peer connected with ID: %d" % id)

func _on_peer_disconnected(id):
	print("Peer disconnected with ID: %d" % id)

func _on_connection_failed():
	print("Connection failed")

# Connect signals for peer connection events
func _init():
	pass
	#get_tree().multiplayer.connect("peer_connected", self, "_on_peer_connected")
	#get_tree().multiplayer.connect("peer_disconnected", self, "_on_peer_disconnected")
	#get_tree().multiplayer.connect("connection_failed", self, "_on_connection_failed")

# --- end code for Microsoft Copilot --- #
