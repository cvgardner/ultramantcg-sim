extends HBoxContainer

# Custom HBOX Container containing the field information for Ultraman Battles

var data = [] #This will be a list of lists containing card instances

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
func set_character(item):
	'''
	Appends a new card to list 'data' based on the input card_no string
	'''
	var new_card = GlobalData.cards[item]._make_copy()
	new_card.flip_face_down()
	data.append([new_card])
	visualize()
	
func level_up(index,item):
	'''
	Adds a new item to the front of the element at index of data. This is essentially level up functionality
	input:
		item: card_no str
		index: index representin card placement
	'''
	var new_card = GlobalData.cards[item]._make_copy()
	new_card.flip_face_down()
	data[index] = [new_card] + data[index]
	visualize()

func visualize():
	'''
	Updates the visual in the hbox container based on the list 'data'
	'''
	#Queue Free / Clear current items in hbox container
	for child in self.get_children():
		self.remove_child(child)
		child.queue_free()
	#Loop through each element (item) in data
	for stack in data: 
		#take the first element of each item and add it to hbox
		self.add_child(stack[0])			
		
func flip_all_face_up():
	''' flips all the first elements in each card stack face up'''
	for card_stack in data:
		card_stack[0].flip_face_up()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
