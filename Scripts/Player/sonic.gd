class_name Player
extends CharacterBody2D

signal state_changed(new_state: State, old_state: State)
signal died
signal rings_changed(count: int)
signal super_started
signal super_ended
signal shield_gained
signal shield_lost
signal emerald_collected(count: int)

enum State { GROUND, AIR, ROLL, SPINDASH, PEELOUT, HURT, DEAD, BAR, TRANSFORM, GLIDE, GLIDE_SLIDE, FLY, STOMP }
enum CameraStyle { SONIC_1, SONIC_2, SONIC_CD }
enum CollisionMode { NORMAL, CROUCH, ROLL, JUMP }
enum FlyLoop { NONE, RISE, FALL }

@export_group("Nodes")
@export var animation_player: AnimationPlayer
@export var super_animation_player: AnimationPlayer
@export var palette_player: AnimationPlayer
@export var jump_sound: AudioStreamPlayer
@export var spindash_sound: AudioStreamPlayer
@export var hurt_sound: AudioStreamPlayer
@export var death_sound: AudioStreamPlayer
@export var camera: Camera2D

@export_group("Sounds")
@export var roll_sound: AudioStreamPlayer
@export var spindash_release_sound: AudioStreamPlayer
@export var peelout_charge_sound: AudioStreamPlayer
@export var peelout_release_sound: AudioStreamPlayer
@export var skid_sound: AudioStreamPlayer
@export var bar_grab_sound: AudioStreamPlayer
@export var rings_lost_sound: AudioStreamPlayer
@export var super_transform_sound: AudioStreamPlayer
@export var super_end_sound: AudioStreamPlayer
@export var glide_sound: AudioStreamPlayer
@export var glide_slide_sound: AudioStreamPlayer
@export var fly_flap_sound: AudioStreamPlayer
@export var fly_fall_sound: AudioStreamPlayer
@export var fly_tired_sound: AudioStreamPlayer
@export var shoot_sound: AudioStreamPlayer
@export var stomp_sound: AudioStreamPlayer
@export var stomp_land_sound: AudioStreamPlayer
@export var roll_deflect_sound: AudioStreamPlayer
@export var shield_sound: AudioStreamPlayer

@export_group("Shield")
@export var shield_scene: PackedScene = preload("res://Entities/Objects/ShieldRegular.tscn")
@export var shield_z_index := 3
@export var shield_offset := Vector2.ZERO

@export_group("Abilities")
@export var spindash_enabled := true
@export var peelout_enabled := true
@export var glide_enabled := false
@export var fly_enabled := false
@export var stomp_enabled := false
@export var arrow_enabled := false

@export_group("Arrow")
@export var arrow_scene: PackedScene
@export var input_shoot: StringName = &"shoot"
@export var arrow_spawn_offset := Vector2(16.0, -4.0)
@export var arrow_cooldown := 0.35
@export var arrow_max_active := 3
@export var arrow_debug_print := false
@export_subgroup("Knockback")
@export var arrow_knockback_enabled := true
@export var arrow_knockback := 150.0
@export var arrow_knockback_air := 90.0
@export var arrow_knockback_lock := 0.0
@export var arrow_knockback_anim_time := 0.3

@export_group("Glide")
@export var glide_start_speed := 240.0
@export var glide_acceleration := 56.25
@export var glide_max_speed := 960.0
@export var glide_turn_speed_deg := 84.375
@export var glide_gravity := 450.0
@export var glide_fall_speed := 30.0
@export var glide_slide_friction := 337.5
@export var glide_release_speed_factor := 0.25
@export var glide_anim_speed := 1.0

@export_group("Fly")
@export var fly_gravity := 112.5
@export var fly_flap_impulse := 120.0
@export var fly_max_time := 8.0
@export var fly_loop_min_fall_speed := 0.0
@export var fly_anim_speed := 1.0

@export_group("Tails")
@export var has_tails := false
@export var tails_sprite: Sprite2D
@export var tails_animation_player: AnimationPlayer
@export var tails_anim_idle: StringName = &"idle"
@export var tails_anim_jump: StringName = &"jump"
@export var tails_visible_animations: Array[StringName] = [&"idle", &"wait", &"wait_loop", &"walk", &"run", &"roll", &"peelout", &"skid", &"push", &"balance", &"look_up", &"look_down", &"spindash", &"spring", &"arrow_knockback"]
@export var tails_idle_start_position := Vector2.ZERO
@export var tails_jump_start_position := Vector2.ZERO
@export var tails_behind_skin := true
@export var tails_anim_speed := 1.0
@export_subgroup("Jump")
@export var tails_circle_radius := 8.0
@export var tails_jump_angle_offset_deg := 0.0
@export var tails_jump_follow_speed := 20.0
@export var tails_jump_min_speed := 30.0
@export var tails_jump_flip_upright := true

@export_group("Stomp")
@export var input_stomp: StringName = &"stomp"
@export var stomp_speed := 960.0
@export var stomp_cancel_horizontal := true
@export var stomp_air_control := false
@export var stomp_bounce_speed := 0.0
@export var stomp_anim_speed := 1.0

@export_group("Roll Deflect")
@export var roll_deflect_enabled := false
@export var roll_deflect_all := false
@export var roll_deflect_scenes: Array[PackedScene] = []
@export var roll_deflect_knockback := Vector2(180.0, -200.0)
@export var roll_deflect_grace := 0.25
@export var roll_deflect_ball_window := 0.12
@export var roll_deflect_protect_fall := true
@export var roll_deflect_debug := false

@export_group("Score")
@export var badnik_chain_points: Array[int] = [100, 200, 500, 1000]

@export_group("Score Popup")
@export var score_popup_scene: PackedScene = preload("res://Entities/Hud/ScorePopup.tscn")
@export var score_popup_min_points := 100
@export var score_popup_offset := Vector2(0.0, -16.0)

@export_group("Collision")
@export var col_normal: CollisionShape2D
@export var col_crouch: CollisionShape2D
@export var col_roll: CollisionShape2D
@export var col_jump: CollisionShape2D

@export_subgroup("Box Collision")
@export var box_collision_enabled := true
@export var stand_box_size := Vector2.ZERO
@export var crouch_box_size := Vector2.ZERO
@export var crouch_height_ratio := 0.6
@export var box_feet_y := 0.0
@export var align_sensors_to_box := true
@export var sensor_edge_inset := 1.0

@export_group("Input")
@export var input_left: StringName = &"ui_left"
@export var input_right: StringName = &"ui_right"
@export var input_up: StringName = &"ui_up"
@export var input_down: StringName = &"ui_down"
@export var input_jump: StringName = &"ui_accept"

@export_group("Animations")
@export var anim_idle: StringName = &"idle"
@export var anim_wait: StringName = &"wait"
@export var anim_wait_loop: StringName = &"wait_loop"
@export var anim_walk: StringName = &"walk"
@export var anim_run: StringName = &"run"
@export var anim_roll: StringName = &"roll"
@export var anim_peelout: StringName = &"peelout"
@export var anim_spring: StringName = &"spring"
@export var anim_look_up: StringName = &"look_up"
@export var anim_look_down: StringName = &"look_down"
@export var anim_spindash: StringName = &"spindash"
@export var anim_die: StringName = &"die"
@export var anim_damage: StringName = &"damage"
@export var anim_skid: StringName = &"skid"
@export var anim_push: StringName = &"push"
@export var anim_balance: StringName = &"balance"
@export var anim_win: StringName = &"win"
@export var anim_hang: StringName = &"hang"
@export var anim_super: StringName = &"super"
@export var anim_glide: StringName = &"glide"
@export var anim_glide_fall: StringName = &"glide_fall"
@export var anim_glide_slide: StringName = &"glide_slide"
@export var anim_fly: StringName = &"fly"
@export var anim_fly_tired: StringName = &"fly_tired"
@export var anim_arrow_knockback: StringName = &"arrow_knockback"
@export var anim_stomp: StringName = &"stomp"
@export var run_speed_threshold := 300.0
@export var idle_speed_threshold := 1.0
@export var skid_min_speed := 240.0
@export var push_max_speed := 30.0
@export var push_check_distance := 2.0
@export var roll_skin_offset := 8.0
@export var spindash_anim_scale_min := 1.0
@export var spindash_anim_scale_max := 3.0
@export var peelout_anim_scale_min := 1.0
@export var peelout_anim_scale_max := 3.0
@export var walk_anim_reference := 150.0
@export var run_anim_reference := 360.0
@export var roll_anim_reference := 360.0
@export var anim_speed_min := 0.3
@export var anim_speed_max := 3.0
@export var ghost_blink_enabled := true
@export var ghost_blink_interval := 0.05
@export var genesis_angle_snap := false
@export_range(1.0, 90.0, 0.5) var genesis_angle_step_deg := 45.0
@export_range(0.0, 90.0, 0.5) var genesis_angle_threshold_deg := 35.0
@export var fall_animation_enabled := false
@export var anim_fall: StringName = &"fall"
@export_subgroup("Angle 45 Animations")
@export var angle45_anims_enabled := true
@export var anim_walk_45: StringName = &"walk45"
@export var anim_run_45: StringName = &"run45"
@export var anim_peelout_45: StringName = &"peelout45"
@export_range(0.0, 90.0, 0.5) var angle45_min_deg := 22.5
@export_range(0.0, 90.0, 0.5) var angle45_max_deg := 67.5
@export_range(-180.0, 180.0, 45.0) var angle45_art_angle_deg := -45.0

@export_group("Ground")
@export var acceleration := 168.75
@export var deceleration := 1800.0
@export var friction := 168.75
@export var top_speed := 360.0
@export var max_ground_speed := 960.0
@export var slope_factor := 450.0
var _ghost_blink_time := 0.0

@export_group("Slopes and Walls")
@export var slip_speed_threshold := 150.0
@export var slip_min_angle_deg := 45.0
@export var fall_min_angle_deg := 90.0
@export var control_lock_time := 0.5
@export var max_floor_angle_deg := 60.0
@export var sensor_length := 20.0
@export var sensor_lift := 8.0
@export var sensor_angle_tolerance_deg := 45.0
@export var skin_rotation_speed := 20.0
@export var skin_air_rotation_speed := 6.0
@export var max_step_distance := 4.0
@export var max_angle_step_deg := 50.0
@export var max_depenetration := 6.0
@export var depenetration_iterations := 3

