extends Node

class_name Card
var CardScene = preload("res://scenes/card.tscn")


var card_name: String
var card_no: String
var character: String
var feature: String
var level: int
var type: String
var bp: Dictionary
var abilities: Array
var image: Texture
var image_path: String

# Gameplay Variables
var curr_stack : String
var curr_power : int
var curr_type : String
var image_path_card_back = "res://images/assets/card_back.png"

signal card_hovered(card_no)

func _init( card_name:= "Ultraman Dyna, Flash Type",
 card_no:= "SD01-001",
 character:= "DYNA",
 feature:= "Ultra Hero",
 level:= 3,
 type:= "SPEED",
 bp:= {
			"SINGLE": 9000,
			"DOUBLE": 11000,
			"TRIPLE": 16000
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
	self.image_path = image_path
	
func _make_copy() -> Card:
	'''Creates a new Card node with the same properties as the current one'''
	var new_card = CardScene.instantiate().with_data(
		self.card_name,
		self.card_no,
		self.character,
		self.feature,
		self.level,
		self.type,
		self.bp,
		self.abilities,
		self.image_path
	)
	return new_card

func with_data( card_name:= "Ultraman Dyna, Flash Type",
 card_no:= "SD01-001",
 character:= "DYNA",
 feature:= "Ultra Hero",
 level:= 3,
 type:= "SPEED",
 bp:= {
			"SINGLE": 9000,
			"DOUBLE": 11000,
			"TRIPLE": 16000
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
	self.image_path = image_path
	
	$TextureRect.texture = self.image
	return self
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Level.texture = ResourceLoader.load("res://images/assets/level_{0}.png".format([str(self.level)]))
	$Stack.texture = ResourceLoader.load("res://images/assets/SINGLE.png")
	self.curr_stack ='SINGLE'
	self.curr_type = self.type
	self.curr_power = self.bp[self.curr_stack]
	_update_power_text(self.bp['SINGLE'])
	self.mouse_entered.connect(_on_mouse_entered)
	pass # Replace with function body.

func _update_power_text(power: int):
	var formatted_string = "[center]" + str(power/1000) + ",000" + "[/center]"
	$Power.set_text(formatted_string)
	
func flip_face_down():
	'''
	Flips this card facedown aka change image to cardback
	'''
	self.image = ResourceLoader.load(image_path_card_back)
	$TextureRect.texture = self.image
	for ui in [$Level, $Power]:
		ui.hide()
	
func flip_face_up():
	'''
	Flips this card face up aka change image to card image
	'''
	self.image = ResourceLoader.load(self.image_path)
	$TextureRect.texture = self.image
	for ui in [$Level, $Power]:
		ui.show()


func card_back(card_name:= "Ultraman Dyna, Flash Type",
	 card_no:= "SD01-001",
	 character:= "DYNA",
	 feature:= "Ultra Hero",
	 level:= 3,
	 type:= "SPEED",
	 bp:= {
			},
	 abilities:= [
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
	self.image = ResourceLoader.load(image_path_card_back)
	self.image_path = image_path
	$Power.hide()
	$Level.hide()
	return self
	
func hide_power():
	$Power.hide()
	
func show_power():
	$Power.show()
	
func hide_level():
	$Level.hide()

func show_level():
	$Level.show()

func show_stack():
	$Stack.show()

func hide_stack():
	$Stack.hide()
	
func show_highlight():
	$Highlight.show()

func hide_highlight():
	$Highlight.hide()
	
func change_stack(new_stack):
	'''
	changes the curr_stack variable and then stack icon
	input should be either "SINGLE", "DOUBLE" or "TRIPLE"
	'''
	curr_stack = new_stack
	$Stack.texture = ResourceLoader.load("res://images/assets/{0}.png".format([curr_stack]))
	self.curr_power = self.bp[new_stack]
	self._update_power_text(self.curr_power)

	
func _on_mouse_entered():
	print("mouse_entered card node ", self.card_no)
	emit_signal("card_hovered", self.card_no)
	
func _on_mouse_exited():
	pass
	
func _on_gui_ui_input(event: InputEvent) -> void:
	pass
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
