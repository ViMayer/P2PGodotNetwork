extends Node

# Node logic signals
signal setup_finished


# Server signals
signal joined_server # Emitted when this user joins/hosts a server
signal server_disconnected
signal connection_failed
signal started_connecting # Emitted when this user starts joining/hosting a server

# User signals
signal user_connected(user: UserInfoResource)
signal user_disconnected(user: UserInfoResource)
signal users_connected_changed

# Tunnel address
const TUNNEL_ADDRESS: String = "relay.nodetunnel.io"

# Holds your UserInfoResource
var user_info := UserInfoResource.new():
	get: user_info["multiplayer_id"] = -1 if not multiplayer else multiplayer.get_unique_id(); return user_info

# Holds all the users that are connected to the server you are
var users_connected: Dictionary[int,UserInfoResource] ## { "multiplayer_id": UserInfoResource } 

var _setting_up := false # Is true only when _setup is running

var peer: NodeTunnelPeer
var setup_done := false # Is set to true if the setup was done correctly finishes
var lobby_key: String # Holds the address for the lobby you are currently connected to

var _connection_error := false # If true this means there was an error when connecting and it is used to stop some functions when it's value is true

var _max_time_to_connect := 20.0 # Maximum time, in seconds, to join/host a server before cancelling the request
var hosting := false # Is true when this user is trying to host a server
var joining := false # Is true when this user is trying to join a server


func _ready() -> void: _setup()

func _setup() -> void:
	if setup_done or _setting_up: return
	_setting_up = true
	peer = NodeTunnelPeer.new()
	peer.room_left.connect(_handle_disconnect)
	multiplayer.multiplayer_peer = peer
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	await peer.connect_to_relay(TUNNEL_ADDRESS,9998)
	_setting_up = false
	setup_done = true
	setup_finished.emit()

func start_host(): # Hosts a lobby server
	if hosting or _connection_error: return
	started_connecting.emit()
	hosting = true
	var _connection_error_timer := _create_connection_timer()
	_connection_error_timer.timeout.connect(func():
		_connection_error = true
		hosting = false
		_log_error("Took too long to host server")
		if is_instance_valid(_connection_error_timer): _connection_error_timer.queue_free()
		peer.disconnect_from_relay()
		_handle_disconnect()
	)
	if not _connection_error: await await_setup()
	if not _connection_error: await peer.host()
	if is_instance_valid(_connection_error_timer): _connection_error_timer.queue_free()
	if not _connection_error:
		lobby_key = peer.online_id
		_on_successfull_connection()
	_connection_error = false


func join_address(address: String): # Joins the server using it's ip/lobby key
	if joining or _connection_error: return
	if address == lobby_key: _log_error("Trying to join the current server"); _on_successfull_connection(); return
	started_connecting.emit()
	joining = true
	var _connection_error_timer: Timer = _create_connection_timer()
	_connection_error_timer.timeout.connect(func():
		_connection_error = true
		joining = false
		_log_error("Took too long to join the server")
		if is_instance_valid(_connection_error_timer): _connection_error_timer.queue_free()
		_handle_disconnect()
		connection_failed.emit()
	)
	if _connection_error: return
	if not _connection_error: await await_setup()
	if not _connection_error: await peer.join(address)
	if is_instance_valid(_connection_error_timer): _connection_error_timer.queue_free()
	if not _connection_error: 
		lobby_key = address
		_on_successfull_connection()
	_connection_error = false

# Disconnects from the current server
func disconnect_from_server():
	if not peer: _log_error("Error in disconnect_from_server function: invalid peer")
	peer.leave_room()
	_handle_disconnect()

# Will wait the setup_finished signal if the setup is not done
func await_setup() -> bool: 
	if not setup_done and not _setting_up: _setup()
	if _setting_up: await setup_finished
	return true

func connect_user(user: UserInfoResource): # Adds the user to users_connected
	if _is_multiplayer_id_registred(user.multiplayer_id): return
	if users_connected.has(user.multiplayer_id): return
	users_connected[user.multiplayer_id] = user
	user_connected.emit(user)
	users_connected_changed.emit()

func disconnect_user(user: UserInfoResource): # Removes the user from users_connected
	if not users_connected.has(user.multiplayer_id): return
	users_connected.erase(user.multiplayer_id)
	user_disconnected.emit(user)
	users_connected_changed.emit()

func _is_multiplayer_id_registred(multiplayer_id: Variant) -> bool: return true if multiplayer_id == 0 else users_connected.has(multiplayer_id)

func _create_connection_timer() -> Timer: # Returns a timer for handling connection timeout
	var timer := Timer.new()
	timer.one_shot = true
	self.add_child(timer)
	timer.start(_max_time_to_connect)
	return timer

func _on_connection_failed(): lobby_key = ""; connection_failed.emit(); _log_error("Error when connecting to the server")
func _on_peer_disconnected(peer_id: int): var user: UserInfoResource = users_connected.get(peer_id); if user: user_disconnected.emit(user)

# Handles what happens after disconnecting
func _handle_disconnect() -> void:
	lobby_key = ""
	setup_done = false
	users_connected = {}
	hosting = false
	joining = false
	peer.disconnect_from_relay()
	server_disconnected.emit()


func _on_successfull_connection(): # Called after successfuly joining/hostingg a server
	joining = false
	hosting = false
	_connection_error = false
	connect_user(user_info)
	joined_server.emit()

func _on_peer_connected(peer_id):
	while joining: await get_tree().process_frame
	_register_user_dic.rpc_id(peer_id,user_info.dic_data) # Register your user in the peer that you connected with

@rpc("any_peer", "reliable")
func _register_user_dic(user_dic_data: Dictionary):
	var new_user_info := UserInfoResource.get_resource_by_dic(user_dic_data)
	connect_user(new_user_info)

func _log_error(message: String) -> void: printerr("[Network] " + message)