@export_group("Air")
@export var air_acceleration := 337.5
@export var gravity_strength := 787.5
@export var max_fall_speed := 960.0
@export var air_drag := 0.96875
@export var air_drag_speed_limit := 240.0

@export_group("Jump")
@export var jump_force := 390.0
@export var jump_release_speed := 240.0

@export_group("Landing")
@export var land_flat_angle_deg := 23.0
@export var land_slope_angle_deg := 45.0

@export_group("Roll")
@export var roll_min_speed := 61.8
@export var roll_friction := 84.375
@export var roll_deceleration := 450.0
@export var roll_slope_up := 281.25
@export var roll_slope_down := 1125.0
@export var unroll_speed := 30.0

@export_group("Spindash")
@export var crouch_max_speed := 30.0
@export var spindash_base_speed := 480.0
@export var spindash_charge_gain := 2.0
@export var spindash_max_charge := 8.0
@export var spindash_speed_per_charge := 30.0
@export var spindash_decay := 0.03125
@export var spindash_pitch_range := 0.5

@export_group("Peelout")
@export var peelout_charge_time := 0.5
@export var peelout_speed := 720.0
@export var peelout_anim_min_speed := 650.0
@export var peelout_run_fraction := 0.5

@export_group("Bar")
@export var bar_launch_speed := 780.0
@export var bar_hang_offset := Vector2.ZERO
@export var bar_skin_offset := Vector2.ZERO
@export var bar_hang_angle_deg := 0.0
@export var bar_regrab_delay := 0.25
@export var bar_anim_reference := 8.0
@export var bar_grab_wall_min_angle_deg := 45.0

@export_group("Super")
@export var super_texture: Texture2D
@export var super_transform_delay := 0.5
@export var super_speed_multiplier := 1.6
@export var super_acceleration_multiplier := 2.0
@export var super_ring_drain_interval := 1.0
@export var ghost_count := 3
@export var ghost_frame_gap := 4
@export var ghost_alpha := 0.3
@export_subgroup("Palette Animations")
@export var pal_normal: StringName = &"normal"
@export var pal_super: StringName = &"super"
@export var pal_normal_to_super: StringName = &"normal_to_super"
@export var pal_super_to_normal: StringName = &"super_to_normal"

@export_group("Emeralds")
@export var super_input_enabled := true
@export var input_super: StringName = &"super"
@export var super_min_rings := 50
@export var super_requires_all_emeralds := true
@export var super_requires_jump := true
@export var super_in_air_only := true

@export_group("Camera")
@export var camera_enabled := true
@export var camera_style: CameraStyle = CameraStyle.SONIC_CD
@export var camera_debug_draw := false
@export var camera_focus_offset := Vector2.ZERO
@export var camera_pixel_snap := false
@export_subgroup("Scroll")
@export var camera_border_left := 10.0
@export var camera_border_right := 10.0
@export var camera_max_scroll_x := 960.0
@export var camera_ground_scroll_slow := 360.0
@export var camera_ground_scroll_fast := 960.0
@export var camera_fast_speed_threshold := 480.0
@export var camera_air_border_up := 32.0
@export var camera_air_border_down := 32.0
@export var camera_air_scroll_speed := 960.0
@export_subgroup("Look Up and Down")
@export var look_enabled := true
@export var look_delay := 1.0
@export var look_delay_sonic2 := 2.0
@export var look_double_tap_window := 0.2667
@export var look_up_distance := 104.0
@export var look_down_distance := 88.0
@export var look_scroll_speed := 120.0
@export_subgroup("Extended Camera")
@export var extended_camera_enabled := true
@export var extended_camera_distance := 64.0
@export var extended_camera_speed := 120.0
@export var extended_camera_min_speed := 360.0
@export var extended_camera_charge_delay := 0.2667
@export_subgroup("Spindash Lag")
@export var spindash_lag_enabled := true
@export var spindash_lag_frames := 32
@export var spindash_lag_blank_history := true

@export_group("Spring")
@export var spring_lock_time := 0.25

@export_group("Damage")
@export var hurt_knockback := Vector2(120.0, -240.0)
@export var hurt_gravity := 675.0
@export var invincibility_time := 2.0
@export var blink_interval := 0.08
@export var die_jump_speed := 420.0
@export var die_gravity := 787.5

@export_group("Rings")
@export var lost_ring_scene: PackedScene
@export var max_scattered_rings := 32
@export var scatter_speed := 300.0

@export_group("Death")
@export var respawn_delay := 3.0
@export var kill_y := 2000.0
@export var uses_lives := true
@export_file("*.tscn") var title_scene := "res://Scenes/Presentation/Title_Screen.tscn"

@export_group("Act Clear")
@export var act_brake_multiplier := 4.0
@export var camera_lock_smoothing := 4.0

@export_group("Debug")
@export var debug_draw := false

var state: State = State.AIR
var ground_speed := 0.0
var badnik_chain := 0
var ground_angle := 0.0
var facing := 1
var control_lock := 0.0
var spindash_charge := 0.0
var rings := 0
var emeralds: int:
	get:
		return Emeralds.count
	set(value):
		Emeralds.set_count(value)
var is_jumping := false
var is_spring := false
var is_crouching := false
var is_looking_up := false
var is_skidding := false
var is_pushing := false
var is_balancing := false
var is_super := false
var has_shield := false
var act_cleared := false
var bar_launch := false
var stomp_hit_window := 0.0

var _dir := 0
var _up := false
var _down := false
var _jump_pressed := false
var _jump_held := false
var _shoot_pressed := false
var _stomp_pressed := false
var _super_pressed := false
var _deflect_fall := false
var _deflect_grace := 0.0
var _ball_timer := 0.0
var _arrow_timer := 0.0
var _arrow_kb_timer := 0.0
var _skin_angle := 0.0
var _skin_base_position := Vector2.ZERO
var _body_center := Vector2.ZERO
var _col_mode: CollisionMode = CollisionMode.NORMAL
var _col_nodes: Array[CollisionShape2D] = []
var _invincible := 0.0
var _peelout_timer := 0.0
var _current_anim: StringName = &""
var _air_hold_anim: StringName = &""
var _air_hold_scale := 1.0
var _air_hold_offset := Vector2.ZERO
var _left: Node2D
var _right: Node2D
var _sensors: Array[Node2D] = []
var _rays: Array[PhysicsRayQueryParameters2D] = []
var _hit := KinematicCollision2D.new()
var _cam_pos := Vector2.ZERO
var _cam_history: Array[Vector2] = []
var _cam_lag_frames := 0
var _look_offset := 0.0
var _look_up_timer := 0.0
var _look_down_timer := 0.0
var _extended_offset := 0.0
var _charge_time := 0.0
var _up_prev := false
var _down_prev := false
var _up_since_press := 999.0
var _down_since_press := 999.0
var _up_double := false
var _down_double := false
var _cam_focus_point := Vector2.ZERO
var _cam_debug_shown := false
var _cam_locked := false
var _cam_lock_point := Vector2.ZERO
var _bar: Node2D
var _bar_spin := 0.0
var _bar_offset := Vector2.ZERO
var _bar_cooldown := 0.0
var _super_pending := 0.0
var _super_drain_timer := 0.0
var _normal_texture: Texture2D
var _ghosts: Array[Sprite2D] = []
var _ghost_history: Array[Dictionary] = []
var _glide_angle := 0.0
var _glide_speed := 0.0
var _glide_fall := false
var _fly_time := 0.0
var _fly_tired := false
var _fly_loop_mode: FlyLoop = FlyLoop.NONE
var _tails_angle := 0.0
var _tails_anim: StringName = &""
var _angle_anim_active := false
var _angle_base_anim: StringName = &""
var _angle_diag := 0.0
var _angle_rotation := 0.0
var _shield_node: Node2D


@onready var skin: Node2D = $Skin
@onready var sensor_a: Node2D = $ThingToKnowAngle1
@onready var sensor_b: Node2D = $ThingToKnowAngle2


func _ready() -> void:
	add_to_group(&"player")
	_skin_base_position = skin.position
	_normal_texture = skin.get("texture") as Texture2D
	_setup_collisions()
	motion_mode = MOTION_MODE_GROUNDED
	floor_stop_on_slope = false
	floor_constant_speed = true
	floor_block_on_wall = false
	floor_snap_length = 0.0
	floor_max_angle = deg_to_rad(max_floor_angle_deg)
	for s: Node2D in [sensor_a, sensor_b]:
		if s is CollisionShape2D:
			(s as CollisionShape2D).set_deferred("disabled", true)
	_left = sensor_a if sensor_a.position.x <= sensor_b.position.x else sensor_b
	_right = sensor_b if _left == sensor_a else sensor_a
	_sensors = [_left, _right]
	for i in 2:
		var q := PhysicsRayQueryParameters2D.new()
		q.exclude = [get_rid()]
		_rays.append(q)
	if animation_player == null:
		animation_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if palette_player == null:
		palette_player = get_node_or_null("PaletteAnimationPlayer") as AnimationPlayer
	if super_animation_player == null:
		super_animation_player = get_node_or_null("SuperAnimationPlayer") as AnimationPlayer
	jump_sound = _find_sound(jump_sound, "JumpSound")
	spindash_sound = _find_sound(spindash_sound, "SpindashSound")
	hurt_sound = _find_sound(hurt_sound, "HurtSound")
	death_sound = _find_sound(death_sound, "DeathSound")
	roll_sound = _find_sound(roll_sound, "RollSound")
	spindash_release_sound = _find_sound(spindash_release_sound, "SpindashReleaseSound")
	peelout_charge_sound = _find_sound(peelout_charge_sound, "PeeloutChargeSound")
	peelout_release_sound = _find_sound(peelout_release_sound, "PeeloutReleaseSound")
	skid_sound = _find_sound(skid_sound, "SkidSound")
	bar_grab_sound = _find_sound(bar_grab_sound, "BarGrabSound")
	rings_lost_sound = _find_sound(rings_lost_sound, "RingsLostSound")
	super_transform_sound = _find_sound(super_transform_sound, "SuperTransformSound")
	super_end_sound = _find_sound(super_end_sound, "SuperEndSound")
	glide_sound = _find_sound(glide_sound, "GlideSound")
	glide_slide_sound = _find_sound(glide_slide_sound, "GlideSlideSound")
	fly_flap_sound = _find_sound(fly_flap_sound, "FlyFlapSound")
	fly_fall_sound = _find_sound(fly_fall_sound, "FlyFallSound")
	fly_tired_sound = _find_sound(fly_tired_sound, "FlyTiredSound")
	shoot_sound = _find_sound(shoot_sound, "ShootSound")
	stomp_sound = _find_sound(stomp_sound, "StompSound")
	stomp_land_sound = _find_sound(stomp_land_sound, "StompLandSound")
	roll_deflect_sound = _find_sound(roll_deflect_sound, "RollDeflectSound")
	shield_sound = _find_sound(shield_sound, "ShieldSound")
	if shield_sound == null:
		shield_sound = _create_shield_sound()
	if fly_flap_sound != null:
		fly_flap_sound.finished.connect(_on_fly_loop_finished)
	if fly_fall_sound != null:
		fly_fall_sound.finished.connect(_on_fly_loop_finished)
	if animation_player != null:
		animation_player.animation_finished.connect(_on_animation_finished)
	if super_animation_player != null:
		super_animation_player.active = false
		super_animation_player.animation_finished.connect(_on_animation_finished)
	if palette_player != null:
		palette_player.animation_finished.connect(_on_palette_finished)
	if camera == null:
		camera = get_node_or_null("Camera") as Camera2D
	_setup_camera()
	_play_palette(pal_normal)
	_setup_tails()
	_ensure_shoot_action()
	_ensure_stomp_action()
	queue_redraw()


