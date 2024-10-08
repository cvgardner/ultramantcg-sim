extends Node

class_name Deck

var deck_size_limit = 50
var card_limit = 4
var deck = [] # This will be a list of card nodes
var deckdict = {} # This is a representation of the deck as a dict of card_no:quantity

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
