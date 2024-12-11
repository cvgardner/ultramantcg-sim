extends Control

var action_queue = [] #Array holding all the current actions
var function_map = {
	"SELF_BP_CHANGE_OPP_TYPE": self_bp_change_opp_type
}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func update_cont_effects():
	'''
	Processing cont effects and directly updates GlobalData game_data variables
	'''	
	if GlobalData.player_game_data['field'].size() !=  GlobalData.opp_game_data['field'].size():
		#Ignore cont effects if the fields aren't the same size
		return
	for i in range(GlobalData.player_game_data['field_mod'].size()):
		#Check for player cont
		var player_card = GlobalData.cards[GlobalData.player_game_data['field'][i][0]]
		print("Player Trigger: ",  player_card.abilities[0].get('trigger'))
		print("Player Stack, Condition: ", GlobalData.player_game_data['field'][i].size(), ' ', player_card.abilities[0]['stack_condition'])
		if (player_card.abilities[0].get('trigger') == 'CONTINUOUS' 
		and GlobalData.stack_map[GlobalData.player_game_data['field'][i].size()] in player_card.abilities[0]['stack_condition']):
			parse_cont_effect(player_card, {"index":i, "caller": "player"})
		#Check for Opp cont
		var opp_card = GlobalData.cards[GlobalData.opp_game_data['field'][i][0]]
		print("Opp Trigger: ",  opp_card.abilities[0].get('trigger'))
		print("Opp Stack, Condition: ", GlobalData.opp_game_data['field'][i].size(), ' ', opp_card.abilities[0]['stack_condition'])

		if (opp_card.abilities[0].get('trigger') == 'CONTINUOUS' 
		and GlobalData.stack_map[GlobalData.opp_game_data['field'][i].size()] in opp_card.abilities[0]['stack_condition']):
			parse_cont_effect(opp_card, {"index":i, "caller": "opponent"})
			
func parse_cont_effect(card, extra_input):
	'''
	Takes input effect_str and runs the respective function
	'''
	for effect in card.abilities[0]['effect']:
		if effect.get('effect_name') in function_map:
			function_map[effect['effect_name']].call(card.card_no, effect['input'], extra_input)

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

# --- EFFECT FUNCTIONS ---
func self_bp_change_opp_type(card_no, effect_input, extra_input):
	#check who caller is
	var player_card_type = coalesce([
		GlobalData.player_game_data['field_mod'][extra_input['index']].get("type"), 
		GlobalData.cards[GlobalData.player_game_data['field'][extra_input['index']][0]].type
	])
	var opp_card_type = coalesce([
		GlobalData.opp_game_data['field_mod'][extra_input['index']].get("type"), 
		GlobalData.cards[GlobalData.opp_game_data['field'][extra_input['index']][0]].type
	])
	if extra_input['caller'] == 'player':
		#Check opp type
		if opp_card_type in effect_input['type']:
			#update global field_mod
			GlobalData.player_game_data['field_mod'][extra_input['index']]['bp_mod'][card_no] = effect_input['bp_mod']
	elif extra_input['caller'] == 'opponent':
		#Check opp type
		if player_card_type in effect_input['type']:
			#update global field_mod
			GlobalData.opp_game_data['field_mod'][extra_input['index']]['bp_mod'][card_no] = effect_input['bp_mod']

		
# --- Helper Functions ---
func coalesce(arg_list): 
	'''Coalesce from list input'''
	for arg in arg_list: 
		if arg != null: 
			return arg 
	return null