func _draw() -> void:
	if not debug_draw:
		return
	for s: Node2D in [sensor_a, sensor_b]:
		draw_line(s.position, s.position + Vector2.DOWN * sensor_length, Color.YELLOW, 1.0)


func _physics_process(delta: float) -> void:
	_read_input()
	_deflect_grace = maxf(_deflect_grace - delta, 0.0)
	stomp_hit_window = maxf(stomp_hit_window - delta, 0.0)
	if state != State.DEAD and global_position.y > kill_y:
		die()
	control_lock = maxf(control_lock - delta, 0.0)
	_invincible = maxf(_invincible - delta, 0.0)
	_deflect_grace = maxf(_deflect_grace - delta, 0.0)
	if _is_ball_state():
		_ball_timer = roll_deflect_ball_window
	else:
		_ball_timer = maxf(_ball_timer - delta, 0.0)
	_bar_cooldown = maxf(_bar_cooldown - delta, 0.0)
	_arrow_timer = maxf(_arrow_timer - delta, 0.0)
	_arrow_kb_timer = maxf(_arrow_kb_timer - delta, 0.0)
	_update_arrow()
	_update_super_timer(delta)
	_update_super_drain(delta)
	_update_skid()
	_update_push()
	if _dir != 0 and control_lock <= 0.0 and not is_skidding and (state == State.GROUND or state == State.AIR or state == State.FLY):
		facing = _dir

	match state:
		State.GROUND: _process_ground(delta)
		State.AIR: _process_air(delta)
		State.ROLL: _process_roll(delta)
		State.SPINDASH: _process_spindash(delta)
		State.PEELOUT: _process_peelout(delta)
		State.HURT: _process_hurt(delta)
		State.DEAD: _process_dead(delta)
		State.BAR: _process_bar(delta)
		State.TRANSFORM: _process_transform(delta)
		State.GLIDE: _process_glide(delta)
		State.GLIDE_SLIDE: _process_glide_slide(delta)
		State.FLY: _process_fly(delta)
		State.STOMP: _process_stomp(delta)

	_update_collision()
	_update_balance()
	_update_animation()
	_update_skin(delta)
	_update_shield()
	_update_ghosts(delta)
	_update_tails(delta)
	_update_camera(delta)


func _setup_collisions() -> void:
	if col_normal == null:
		col_normal = get_node_or_null("Col") as CollisionShape2D
	if col_crouch == null:
		col_crouch = get_node_or_null("ColCrouch") as CollisionShape2D
	if box_collision_enabled:
		_setup_box_collisions()
	_body_center = col_normal.position
	_col_nodes = [
		col_normal,
		col_crouch if col_crouch != null else col_normal,
		col_roll if col_roll != null else col_normal,
		col_jump if col_jump != null else col_normal,
	]
	_apply_collision(CollisionMode.NORMAL)


func _setup_box_collisions() -> void:
	var stand := stand_box_size
	if stand == Vector2.ZERO:
		stand = _shape_size(col_normal.shape)
	var crouch := crouch_box_size
	if crouch == Vector2.ZERO:
		crouch = Vector2(stand.x, stand.y * crouch_height_ratio)

	var x := col_normal.position.x
	_fit_box(col_normal, stand, x)
	if col_crouch != null:
		_fit_box(col_crouch, crouch, x)
	else:
		push_warning("Player: ColCrouch não encontrado.")

	if align_sensors_to_box:
		var half := maxf(stand.x * 0.5 - sensor_edge_inset, 0.0)
		var a_is_left := sensor_a.position.x <= sensor_b.position.x
		sensor_a.position.x = -half if a_is_left else half
		sensor_b.position.x = half if a_is_left else -half


func _fit_box(col: CollisionShape2D, size: Vector2, x: float) -> void:
	var box := RectangleShape2D.new()
	box.size = size
	col.shape = box
	col.rotation = 0.0
	col.position = Vector2(x, box_feet_y - size.y * 0.5)


func _shape_size(shape: Shape2D) -> Vector2:
	if shape is CapsuleShape2D:
		var c := shape as CapsuleShape2D
		return Vector2(c.radius * 2.0, c.height)
	if shape is RectangleShape2D:
		return (shape as RectangleShape2D).size
	if shape is CircleShape2D:
		return Vector2.ONE * (shape as CircleShape2D).radius * 2.0
	return Vector2(20.0, 40.0)


func _desired_collision_mode() -> CollisionMode:
	match state:
		State.GROUND:
			return CollisionMode.CROUCH if is_crouching else CollisionMode.NORMAL
		State.ROLL, State.SPINDASH:
			return CollisionMode.ROLL
		State.AIR:
			return CollisionMode.JUMP if is_jumping else CollisionMode.NORMAL
		State.GLIDE, State.STOMP:
			return CollisionMode.JUMP
		State.GLIDE_SLIDE:
			return CollisionMode.CROUCH
	return CollisionMode.NORMAL


func _update_collision() -> void:
	var mode := _desired_collision_mode()
	if mode != _col_mode:
		_apply_collision(mode)


func _apply_collision(mode: CollisionMode) -> void:
	_col_mode = mode
	var active := _col_nodes[mode]
	for n in _col_nodes:
		n.set_deferred("disabled", n != active)


func _active_col() -> CollisionShape2D:
	return _col_nodes[_col_mode]


func _focus_origin() -> Vector2:
	return to_global(_body_center)


func _read_input() -> void:
	if act_cleared:
		_dir = 0
		_up = false
		_down = false
		_jump_pressed = false
		_jump_held = false
		_shoot_pressed = false
		_stomp_pressed = false
		_super_pressed = false
		return
	_dir = int(signf(Input.get_axis(input_left, input_right)))
	_up = Input.is_action_pressed(input_up)
	_down = Input.is_action_pressed(input_down)
	_jump_pressed = Input.is_action_just_pressed(input_jump)
	_jump_held = Input.is_action_pressed(input_jump)
	_shoot_pressed = InputMap.has_action(input_shoot) and Input.is_action_just_pressed(input_shoot)
	_stomp_pressed = InputMap.has_action(input_stomp) and Input.is_action_just_pressed(input_stomp)
	_super_pressed = super_input_enabled and InputMap.has_action(input_super) and Input.is_action_just_pressed(input_super)


func is_vulnerable() -> bool:
	return not act_cleared and not is_super and _invincible <= 0.0 \
			and state != State.HURT and state != State.DEAD \
			and state != State.TRANSFORM and state != State.STOMP


func is_dead() -> bool:
	return state == State.DEAD


func finish_act() -> void:
	act_cleared = true


func lock_camera_to(point: Vector2) -> void:
	_cam_locked = true
	_cam_lock_point = point


func _brake_mult() -> float:
	return act_brake_multiplier if act_cleared else 1.0


func _super_mult() -> float:
	return super_speed_multiplier if is_super else 1.0


func _top_speed() -> float:
	return top_speed * _super_mult()


func _acceleration() -> float:
	return acceleration * (super_acceleration_multiplier if is_super else 1.0)


func _air_acceleration() -> float:
	return air_acceleration * (super_acceleration_multiplier if is_super else 1.0)


func is_attacking() -> bool:
	return is_super or is_jumping or state == State.ROLL or state == State.SPINDASH or state == State.GLIDE or state == State.GLIDE_SLIDE or state == State.STOMP


func add_rings(amount: int = 1) -> void:
	rings += amount
	rings_changed.emit(rings)


func has_all_emeralds() -> bool:
	return Emeralds.is_full()


func add_emerald(amount: int = 1) -> void:
	Emeralds.add(amount)
	emerald_collected.emit(Emeralds.count)


func can_super() -> bool:
	if is_super or _super_pending > 0.0:
		return false
	if state == State.DEAD or state == State.TRANSFORM or state == State.HURT:
		return false
	if super_requires_all_emeralds and not has_all_emeralds():
		return false
	if rings < super_min_rings:
		return false
	if super_in_air_only and state != State.AIR:
		return false
	if super_requires_jump and not is_jumping:
		return false
	return true


func _try_super_input() -> bool:
	if not _super_pressed or not can_super():
		return false
	start_super()
	return true


func give_shield() -> void:
	if state == State.DEAD:
		return
	_play_sound(shield_sound)
	if has_shield:
		return
	has_shield = true
	if shield_scene != null:
		_shield_node = shield_scene.instantiate() as Node2D
		if _shield_node != null:
			_shield_node.z_index = shield_z_index
			add_child(_shield_node)
			_update_shield()
	shield_gained.emit()


