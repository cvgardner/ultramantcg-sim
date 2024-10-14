extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Player deck: ", GlobalData.player_deck, "Opp deck: ", GlobalData.opp_deck)
	print(GlobalData.player_deck, " opponent_deck ", GlobalData.opp_deck.deckdict)
	
	#Ready The Decks
	for deck in [GlobalData.player_deck, GlobalData.opp_deck]:
		deck.create_deck()
		deck.shuffle_deck() #This would desync the player and server. I think this is where I start having server pass all info to the client?
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
