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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_from_directory()
	
	
	
func load_from_directory():
	var dir = DirAccess.open('res://Scripts/card_data')
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
	var file_path_prefix = "res://Scripts/card_data/"
	var json_as_text = FileAccess.get_file_as_string(file_path_prefix + file_path)
	var json_as_dict = JSON.parse_string(json_as_text)
	for card in json_as_dict:
		
		var new_card = CardScene.instantiate().with_data(card["card_name"], card["card_no"], card["character"], card["feature"], card["level"], card["type"], card["bp"], card["abilities"], card["image_path"])
		cards[new_card.card_no] = new_card

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
