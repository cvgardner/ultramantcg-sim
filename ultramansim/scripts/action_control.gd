extends Control

var action_queue = [] #Array holding all the current actions
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func update_cont_effects():
	'''
	Processing cont effects and directly updates GlobalData game_data variables
	'''	
	for i in range(GlobalData.player_game_data['field_mod'].size()):
		#Check for player cont
		var player_card = GlobalData.cards[GlobalData.player_game_data['field'][i][0]]
		if (player_card.abilities[0]['trigger'] == 'CONTINUOUS' 
		and player_card.curr_stack in player_card.abilities[0]['stack_condition']):
			pass
		#Check for Opp cont
		var opp_card = GlobalData.cards[GlobalData.opp_game_data['field'][i][0]]
		if (opp_card.abilities[0]['trigger'] == 'CONTINUOUS' 
		and opp_card.curr_stack in opp_card.abilities[0]['stack_condition']):
			pass
			


func update_actionlist_ui():
	'''Updates the action list with action_queue'''
	$ActionQueue/ActionList.clear()
	var index = 0
	for card in action_queue:
		$ActionQueue/ActionList.add_item("", GlobalData.cards[card].image)
		$ActionQueue/ActionList.set_item_metadata(index, card)
		index += 1
	$ActionQueue/ActionList.queue_redraw()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
