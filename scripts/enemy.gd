extends CharacterBody2D

const MAX_SPEED = 50.0
const ACCEL = 500.0
const FRICTION = 300.0

var player: CharacterBody2D = null
var player_chase := false

var health = 100.0
var player_inattack_zone= false
var can_take_damage = true

@onready var anim = $AnimatedSprite2D

func _ready() -> void:
	var rand_anim = randi_range(1,3)
	if rand_anim == 1:
		anim.play("front_idle")
	else:
		if rand_anim == 2:
			anim.play("side_idle")
			anim.flip_h = false
		else:
			anim.play("side_idle")
			anim.flip_h = true

func _physics_process(delta: float) -> void:
	deal_with_damage()
	
	if player_chase and player != null:
		var direction = (player.position - position).normalized()
		velocity += direction * ACCEL * delta
		velocity = velocity.limit_length(MAX_SPEED)
		
		update_animation(velocity)
	else:
		if velocity.length() > (FRICTION * delta):
			velocity -= velocity.normalized() * (FRICTION * delta)
		else:
			velocity = Vector2.ZERO
		
		# Si el enemigo se detuvo por completo, ponemos la animación de reposo.
		if velocity.is_zero_approx():
			play_idle_animation()

	# Movemos al enemigo usando la velocidad calculada.
	move_and_slide()

# La lógica de animación ahora usa la "velocity" para ser más precisa.
func update_animation(current_velocity: Vector2):
	# Si el enemigo no se está moviendo, no hacemos nada aquí.
	if current_velocity.is_zero_approx():
		return

	# Comparamos si el movimiento es más horizontal o vertical.
	if abs(current_velocity.x) > abs(current_velocity.y):
		anim.play("side_walk")
		# La dirección del sprite (izquierda/derecha) depende del signo de la velocidad en x.
		anim.flip_h = current_velocity.x < 0
	else:
		if current_velocity.y > 0:
			anim.play("front_walk")
		else:
			anim.play("back_walk")

func play_idle_animation():
	var current_animation = anim.animation
	
	if "walk" in current_animation:
		var idle_animation = current_animation.replace("walk", "idle")
		anim.play(idle_animation)

# --- Las funciones de detección no cambian ---
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		player_chase = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		# Ya no ponemos player en null inmediatamente, para que el enemigo
		# sepa dónde estaba por última vez, pero dejamos de perseguirlo.
		player_chase = false

func enemy():
	pass

func _on_enemy_hitbox_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		player_inattack_zone = true

func _on_enemy_hitbox_body_exited(body: Node2D) -> void:
	if body.has_method("player"):
		player_inattack_zone = false

func deal_with_damage():
	if player_inattack_zone and Global.player_current_attack:
		if can_take_damage:
			health -= 20
			$take_damage_cooldown.start()
			can_take_damage = false
			print("Slime health: ", health)
			if health <= 0:
				self.queue_free()


func _on_take_damage_cooldown_timeout() -> void:
	can_take_damage = true
