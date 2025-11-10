extends Control
class_name UserCard

@onready var background_color_rect: ColorRect = %Background
@onready var display_name_label: Label = %DisplayNameLabel

@export var user: UserInfoResource:
	set(value): if user != value: user = value; call_deferred("update_visuals")

func _ready() -> void: update_visuals()

func update_visuals():
	if not is_instance_valid(user):
		self.hide()
		display_name_label.text = ""
		background_color_rect.color = Color.BLACK
		return
	self.show()
	display_name_label.text = user.display_name
	background_color_rect.color = user.color
