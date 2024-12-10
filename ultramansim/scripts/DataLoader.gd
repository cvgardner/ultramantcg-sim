extends Node

var cards = {}
var CardScene = preload("res://scenes/card.tscn")
var player_deck = Deck.new()
var opp_deck = Deck.new()
var player_id : String
var opp_id : String
var player_hand = []
var opp_hand = []
var player_discard = []
var opp_discard = []
var player_game_data = {
	"field": [], # Array of Arrays storing the card_no in the field
	"field_vis": [], # Boolean Array showing what is faceup (true) and facedown (false)
	"field_mod": [], # Array of Dict of Dict storing Power/BP modifiers and their origins (to prevent effect stacking)
	"effect_queue": [], # List of card_no to help process effects
	"hand": [], # Array of card_no representing hand of cards
	"deck": Deck.new(), # Deck object
	"scene_owner": false # Boolean representing if this player controls the scene
}

var opp_game_data = {
	"field": [],
	"field_vis": [],
	"field_mod": [],
	"action_queue": [],
	"hand": [],
	"deck": Deck.new(),
	"scene_owner": false
}

var stack_map = {
		1: "SINGLE",
		2: "DOUBLE",
		3: "TRIPLE"
	}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_from_directory()
	
	
	
func load_from_directory():
	var dir = DirAccess.open('res://scripts/card_data')
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				load_cards_from_file(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	
func load_cards_from_file(file_path):
	'''Loads all the card data from the specified json file. 
	Updates the "cards" property to be an array of all the cards loaded.'''
	var file_path_prefix = "res://scripts/card_data/"
	var json_as_text = FileAccess.get_file_as_string(file_path_prefix + file_path)
	var json_as_dict = JSON.parse_string(json_as_text)
	for card in json_as_dict:
		
		var new_card = CardScene.instantiate().with_data(card["card_name"], card["card_no"], card["character"], card["feature"], card["level"], card["type"], card["bp"], card["abilities"], card["image_path"])
		cards[new_card.card_no] = new_card

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
