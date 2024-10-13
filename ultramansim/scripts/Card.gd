extends Node

class_name Card

var card_name: String
var card_no: String
var character: String
var feature: String
var level: int
var type: String
var bp: Dictionary
var abilities: Array
var image: Texture

func _init( card_name:= "Ultraman Dyna, Flash Type",
 card_no:= "SD01-001",
 character:= "DYNA",
 feature:= "Ultra Hero",
 level:= 3,
 type:= "SPEED",
 bp:= {
			"single": 9000,
			"double": 11000,
			"triple": 16000
		},
 abilities:= [
			{
				"trigger": "ENTER_PLAY",
				"stack_condition": ["double", "triple"],
				"target": {
					"card_no": ["SD01-014"],
					"character": ["TIGA", "GAIA"]
				},
				"effect": [{
					"DECK_SEARCH_DISCARD": 3
			}]
			}
		],
 image_path:= "res://images/cards/SD01/SD01-001.webp"):
	self.card_name = card_name
	self.card_no = card_no
	self.character = character
	self.feature = feature
	self.level = level
	self.type = type
	self.bp = bp
	self.abilities = abilities
	self.image = ResourceLoader.load(image_path)
	
func _make_copy() -> Card:
	'''Creates a new Card node with the same properties as the current one'''
	var new_card = Card.new(
		self.card_name,
		self.card_no,
		self.character,
		self.feature,
		self.level,
		self.type,
		self.bp,
		self.abilities,
		"dummy_path"
	)
	new_card.image = self.image
	return new_card

func with_data( card_name:= "Ultraman Dyna, Flash Type",
 card_no:= "SD01-001",
 character:= "DYNA",
 feature:= "Ultra Hero",
 level:= 3,
 type:= "SPEED",
 bp:= {
			"single": 9000,
			"double": 11000,
			"triple": 16000
		},
 abilities:= [
			{
				"trigger": "ENTER_PLAY",
				"stack_condition": ["double", "triple"],
				"target": {
					"card_no": ["SD01-014"],
					"character": ["TIGA", "GAIA"]
				},
				"effect": [{
					"DECK_SEARCH_DISCARD": 3
			}]
			}
		],
 image_path:= "res://images/cards/SD01/SD01-001.webp"):
	self.card_name = card_name
	self.card_no = card_no
	self.character = character
	self.feature = feature
	self.level = level
	self.type = type
	self.bp = bp
	self.abilities = abilities
	self.image = ResourceLoader.load(image_path)
	return self
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _update_power_text(power: int):
	var formatted_string = "[center]" + str(power/1000) + ",000" + "[/center]"
	$TextEdit.set_text(formatted_string)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