func remove_shield() -> void:
	if not has_shield:
		return
	has_shield = false
	if _shield_node != null:
		_shield_node.queue_free()
		_shield_node = null
	shield_lost.emit()


func _update_shield() -> void:
	if _shield_node == null:
		return
	_shield_node.global_rotation = 0.0
	_shield_node.global_position = skin.global_position + shield_offset
	_shield_node.visible = state != State.DEAD and state != State.TRANSFORM and not is_super


func hit_badnik() -> int:
	var airborne := state == State.AIR or state == State.GLIDE or state == State.FLY or state == State.STOMP
	if not airborne:
		badnik_chain = 0
	var pts: int = badnik_chain_points[mini(badnik_chain, badnik_chain_points.size() - 1)]
	badnik_chain += 1
	Score.add(pts)
	spawn_score_popup(pts)
	return pts


func spawn_score_popup(points: int, at: Vector2 = Vector2.INF) -> void:
	if points < score_popup_min_points or score_popup_scene == null:
		return
	var popup := score_popup_scene.instantiate() as ScorePopup
	if popup == null:
		push_warning("Player: score_popup_scene não tem o script ScorePopup na raiz.")
		return
	popup.points = points
	get_parent().add_child(popup)
	var origin := _focus_origin() if at == Vector2.INF else at
	popup.global_position = origin + score_popup_offset


func set_arrow_enabled(value: bool) -> void:
	arrow_enabled = value


func toggle_arrow() -> void:
	arrow_enabled = not arrow_enabled


func set_arrow_knockback_enabled(value: bool) -> void:
	arrow_knockback_enabled = value


func toggle_arrow_knockback() -> void:
	arrow_knockback_enabled = not arrow_knockback_enabled


func _ensure_shoot_action() -> void:
	if InputMap.has_action(input_shoot):
		return
	InputMap.add_action(input_shoot)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_X
	InputMap.action_add_event(input_shoot, key)
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_X
	InputMap.action_add_event(input_shoot, pad)


func _ensure_stomp_action() -> void:
	if InputMap.has_action(input_stomp):
		return
	InputMap.add_action(input_stomp)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_C
	InputMap.action_add_event(input_stomp, key)
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_Y
	InputMap.action_add_event(input_stomp, pad)


func _update_arrow() -> void:
	if not _shoot_pressed:
		return
	if arrow_debug_print:
		print("Player: shoot pressed. enabled=", arrow_enabled, " scene=", arrow_scene, " cooldown=", _arrow_timer, " state=", state)
	if not arrow_enabled or arrow_scene == null:
		return
	if _arrow_timer > 0.0:
		return
	if state != State.GROUND and state != State.AIR:
		return
	if get_tree().get_nodes_in_group(&"arrows").size() >= arrow_max_active:
		return
	shoot_arrow()


func shoot_arrow() -> void:
	var arrow := arrow_scene.instantiate() as Arrow
	if arrow == null:
		push_warning("Player: arrow_scene não tem o script Arrow na raiz.")
		return
	arrow.direction = Vector2(facing, 0.0)
	arrow.shooter = self
	get_parent().add_child(arrow)
	arrow.global_position = _focus_origin() + Vector2(arrow_spawn_offset.x * facing, arrow_spawn_offset.y)
	_arrow_timer = arrow_cooldown
	_play_sound(shoot_sound)
	if arrow_knockback_enabled:
		_apply_arrow_knockback()


func _apply_arrow_knockback() -> void:
	if state == State.GROUND:
		ground_speed -= facing * arrow_knockback
	else:
		velocity.x -= facing * arrow_knockback_air
	if arrow_knockback_lock > 0.0:
		control_lock = maxf(control_lock, arrow_knockback_lock)
	_arrow_kb_timer = arrow_knockback_anim_time
	_current_anim = &""


func start_super() -> void:
	if is_super or _super_pending > 0.0 or state == State.TRANSFORM or state == State.DEAD:
		return
	_super_pending = maxf(super_transform_delay, 0.001)


func end_super() -> void:
	_super_pending = 0.0
	if not is_super:
		return
	is_super = false
	_play_sound(super_end_sound)
	_swap_animation_players(false)
	if _normal_texture != null:
		skin.set("texture", _normal_texture)
	_clear_ghosts()
	_play_palette(pal_super_to_normal)
	super_ended.emit()


func _update_super_timer(delta: float) -> void:
	if _super_pending <= 0.0:
		return
	if state == State.DEAD:
		_super_pending = 0.0
		return
	_super_pending -= delta
	if _super_pending <= 0.0:
		_super_pending = 0.0
		_begin_transform()


func _update_super_drain(delta: float) -> void:
	if not is_super or state == State.DEAD:
		return
	_super_drain_timer += delta
	if _super_drain_timer < super_ring_drain_interval:
		return
	_super_drain_timer -= super_ring_drain_interval
	rings = maxi(rings - 1, 0)
	rings_changed.emit(rings)
	if rings <= 0:
		end_super()


func _begin_transform() -> void:
	_enter_air()
	velocity = Vector2.ZERO
	ground_speed = 0.0
	_set_state(State.TRANSFORM)
	_current_anim = &""
	_play_sound(super_transform_sound)
	_play_palette(pal_normal_to_super)


func _process_transform(_delta: float) -> void:
	velocity = Vector2.ZERO
	ground_speed = 0.0


func _finish_transform() -> void:
	is_super = true
	_super_drain_timer = 0.0
	_swap_animation_players(true)
	if super_texture != null:
		skin.set("texture", super_texture)
	_play_palette(pal_super)
	_start_ghosts()
	_current_anim = &""
	_set_state(State.AIR)
	_clear_air_animation()
	super_started.emit()


func _current_player() -> AnimationPlayer:
	if is_super and super_animation_player != null:
		return super_animation_player
	return animation_player


func _swap_animation_players(to_super: bool) -> void:
	if super_animation_player == null:
		return
	if animation_player != null:
		animation_player.active = not to_super
	super_animation_player.active = to_super
	_current_anim = &""


func _play_palette(anim: StringName) -> void:
	if palette_player == null:
		push_warning("Player: palette_player not set.")
		return
	if not palette_player.has_animation(anim):
		push_warning("Player: animation '%s' don't exist on pallete player ur chud." % anim)
		return
	palette_player.play(anim)


func _on_palette_finished(anim_name: StringName) -> void:
	if anim_name == pal_super_to_normal and not is_super:
		_play_palette(pal_normal)


func _start_ghosts() -> void:
	_clear_ghosts()
	_ghost_blink_time = 0.0
	for i in ghost_count:
		var g := Sprite2D.new()
		g.top_level = true
		g.z_index = -1
		g.material = skin.material
		g.modulate.a = ghost_alpha * (1.0 - float(i) / float(maxi(ghost_count, 1)))
		g.visible = false
		add_child(g)
		_ghosts.append(g)


func _update_ghosts(delta: float) -> void:
	if not is_super or _ghosts.is_empty():
		return
	_ghost_blink_time += delta
	_ghost_history.push_front({
		"position": skin.global_position,
		"rotation": skin.global_rotation,
		"scale": skin.global_scale,
		"visible": skin.visible,
		"texture": skin.get("texture"),
		"hframes": skin.get("hframes"),
		"vframes": skin.get("vframes"),
		"frame": skin.get("frame"),
		"flip_h": skin.get("flip_h"),
		"offset": skin.get("offset"),
		"centered": skin.get("centered"),
	})
	var needed := ghost_frame_gap * _ghosts.size() + 1
	while _ghost_history.size() > needed:
		_ghost_history.pop_back()
	for i in _ghosts.size():
		var g := _ghosts[i]
		var index := (i + 1) * ghost_frame_gap
		if index >= _ghost_history.size():
			g.visible = false
			continue
		var h: Dictionary = _ghost_history[index]
		g.texture = h["texture"]
		g.hframes = h["hframes"]
		g.vframes = h["vframes"]
		g.frame = h["frame"]
		g.flip_h = h["flip_h"]
		g.offset = h["offset"]
		g.centered = h["centered"]
		g.global_position = h["position"]
		g.global_rotation = h["rotation"]
		g.global_scale = h["scale"]
		var blink_on := true
		if ghost_blink_enabled and ghost_blink_interval > 0.0:
			blink_on = (int(_ghost_blink_time / ghost_blink_interval) + i) % 2 == 0
		g.visible = h["visible"] and state != State.DEAD and blink_on


func _clear_ghosts() -> void:
	for g in _ghosts:
		g.queue_free()
	_ghosts.clear()
	_ghost_history.clear()


func hurt(source_x: float, source: Node = null) -> void:
	if not is_vulnerable():
		return
	var listed := _is_deflect_source(source)
	var protected := _is_ball_state() or _ball_timer > 0.0 or (roll_deflect_protect_fall and _deflect_fall)
	if roll_deflect_debug:
		print("[deflect] source=", source, " enabled=", roll_deflect_enabled, " all=", roll_deflect_all, " listed=", listed, " state=", state, " jumping=", is_jumping, " ball_timer=", snappedf(_ball_timer, 0.001), " grace=", snappedf(_deflect_grace, 0.001), " fall=", _deflect_fall, " protected=", protected)
	if listed:
		if _deflect_grace > 0.0:
			return
		if protected:
			_deflect(source_x)
			return
	var shielded := has_shield
	if not shielded and rings <= 0:
		die()
		return
	_super_pending = 0.0
	_play_sound(hurt_sound)
	if shielded:
		remove_shield()
	else:
		_scatter_rings()
	var side := 1 if global_position.x >= source_x else -1
	var v := Vector2(hurt_knockback.x * side, hurt_knockback.y)
	_enter_air()
	_set_state(State.HURT)
	velocity = v
	_invincible = invincibility_time


func _is_ball_state() -> bool:
	match state:
		State.ROLL, State.STOMP:
			return true
		State.AIR:
			return is_jumping
	return false


func _is_deflect_source(source: Node) -> bool:
	if not roll_deflect_enabled:
		return false
	if roll_deflect_all:
		return true
	if source == null or roll_deflect_scenes.is_empty():
		return false
	var n: Node = source
	while n != null:
		var path := n.scene_file_path
		if path != "":
			for scene in roll_deflect_scenes:
				if scene != null and scene.resource_path == path:
					return true
		n = n.get_parent()
	return false


