extends CanvasLayer
class_name UsersList

# This node automatially lists connected Network users

@onready var users_container: VBoxContainer = %UsersContainer # Holds all the label nodes that show the user display_name
@onready var user_label_template: Label = %UserLabelTemplate # Is duplicated and used as base to list new users
@onready var panel: Panel = %Panel

# Connects the functions to the correct Network signals
func _init() -> void: 
	Network.user_connected.connect(_on_user_connected)
	Network.user_disconnected.connect(_on_user_disconnected)
	Network.server_disconnected.connect(_on_server_disconnected)
	
func _ready() -> void: user_label_template.visible = false

func toggle_users_list(active: bool) -> void:
	if active: self.show()
	else: self.hide()

# Lists/updates a user info
func list_user(user: UserInfoResource) -> void:
	if not is_instance_valid(user): _log_error("Error in list_user function: invalid user!"); return
	var user_mult_id := user.multiplayer_id
	var new_user_label_template: Label # The label to be added/edited
	# Tries to find and select the user label if it exists
	for user_label in users_container.get_children(): if user_label.name == str(user_mult_id): new_user_label_template = user_label; break
	# Otherwise creates and adds a new one
	if not new_user_label_template: new_user_label_template = user_label_template.duplicate(); new_user_label_template.visible = true; users_container.add_child(new_user_label_template)
	new_user_label_template.text = user.display_name
	new_user_label_template.name = str(user.multiplayer_id) # Uses the multiplayer_id as the node name so we can use it to sort/remove the label
	_order_users_list()

# Unlists/removes a user info
func unlist_user(user: UserInfoResource) -> void:
	if not is_instance_valid(user): _log_error("Error in unlist_user function: invalid user!"); return
	var user_mult_id := user.multiplayer_id
	for user_label in users_container.get_children(): if user_label.name == str(user_mult_id): user_label.queue_free()
	_order_users_list()

func _on_user_connected(user: UserInfoResource): list_user(user)

func _on_user_disconnected(user: UserInfoResource): unlist_user(user)

func _on_server_disconnected():
	toggle_users_list(false)
	_clear_users_list()

func _clear_users_list() -> void: # Removes all listed users
	for listed_label in _get_listed_labels(): listed_label.queue_free()

func _get_listed_labels() -> Array[Label]:
	var value: Array[Label] = []
	value.append_array(users_container.get_children().filter(func(x): return is_instance_valid(x) and x is Label and x != user_label_template))
	return value

func _order_users_list() -> void:
	var children := users_container.get_children().filter(func(x): return is_instance_valid(x) and x is Label)
	if children.size() == 0: return
	children.sort_custom(func(a, b): return a.text < b.text)
	for i in range(children.size()): users_container.move_child(children[i], i)

func _on_started_connecting() -> void: toggle_users_list(false)

func _log_error(message: String) -> void: printerr("[UsersList] " + message)
