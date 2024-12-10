extends ItemList

var item
signal hovered_item(item)
signal card_clicked(item)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.gui_input.connect(_on_ItemList_gui_input)
	self.item_selected.connect(_on_item_select)
	pass # Replace with function body.

func _on_ItemList_gui_input(event: InputEvent) -> void:
	item = get_item_at_position(get_local_mouse_position(), true)
	if event is InputEventMouseMotion and item != -1:
		#emit a signal regarding the current item
		hovered_item.emit(get_item_metadata(item))
	elif event is InputEventMouseMotion and item == -1:
		hovered_item.emit('none')
		
func _on_item_select(ind):
	emit_signal("card_selected", get_item_metadata(ind))
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