func _deflect(source_x: float) -> void:
	var side := 1 if global_position.x >= source_x else -1
	var v := Vector2(roll_deflect_knockback.x * side, roll_deflect_knockback.y)
	_enter_air()
	_clear_air_animation()
	velocity = v
	_deflect_fall = true
	_deflect_grace = roll_deflect_grace
	_current_anim = &""
	_play_sound(roll_deflect_sound)


func die() -> void:
	if state == State.DEAD:
		return
	_super_pending = 0.0
	remove_shield()
	_play_sound(death_sound)
	_reset_ground()
	_invincible = 0.0
	z_index = 100
	velocity = Vector2(0.0, -die_jump_speed)
	collision_layer = 0
	collision_mask = 0
	_set_state(State.DEAD)
	_apply_collision(CollisionMode.NORMAL)
	died.emit()
	if uses_lives:
		Lives.lose()
	get_tree().create_timer(maxf(respawn_delay - ScreenFade.fade_time, 0.0)).timeout.connect(_on_respawn_timeout)

func _on_respawn_timeout() -> void:
	if uses_lives and Lives.is_game_over():
		await ScreenFade.fade_out()
		Lives.reset()
		Score.reset()
		Checkpoint.reset_checkpoint()
		ScreenFade.change_scene(title_scene, false)
	else:
		ScreenFade.reload_scene()

func _scatter_rings() -> void:
	var count := mini(rings, max_scattered_rings)
	rings = 0
	rings_changed.emit(rings)
	if count > 0:
		_play_sound(rings_lost_sound)
	var angle := deg_to_rad(101.25)
	var speed := scatter_speed
	var flip := false
	for i in count:
		if i == 16:
			speed *= 0.5
			angle = deg_to_rad(101.25)
			flip = false
		var ring: Node2D
		if lost_ring_scene != null:
			ring = lost_ring_scene.instantiate() as Node2D
		else:
			ring = LostRing.new()
		var v := Vector2(cos(angle), -sin(angle)) * speed
		if flip:
			v.x = -v.x
			angle += deg_to_rad(22.5)
		flip = not flip
		ring.set("velocity", v)
		ring.position = position
		get_parent().add_child.call_deferred(ring)


func spring(impulse: Vector2) -> void:
	if impulse.y == 0.0 and (state == State.GROUND or state == State.ROLL):
		ground_speed = impulse.x
		control_lock = spring_lock_time
		facing = int(signf(impulse.x))
		return
	var v := velocity
	if state == State.GROUND or state == State.ROLL:
		v = Vector2.RIGHT.rotated(ground_angle) * ground_speed
	if impulse.x != 0.0:
		v.x = impulse.x
	if impulse.y != 0.0:
		v.y = impulse.y
	_enter_air()
	_clear_air_animation()
	velocity = v
	is_spring = true


func can_grab_bar() -> bool:
	if _bar_cooldown > 0.0:
		return false
	match state:
		State.AIR, State.GLIDE, State.FLY:
			return not _down
		State.GROUND, State.ROLL:
			return absf(ground_angle) >= deg_to_rad(bar_grab_wall_min_angle_deg)
	return false


func grab_bar(bar: Node2D, spin_rate: float) -> void:
	_enter_air()
	_set_state(State.BAR)
	_play_sound(bar_grab_sound)
	_bar = bar
	_bar_offset = Vector2(global_position.x - bar.global_position.x, 0.0)
	_bar_spin = spin_rate * facing
	velocity = Vector2.ZERO
	ground_speed = 0.0


func _process_bar(_delta: float) -> void:
	if _bar == null:
		return
	velocity = Vector2.ZERO
	global_position = _bar.global_position + _bar_offset + bar_hang_offset
	if _jump_pressed:
		_release_bar()


func _release_bar() -> void:
	var spinning := _bar_spin != 0.0
	var launch := bar_launch_speed if spinning else jump_release_speed
	_enter_air()
	_clear_air_animation()
	velocity = Vector2(0.0, -launch)
	is_spring = true
	bar_launch = spinning
	_bar_cooldown = bar_regrab_delay
	_play_sound(jump_sound)


func _process_ground(delta: float) -> void:
	var slow := absf(ground_speed) <= crouch_max_speed
	var flat := absf(ground_angle) < deg_to_rad(slip_min_angle_deg)
	is_crouching = _down and slow and flat
	is_looking_up = _up and not _down and slow and flat

	if _jump_pressed:
		if is_crouching and spindash_enabled:
			_start_spindash()
		elif is_looking_up and peelout_enabled:
			_start_peelout()
		else:
			_jump()
		return

	if _down and absf(ground_speed) >= roll_min_speed:
		_play_sound(roll_sound)
		_set_state(State.ROLL)
		return

	if is_crouching or is_looking_up:
		ground_speed = move_toward(ground_speed, 0.0, friction * delta)
		_move_on_ground(delta)
		return

	ground_speed += slope_factor * sin(ground_angle) * delta

	if control_lock <= 0.0:
		if _dir != 0:
			if ground_speed * _dir < 0.0:
				ground_speed += _dir * deceleration * delta
			elif absf(ground_speed) < _top_speed():
				ground_speed += _dir * _acceleration() * delta
				if absf(ground_speed) > _top_speed():
					ground_speed = _dir * _top_speed()
		else:
			ground_speed = move_toward(ground_speed, 0.0, friction * _brake_mult() * delta)

	if control_lock <= 0.0 \
			and absf(ground_speed) < slip_speed_threshold \
			and absf(ground_angle) >= deg_to_rad(slip_min_angle_deg):
		control_lock = control_lock_time
		if absf(ground_angle) >= deg_to_rad(fall_min_angle_deg):
			var v := Vector2.RIGHT.rotated(ground_angle) * ground_speed
			_enter_air()
			velocity = v
			return

	_move_on_ground(delta)


func _process_roll(delta: float) -> void:
	if _jump_pressed:
		_jump()
		return

	var slope := sin(ground_angle)
	var factor := roll_slope_down if signf(slope) == signf(ground_speed) else roll_slope_up
	ground_speed += factor * slope * delta

	if control_lock <= 0.0 and _dir != 0 and ground_speed * _dir < 0.0:
		ground_speed = move_toward(ground_speed, 0.0, roll_deceleration * delta)
	ground_speed = move_toward(ground_speed, 0.0, roll_friction * _brake_mult() * delta)

	if absf(ground_speed) < unroll_speed:
		_set_state(State.GROUND)

	_move_on_ground(delta)


func _update_skid() -> void:
	var was := is_skidding
	if state != State.GROUND:
		is_skidding = false
		return
	var opposite := control_lock <= 0.0 and _dir != 0 and ground_speed * _dir < 0.0
	is_skidding = opposite and (is_skidding or absf(ground_speed) >= skid_min_speed)
	if is_skidding and not was:
		_play_sound(skid_sound)


func _update_push() -> void:
	is_pushing = false
	if state != State.GROUND or _dir == 0 or _down or _up or control_lock > 0.0:
		return
	if absf(ground_speed) > push_max_speed:
		return
	var motion := Vector2.RIGHT.rotated(ground_angle) * _dir * push_check_distance
	if test_move(global_transform, motion, _hit):
		is_pushing = _hit.get_normal().dot(motion.normalized()) < -0.5


func _update_balance() -> void:
	is_balancing = false
	if act_cleared or state != State.GROUND or is_crouching or is_looking_up or is_skidding or is_pushing:
		return
	if absf(ground_speed) >= idle_speed_threshold:
		return
	var left_ground := _sensor_has_ground(0)
	var right_ground := _sensor_has_ground(1)
	if left_ground == right_ground:
		return
	is_balancing = true
	facing = 1 if left_ground else -1


func _sensor_has_ground(index: int) -> bool:
	var down := global_transform.y.normalized()
	var origin := _sensors[index].global_position
	var q := _rays[index]
	q.from = origin - down * sensor_lift
	q.to = origin + down * sensor_length
	q.collision_mask = collision_mask
	return not get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _start_spindash() -> void:
	spindash_charge = 0.0
	ground_speed = 0.0
	_set_state(State.SPINDASH)
	_play_spindash_sound()


func _process_spindash(delta: float) -> void:
	ground_speed = 0.0
	velocity = Vector2.ZERO
	if _jump_pressed:
		spindash_charge = minf(spindash_charge + spindash_charge_gain, spindash_max_charge)
		_play_spindash_sound()
		_current_anim = &""
	spindash_charge *= pow(1.0 - spindash_decay, delta * 60.0)
	if not _down:
		ground_speed = facing * (spindash_base_speed + spindash_charge * spindash_speed_per_charge) * _super_mult()
		_start_camera_lag(int(spindash_charge))
		spindash_charge = 0.0
		_play_sound(spindash_release_sound)
		_set_state(State.ROLL)


func _start_peelout() -> void:
	ground_speed = 0.0
	_peelout_timer = 0.0
	_set_state(State.PEELOUT)
	_play_sound(peelout_charge_sound)


func _process_peelout(delta: float) -> void:
	ground_speed = 0.0
	velocity = Vector2.ZERO
	_peelout_timer += delta
	if not _up:
		_set_state(State.GROUND)
		if _peelout_timer >= peelout_charge_time:
			ground_speed = facing * peelout_speed * _super_mult()
			_play_sound(peelout_release_sound)


func _move_on_ground(delta: float) -> void:
	var limit := max_ground_speed * _super_mult()
	ground_speed = clampf(ground_speed, -limit, limit)
	var steps := clampi(ceili(absf(ground_speed) * delta / max_step_distance), 1, 16)
	for i in steps:
		var tangent := Vector2.RIGHT.rotated(ground_angle)
		velocity = tangent * ground_speed / float(steps)
		move_and_slide()

		if is_on_wall() and get_wall_normal().dot(tangent) * ground_speed < 0.0:
			ground_speed = 0.0

		if not _snap_to_ground():
			var v := tangent * ground_speed
			_enter_air()
			velocity = v
			return

		if ground_speed == 0.0:
			break
	velocity = Vector2.RIGHT.rotated(ground_angle) * ground_speed


