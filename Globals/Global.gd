extends Node

###################################
# Instance ID
var instance_id: int = 0
func _init() -> void: _setup_instance_id()
func _setup_instance_id(): for arg in OS.get_cmdline_args(): if arg.begins_with("instance_id="): instance_id = int(arg.split("=")[1])
###################################
