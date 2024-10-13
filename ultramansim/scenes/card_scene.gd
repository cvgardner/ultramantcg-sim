extends Control

var card
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create()
	_update_power_text(self.bp["single"])
	$Level.set_text(str(self.level))
	pass # Replace with function body.

func create(card_name:= "Ultraman Dyna, Flash Type",
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
	card = Card.new(card_name, card_no, character, feature, level, type, bp, abilities, image_path)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
