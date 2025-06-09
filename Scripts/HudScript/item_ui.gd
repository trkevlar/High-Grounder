extends Control

@onready var skill_container: Control = self
@onready var tooltip_panel: PanelContainer = $PanelContainer
@onready var tooltip_label: Label = $PanelContainer/Label

@export var player_path: NodePath
var playera: Node
var skills: Dictionary = {}  # SkillType -> PlayerSkill

func _ready() -> void:
	playera = get_node(player_path)
	playera.connect("skill_added", _on_skill_added)
	
	# Bersihkan UI sebelum memuat ulang
	for icon in skill_container.get_children():
		if icon != tooltip_panel:
			icon.visible = false
	
	# Muat ulang skills yang ada
	for skill_type in playera.active_skills:
		_on_skill_added(skill_type)
	
	for icon in skill_container.get_children():
		if icon == tooltip_panel:
			continue
		icon.visible = false
		icon.connect("mouse_entered", _on_icon_hover.bind(icon))
		icon.connect("mouse_exited", _on_icon_unhover)

func _on_skill_added(skill: PlayerSkill) -> void:
	var icon_name: String = PlayerSkill.SkillType.keys()[skill.type]
	print("Skill Added:", icon_name)
	var icon: Control = skill_container.get_node_or_null(icon_name)
	if icon:
		print("Ikon ditemukan:", icon.name)
		icon.visible = true
		skills[skill.type] = skill
	else:
		push_warning("Ikon tidak ditemukan di scene: " + icon_name)


func _on_icon_hover(icon: Control) -> void:
	var skill_type = _skill_type_from_icon(icon.name)
	var skill: PlayerSkill = skills.get(skill_type, null)
	if skill:
		tooltip_label.text = _build_tooltip(skill)
		tooltip_panel.global_position = get_global_mouse_position() + Vector2(16, 16)
		tooltip_panel.visible = true

func _on_icon_unhover() -> void:
	tooltip_panel.visible = false

func _process(_delta: float) -> void:
	if tooltip_panel.visible:
		tooltip_panel.global_position = get_global_mouse_position() + Vector2(16, 16)

# --- Helpers ---
func _skill_type_from_icon(icon_name: String) -> PlayerSkill.SkillType:
	# Apakah string ikon ada di enum?
	if PlayerSkill.SkillType.has(icon_name):
		return PlayerSkill.SkillType[icon_name]   # ✅ langsung ambil nilai enum-nya

	# Fallback (nama ikon tak cocok enum mana pun)
	push_warning("Skill icon_name not found: " + icon_name)
	return PlayerSkill.SkillType.LIFE_STEAL

func _build_tooltip(skill: PlayerSkill) -> String:
	match skill.type:
		PlayerSkill.SkillType.LIFE_STEAL:  return "Life-steal: %.0f%% dari damage" % (skill.value * 100)
		PlayerSkill.SkillType.STRENGTH_UP: return "Damage +%.0f" % skill.value
		PlayerSkill.SkillType.HEALTH_UP:   return "Max HP +%.0f" % skill.value
		PlayerSkill.SkillType.SPEED_UP:    return "Speed +%.0f%%" % (skill.value * 100)
		PlayerSkill.SkillType.DAMAGE_RESISTANCE: return "Damage Resistance %.0f%%" % (skill.value * 100)
		_:                                 return "Unknown Skill"
