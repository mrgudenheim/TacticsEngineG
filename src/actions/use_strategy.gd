# TODO make abstract in Godot 4.5 https://github.com/godotengine/godot-proposals/issues/5641
class_name UseStrategy
extends Resource

# TODO implement UseStrategy
func use(action_instance: ActionInstance) -> void:
	push_error("Using base UseStrategy - does nothing")
	return
