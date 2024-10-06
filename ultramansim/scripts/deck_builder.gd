extends Control

var available_cards = []
var player_deck = Deck.new()
var deck_list
var all_cards_list
var available_card_list
var available_cards_container
var deck_container
@onready var card_preview = $MainContainer/CardPreview
@onready var main_container = $MainContainer
@onready var load_deck_options = $MainContainer/CardListContainer/ButtonContainer/LoadDeckOptions
@onready var deck_save_name = $MainContainer/CardListContainer/ButtonContainer/DeckSaveName

@onready var feature_filter = $MainContainer/CardListContainer/ButtonContainer2/FeatureFilter
@onready var level_filter = $MainContainer/CardListContainer/ButtonContainer2/LevelFilter
@onready var character_filter = $MainContainer/CardListContainer/ButtonContainer2/CharacterFilter
@onready var type_filter = $MainContainer/CardListContainer/ButtonContainer2/TypeFilter
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Setup UI Elements
	$MainContainer/CardListContainer.size_flags_stretch_ratio = 2
	$MainContainer/DeckListContainer.size_flags_stretch_ratio = 1
	$MainContainer/CardListContainer/ButtonContainer.size_flags_stretch_ratio = 0.1
	deck_save_name.set_expand_to_text_length_enabled(true)
	deck_save_name.set_placeholder("Deck Name Here")
	card_preview.set_expand_mode(5) #EXPAND_FIT_HEIGHT_PROPORTIONAL
	card_preview.set_stretch_mode(5) #STRETCH_KEEP_ASPECT_CENTERED
	#Load Card Data
	load_available_cards()
	#Setup ItemLists
	configure_available_cards_itemlist()
	configure_deck_itemlist()
	#Connect Signals
	$MainContainer/CardListContainer/ButtonContainer2/BackButton.pressed.connect(_on_BackButton_pressed)
	$MainContainer/CardListContainer/ButtonContainer/SaveButton.pressed.connect(save_deck_list_json)
	$MainContainer/CardListContainer/ButtonContainer/LoadButton.pressed.connect(load_deck_list_json)
	$MainContainer/CardListContainer/ButtonContainer/ClearButton.pressed.connect(clear_deck_list)
	$MainContainer/CardListContainer/ButtonContainer2/ResetFilterButton.pressed.connect(reset_filters)
	for filter in [feature_filter, level_filter, character_filter, type_filter]:
		filter.item_selected.connect(apply_filters)
	
	#Load UI Elements
	configure_filters()
	update_card_list_ui()
	update_deck_list_ui()
	populate_load_deck_options()
	card_preview.set_texture(available_cards[available_cards.keys()[0]].image)

	
func configure_available_cards_itemlist():
	available_card_list = $MainContainer/CardListContainer/ScrollContainer/AvailableCardList
	available_card_list.auto_height = true
	available_card_list.set_max_columns(5)
	available_card_list.fixed_icon_size = Vector2(128, 128)
	available_card_list.set_allow_reselect(true)
	available_card_list.set_allow_rmb_select(true)
	available_card_list.set_icon_mode(0)
	available_card_list.item_selected.connect(_add_card_to_deck)
	available_card_list.hovered_item.connect(_preview_card)

	
func configure_deck_itemlist():
	#deck_list = $MainContainer/DeckListContainer/DeckList
	deck_list = $MainContainer/CardListContainer/ScrollContainer2/DeckList
	deck_list.auto_height = true
	deck_list.set_max_columns(8)
	deck_list.fixed_icon_size = Vector2(96, 96)
	deck_list.set_allow_reselect(true)
	deck_list.set_allow_rmb_select(true)
	deck_list.set_icon_mode(0)
	deck_list.item_selected.connect(_remove_card_from_deck)
	deck_list.hovered_item.connect(_preview_card)


	
func load_available_cards():
	'''Pulls in card data from the DataLoader Node'''
	var data_loader = get_node("/root/deck_builder/DataLoader")
	all_cards_list = data_loader.cards
	available_cards = all_cards_list

func update_card_list_ui():
	'''Populates UI component based on available cards'''
	var index = 0
	available_card_list.clear()
	for card in available_cards.values():
		available_card_list.add_item(card.card_no, card.image)
		available_card_list.set_item_metadata(index, card.card_no)
		index += 1
	
		
		

func update_deck_list_ui():
	'''Populates UI components based on decklist'''
	deck_list.clear()
	var index = 0
	for card_no in player_deck.deckdict.keys():
		deck_list.add_item(str(player_deck.deckdict[card_no]), available_cards[card_no].image)
		#deck_list.add_item(str(player_deck.deckdict[card_no]) + "x " + card_no)
		deck_list.set_item_metadata(index, card_no)
		index += 1
	main_container.queue_redraw()
		
