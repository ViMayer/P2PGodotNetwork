extends CanvasLayer
class_name MultiplayerMenu

@export var _debug_auto_host_and_join := false ## If true it will automatically host with the first debug instance and then join at max 2 other instances

# Onready vars
@onready var nickname_input: LineEdit = %NicknameInput
@onready var server_address_input: LineEdit = %ServerAddressInput
@onready var menu: Control = %Menu
@onready var lobby_label: Label = %LobbyLabel
@onready var color_picker_button: ColorPickerButton = %ColorPickerButton
@onready var host_button: Button = %HostButton
@onready var join_button: Button = %JoinButton
@onready var disconnect_button: Button = %DisconnectButton
@onready var quit_button: Button = %QuitButton

var instance_id: int:
	get: return Global.instance_id

var server_address: String:
	get: return server_address_input.text.strip_edges()


var nickname: String:
	get:
		var prefix := "" if instance_id <= 0 else "("+str(instance_id)+") "
		var input_value := nickname_input.text.strip_edges()
		var value := prefix + ("Player" if not input_value else input_value)
		return value

var _disable_interactions: bool = false: # If true it won't be possible to interact with anything inside menu
	set(value): _disable_interactions = value; menu.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED if _disable_interactions else Control.MOUSE_BEHAVIOR_INHERITED; menu.modulate =  Color(0.5,0.5,0.5,1.0) if _disable_interactions else Color.WHITE

var color: Color:
	get: return color_picker_button.color

var _lobby_key: String:
	set(value): _lobby_key = value; lobby_label.text = "Lobby Key: " + str(_lobby_key); lobby_label.visible = false if not _lobby_key else true



func _init() -> void:
	Network.server_disconnected.connect(_on_server_disconnected)
	Network.connection_failed.connect(_on_connection_failed)
	Network.joined_server.connect(_on_joined_server)


func _ready():
	host_button.pressed.connect(host)
	disconnect_button.pressed.connect(_disconnect_from_server)
	join_button.pressed.connect(join)
	quit_button.pressed.connect(_quit_game)
	toggle_menu(true)
	await Network.await_setup()
	if _debug_auto_host_and_join: _auto_host_or_join()

func _auto_host_or_join():
	if instance_id <= 1: host()
	else:
		await get_tree().create_timer(2.5).timeout
		server_address_input.text = DisplayServer.clipboard_get()
		join()


func host():
	_disable_interactions = true
	await Network.await_setup()
	_update_my_network_user()
	await Network.start_host()
	server_address_input.text = _lobby_key
	DisplayServer.clipboard_set(_lobby_key)


func _on_joined_server() -> void:
	_lobby_key = Network.lobby_key
	_disable_interactions = false

func _update_my_network_user() -> void:
	Network.user_info["display_name"] = nickname
	Network.user_info["color"] = color


func join():
	if not server_address: return
	_disable_interactions = true
	_update_my_network_user()
	await Network.await_setup()
	await Network.join_address(server_address)
	



func toggle_menu(active: bool = not menu.visible):
	if active: menu.show()
	else: menu.hide()

func _disconnect_from_server(): _disable_interactions = true; Network.disconnect_from_server()

func _on_server_disconnected() -> void: _disable_interactions = false
func _on_connection_failed() -> void: _disable_interactions = false;

func _quit_game(): get_tree().quit()
