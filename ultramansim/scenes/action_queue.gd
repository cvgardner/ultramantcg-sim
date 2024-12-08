extends Control

var action_queue = [] # Array holding card_no for effects to be able to activate 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func process_scene_enters_effects(card_no):
	'''Function to process Enters effects of Scenes based on card_no'''

func process_enters_effects(action_queue):
	'''Function to process effects from enters play'''
	self.action_queue = action_queue
	update_ui()
	pass
	
func process_activate_effects():
	'''Function to process effects from activate phase'''
	self.action_queue = action_queue
	update_ui()
	pass
	
	
	
func update_ui():
	'''Updates the action list with action_queue'''
	$ActionList.clear()
	var index = 0
	for card in action_queue:
		$ActionList.add_item("", GlobalData.cards[card].image)
		$ActionList.set_item_metadata(index, card)
		index += 1
	$ActionList.queue_redraw()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
