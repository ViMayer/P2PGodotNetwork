extends Resource
class_name UserInfoResource

signal properties_changed

@export var display_name: String = "USERNAME":
		set(value): if display_name != value: display_name = value; call_deferred("_on_properties_changed")
@export var avatar_url: String:
		set(value): if avatar_url != value: avatar_url = value; call_deferred("_on_properties_changed")
@export var multiplayer_id: int = -1:
		set(value): if multiplayer_id != value: multiplayer_id = value; call_deferred("_on_properties_changed")
@export var color: Color = Color(0,0,0,0)

# Contains the names of the valid user variables
var _valid_variables: Array[String] = ["display_name","avatar_url","multiplayer_id","color"]

# Returns the user data in Dictionary format
var dic_data: Dictionary: 
	get:
		var value := {}; for key in _valid_variables: value.set(key,self.get(key))
		return value

static func get_resource_by_dic(dic: Dictionary) -> UserInfoResource:
	var resource := UserInfoResource.new(); resource.read_data_in_dictionary(dic); return resource

# Reads a dictionary and updates the resource variables based on the variables read
func read_data_in_dictionary(dic: Dictionary):
	for valid_key in _valid_variables: if dic.has(valid_key): self.set(valid_key,dic[valid_key])

static func dic_to_user(dic: Dictionary) -> UserInfoResource:
	var new_user_info := UserInfoResource.new()
	for key in dic: new_user_info.set(key,dic[key])
	return new_user_info


func _on_properties_changed(): properties_changed.emit()
