# TODO make abstract in Godot 4.5 https://github.com/godotengine/godot-proposals/issues/5641
class_name UseableStrategy
extends Resource

# TODO implement UseableStrategy
func is_usable(action_instance: ActionInstance) -> bool:
	push_warning("Using default UseableStrategy, always true")
	return true 
