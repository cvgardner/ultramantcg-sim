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

'''

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