func _process_air(delta: float) -> void:
	if is_spring and velocity.y > 0.0:
		is_spring = false

	if _stomp_pressed and stomp_enabled and is_jumping:
		_start_stomp()
		return

	if _try_super_input():
		return

	if _jump_pressed and _try_air_ability():
		return

	if _dir != 0:
		var new_x := velocity.x + _dir * _air_acceleration() * delta
		if absf(new_x) <= _top_speed() or absf(new_x) < absf(velocity.x):
			velocity.x = new_x

	if velocity.y < 0.0 and velocity.y > -air_drag_speed_limit:
		velocity.x *= pow(air_drag, delta * 60.0)

	if (is_jumping or bar_launch) and not _jump_held and velocity.y < -jump_release_speed:
		velocity.y = -jump_release_speed

	velocity.y = minf(velocity.y + gravity_strength * delta, max_fall_speed)

	var pre := velocity
	move_and_slide()

	if is_on_floor() and pre.y >= 0.0:
		_land(pre)


func _try_air_ability() -> bool:
	if not is_jumping:
		return false
	if fly_enabled:
		_start_fly()
		return true
	if glide_enabled:
		_start_glide()
		return true
	return false


func _start_stomp() -> void:
	is_jumping = false
	is_spring = false
	bar_launch = false
	if stomp_cancel_horizontal:
		velocity.x = 0.0
	velocity.y = stomp_speed
	_set_state(State.STOMP)
	_play_sound(stomp_sound)


func _process_stomp(delta: float) -> void:
	if stomp_air_control and _dir != 0:
		var new_x := velocity.x + _dir * _air_acceleration() * delta
		if absf(new_x) <= _top_speed() or absf(new_x) < absf(velocity.x):
			velocity.x = new_x
	velocity.y = stomp_speed
	move_and_slide()
	if is_on_floor():
		stomp_hit_window = 0.1
		_land(Vector2.ZERO)
		_play_sound(stomp_land_sound)
		if stomp_bounce_speed > 0.0:
			_enter_air()
			velocity = Vector2(0.0, -stomp_bounce_speed)
			is_jumping = true
			_apply_collision(CollisionMode.JUMP)


func _start_glide() -> void:
	is_jumping = false
	_glide_fall = false
	_glide_speed = glide_start_speed
	_glide_angle = 0.0 if facing >= 0 else PI
	velocity.y = maxf(velocity.y, 0.0)
	_set_state(State.GLIDE)
	_play_sound(glide_sound)


func _process_glide(delta: float) -> void:
	if not _jump_held:
		_end_glide(glide_release_speed_factor)
		return
	var turning := false
	if _dir != 0:
		var target := 0.0 if _dir > 0 else PI
		var diff := angle_difference(_glide_angle, target)
		if absf(diff) > 0.0001:
			turning = true
			var step := deg_to_rad(glide_turn_speed_deg) * delta
			_glide_angle = wrapf(_glide_angle + clampf(diff, -step, step), -PI, PI)
	if not turning:
		_glide_speed = minf(_glide_speed + glide_acceleration * delta, glide_max_speed)
	var dir_x := cos(_glide_angle)
	if absf(dir_x) > 0.01:
		facing = 1 if dir_x > 0.0 else -1
	velocity.x = dir_x * _glide_speed
	velocity.y = move_toward(velocity.y, glide_fall_speed, glide_gravity * delta)
	var pre := velocity
	move_and_slide()
	if is_on_floor():
		_land(Vector2(pre.x, 0.0))
		_set_state(State.GLIDE_SLIDE)
		_play_sound(glide_slide_sound)
	elif is_on_wall() and get_wall_normal().x * pre.x < 0.0:
		_end_glide(0.0)


func _end_glide(x_factor: float) -> void:
	velocity.x *= x_factor
	_glide_fall = true
	_set_state(State.AIR)


func _process_glide_slide(delta: float) -> void:
	ground_speed = move_toward(ground_speed, 0.0, glide_slide_friction * delta)
	if not _jump_held or is_zero_approx(ground_speed):
		ground_speed = 0.0
		_set_state(State.GROUND)
		return
	_move_on_ground(delta)


func _start_fly() -> void:
	is_jumping = false
	_fly_time = 0.0
	_fly_tired = false
	_set_state(State.FLY)
	_flap()


func _flap() -> void:
	velocity.y = -fly_flap_impulse


func _process_fly(delta: float) -> void:
	_fly_time += delta
	if not _fly_tired and _fly_time >= fly_max_time:
		_fly_tired = true
		_play_sound(fly_tired_sound)
	if _jump_pressed and not _fly_tired:
		_flap()
	if _dir != 0:
		var new_x := velocity.x + _dir * _air_acceleration() * delta
		if absf(new_x) <= _top_speed() or absf(new_x) < absf(velocity.x):
			velocity.x = new_x
	var g := gravity_strength if _fly_tired else fly_gravity
	velocity.y = minf(velocity.y + g * delta, max_fall_speed)
	_set_fly_loop(FlyLoop.FALL if velocity.y > fly_loop_min_fall_speed else FlyLoop.RISE)
	var pre := velocity
	move_and_slide()
	if is_on_floor() and pre.y >= 0.0:
		_land(pre)


func _fly_loop_player(mode: FlyLoop) -> AudioStreamPlayer:
	match mode:
		FlyLoop.RISE:
			return fly_flap_sound
		FlyLoop.FALL:
			return fly_fall_sound
	return null


func _set_fly_loop(mode: FlyLoop) -> void:
	if mode == _fly_loop_mode:
		return
	_stop_sound(_fly_loop_player(_fly_loop_mode))
	_fly_loop_mode = mode
	_play_sound(_fly_loop_player(mode))


func _on_fly_loop_finished() -> void:
	_play_sound(_fly_loop_player(_fly_loop_mode))


func _process_hurt(delta: float) -> void:
	velocity.y = minf(velocity.y + hurt_gravity * delta, max_fall_speed)
	var pre := velocity
	move_and_slide()
	if is_on_floor() and pre.y >= 0.0:
		control_lock = 0.0
		_land(Vector2.ZERO)


func _process_dead(delta: float) -> void:
	velocity.x = 0.0
	velocity.y += die_gravity * delta
	move_and_slide()


func _jump() -> void:
	var v := Vector2.RIGHT.rotated(ground_angle) * ground_speed \
			+ Vector2.UP.rotated(ground_angle) * jump_force
	_enter_air()
	velocity = v
	is_jumping = true
	_play_sound(jump_sound)
	_apply_collision(CollisionMode.JUMP)


func _reset_ground() -> void:
	if not is_zero_approx(rotation):
		var local_center := _active_col().position
		var center := to_global(local_center)
		rotation = 0.0
		global_position = center - local_center
		_depenetrate()
	ground_angle = 0.0
	rotation = 0.0
	up_direction = Vector2.UP
	is_jumping = false
	is_spring = false
	bar_launch = false
	_glide_fall = false
	_deflect_fall = false
	_bar = null
	_bar_spin = 0.0


func _enter_air() -> void:
	_reset_ground()
	_set_state(State.AIR)


func _land(pre: Vector2) -> void:
	badnik_chain = 0
	var s := _sense_ground()
	var a: float
	if s.is_empty():
		a = wrapf(get_floor_normal().angle() + PI / 2.0, -PI, PI)
	else:
		a = s.angle
	_set_ground_angle(a)
	_snap_to_ground()

	var deg := absf(rad_to_deg(a))
	if deg <= land_flat_angle_deg or absf(pre.x) > absf(pre.y):
		ground_speed = pre.x
	else:
		var k := 0.5 if deg <= land_slope_angle_deg else 1.0
		ground_speed = pre.y * k * signf(sin(a))

	is_jumping = false
	is_spring = false
	bar_launch = false
	_glide_fall = false
	_deflect_fall = false
	_set_state(State.GROUND)
	_update_collision()


func _set_ground_angle(a: float) -> void:
	ground_angle = a
	rotation = a
	up_direction = Vector2.UP.rotated(a)


func _limited_angle(target: float) -> float:
	var limit := deg_to_rad(max_angle_step_deg)
	var step := clampf(angle_difference(ground_angle, target), -limit, limit)
	return wrapf(ground_angle + step, -PI, PI)


func _depenetrate() -> void:
	for i in depenetration_iterations:
		if not test_move(global_transform, Vector2.ZERO, _hit, 0.08, true):
			return
		var depth := _hit.get_depth()
		if depth <= 0.1:
			return
		global_position += _hit.get_normal() * minf(depth, max_depenetration)


func _snap_to_ground() -> bool:
	var s := _sense_ground()
	if s.is_empty():
		return false
	var a := _limited_angle(s.angle)
	if not is_equal_approx(a, ground_angle):
		_set_ground_angle(a)
		s = _sense_ground()
	if not s.is_empty():
		global_position += global_transform.y.normalized() * s.shift
	_depenetrate()
	return true


func _sense_ground() -> Dictionary:
	var down := global_transform.y.normalized()
	var space := get_world_2d().direct_space_state
	var hits: Array[Dictionary] = []

	for i in 2:
		var s := _sensors[i]
		var origin := s.global_position
		var q := _rays[i]
		q.from = origin - down * sensor_lift
		q.to = origin + down * sensor_length
		q.collision_mask = collision_mask
		var h := space.intersect_ray(q)
		if h.is_empty():
			continue
		var dist: float = (h.position - origin).dot(down)
		h["dist"] = dist
		h["shift"] = dist + s.position.y
		hits.append(h)

	if hits.is_empty():
		return {}

	var shift: float = hits[0].shift
	var angle: float
	if hits.size() == 2:
		shift = minf(shift, hits[1].shift)
		var chord: Vector2 = hits[1].position - hits[0].position
		angle = chord.angle()
		var na := _normal_to_angle(hits[0].normal)
		var nb := _normal_to_angle(hits[1].normal)
		var tol := deg_to_rad(sensor_angle_tolerance_deg)
		if absf(angle_difference(angle, na)) > tol and absf(angle_difference(angle, nb)) > tol:
			angle = na if hits[0].dist <= hits[1].dist else nb
	else:
		angle = _normal_to_angle(hits[0].normal)

	return {"angle": angle, "shift": shift}


