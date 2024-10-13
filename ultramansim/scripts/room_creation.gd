extends Control



	


# Define constants for the server and client roles
const SERVER = true
const CLIENT = false

# Define the port for the connection
const PORT = 4242


var role
var room_code = ""

var player_id
var players = []

var own_port
var host_address
var host_port
var players_joined = 0
var num_players
var player_deck = Deck.new()
var all_cards_list 
var available_cards_list
var available_cards = []
@export var local_testing = false

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
@onready var hole_puncher = $HolePunch
@onready var deck_list = $LobbyContainer/ScrollContainer/DeckList

var network_peer = ENetMultiplayerPeer.new()

#Custom Signals

func _ready():
	room_code_container.hide()
	lobby_info_container.hide()
	#Connect Signals
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	copy_connect_button.pressed.connect(_on_copy_connect_button_pressed)
	ready_start_button.pressed.connect(_on_start_button_pressed)
	deck_select_button.item_selected.connect(load_deck_list_json)
	$MainMenuButton.pressed.connect(_on_MainMenuButton_pressed)
	$ConnectTimer.timeout.connect(_on_connect_time_timeout)
	$ConnectTimer.one_shot = true
	
	configure_deck_itemlist()
	populate_deck_options()
	setup_hole_punch()
	player_id = gen_player_id()
	
func configure_deck_itemlist():
	#deck_list = $MainContainer/DeckListContainer/DeckList
	deck_list.auto_height = true
	deck_list.set_max_columns(8)
	deck_list.fixed_icon_size = Vector2(96, 96)
	deck_list.set_allow_reselect(true)
	deck_list.set_allow_rmb_select(true)
	deck_list.set_icon_mode(0)
	
func setup_hole_punch():
	#Ready hole puncher
	hole_puncher.rendevouz_address = '18.222.16.213'
	hole_puncher.rendevouz_port = 3000
	hole_puncher.session_registered.connect(_on_session_registered)
	hole_puncher.hole_punched.connect(_on_HolePunch_hole_punched)
	



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
	ready_start_button.text = 'Waiting...'
	
	host_join_container.hide()
	room_code_container.show()
	lobby_info_container.show()
	

	populate_lobby_list(player_id)

func gen_player_id():
	var full_id = OS.get_unique_id()
	var md5 = HashingContext.new()
	md5.start(HashingContext.HASH_MD5)
	md5.update(full_id.to_utf8_buffer())
	var hashy = md5.finish().hex_encode()
	return "Ultra_" + hashy.substr(0, 8)  # Truncate the hash to 8 characters
	
func _on_join_button_pressed():
	role = CLIENT
	#update lobby UI
	copy_connect_button.text = "Connect"
	room_code_input.placeholder_text = "Room Code Here"
	room_code_input.editable = true
	
	host_join_container.hide()
	room_code_container.show()
	lobby_info_container.show()

	#for local testing
	if local_testing:
		player_id = player_id + "1"
	populate_lobby_list(player_id)
	
func _on_copy_connect_button_pressed():
	var input_code = room_code_input.text
	if hole_puncher.is_host:
		DisplayServer.clipboard_set(input_code)
		print("Code copied to clipboard: " + DisplayServer.clipboard_get())
	else:
		ready_start_button.text = 'Connecting...'
		if input_code == "":
			print("Please enter a room code.")
			return
		print(player_id)
		hole_puncher.start_traversal(input_code, role, player_id)
	
func _on_cancel_button_pressed():
	if hole_puncher.is_host:
		hole_puncher.checkout()
		hole_puncher._exit_tree()
	else:
		hole_puncher.checkout()
		hole_puncher._exit_tree()
	rpc("disconnect_server")
	disconnect_server()
	setup_hole_punch()
	host_join_container.show()
	room_code_container.hide()
	lobby_info_container.hide()
	
@rpc("any_peer", "reliable")
func disconnect_server():
	get_tree().get_multiplayer().set_multiplayer_peer(null)

