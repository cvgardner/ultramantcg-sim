extends HBoxContainer

# Custom HBOX Container containing the field information for Ultraman Battles

var data = [] #This will be a list of lists containing card instances
#var card = load("res://scenes/card.tscn")
signal item_hovered(item_card_no)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.add_theme_constant_override("separation", 85)
	pass # Replace with function body.
	

#func set_character(item):
	#'''
	#Appends a new card to list 'data' based on the input card_no string
	#'''
	#var new_card = GlobalData.cards[item]._make_copy()
	#new_card.flip_face_down()
	#data.append([new_card])
	#visualize()
	#
#func level_up(index,item):
	#'''
	#Adds a new item to the front of the element at index of data. This is essentially level up functionality
	#input:
		#item: card_no str
		#index: index representin card placement
	#'''
	#var new_card = GlobalData.cards[item]._make_copy()
	#new_card.flip_face_down()
	#data[index] = [new_card] + data[index]
	#visualize()


#TODO: Update function to take in the card_no arry and boolean array necessary for UI updates
func visualize(field, field_vis):
	'''
	Updates the visual in the hbox container based on the list 'data'
	'''
	#Queue Free / Clear current items in hbox container
	for child in self.get_children():
		self.remove_child(child)
		child.queue_free()
		
	var stack_map = {
		1: "SINGLE",
		2: "DOUBLE",
		3: "TRIPLE"
	}
	#Loop through each element (item) in data
	var i = 0
	while i < len(field):
		var wrapper_node = Control.new()
		wrapper_node.set_size(Vector2(75,100))
		#self.add_child(GlobalData.cards[field[i][0]])
		var new_card = GlobalData.cards[field[i][0]]._make_copy()
		print(field_vis, field_vis[i],not field_vis[i], !field_vis[i])
		if not field_vis[i]:
			new_card.flip_face_down()
		#new_card.change_stack(stack_map[len(field[i])])
		new_card.card_hovered.connect(_on_item_mouse_entered)
		wrapper_node.add_child(new_card)
		self.add_child(wrapper_node)		
		i += 1
		
func _on_item_mouse_entered(card_no):
	emit_signal("item_hovered", card_no)

func flip_all_face_up():
	''' flips all the first elements in each card stack face up then visualize'''
	for item in self.get_children():
		item.get_child(0).flip_face_up()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