func _normal_to_angle(n: Vector2) -> float:
	return wrapf(n.angle() + PI / 2.0, -PI, PI)


func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	var old := state
	state = new_state
	if new_state == State.AIR and old != State.AIR:
		_capture_air_animation()
	if new_state != State.FLY:
		_set_fly_loop(FlyLoop.NONE)
	if old == State.FLY:
		_stop_sound(fly_tired_sound)
	if old == State.PEELOUT:
		_stop_sound(peelout_charge_sound)
	if new_state != State.GROUND and new_state != State.AIR:
		_arrow_kb_timer = 0.0
	if new_state != State.GROUND:
		is_crouching = false
		is_looking_up = false
		is_skidding = false
		is_pushing = false
		is_balancing = false
	state_changed.emit(new_state, old)


func _find_sound(current: AudioStreamPlayer, node_name: String) -> AudioStreamPlayer:
	return current if current != null else get_node_or_null(node_name) as AudioStreamPlayer


func _create_shield_sound() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = "ShieldSound"
	player.stream = preload("res://Audios/effects/AF - Shield Get.wav")
	add_child(player)
	return player


func _play_sound(player: AudioStreamPlayer) -> void:
	if player != null:
		player.play()


func _stop_sound(player: AudioStreamPlayer) -> void:
	if player != null:
		player.stop()


func _play_spindash_sound() -> void:
	if spindash_sound == null:
		return
	spindash_sound.pitch_scale = 1.0 + spindash_charge / spindash_max_charge * spindash_pitch_range
	spindash_sound.play()


func _snap_angle(a: float) -> float:
	if not genesis_angle_snap or genesis_angle_step_deg <= 0.0:
		return a
	var wrapped := wrapf(a, -PI, PI)
	if angle45_anims_enabled and _angle_anims_available(_current_player()):
		return snappedf(wrapped, PI / 2.0)
	var mag := absf(wrapped)
	if mag < deg_to_rad(genesis_angle_threshold_deg):
		return 0.0
	var step := deg_to_rad(genesis_angle_step_deg)
	var snapped_mag := maxf(snappedf(mag, step), step)
	return signf(wrapped) * snapped_mag


func _angle_anims_available(ap: AnimationPlayer) -> bool:
	if ap == null:
		return false
	return ap.has_animation(anim_walk_45) and ap.has_animation(anim_run_45)


func _angle_anim_for(base: StringName) -> StringName:
	if not angle45_anims_enabled or not genesis_angle_snap:
		return &""
	var is_peelout := base == anim_peelout
	if base != anim_walk and base != anim_run and not is_peelout:
		return &""
	var ap := _current_player()
	if ap == null:
		return &""
	if not is_peelout and not _angle_anims_available(ap):
		return &""
	var wrapped := wrapf(ground_angle, -PI, PI)
	var mag := rad_to_deg(absf(wrapped))
	var diag_deg := 0.0
	if mag >= angle45_min_deg and mag <= angle45_max_deg:
		diag_deg = 45.0
	elif mag >= 180.0 - angle45_max_deg and mag <= 180.0 - angle45_min_deg:
		diag_deg = 135.0
	else:
		return &""
	var diag := signf(wrapped) * deg_to_rad(diag_deg)
	var target: StringName
	if is_peelout:
		target = anim_peelout_45
	elif base == anim_run:
		target = anim_run_45
	else:
		target = anim_walk_45
	if ap.has_animation(target):
		_angle_diag = diag
		var art := deg_to_rad(angle45_art_angle_deg)
		_angle_rotation = wrapf(diag - art if facing >= 0 else diag + art, -PI, PI)
		return target
	return &""


func _update_skin(delta: float) -> void:
	if state == State.BAR:
		_skin_angle = deg_to_rad(bar_hang_angle_deg) * facing
		skin.global_rotation = _skin_angle
		skin.position = _skin_base_position + bar_skin_offset
		skin.set("flip_h", facing < 0)
		skin.visible = true
		return
	if _angle_anim_active:
		_skin_angle = _angle_rotation
		skin.global_rotation = _angle_rotation
	else:
		var target := rotation if state == State.GROUND or state == State.PEELOUT else 0.0
		var airborne := state == State.AIR or state == State.HURT or state == State.GLIDE or state == State.FLY or state == State.STOMP
		var rate := skin_air_rotation_speed if airborne else skin_rotation_speed
		var t := 1.0 if rate <= 0.0 else 1.0 - exp(-rate * delta)
		var snap90 := genesis_angle_snap and angle45_anims_enabled and _angle_anims_available(_current_player())
		if snap90 and not airborne:
			_skin_angle = _snap_angle(target)
		else:
			_skin_angle = lerp_angle(_skin_angle, target, t)
		skin.global_rotation = _snap_angle(_skin_angle)
	var skin_offset := Vector2(0.0, roll_skin_offset) if state == State.ROLL else Vector2.ZERO
	if _air_hold_active():
		skin_offset = _air_hold_offset
	skin.position = _skin_base_position + skin_offset
	skin.set("flip_h", facing < 0)
	if _invincible > 0.0:
		skin.visible = int(_invincible / blink_interval) % 2 == 0
	else:
		skin.visible = true


func _update_animation() -> void:
	_angle_anim_active = false
	var ap := _current_player()
	if ap == null:
		return
	var anim := anim_idle
	var anim_scale := 1.0
	match state:
		State.GROUND:
			if act_cleared and absf(ground_speed) < idle_speed_threshold:
				anim = anim_win
			elif is_crouching:
				anim = anim_look_down
			elif is_looking_up:
				anim = anim_look_up
			elif is_skidding:
				anim = anim_skid
			elif is_pushing:
				anim = anim_push
			elif absf(ground_speed) < idle_speed_threshold:
				anim = anim_balance if is_balancing else _standing_animation()
			elif absf(ground_speed) >= peelout_anim_min_speed:
				anim = anim_peelout
				anim_scale = lerpf(peelout_anim_scale_min, peelout_anim_scale_max, clampf(absf(ground_speed) / peelout_speed, 0.0, 1.0))
				var peel_anim := _angle_anim_for(anim)
				if peel_anim != &"":
					_angle_base_anim = anim
					_angle_anim_active = true
					anim = peel_anim
			else:
				anim = _move_animation(ground_speed)
				anim_scale = _move_scale(anim, ground_speed)
				var angle_anim := _angle_anim_for(anim)
				if angle_anim != &"":
					_angle_base_anim = anim
					_angle_anim_active = true
					anim = angle_anim
		State.AIR:
			if _deflect_fall:
				anim = anim_fall if ap.has_animation(anim_fall) else _move_animation(velocity.x)
			elif _glide_fall:
				anim = anim_glide_fall
			elif is_jumping:
				anim = anim_roll
				anim_scale = _speed_scale(velocity.length(), roll_anim_reference)
			elif is_spring:
				anim = anim_spring
			elif _air_hold_anim != &"":
				anim = _air_hold_animation()
				anim_scale = _air_hold_scale
			elif fall_animation_enabled and ap.has_animation(anim_fall):
				anim = anim_fall
			else:
				anim = _move_animation(velocity.x)
				anim_scale = _move_scale(anim, velocity.x)
		State.ROLL:
			anim = anim_roll
			anim_scale = _speed_scale(ground_speed, roll_anim_reference)
		State.SPINDASH:
			anim = anim_spindash
			anim_scale = lerpf(spindash_anim_scale_min, spindash_anim_scale_max, clampf(spindash_charge / spindash_max_charge, 0.0, 1.0))
		State.PEELOUT:
			var charge := clampf(_peelout_timer / peelout_charge_time, 0.0, 1.0)
			if charge >= 1.0:
				anim = anim_peelout
				anim_scale = peelout_anim_scale_max
			else:
				anim = anim_run if charge >= peelout_run_fraction else anim_walk
				anim_scale = lerpf(peelout_anim_scale_min, peelout_anim_scale_max, charge)
			var charge_anim := _angle_anim_for(anim)
			if charge_anim != &"":
				_angle_base_anim = anim
				_angle_anim_active = true
				anim = charge_anim
		State.HURT:
			anim = anim_damage
		State.DEAD:
			anim = anim_die
		State.BAR:
			anim = anim_hang
			anim_scale = 0.0 if _bar_spin == 0.0 else _speed_scale(_bar_spin, bar_anim_reference)
		State.TRANSFORM:
			anim = anim_super
		State.GLIDE:
			anim = anim_glide
			anim_scale = glide_anim_speed
		State.GLIDE_SLIDE:
			anim = anim_glide_slide
		State.FLY:
			anim = anim_fly_tired if _fly_tired else anim_fly
			anim_scale = fly_anim_speed
		State.STOMP:
			anim = anim_stomp if ap.has_animation(anim_stomp) else anim_roll
			anim_scale = stomp_anim_speed
	if _arrow_kb_timer > 0.0 and not is_jumping and (state == State.GROUND or state == State.AIR) and ap.has_animation(anim_arrow_knockback):
		anim = anim_arrow_knockback
		anim_scale = 1.0
		_angle_anim_active = false
	ap.speed_scale = anim_scale
	_play(anim)


func _capture_air_animation() -> void:
	var ap := _current_player()
	_air_hold_anim = _angle_base_anim if _angle_anim_active else _current_anim
	_air_hold_scale = ap.speed_scale if ap != null else 1.0
	_air_hold_offset = skin.position - _skin_base_position
	var holdable: Array[StringName] = [
		anim_idle, anim_wait, anim_wait_loop, anim_walk, anim_run,
		anim_roll, anim_peelout,
	]
	if not holdable.has(_air_hold_anim):
		_clear_air_animation()


func _clear_air_animation() -> void:
	_air_hold_anim = &""
	_air_hold_scale = 1.0
	_air_hold_offset = Vector2.ZERO


func _air_hold_active() -> bool:
	return state == State.AIR and _air_hold_anim != &"" and not _glide_fall and not _deflect_fall and not is_jumping and not is_spring


func _air_hold_animation() -> StringName:
	if _air_hold_anim == anim_idle or _air_hold_anim == anim_wait or _air_hold_anim == anim_wait_loop:
		return _standing_animation()
	return _air_hold_anim


