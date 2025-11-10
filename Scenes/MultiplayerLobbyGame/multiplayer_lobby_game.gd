extends Node
class_name MultiplayerLobbyGame

@onready var players_container := %PlayersContainer
@onready var multiplayer_menu: MultiplayerMenu = %MultiplayerMenu
@onready var users_list: UsersList = %UsersList

var _users_connected: Dictionary[int,UserInfoResource]: ## { "multiplayer_id": UserInfoResource } 
	get: return Network.users_connected

func _init() -> void:
	Network.joined_server.connect(_on_joined_server)
	Network.server_disconnected.connect(_on_server_disconnected)
	Network.connection_failed.connect(_on_connection_failed)


func _ready() -> void: users_list.toggle_users_list(false); multiplayer_menu.toggle_menu(true)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel") and _users_connected and not (Network.hosting or Network.joining): multiplayer_menu.toggle_menu();
	if Input.is_action_just_pressed("debug"): _debug()

func _on_joined_server():
	await get_tree().create_timer(0.2).timeout
	users_list.toggle_users_list(true);
	multiplayer_menu.toggle_menu(false)

func _on_connection_failed() -> void: _reset_node()
func _on_server_disconnected() -> void: _reset_node()



func _reset_node() -> void:
	users_list.toggle_users_list(false)
	users_list._clear_users_list()
	multiplayer_menu.toggle_menu(true)

func _debug() -> void:
	print("========== DEBUG ==========")
	var debug_users_connected = []
	for mult_id in _users_connected: var user := _users_connected[mult_id]; debug_users_connected.append([user.multiplayer_id, user.dic_data])
	print(Global.instance_id," debug_users_connected: ",debug_users_connected)
	print("===========================")
