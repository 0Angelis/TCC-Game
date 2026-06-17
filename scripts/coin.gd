extends Area2D

func _ready() -> void:
	pass 


func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	$anim.play("collect")
	

func _on_anim_animation_finished() -> void:
	queue_free()