func _setup_tails() -> void:
	if tails_sprite == null:
		tails_sprite = get_node_or_null("Tails") as Sprite2D
	if tails_animation_player == null:
		tails_animation_player = get_node_or_null("TailsAnimationPlayer") as AnimationPlayer
	if tails_sprite == null:
		if has_tails:
			push_warning("Player: has_tails ligado mas tails_sprite não definido.")
		return
	tails_sprite.show_behind_parent = tails_behind_skin
	if tails_sprite.material == null:
		tails_sprite.material = skin.material
	tails_sprite.visible = false


func _update_tails(delta: float) -> void:
	if tails_sprite == null:
		return
	var anim_key := _angle_base_anim if _angle_anim_active else _current_anim
	var visible_now := has_tails and skin.visible and state != State.DEAD and tails_visible_animations.has(anim_key)
	tails_sprite.visible = visible_now
	if not visible_now:
		_tails_angle = _skin_angle
		return

	var jumping := _current_anim == anim_roll
	var start := tails_jump_start_position if jumping else tails_idle_start_position
	var visual_rot := _angle_diag if _angle_anim_active else skin.global_rotation
	var anchor := skin.global_position + (Vector2(start.x * facing, start.y) * skin.global_scale).rotated(visual_rot)

	if jumping:
		if velocity.length() >= tails_jump_min_speed:
			var target := velocity.angle() + PI
			var t := 1.0 if tails_jump_follow_speed <= 0.0 else 1.0 - exp(-tails_jump_follow_speed * delta)
			_tails_angle = lerp_angle(_tails_angle, target, t)
		var shown := _snap_angle(_tails_angle)
		tails_sprite.global_position = anchor + Vector2.from_angle(shown) * tails_circle_radius
		tails_sprite.global_rotation = shown + deg_to_rad(tails_jump_angle_offset_deg)
		tails_sprite.flip_h = false
		tails_sprite.flip_v = tails_jump_flip_upright and cos(shown) < 0.0
		_play_tails(tails_anim_jump)
	else:
		_tails_angle = _angle_diag if _angle_anim_active else _skin_angle
		tails_sprite.global_position = anchor
		tails_sprite.global_rotation = _angle_diag if _angle_anim_active else _snap_angle(_skin_angle)
		tails_sprite.flip_h = facing < 0
		tails_sprite.flip_v = false
		_play_tails(tails_anim_idle)


func _play_tails(anim: StringName) -> void:
	var ap := tails_animation_player
	if ap == null or not ap.has_animation(anim):
		return
	ap.speed_scale = tails_anim_speed
	if _tails_anim == anim:
		return
	_tails_anim = anim
	ap.play(anim)


func _standing_animation() -> StringName:
	if _current_anim == anim_idle or _current_anim == anim_wait or _current_anim == anim_wait_loop:
		return _current_anim
	return anim_idle


func _move_animation(speed: float) -> StringName:
	return anim_run if absf(speed) >= run_speed_threshold else anim_walk


func _move_scale(anim: StringName, speed: float) -> float:
	var reference := run_anim_reference if anim == anim_run else walk_anim_reference
	return _speed_scale(speed, reference)


func _speed_scale(speed: float, reference: float) -> float:
	return clampf(absf(speed) / reference, anim_speed_min, anim_speed_max)


func _play(anim: StringName) -> void:
	var ap := _current_player()
	if ap == null or not ap.has_animation(anim):
		return
	if _current_anim == anim:
		return
	_current_anim = anim
	ap.play(anim)


func _on_animation_finished(anim_name: StringName) -> void:
	if state == State.TRANSFORM and anim_name == anim_super:
		_finish_transform()
	elif anim_name == anim_idle and _current_anim == anim_idle:
		_play(anim_wait)
	elif anim_name == anim_wait and _current_anim == anim_wait:
		_play(anim_wait_loop)


func _setup_camera() -> void:
	_cam_pos = _focus_origin() + camera_focus_offset
	_cam_history.clear()
	for i in spindash_lag_frames + 1:
		_cam_history.append(_focus_origin())
	if camera == null:
		return
	camera.top_level = true
	camera.ignore_rotation = true
	camera.position_smoothing_enabled = false
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.z_index = 4000
	camera.draw.connect(_draw_camera_debug)
	camera.global_position = _cam_pos


func _start_camera_lag(rev: int) -> void:
	if not spindash_lag_enabled or camera_style == CameraStyle.SONIC_1:
		return
	_cam_lag_frames = maxi(spindash_lag_frames - rev, 0)
	if spindash_lag_blank_history:
		for i in _cam_history.size():
			_cam_history[i] = _focus_origin()


func _update_camera(delta: float) -> void:
	if camera == null or not camera_enabled or state == State.DEAD:
		return

	if _cam_locked:
		var t := 1.0 - exp(-camera_lock_smoothing * delta)
		_cam_pos = _clamp_camera_to_limits(_cam_pos.lerp(_cam_lock_point, t))
		camera.global_position = _cam_pos.round() if camera_pixel_snap else _cam_pos
		return

	_cam_history.push_front(_focus_origin())
	while _cam_history.size() > spindash_lag_frames + 1:
		_cam_history.pop_back()

	var focus := _focus_origin()
	if _cam_lag_frames > 0:
		focus = _cam_history[mini(_cam_lag_frames, _cam_history.size() - 1)]
		_cam_lag_frames -= 1
	focus += camera_focus_offset

	_update_look_offset(delta)
	_update_extended_offset(delta)

	var px := focus.x + _extended_offset
	var py := focus.y + _look_offset
	_cam_focus_point = Vector2(px, py)

	var dx := px - _cam_pos.x
	var max_dx := camera_max_scroll_x * delta
	if dx < -camera_border_left:
		_cam_pos.x += maxf(dx + camera_border_left, -max_dx)
	elif dx > camera_border_right:
		_cam_pos.x += minf(dx - camera_border_right, max_dx)

	if state == State.AIR or state == State.HURT or state == State.GLIDE or state == State.FLY or state == State.STOMP:
		var dy := py - _cam_pos.y
		var max_dy := camera_air_scroll_speed * delta
		if dy < -camera_air_border_up:
			_cam_pos.y += maxf(dy + camera_air_border_up, -max_dy)
		elif dy > camera_air_border_down:
			_cam_pos.y += minf(dy - camera_air_border_down, max_dy)
	else:
		var fast := absf(ground_speed) >= camera_fast_speed_threshold
		var scroll := camera_ground_scroll_fast if fast else camera_ground_scroll_slow
		_cam_pos.y = move_toward(_cam_pos.y, py, scroll * delta)

	_cam_pos = _clamp_camera_to_limits(_cam_pos)
	camera.global_position = _cam_pos.round() if camera_pixel_snap else _cam_pos
	if camera_debug_draw or _cam_debug_shown:
		camera.queue_redraw()
	_cam_debug_shown = camera_debug_draw


func _update_look_offset(delta: float) -> void:
	_up_since_press += delta
	if _up and not _up_prev:
		_up_double = _up_since_press <= look_double_tap_window
		_up_since_press = 0.0
	elif not _up:
		_up_double = false
	_up_prev = _up

	_down_since_press += delta
	if _down and not _down_prev:
		_down_double = _down_since_press <= look_double_tap_window
		_down_since_press = 0.0
	elif not _down:
		_down_double = false
	_down_prev = _down

	var can_look := look_enabled and state == State.GROUND
	var looking_up := can_look and is_looking_up
	var looking_down := can_look and is_crouching
	_look_up_timer = _look_up_timer + delta if looking_up else 0.0
	_look_down_timer = _look_down_timer + delta if looking_down else 0.0

	var target := 0.0
	if looking_up and _look_ready(_look_up_timer, _up_double):
		target = -look_up_distance
	elif looking_down and _look_ready(_look_down_timer, _down_double):
		target = look_down_distance
	_look_offset = move_toward(_look_offset, target, look_scroll_speed * delta)


func _look_ready(timer: float, double_tap: bool) -> bool:
	match camera_style:
		CameraStyle.SONIC_1:
			return true
		CameraStyle.SONIC_2:
			return timer >= look_delay_sonic2
		_:
			return double_tap or timer >= look_delay


func _update_extended_offset(delta: float) -> void:
	if state == State.SPINDASH or state == State.PEELOUT:
		_charge_time += delta
	else:
		_charge_time = 0.0
	var target := 0.0
	if extended_camera_enabled and camera_style == CameraStyle.SONIC_CD:
		var speed := 0.0
		match state:
			State.GROUND, State.ROLL, State.GLIDE_SLIDE: speed = ground_speed
			State.AIR, State.GLIDE, State.FLY, State.STOMP: speed = velocity.x
		if absf(speed) >= extended_camera_min_speed:
			target = signf(speed) * extended_camera_distance
		elif _charge_time >= extended_camera_charge_delay:
			target = facing * extended_camera_distance
	_extended_offset = move_toward(_extended_offset, target, extended_camera_speed * delta)


func _clamp_camera_to_limits(p: Vector2) -> Vector2:
	var half := get_viewport_rect().size / camera.zoom * 0.5
	var min_x := camera.limit_left + half.x
	var max_x := camera.limit_right - half.x
	var min_y := camera.limit_top + half.y
	var max_y := camera.limit_bottom - half.y
	p.x = (min_x + max_x) * 0.5 if min_x > max_x else clampf(p.x, min_x, max_x)
	p.y = (min_y + max_y) * 0.5 if min_y > max_y else clampf(p.y, min_y, max_y)
	return p


func _draw_camera_debug() -> void:
	if not camera_debug_draw or camera == null:
		return
	var window := Rect2(
			-camera_border_left,
			-camera_air_border_up,
			camera_border_left + camera_border_right,
			camera_air_border_up + camera_air_border_down)
	camera.draw_rect(window, Color.WHITE, false, 1.0)
	camera.draw_line(Vector2(window.position.x - 8.0, 0.0), Vector2(window.end.x + 8.0, 0.0), Color.GREEN, 1.0)
	camera.draw_line(Vector2(0.0, -4.0), Vector2(0.0, 4.0), Color.GREEN, 1.0)
	camera.draw_circle(_cam_focus_point - _cam_pos, 2.0, Color.RED)
