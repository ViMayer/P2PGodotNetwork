extends CanvasLayer
class_name UsersList

## The UsersList node automatially lists connected Network users

const USER_CARD_TSCN := preload("uid://ccvsxrmstwcgy") # Is used to read and display a UserInfoResource it receives

@onready var user_cards_container: VBoxContainer = %UserCardsContainer # Holds all the label nodes that show the user display_name
@onready var panel: Panel = %Panel

# Connects the functions to the correct Network signals
func _init() -> void: 
	Network.user_connected.connect(_on_user_connected)
	Network.user_disconnected.connect(_on_user_disconnected)
	Network.server_disconnected.connect(_on_server_disconnected)
	
func toggle_users_list(active: bool) -> void:
	if active: self.show()
	else: self.hide()

# Lists/updates a user info
func list_user(user: UserInfoResource) -> void:
	if not is_instance_valid(user): _log_error("Error in list_user function: invalid user!"); return
	var new_user_card: UserCard
	# Tries to find and select the existing user UserCard if it exists
	for user_card: UserCard in user_cards_container.get_children(): if user_card.user and user_card.user.multiplayer_id == user.multiplayer_id: new_user_card = user_card; break
	# If no available UserCard is found it creates and adds a new one
	if not is_instance_valid(new_user_card):
		new_user_card = USER_CARD_TSCN.instantiate()
		user_cards_container.add_child(new_user_card)
	new_user_card.name = str(user.display_name) # Uses the received UserInfoResource display_name as the card node name so that the listing of cards can be sorted
	new_user_card.user = user # Sets the UserInfoResource for the UserCard
	new_user_card.update_visuals() # Forces the UserCard to update it's appearance to fit the UserInfoResource it just received
	_sort_user_cards()

# Unlists/removes a user info
func unlist_user(user: UserInfoResource) -> void:
	if not is_instance_valid(user): _log_error("Error in unlist_user function: invalid user!"); return
	var user_mult_id := user.multiplayer_id
	for user_card: UserCard in user_cards_container.get_children(): if user_card.user and user_card.user.multiplayer_id == user_mult_id: user_card.queue_free()
	_sort_user_cards()

func _on_user_connected(user: UserInfoResource): list_user(user)

func _on_user_disconnected(user: UserInfoResource): unlist_user(user)

func _on_server_disconnected():
	toggle_users_list(false)
	_clear_users_list()

func _clear_users_list() -> void: # Removes all listed users
	for listed_label in _get_listed_user_cards(): listed_label.queue_free()

func _get_listed_user_cards() -> Array[UserCard]:
	var value: Array[UserCard] = []
	value.append_array(user_cards_container.get_children().filter(func(x): return is_instance_valid(x) and x is UserCard))
	return value

# Sorts the display order of the current user cards listed 
func _sort_user_cards() -> void: _sort_node_children_by_name(user_cards_container)

# Receives a node and then sorts their children order based on their node names
func _sort_node_children_by_name(target_node: Node) -> void:
	if not is_instance_valid(target_node): _log_error("Error at sorting node's children: Invalid target_node!")
	var children := target_node.get_children()
	children.sort_custom(func(a, b): return a.name.naturalnocasecmp_to(b.name) < 0)
	for i in range(children.size()): target_node.move_child(children[i], i)

func _on_started_connecting() -> void: toggle_users_list(false)

func _log_error(message: String) -> void: printerr("[UsersList] " + message)

func sort_children_by_name(parent: Node) -> void: 
	# Get all children
	var children = parent.get_children()
	
	# Sort the children by their 'name' property (alphabetically)
	children.sort_custom(func(a, b): return a.name < b.name)
	
	# Reorder children in the scene tree
	for i in range(children.size()):
		parent.move_child(children[i], i)
