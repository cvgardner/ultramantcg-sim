extends HBoxContainer

# Custom HBOX Container containing the field information for Ultraman Battles

var data = [] #This will be a list of lists containing card instances
#var card = load("res://scenes/card.tscn")
signal item_hovered(item_card_no)
signal item_clicked(item_index)
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
func level_up(field, index, card_no):
	'''
	Adds a new item to the front of the element at index of data. This is essentially level up functionality
	input:
		item: card_no str
		index: index representin card placement
	'''
	field[index] = [card_no] + field[index]



#TODO: Update function to take in the card_no arry and boolean array necessary for UI updates
func visualize(field, field_vis, field_mod):
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
		
		#new_card.change_stack(stack_map[len(field[i])])
		new_card.card_hovered.connect(_on_item_mouse_entered)
		#wrapper_node.gui_input.connect(_on_child_gui_input)
		new_card.gui_input.connect(_on_child_gui_input.bind(wrapper_node))
		
		
		
		wrapper_node.add_child(new_card)
		self.add_child(wrapper_node)		
		
		#update card (stack, vis, power)
		print("Stack Size: ", field[i].size())
		new_card.change_stack(stack_map[field[i].size()])
		if not field_vis[i]:
			new_card.flip_face_down()
			
		#Continuous Effects Activated
		
		#Modify BP and power based on field_mod
		#new_card.add_power(field_mod[i])
		
		i += 1
		
func _on_item_mouse_entered(card_no):
	emit_signal("item_hovered", card_no)

func flip_all_face_up():
	''' flips all the first elements in each card stack face up then visualize'''
	for item in self.get_children():
		item.get_child(0).flip_face_up()
		
func _on_child_gui_input(event, wrapper):
	if event is InputEventMouseButton and event.pressed:
		#var wrapper = event.target.get_parent()
		var index = self.get_children().find(wrapper)
		print("highlighted ", index)
		emit_signal("item_clicked", index)
		
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