func _on_start_button_pressed():
	if ready_start_button.text == "Ready":
		lobby_ready(player_id)
		rpc("lobby_ready", player_id)
		deck_select_button.disabled = true
	elif ready_start_button.text == "Start":
		pass

@rpc("any_peer", "reliable")
func lobby_ready(player_id):
	var lobby_list = $LobbyContainer/LobbyInfoContainer/LobbyList
	var all_ready = true
	var ready_color = Color(0.184,0.678,0.039)
	for i in range(lobby_list.get_item_count()):
		if lobby_list.get_item_text(i) == player_id:
			lobby_list.set_item_custom_bg_color(i, ready_color) #Green color when ready
		if lobby_list.get_item_custom_bg_color(i) != ready_color:
			all_ready = false
	if hole_puncher.is_host and all_ready:
		ready_start_button.text = "Start"
	elif all_ready:
		ready_start_button.text = "Waiting to Start"
	
func _on_MainMenuButton_pressed():
	'''Returns to main menu''' 
	_on_cancel_button_pressed() #Make sure we disconnect all the connections
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

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
	print("Status: HolePunch successful, starting server!")
	if hole_puncher.is_host:
		$ConnectTimer.start(1) # Waits for port to beocme unused
		ready_start_button.text = 'Connecting...'
	else:
		$ConnectTimer.start(3) #Waits for Host to Start
		ready_start_button.text = 'Connecting...'
		
func _on_connect_time_timeout():
	print("Connection Timer Timeout")
	
	get_tree().get_multiplayer().peer_connected.connect(_on_peer_connected)
	get_tree().get_multiplayer().peer_disconnected.connect(_on_peer_disconnected)

	if hole_puncher.is_host:
		network_peer.create_server(own_port, 2)
		get_tree().get_multiplayer().set_multiplayer_peer(network_peer)
		print("Host Network Peer Setup Complete")

	else:
		await get_tree().create_timer(3.0).timeout
		network_peer.create_client(host_address, host_port, 0, 0, 0 ,own_port)
		get_tree().get_multiplayer().set_multiplayer_peer(network_peer)
		print("Client Network Peer Setup Complete")


@rpc("any_peer", "reliable")	
func populate_lobby_list(new_player_id):
	var lobby_list = $LobbyContainer/LobbyInfoContainer/LobbyList
	players.append(new_player_id)
	lobby_list.clear()
	for player_name in players:
		lobby_list.add_item(player_name)
		
func _on_peer_connected(_id):
	print("Player Connected")
	ready_start_button.text = 'Ready'
	rpc("populate_lobby_list", player_id)
	#var player_name = "Ultra_" + str(id)
	#players.append(player_name)
	#populate_lobby_list()
	
func _on_peer_disconnected(id):
	print("Player Disconnected")
	var player_name = "Ultra_" + str(id)
	players.erase(player_name)
	#populate_lobby_list()
		
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

func load_deck_list_json(_idx):
	'''Loads decklist from json file in res://decks'''
	print("Loading Decklist")
	var file_name = deck_select_button.text
	var file_path = 'res://decks/' + file_name + '.json'
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var json_result = JSON.parse_string(json_text)
		player_deck.deckdict = json_result
		update_deck_list_ui()
		print("Deck Load Complete")
	else:
		print("ERROR: Failed to open file ", file_path)


func update_deck_list_ui():
	'''Populates UI components based on decklist'''
	deck_list.clear()
	var index = 0
	for card_no in player_deck.deckdict.keys():
		deck_list.add_item(str(player_deck.deckdict[card_no]), GlobalData.cards[card_no].image)
		#deck_list.add_item(str(player_deck.deckdict[card_no]) + "x " + card_no)
		deck_list.set_item_metadata(index, card_no)
		index += 1
	$LobbyContainer.queue_redraw()

func make_option_button_items_non_radio_checkable(option_button: OptionButton) -> void:
	var pm: PopupMenu = option_button.get_popup()
	for i in pm.get_item_count():
		if pm.is_item_radio_checkable(i):
			pm.set_item_as_radio_checkable(i, false)	

func _on_session_registered():
	print("Session Registered")