func save_deck_list_json():
	'''Saves decklist to json file in res://decks'''
	var file_name = $MainContainer/CardListContainer/ButtonContainer/DeckSaveName.text
	var file = FileAccess.open('res://decks/' + file_name + '.json', FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(player_deck.deckdict))
		file.close()
	populate_load_deck_options()
	
func load_deck_list_json():
	'''Loads decklist from json file in res://decks'''
	var file_name = $MainContainer/CardListContainer/ButtonContainer/LoadDeckOptions.text
	var file_path = 'res://decks/' + file_name + '.json'
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var json_result = JSON.parse_string(json_text)
		player_deck.deckdict = json_result
		update_deck_list_ui()
		deck_save_name.text = file_name

	else:
		print("ERROR: Failed to open file ", file_path)

func clear_deck_list():
	player_deck.deckdict = {}
	update_deck_list_ui()
	
func populate_load_deck_options():
	'''Populates the option buttion LoadDeckOptions with decks from res://decks'''
	load_deck_options.clear()
	var dir = DirAccess.open('res://decks')
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				load_deck_options.add_item(file_name.replace(".json", ""))
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("ERROR: Failed to open directory res://Decks")
	make_option_button_items_non_radio_checkable(load_deck_options)
	
func configure_filters():
	'''Configures all the Card Collection Filters'''
	#Add Items to FeatureFilter
	for item in ["Card Type", "Ultra Hero", "Ultra Kaiju", "Scene"]:
		feature_filter.add_item(item)
	#Add Items to LevelFilter
	for item in ["Level", "0", "1", "2", "3", "4", "5", "6"]:
		level_filter.add_item(item)
	#Add Items to CharacterFilter
	for item in ["Character", 'TIGA', 'DYNA', 'GAIA', 
					'ZERO', 'GEED', 'Z', 'SKULL GOMORA', 
					'PENDANIUM ZETTON', 'SATAN BIZOR', 'KING OF MONS']:
		character_filter.add_item(item)
	#Add Items to TypeFilter
	for item in ["Type", "BASIC", "POWER", "SPEED", "ARMED", "HAZARD"]:
		type_filter.add_item(item)
	
	#Remove radio buttons
	for filter in [feature_filter, level_filter, character_filter, type_filter]:
		make_option_button_items_non_radio_checkable(filter)
		
func apply_filters(index):
	'''Applys the filters on all_cards to update available cards'''
	available_cards = all_cards_list.duplicate(true)
	for card in all_cards_list.keys():
		#Apply Feature
		if feature_filter.text != "Card Type":
			if all_cards_list[card].feature != feature_filter.text:
				available_cards.erase(card)
		#Apply Level
		if level_filter.text != "Level":
			if all_cards_list[card].level != int(level_filter.text):
				available_cards.erase(card)
		#Apply Character
		if character_filter.text != "Character":
			if all_cards_list[card].character != character_filter.text:
				available_cards.erase(card)
		#Apply Type
		if type_filter.text != "Type":
			if all_cards_list[card].type != type_filter.text:
				available_cards.erase(card)
	update_card_list_ui()
	
	
func reset_filters():
	'''Resets the filters and available cards'''
	for filter in [feature_filter, level_filter, character_filter, type_filter]:
		filter.select(0)
	apply_filters("DUMMY")

func _add_card_to_deck(index):
	'''Adds the specified card to the players deck if the deck isnt't already 
	at max size and the card duplicate limit hasn't been reached yet.'''
	var card_no = available_card_list.get_item_text(index)
	var result = player_deck.add_card_to_deck(card_no)
	if not result:
		print("ERROR: Too many Cards in Deck or Maximum copies reached")
	update_deck_list_ui()
		
func _remove_card_from_deck(index):
	''' Removes a card from the deck and then updates the decklist ui
	'''
	var card_no = deck_list.get_item_metadata(index)
	var result = player_deck.remove_card_from_deck(card_no)
	if not result:
		print("ERROR: Card does not exist in deck")
	update_deck_list_ui()
	 
func _preview_card(item):
	if item != 'none':
		card_preview.set_visible(true)
		card_preview.set_texture(available_cards[item].image)
	#elif item == 'none':
		#card_preview.set_visible(false)

func _on_BackButton_pressed():
	''' Return to Main Menu Screen'''
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func make_option_button_items_non_radio_checkable(option_button: OptionButton) -> void:
	var pm: PopupMenu = option_button.get_popup()
	for i in pm.get_item_count():
		if pm.is_item_radio_checkable(i):
			pm.set_item_as_radio_checkable(i, false)	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
