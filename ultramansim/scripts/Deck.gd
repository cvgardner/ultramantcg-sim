extends Node

class_name Deck

var deck_size_limit = 50
var card_limit = 4
var deck = [] # This will be a list of card nodes/ card_no strings (unsure atm)
var deckdict = {} # This is a representation of the deck as a dict of card_no:quantity
var CardScene = preload("res://scenes/card.tscn")


func create_deck():
	''' Creates the deck array of card scenes from the deckdict'''
	for key in deckdict.keys():
		for i in range(deckdict[key]):
			
			# Initially wanted to use nodes for the deck but just realized its only necessary to instantiate when viewing in the UI
			# Keeping this code incase I want to revert back to a deck of nodes
			#var new_card = CardScene.instantiate().with_data(GlobalData.cards[key].card_name, GlobalData.cards[key].card_no, GlobalData.cards[key].character, GlobalData.cards[key].feature, GlobalData.cards[key].level, GlobalData.cards[key].type, GlobalData.cards[key].bp, GlobalData.cards[key].abilities, GlobalData.cards[key].image_path)
			deck.append(key)
			pass
			
func draw_card(x):
	'''Pops the first x elements from the deck and returns them in an array'''
	var results = []
	if deck.size() >= x:
		for card in range(x):
			results.append(deck.pop_front())
	else:
		print("deck is empty")
	return results	
		
	
	
func shuffle_deck():
	'''Randomizes the array self.deck using built_in shuffle.'''
	deck.shuffle()

	

func _get_card_count() -> int:
	var total_count = 0
	for count in deckdict.values():
		total_count += count
	return total_count
	
func add_card_to_deck(card_no) -> bool:
	'''Adds card to the deck dict
	
	Returns:
		bool: true if success and false on failure'''
	if _get_card_count() < deck_size_limit:
		if deckdict.has(card_no) and deckdict[card_no] < 4:
			deckdict[card_no] += 1
			return true
		elif deckdict.has(card_no) and deckdict[card_no] >= 4:
			return false
		else:
			deckdict[card_no] = 1
			return true
	else:
		return false
		
func remove_card_from_deck(card_no) -> bool:
	'''Removes card from deck dict
	
	Returns:
		bool: true if success and false on failure'''
	if deckdict.has(card_no):
		if deckdict[card_no] == 1:
			deckdict.erase(card_no)
		else:
			deckdict[card_no] -= 1
		return true
	else:
		return false
func _check_card_limit(card_no: String) -> bool:
	'''Checks the deck to see if a certain card is over the card limit
	Returns:
		bool: false if check failed and true if check passed'''
	var counter = 0
	for card in deck:
		if card.card_no == card_no:
			counter += 1
		if counter >= card_limit:
			return false
	return true
	
func _check_deck_size() -> bool:
	'''Checks the deck to see if a it exceeds the deck size limit
	
	Returns:
		bool: false if deck exceeds limit true if deck is at or under limit'''
	if deck.size() >= deck_size_limit:
		return false
	else:
		return true
		
func deck_sort():
	''' Sorts the deck using our custom sorter (card_no)'''
	deck.sort_custom(_sort_card_no)
	
func _sort_card_no(a, b):
	''' Custom sort based on card_no'''
	if a.card_no < b.card_no:
		return true
	return false
	
func _erase_card_no(card_no: String) -> bool:
	'''Deletes a card (node) from the deck and frees it from memory based on the value of card_no.
	
	Returns:
		bool: True if success, False if failed
	'''
	for node in deck:
		if node.card_no == card_no:
			deck.erase(node)
			return true
	return false
	
func load_deck_list_json(file_name):
	'''Loads decklist from json file in res://Decks'''
	var file_path = 'res://Decks/' + file_name + '.json'
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var json_result = JSON.parse_string(json_text)
		deckdict = json_result


	else:
		print("ERROR: Failed to open file ", file_path)
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
