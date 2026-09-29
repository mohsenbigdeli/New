extends Area2D

@export_multiline var message := "Hello."

func interact() -> Dictionary:
	return {"message": message}
