# bagian boss

extends ProgressBar

@export var target_path: NodePath
var target        

@onready var tick_timer: Timer        = $Timer          # satu-satunya Timer
@onready var damage_bar: ProgressBar  = $DamageBar
@onready var name_label: Label = $NameLabel


var parent
var maxValueAmount
var minValueAmount
var last_health := 0

const DELAY := 1.0                     # detik menunggu sebelum bar merah turun
var delay_remaining := 0.0             # hitung mundur

func _ready() -> void:
	target = get_node(target_path)
	maxValueAmount = target.healthMax
	minValueAmount = target.healthMin
	
	name_label.text = target.name + " (Boss)"
	
	max_value = maxValueAmount
	value     = maxValueAmount
	damage_bar.max_value = maxValueAmount
	damage_bar.value     = maxValueAmount
	last_health = maxValueAmount

	tick_timer.wait_time = 0.05        # kecepatan turun
	tick_timer.one_shot  = false
	tick_timer.stop()

func _process(delta: float) -> void:
	if !is_instance_valid(target):
		queue_free(); 
		return

	var cur: int = target.health
	if cur != last_health:
		_set_health(cur)
		last_health = cur

	# hitung mundur delay
	if delay_remaining > 0.0:
		delay_remaining -= delta
		if delay_remaining <= 0.0:
			tick_timer.start()         # mulai turunkan bar merah

	visible = (cur < maxValueAmount and cur > minValueAmount)

func _set_health(new_health: int) -> void:
	var prev := value
	value = clamp(new_health, 0, maxValueAmount)

	if value <= 0:
		queue_free()
		return

	if value < prev:                   # KENA DAMAGE
		delay_remaining = DELAY        # reset tunggu 1 detik
		tick_timer.stop()              # hentikan penurunan kalau masih jalan
	else:                              # HEAL
		damage_bar.value = value

func _on_timer_timeout() -> void:
	var diff := damage_bar.value - value
	if diff <= 0:
		tick_timer.stop()              # sudah sejajar
	else:
		damage_bar.value -= min(diff, 6)   
