extends Control


func _on_MainMenuButton_pressed():
	'''Returns to main menu''' 
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# ---- CODE from Microsoft COPILOT for pvp connection --- #

# Define constants for the server and client roles
const SERVER = 1
const CLIENT = 2

# Define the port for the connection
const PORT = 4242

# Variables to store the network peer and role
var network_peer : ENetMultiplayerPeer
var role = 0
var room_code = ""

# UI elements
@onready var host_button = $HostButton
@onready var join_button = $JoinButton
@onready var room_code_input = $RoomCodeInput
@onready var room_code_label = $RoomCodeLabel

func _ready():
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	#Connect Signals
	$VBoxContainer/MainMenuButton.pressed.connect(_on_MainMenuButton_pressed)

func _on_host_button_pressed():
	role = SERVER
	network_peer = ENetMultiplayerPeer.new()
	network_peer.create_server(PORT)
	get_tree().multiplayer.multiplayer_peer = network_peer
	room_code = generate_room_code()
	room_code_label.text = "Room Code: %s" % room_code
	print("Server started with room code: %s" % room_code)

func _on_join_button_pressed():
	role = CLIENT
	var input_code = room_code_input.text
	if input_code == "":
		print("Please enter a room code.")
		return
	network_peer = ENetMultiplayerPeer.new()
	network_peer.create_client("127.0.0.1", PORT)  # Replace with actual server IP in a real scenario
	get_tree().multiplayer.multiplayer_peet = network_peer
	print("Client attempting to join room with code: %s" % input_code)

func generate_room_code():
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code = ""
	for i in range(6):
		code += chars[randi() % chars.length()]
	return code

func _process(delta):
	if network_peer:
		if role == SERVER:
			# Server-specific logic
			pass
		elif role == CLIENT:
			# Client-specific logic
			pass

func _on_peer_connected(id):
	print("Peer connected with ID: %d" % id)

func _on_peer_disconnected(id):
	print("Peer disconnected with ID: %d" % id)

func _on_connection_failed():
	print("Connection failed")

# Connect signals for peer connection events
func _init():
	get_tree().multiplayer.connect("peer_connected", self, "_on_peer_connected")
	get_tree().multiplayer.connect("peer_disconnected", self, "_on_peer_disconnected")
	get_tree().multiplayer.connect("connection_failed", self, "_on_connection_failed")

# --- end code for Microsoft Copilot --- #
