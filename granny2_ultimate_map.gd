extends Node3D
# ============================================================
# GRANNY 2 ULTIMATE MAP - FINAL VERSION
# 5 Ebenen mit 24x20m Grundflaeche
# 400+ interaktive Objekte, 10+ Geheimraeume
# Kombinationsschloss, Fallen, Raetsel, Grusel-Effekte
# ============================================================

# ===== KONFIGURATION =====
@export_group("Texturen")
@export var tex_wood: Texture2D
@export var tex_wood_dark: Texture2D
@export var tex_wallpaper: Texture2D
@export var tex_concrete: Texture2D
@export var tex_tile: Texture2D
@export var tex_ceiling: Texture2D
@export var tex_fabric: Texture2D
@export var tex_metal: Texture2D
@export var tex_key: Texture2D
@export var tex_paper: Texture2D
@export var tex_brick: Texture2D
@export var tex_carpet: Texture2D

@export_group("EG")
@export var eg_floor_tex: Texture2D
@export var eg_wall_tex: Texture2D
@export var eg_ceiling_tex: Texture2D

@export_group("OG")
@export var og_floor_tex: Texture2D
@export var og_wall_tex: Texture2D
@export var og_ceiling_tex: Texture2D

@export_group("Attic")
@export var attic_floor_tex: Texture2D
@export var attic_wall_tex: Texture2D

@export_group("Basement")
@export var basement_floor_tex: Texture2D
@export var basement_wall_tex: Texture2D

@export_group("SubBasement")
@export var sub_floor_tex: Texture2D
@export var sub_wall_tex: Texture2D

@export_group("Einstellungen")
@export var enable_fog: bool = true
@export var fog_density: float = 0.03
@export var ambient_light_energy: float = 0.2
@export var player_speed: float = 5.0
@export var interaction_range: float = 3.0
@export var enable_ghost_events: bool = true
@export var ghost_spawn_chance: float = 0.1

# ===== KONSTANTEN =====
const SUB_Y := -6.0
const BASE_Y := -3.0
const EG_Y := 0.0
const OG_Y := 3.2
const ATTIC_Y := 6.4
const CEIL := 3.0
const WALL_T := 0.15
const EXT_T := 0.3
const DOOR_W := 1.6
const DOOR_H := 2.2
const W := 24.0
const D := 20.0
const PI := 3.14159265359
const TAU := 6.28318530718

# ===== MATERIALIEN =====
var mat_wood: StandardMaterial3D
var mat_wood_light: StandardMaterial3D
var mat_wood_dark: StandardMaterial3D
var mat_wall: StandardMaterial3D
var mat_concrete: StandardMaterial3D
var mat_ceiling: StandardMaterial3D
var mat_tile: StandardMaterial3D
var mat_metal: StandardMaterial3D
var mat_metal_rusty: StandardMaterial3D
var mat_fabric_red: StandardMaterial3D
var mat_fabric_blue: StandardMaterial3D
var mat_fabric_green: StandardMaterial3D
var mat_black: StandardMaterial3D
var mat_white: StandardMaterial3D
var mat_paper: StandardMaterial3D
var mat_gold: StandardMaterial3D
var mat_ceramic: StandardMaterial3D
var mat_glass: StandardMaterial3D
var mat_key: StandardMaterial3D
var mat_brick: StandardMaterial3D
var mat_carpet: StandardMaterial3D

# ===== ETAGEN-MATERIALIEN =====
var eg_mats: Dictionary
var og_mats: Dictionary
var attic_mats: Dictionary
var basement_mats: Dictionary
var sub_mats: Dictionary

# ===== INVENTAR =====
var inventory: Dictionary = {"keys": {}, "tools": {}, "notes": {}}
var current_note: String = ""

# ===== SPIELER & KAMERA =====
var player: CharacterBody3D
var camera: Camera3D
var raycast: RayCast3D

# ===== UI =====
var interaction_ui: Control
var message_ui: Label
var inventory_ui: Control
var note_ui: Control
var tasks_ui: Control
var crosshair: Control

# ===== INTERAKTIVE OBJEKTE =====
var interactive_objects: Array = []
var current_interactable: Node3D = null
var is_dragging: bool = false
var dragged_object: RigidBody3D = null
var drag_offset: Vector3 = Vector3.ZERO

# ===== GRUSEL-EFFEKTE =====
var flicker_timer: Timer
var sound_timer: Timer
var ghost_timer: Timer

# ===== AUFGABEN =====
var tasks: Array = [
    {"id": "find_keller_key", "text": "Finde den Keller-Schlüssel", "completed": false},
    {"id": "open_basement_door", "text": "Öffne die Kellertür", "completed": false},
    {"id": "find_attic_key", "text": "Finde den Dachboden-Schlüssel", "completed": false},
    {"id": "open_attic_door", "text": "Öffne die Dachbodentür", "completed": false},
    {"id": "find_master_key", "text": "Finde den Hauptschlüssel", "completed": false},
    {"id": "open_secret_room", "text": "Finde den Geheimraum", "completed": false},
    {"id": "solve_combination_lock", "text": "Löse Kombinationsschloss (7-3-9)", "completed": false},
    {"id": "find_ghost_room", "text": "Finde den Geisterraum", "completed": false}
]

var light_switches: Array = []
var ambient_sounds: Array = [
    "res://sounds/creak1.wav", "res://sounds/creak2.wav",
    "res://sounds/whisper1.wav", "res://sounds/whisper2.wav",
    "res://sounds/door_slam.wav", "res://sounds/footsteps1.wav"
]


# ============================================================
# HILFSFUNKTIONEN
# ============================================================

func _m(c: Color, rough: float, metal: float, tex: Texture2D) -> StandardMaterial3D:
    var m = StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = rough
    m.metallic = metal
    if tex != null:
        m.albedo_texture = tex
        m.texture_repeat = true
        m.uv1_scale = Vector3(2, 2, 2)
    return m

func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, collide: bool) -> void:
    var mesh = MeshInstance3D.new()
    mesh.mesh = BoxMesh.new()
    mesh.mesh.size = size
    mesh.material_override = mat
    mesh.position = pos
    parent.add_child(mesh)
    if collide:
        var collision = CollisionShape3D.new()
        collision.shape = BoxShape3D.new()
        collision.shape.size = size
        collision.position = pos
        parent.add_child(collision)

func _cyl(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material, collide: bool) -> void:
    var mesh = MeshInstance3D.new()
    mesh.mesh = CylinderMesh.new()
    mesh.mesh.radius = radius
    mesh.mesh.height = height
    mesh.material_override = mat
    mesh.position = pos
    parent.add_child(mesh)
    if collide:
        var collision = CollisionShape3D.new()
        collision.shape = CylinderShape3D.new()
        collision.shape.radius = radius
        collision.shape.height = height
        collision.position = pos
        parent.add_child(collision)

func _floor(parent: Node3D, x1: float, x2: float, z1: float, z2: float, y: float, mat: Material) -> void:
    var size = Vector3(x2 - x1, 0.1, z2 - z1)
    _box(parent, Vector3((x1 + x2) / 2, y + 0.05, (z1 + z2) / 2), size, mat, true)

func _floor_hole(parent: Node3D, x1: float, x2: float, z1: float, z2: float, y: float, mat: Material, hx1: float, hx2: float, hz1: float, hz2: float) -> void:
    _floor(parent, x1, x2, z1, z2, y, mat)
    var hole_mat = StandardMaterial3D.new()
    hole_mat.albedo_color = Color(0, 0, 0, 0)
    hole_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _floor(parent, hx1, hx2, hz1, hz2, y + 0.01, hole_mat)

func _wall_x(parent: Node3D, x1: float, x2: float, z: float, y: float, height: float, thickness: float, mat: Material, doors: Array = []) -> void:
    var segments = []
    var current_x = x1
    for door in doors:
        var door_x = door[0]
        var door_w = door[1]
        if door_x > current_x:
            segments.append([current_x, door_x])
        current_x = door_x + door_w
    if current_x < x2:
        segments.append([current_x, x2])
    if segments.size() == 0:
        segments.append([x1, x2])
    for seg in segments:
        var sx1 = seg[0]
        var sx2 = seg[1]
        var size = Vector3(sx2 - sx1, height, thickness)
        _box(parent, Vector3((sx1 + sx2) / 2, y + height / 2, z), size, mat, true)

func _wall_z(parent: Node3D, z1: float, z2: float, x: float, y: float, height: float, thickness: float, mat: Material, doors: Array = []) -> void:
    var segments = []
    var current_z = z1
    for door in doors:
        var door_z = door[0]
        var door_w = door[1]
        if door_z > current_z:
            segments.append([current_z, door_z])
        current_z = door_z + door_w
    if current_z < z2:
        segments.append([current_z, z2])
    if segments.size() == 0:
        segments.append([z1, z2])
    for seg in segments:
        var sz1 = seg[0]
        var sz2 = seg[1]
        var size = Vector3(thickness, height, sz2 - sz1)
        _box(parent, Vector3(x, y + height / 2, (sz1 + sz2) / 2), size, mat, true)

func _stairs(parent: Node3D, x: float, z: float, width: float, y1: float, y2: float, step_height: float, mat: Material) -> void:
    var direction = 1.0 if y2 > y1 else -1.0
    var num_steps = int(abs(y2 - y1) / step_height)
    for i in range(num_steps):
        var step_y = y1 + (i + 0.5) * step_height * direction
        var step_z = z + i * 0.3 * direction
        _box(parent, Vector3(x, step_y + 0.05, step_z), Vector3(width, 0.1, 0.3), mat, true)

# ============================================================
# MATERIAL-INITIALISIERUNG
# ============================================================

func _init_materials() -> void:
    mat_wood = _m(Color(0.25, 0.15, 0.1), 0.7, 0.0, tex_wood)
    mat_wood_light = _m(Color(0.45, 0.3, 0.2), 0.6, 0.0, null)
    mat_wood_dark = _m(Color(0.15, 0.08, 0.05), 0.8, 0.0, tex_wood_dark)
    mat_wall = _m(Color(0.5, 0.4, 0.3), 0.95, 0.0, tex_wallpaper)
    mat_concrete = _m(Color(0.25, 0.25, 0.28), 0.98, 0.0, tex_concrete)
    mat_ceiling = _m(Color(0.4, 0.35, 0.3), 0.95, 0.0, tex_ceiling)
    mat_tile = _m(Color(0.45, 0.5, 0.55), 0.6, 0.0, tex_tile)
    mat_metal = _m(Color(0.45, 0.45, 0.5), 0.4, 0.8, tex_metal)
    mat_metal_rusty = _m(Color(0.35, 0.25, 0.2), 0.9, 0.5, null)
    mat_fabric_red = _m(Color(0.35, 0.05, 0.05), 0.98, 0.0, tex_fabric)
    mat_fabric_blue = _m(Color(0.1, 0.15, 0.3), 0.98, 0.0, null)
    mat_fabric_green = _m(Color(0.1, 0.25, 0.1), 0.98, 0.0, null)
    mat_black = _m(Color(0.02, 0.02, 0.03), 0.95, 0.0, null)
    mat_white = _m(Color(0.7, 0.7, 0.65), 0.8, 0.0, null)
    mat_paper = _m(Color(0.75, 0.7, 0.6), 0.95, 0.0, tex_paper)
    mat_gold = _m(Color(0.65, 0.5, 0.2), 0.5, 0.9, null)
    mat_ceramic = _m(Color(0.75, 0.72, 0.68), 0.4, 0.0, null)
    mat_glass = StandardMaterial3D.new()
    mat_glass.albedo_color = Color(0.6, 0.7, 0.8, 0.3)
    mat_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat_glass.roughness = 0.2
    mat_key = _m(Color(0.7, 0.6, 0.4), 0.5, 0.8, tex_key)
    mat_brick = _m(Color(0.4, 0.25, 0.2), 0.8, 0.0, tex_brick)
    mat_carpet = _m(Color(0.5, 0.1, 0.1), 0.9, 0.0, tex_carpet)

func _init_etage_materials() -> void:
    eg_mats = {
        "floor": _m(Color(0.35, 0.22, 0.15), 0.75, 0.0, eg_floor_tex if eg_floor_tex else tex_wood),
        "wall": _m(Color(0.5, 0.4, 0.3), 0.95, 0.0, eg_wall_tex if eg_wall_tex else tex_wallpaper),
        "ceiling": _m(Color(0.4, 0.35, 0.3), 0.95, 0.0, eg_ceiling_tex if eg_ceiling_tex else tex_ceiling),
        "wood": mat_wood, "wood_dark": mat_wood_dark, "wood_light": mat_wood_light,
        "fabric": mat_fabric_red, "metal": mat_metal, "concrete": mat_concrete,
        "tile": mat_tile, "brick": mat_brick, "carpet": mat_carpet
    }
    
    og_mats = {
        "floor": _m(Color(0.25, 0.15, 0.1), 0.8, 0.0, og_floor_tex if og_floor_tex else tex_wood_dark),
        "wall": _m(Color(0.35, 0.28, 0.22), 0.98, 0.0, og_wall_tex if og_wall_tex else tex_wallpaper),
        "ceiling": _m(Color(0.3, 0.25, 0.22), 0.96, 0.0, og_ceiling_tex if og_ceiling_tex else tex_ceiling),
        "wood": mat_wood_dark, "wood_dark": mat_wood_dark, "wood_light": mat_wood,
        "fabric": mat_fabric_blue, "metal": mat_metal_rusty, "concrete": mat_concrete,
        "tile": mat_tile, "brick": mat_brick, "carpet": mat_carpet
    }
    
    attic_mats = {
        "floor": _m(Color(0.15, 0.08, 0.05), 0.9, 0.0, attic_floor_tex if attic_floor_tex else tex_wood_dark),
        "wall": _m(Color(0.25, 0.2, 0.18), 0.99, 0.0, attic_wall_tex if attic_wall_tex else tex_wallpaper),
        "ceiling": mat_wood_dark,
        "wood": mat_wood_dark, "wood_dark": mat_wood_dark, "wood_light": mat_wood,
        "fabric": mat_fabric_green, "metal": mat_metal_rusty, "concrete": mat_concrete,
        "tile": mat_tile, "brick": mat_brick, "carpet": mat_carpet
    }
    
    basement_mats = {
        "floor": _m(Color(0.2, 0.2, 0.22), 0.98, 0.0, basement_floor_tex if basement_floor_tex else tex_concrete),
        "wall": _m(Color(0.22, 0.22, 0.25), 0.99, 0.0, basement_wall_tex if basement_wall_tex else tex_concrete),
        "ceiling": _m(Color(0.2, 0.2, 0.22), 0.98, 0.0, tex_concrete),
        "wood": mat_wood_dark, "wood_dark": mat_wood_dark, "wood_light": mat_wood,
        "fabric": mat_fabric_red, "metal": mat_metal_rusty, "concrete": mat_concrete,
        "tile": mat_tile, "brick": mat_brick, "carpet": mat_carpet
    }
    
    sub_mats = {
        "floor": _m(Color(0.15, 0.15, 0.18), 0.99, 0.0, sub_floor_tex if sub_floor_tex else tex_concrete),
        "wall": _m(Color(0.18, 0.18, 0.2), 0.99, 0.0, sub_wall_tex if sub_wall_tex else tex_concrete),
        "ceiling": _m(Color(0.15, 0.15, 0.18), 0.99, 0.0, tex_concrete),
        "wood": mat_wood_dark, "wood_dark": mat_wood_dark, "wood_light": mat_wood,
        "fabric": mat_fabric_red, "metal": mat_metal_rusty, "concrete": mat_concrete,
        "tile": mat_tile, "brick": mat_brick, "carpet": mat_carpet
    }


# ============================================================
# WELT & SPIELER
# ============================================================

func _init_world() -> void:
    var env = Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.0, 0.0, 0.0)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.1, 0.1, 0.15)
    env.ambient_light_energy = ambient_light_energy
    env.fog_enabled = enable_fog
    env.fog_light_color = Color(0.01, 0.01, 0.02)
    env.fog_density = fog_density
    env.fog_depth_begin = 0.1
    env.fog_depth_end = 12.0
    var we = WorldEnvironment.new()
    we.environment = env
    add_child(we)

    flicker_timer = Timer.new()
    flicker_timer.wait_time = randf_range(3.0, 8.0)
    flicker_timer.timeout.connect(_on_flicker_timer_timeout)
    add_child(flicker_timer)
    flicker_timer.start()

    sound_timer = Timer.new()
    sound_timer.wait_time = randf_range(5.0, 15.0)
    sound_timer.timeout.connect(_on_sound_timer_timeout)
    add_child(sound_timer)
    sound_timer.start()

    ghost_timer = Timer.new()
    ghost_timer.wait_time = 60.0
    ghost_timer.timeout.connect(_on_ghost_timer_timeout)
    add_child(ghost_timer)
    ghost_timer.start()

func _create_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    add_child(player)

    var collision = CollisionShape3D.new()
    collision.shape = CapsuleShape3D.new()
    collision.shape.radius = 0.5
    collision.shape.height = 1.8
    player.add_child(collision)

    camera = Camera3D.new()
    camera.position = Vector3(0, 1.6, 0)
    camera.current = true
    player.add_child(camera)

    raycast = RayCast3D.new()
    raycast.position = Vector3(0, 0, -0.5)
    raycast.target_position = Vector3(0, 0, -interaction_range)
    camera.add_child(raycast)

    var footstep_timer = Timer.new()
    footstep_timer.wait_time = 0.5
    footstep_timer.timeout.connect(_on_footstep_timer_timeout)
    player.add_child(footstep_timer)

    var script = GDScript.new()
    script.source_code = """
extends CharacterBody3D
@export var speed: float = 5.0
@export var jump_force: float = 4.5
@export var mouse_sensitivity: float = 0.002
@export var is_walking: bool = false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func _input(event):
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
        $Camera3D.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
        $Camera3D.rotation.x = clamp($Camera3D.rotation.x, deg_to_rad(-80), deg_to_rad(80))
func _physics_process(delta):
    if not is_on_floor():
        velocity.y -= gravity * delta
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_force
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction = (global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    if direction.length() > 0.1:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
        is_walking = true
    else:
        velocity.x = move_toward(velocity.x, 0, speed)
        velocity.z = move_toward(velocity.z, 0, speed)
        is_walking = false
    move_and_slide()
"""
    player.set_script(script)
    player.speed = player_speed
    player.position = Vector3(4, 0.1, 4)

func _on_footstep_timer_timeout() -> void:
    if player.is_walking and player.is_on_floor():
        var sound = AudioStreamPlayer3D.new()
        sound.position = player.global_position
        sound.stream = load(ambient_sounds[randi() % 2 + 4]) if ambient_sounds.size() > 4 else null
        if sound.stream:
            sound.volume_db = -5
            add_child(sound)
            sound.play()

# ============================================================
# UI
# ============================================================

func _create_ui() -> void:
    var canvas = CanvasLayer.new()
    add_child(canvas)

    # INTERAKTIONS-UI
    interaction_ui = Control.new()
    interaction_ui.anchor_right = 0.5
    interaction_ui.anchor_bottom = 1.0
    interaction_ui.position = Vector2(-100, -50)
    interaction_ui.size = Vector2(200, 40)
    interaction_ui.self_modulate = Color(1, 1, 1, 0.8)
    var interaction_label = Label.new()
    interaction_label.text = ""
    interaction_label.font_size = 24
    interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    interaction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    interaction_ui.add_child(interaction_label)
    interaction_ui.hide()
    canvas.add_child(interaction_ui)

    # NACHRICHTEN-UI
    message_ui = Label.new()
    message_ui.position = Vector2(10, -50)
    message_ui.size = Vector2(400, 100)
    message_ui.font_size = 20
    message_ui.self_modulate = Color(1, 1, 1, 0.9)
    message_ui.background_color = Color(0, 0, 0, 0.7)
    message_ui.visible = false
    canvas.add_child(message_ui)

    # INVENTAR-UI
    inventory_ui = Control.new()
    inventory_ui.position = Vector2(10, 10)
    inventory_ui.size = Vector2(300, 400)
    inventory_ui.visible = false
    inventory_ui.self_modulate = Color(1, 1, 1, 0.9)
    inventory_ui.background_color = Color(0.1, 0.1, 0.15, 0.9)
    
    var inv_title = Label.new()
    inv_title.text = "INVENTAR"
    inv_title.font_size = 28
    inv_title.position = Vector2(10, 10)
    inv_title.size = Vector2(280, 40)
    inv_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    inventory_ui.add_child(inv_title)
    
    var keys_label = Label.new()
    keys_label.text = "Schlüssel:"
    keys_label.font_size = 20
    keys_label.position = Vector2(10, 60)
    inventory_ui.add_child(keys_label)
    
    var keys_container = Control.new()
    keys_container.position = Vector2(10, 90)
    keys_container.size = Vector2(280, 100)
    inventory_ui.add_child(keys_container)
    
    var tools_label = Label.new()
    tools_label.text = "Werkzeuge:"
    tools_label.font_size = 20
    tools_label.position = Vector2(10, 200)
    inventory_ui.add_child(tools_label)
    
    var tools_container = Control.new()
    tools_container.position = Vector2(10, 230)
    tools_container.size = Vector2(280, 100)
    inventory_ui.add_child(tools_container)
    
    var notes_label = Label.new()
    notes_label.text = "Notizen:"
    notes_label.font_size = 20
    notes_label.position = Vector2(10, 340)
    inventory_ui.add_child(notes_label)
    
    var notes_container = Control.new()
    notes_container.position = Vector2(10, 370)
    notes_container.size = Vector2(280, 30)
    inventory_ui.add_child(notes_container)
    
    canvas.add_child(inventory_ui)

    # NOTIZEN-UI
    note_ui = Control.new()
    note_ui.position = Vector2(0, 0)
    note_ui.size = Vector2(get_viewport_rect().size)
    note_ui.visible = false
    note_ui.self_modulate = Color(0, 0, 0, 0.8)
    
    var note_text = RichTextLabel.new()
    note_text.position = Vector2(50, 50)
    note_text.size = Vector2(get_viewport_rect().size.x - 100, get_viewport_rect().size.y - 100)
    note_text.font_size = 20
    note_text.background_color = Color(0.1, 0.1, 0.1, 0.9)
    note_ui.add_child(note_text)
    
    var close_btn = Button.new()
    close_btn.text = "X"
    close_btn.font_size = 24
    close_btn.position = Vector2(get_viewport_rect().size.x - 50, 10)
    close_btn.size = Vector2(40, 40)
    close_btn.pressed.connect(func(): note_ui.visible = false)
    note_ui.add_child(close_btn)
    
    canvas.add_child(note_ui)

    # AUFGABEN-UI
    tasks_ui = Control.new()
    tasks_ui.position = Vector2(get_viewport_rect().size.x - 310, 10)
    tasks_ui.size = Vector2(300, 400)
    tasks_ui.visible = false
    tasks_ui.self_modulate = Color(1, 1, 1, 0.9)
    tasks_ui.background_color = Color(0.1, 0.1, 0.15, 0.9)
    
    var tasks_title = Label.new()
    tasks_title.text = "AUFGABEN"
    tasks_title.font_size = 28
    tasks_title.position = Vector2(10, 10)
    tasks_title.size = Vector2(280, 40)
    tasks_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    tasks_ui.add_child(tasks_title)
    
    var tasks_container = Control.new()
    tasks_container.position = Vector2(10, 60)
    tasks_container.size = Vector2(280, 330)
    tasks_ui.add_child(tasks_container)
    
    canvas.add_child(tasks_ui)

    # CROSSHAIR
    crosshair = Control.new()
    crosshair.anchor_right = 0.5
    crosshair.anchor_bottom = 0.5
    crosshair.position = Vector2(0, 0)
    crosshair.size = Vector2(20, 20)
    
    var cross_h = TextureRect.new()
    cross_h.texture = Texture2D.new()
    cross_h.texture.create(1, 1, Image.FORMAT_RF, Image.USAGE_SAMPLING)
    cross_h.texture.fill(Color.WHITE)
    cross_h.size = Vector2(20, 2)
    cross_h.position = Vector2(0, 9)
    crosshair.add_child(cross_h)
    
    var cross_v = TextureRect.new()
    cross_v.texture = Texture2D.new()
    cross_v.texture.create(1, 1, Image.FORMAT_RF, Image.USAGE_SAMPLING)
    cross_v.texture.fill(Color.WHITE)
    cross_v.size = Vector2(2, 20)
    cross_v.position = Vector2(9, 0)
    crosshair.add_child(cross_v)
    
    canvas.add_child(crosshair)

func _update_inventory_ui() -> void:
    var keys_container = inventory_ui.get_child(3)
    keys_container.clear_children()
    var y = 0
    for key_id in inventory["keys"]:
        if inventory["keys"][key_id]:
            var label = Label.new()
            label.text = "➜ " + key_id.replace("_", " ").capitalize()
            label.font_size = 18
            label.position = Vector2(10, y)
            label.size = Vector2(260, 25)
            keys_container.add_child(label)
            y += 25
    
    var tools_container = inventory_ui.get_child(5)
    tools_container.clear_children()
    y = 0
    for tool_id in inventory["tools"]:
        if inventory["tools"][tool_id]:
            var label = Label.new()
            label.text = "➜ " + tool_id.replace("_", " ").capitalize()
            label.font_size = 18
            label.position = Vector2(10, y)
            label.size = Vector2(260, 25)
            tools_container.add_child(label)
            y += 25
    
    var notes_container = inventory_ui.get_child(7)
    notes_container.clear_children()
    y = 0
    for note_id in inventory["notes"]:
        if inventory["notes"][note_id]:
            var btn = Button.new()
            btn.text = "➜ " + note_id.replace("_", " ").capitalize()
            btn.font_size = 18
            btn.position = Vector2(10, y)
            btn.size = Vector2(260, 25)
            btn.pressed.connect(func(): _show_note(note_id))
            notes_container.add_child(btn)
            y += 25

func _update_tasks_ui() -> void:
    var container = tasks_ui.get_child(1)
    container.clear_children()
    var y = 0
    for task in tasks:
        var label = Label.new()
        label.text = ("✓ " if task["completed"] else "○ ") + task["text"]
        label.font_size = 18
        label.position = Vector2(10, y)
        label.size = Vector2(260, 25)
        label.self_modulate = Color(0.5, 0.8, 0.5) if task["completed"] else Color(1, 0.8, 0.8)
        container.add_child(label)
        y += 25

func _show_interaction(text: String) -> void:
    interaction_ui.get_child(0).text = text
    interaction_ui.show()

func _hide_interaction() -> void:
    interaction_ui.hide()

func _show_message(text: String, duration: float = 3.0) -> void:
    message_ui.text = text
    message_ui.visible = true
    var timer = Timer.new()
    timer.wait_time = duration
    timer.timeout.connect(func(): message_ui.visible = false)
    add_child(timer)
    timer.start()

func _show_note(note_id: String) -> void:
    current_note = note_id
    note_ui.get_child(0).text = inventory["notes"][note_id]
    note_ui.visible = true

func _complete_task(task_id: String) -> void:
    for i in range(tasks.size()):
        if tasks[i]["id"] == task_id:
            tasks[i]["completed"] = true
            _update_tasks_ui()
            _show_message("Aufgabe: " + tasks[i]["text"])
            break

# ============================================================
# INTERAKTIVE OBJEKTE
# ============================================================

func _create_door(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, is_locked: bool = false, key_id: String = "", door_type: String = "normal") -> Node3D:
    var door = Node3D.new()
    door.name = "Door_" + door_type + "_" + str(parent.get_children().size())
    door.position = pos
    parent.add_child(door)

    var mesh = MeshInstance3D.new()
    mesh.mesh = BoxMesh.new()
    mesh.mesh.size = Vector3(size.x, size.y, 0.1)
    mesh.material_override = mat
    door.add_child(mesh)

    var collision = CollisionShape3D.new()
    collision.shape = BoxShape3D.new()
    collision.shape.size = Vector3(size.x, size.y, 0.1)
    door.add_child(collision)

    var area = Area3D.new()
    area.name = "InteractionArea"
    area.add_child(CollisionShape3D.new())
    area.get_child(0).shape = BoxShape3D.new()
    area.get_child(0).shape.size = Vector3(size.x + 1, size.y + 1, 1.0)
    door.add_child(area)

    var anim = AnimationPlayer.new()
    door.add_child(anim)

    var anim_open = Animation.new()
    anim_open.length = 1.0
    anim_open.track_insert_key(0, 0.0, mesh.rotation.y)
    anim_open.track_insert_key(0, 1.0, mesh.rotation.y - PI/2)
    anim.add_animation("open", anim_open)

    var anim_close = Animation.new()
    anim_close.length = 1.0
    anim_close.track_insert_key(0, 0.0, mesh.rotation.y - PI/2)
    anim_close.track_insert_key(0, 1.0, mesh.rotation.y)
    anim.add_animation("close", anim_close)

    var script = GDScript.new()
    script.source_code = """
extends Node3D
@export var is_locked: bool = false
@export var key_id: String = ""
@export var is_open: bool = false
@export var door_type: String = "normal"
var area: Area3D
var anim: AnimationPlayer
var mesh: MeshInstance3D
var collision: CollisionShape3D
func _ready():
    area = $InteractionArea
    anim = $AnimationPlayer
    mesh = $MeshInstance3D
    collision = $CollisionShape3D
    area.body_entered.connect(_on_body_entered)
    area.body_exited.connect(_on_body_exited)
func _on_body_entered(body):
    if body.name == "Player":
        if is_locked:
            if not key_id.is_empty() and get_parent().get_parent().inventory["keys"].get(key_id, false):
                get_parent().get_parent()._show_interaction("E: Tür entriegeln")
            else:
                get_parent().get_parent()._show_interaction("E: Tür verriegelt")
        else:
            get_parent().get_parent()._show_interaction("E: Tür " + ("schließen" if is_open else "öffnen"))
func _on_body_exited(body):
    if body.name == "Player":
        get_parent().get_parent()._hide_interaction()
func interact():
    if is_locked:
        if not key_id.is_empty() and get_parent().get_parent().inventory["keys"].get(key_id, false):
            is_locked = false
            get_parent().get_parent()._show_message("Tür entriegelt!")
            return true
        else:
            get_parent().get_parent()._show_message("Tür verriegelt! Braucht: " + key_id.replace("_", " ").capitalize())
            return false
    is_open = !is_open
    if is_open:
        anim.play("open")
        collision.disabled = true
    else:
        anim.play("close")
        collision.disabled = false
    if door_type == "basement" and is_open:
        get_parent().get_parent()._complete_task("open_basement_door")
    elif door_type == "attic" and is_open:
        get_parent().get_parent()._complete_task("open_attic_door")
    return true
"""
    door.set_script(script)
    door.is_locked = is_locked
    door.key_id = key_id
    door.door_type = door_type

    interactive_objects.append(door)
    return door

func _create_painting_with_secret(parent: Node3D, pos: Vector3, size: Vector3, style: int = 0, secret_door: Node3D = null) -> Node3D:
    var painting = Node3D.new()
    painting.name = "Painting_" + str(parent.get_children().size())
    painting.position = pos
    parent.add_child(painting)

    var frame_colors = [Color(0.35, 0.2, 0.1), Color(0.55, 0.45, 0.2), Color(0.15, 0.15, 0.15)]
    var canvas_colors = [Color(0.4, 0.3, 0.25), Color(0.3, 0.35, 0.4), Color(0.55, 0.5, 0.35)]

    var frame = MeshInstance3D.new()
    frame.mesh = BoxMesh.new()
    frame.mesh.size = size
    frame.material_override = _m(frame_colors[style % 3], 0.6, 0.3, null)
    painting.add_child(frame)

    var canvas = MeshInstance3D.new()
    canvas.mesh = BoxMesh.new()
    canvas.mesh.size = size - Vector3(0.15, 0.15, 0.01)
    canvas.position = Vector3(0, 0, 0.02)
    canvas.material_override = _m(canvas_colors[style % 3], 0.9, 0.0, null)
    painting.add_child(canvas)

    var area = Area3D.new()
    area.name = "InteractionArea"
    area.add_child(CollisionShape3D.new())
    area.get_child(0).shape = BoxShape3D.new()
    area.get_child(0).shape.size = size * 1.2
    painting.add_child(area)

    var script = GDScript.new()
    script.source_code = """
extends Node3D
var area: Area3D
var is_rotated: bool = false
var secret_door: Node3D
func _ready():
    area = $InteractionArea
    area.body_entered.connect(_on_body_entered)
    area.body_exited.connect(_on_body_exited)
    if secret_door:
        secret_door.visible = false
func _on_body_entered(body):
    if body.name == "Player":
        get_parent().get_parent()._show_interaction("E: Bild drehen")
func _on_body_exited(body):
    if body.name == "Player":
        get_parent().get_parent()._hide_interaction()
func interact():
    is_rotated = !is_rotated
    var target_angle = PI/2 if is_rotated else 0.0
    var tween = create_tween()
    tween.tween_property($MeshInstance3D, "rotation_y", target_angle, 1.0)
    if secret_door:
        secret_door.visible = is_rotated
        if is_rotated:
            get_parent().get_parent()._show_message("Versteckte Tür freigelegt!")
    return true
"""
    painting.set_script(script)
    painting.secret_door = secret_door

    interactive_objects.append(painting)
    return painting

func _create_rotating_bookshelf(parent: Node3D, pos: Vector3, size: Vector3, mats: Dictionary, secret_passage: Node3D = null) -> RigidBody3D:
    var bookshelf = RigidBody3D.new()
    bookshelf.name = "RotatingBookshelf_" + str(parent.get_children().size())
    bookshelf.position = pos
    parent.add_child(bookshelf)

    var mesh = MeshInstance3D.new()
    mesh.mesh = BoxMesh.new()
    mesh.mesh.size = size
    mesh.material_override = mats["wood_dark"]
    bookshelf.add_child(mesh)

    var collision = CollisionShape3D.new()
    collision.shape = BoxShape3D.new()
    collision.shape.size = size
    bookshelf.add_child(collision)

    bookshelf.mass = 50.0
    bookshelf.linear_damp = 0.9
    bookshelf.angular_damp = 0.9
    bookshelf.can_sleep = true
    bookshelf.sleeping = true

    var area = Area3D.new()
    area.name = "InteractionArea"
    area.add_child(CollisionShape3D.new())
    area.get_child(0).shape = BoxShape3D.new()
    area.get_child(0).shape.size = size * 1.2
    bookshelf.add_child(area)

    var script = GDScript.new()
    script.source_code = """
extends RigidBody3D
var area: Area3D
var is_rotating: bool = false
var secret_passage: Node3D
var initial_rotation: float = 0.0
var target_rotation: float = PI/2
var rotation_speed: float = 1.0
func _ready():
    area = $InteractionArea
    area.body_entered.connect(_on_body_entered)
    area.body_exited.connect(_on_body_exited)
    initial_rotation = rotation.y
    secret_passage = get_parent().get_parent().get_node_or_null(get_name().replace("RotatingBookshelf_", "SecretPassage_"))
    if secret_passage:
        secret_passage.visible = false
func _on_body_entered(body):
    if body.name == "Player":
        get_parent().get_parent()._show_interaction("E: Regal drehen")
func _on_body_exited(body):
    if body.name == "Player":
        get_parent().get_parent()._hide_interaction()
func interact():
    if not is_rotating:
        is_rotating = true
        var tween = create_tween()
        tween.tween_property(self, "rotation_y", initial_rotation + target_rotation, rotation_speed)
        tween.tween_callback(self, "_on_rotation_complete")
    return true
func _on_rotation_complete():
    is_rotating = false
    if secret_passage:
        secret_passage.visible = true
        get_parent().get_parent()._show_message("Geheimgang freigelegt!")
func _physics_process(delta):
    rotation.y = clamp(rotation.y, initial_rotation - 0.1, initial_rotation + target_rotation + 0.1)
"""
    bookshelf.set_script(script)
    bookshelf.secret_passage = secret_passage

    interactive_objects.append(bookshelf)
    return bookshelf

func _create_pushable_object(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> RigidBody3D:
    var obj = RigidBody3D.new()
    obj.name = "Pushable_" + str(parent.get_children().size())
    obj.position = pos
    parent.add_child(obj)

    var mesh = MeshInstance3D.new()
    mesh.mesh = BoxMesh.new()
    mesh.mesh.size = size
    mesh.material_override = mat
    obj.add_child(mesh)

    var collision = CollisionShape3D.new()
    collision.shape = BoxShape3D.new()
    collision.shape.size = size
    obj.add_child(collision)

    obj.mass = 10.0 if size.x * size.y * size.z < 1.0 else 20.0
    obj.linear_damp = 0.8
    obj.angular_damp = 0.8
    obj.can_sleep = true
    obj.sleeping = true

    var area = Area3D.new()
    area.name = "InteractionArea"
    area.add_child(CollisionShape3D.new())
    area.get_child(0).shape = BoxShape3D.new()
    area.get_child(0).shape.size = size * 1.2
    obj.add_child(area)

    var script = GDScript.new()
    script.source_code = """
extends RigidBody3D
var area: Area3D
func _ready():
    area = $InteractionArea
    area.body_entered.connect(_on_body_entered)
    area.body_exited.connect(_on_body_exited)
func _on_body_entered(body):
    if body.name == "Player":
        get_parent().get_parent()._show_interaction("Linksklick + Ziehen: Verschieben")
func _on_body_exited(body):
    if body.name == "Player":
        get_parent().get_parent()._hide_interaction()
func interact():
    return false
"""
    obj.set_script(script)

    interactive_objects.append(obj)
    return obj

func _create_key(parent: Node3D, pos: Vector3, key_id: String) -> Node3D:
    var key = Node3D.new()
    key.name = "Key_" + key_id
    key.position = pos
    parent.add_child(key)

    var mesh = MeshInstance3D.new()
    mesh.mesh = BoxMesh.new()
    mesh.mesh.size = Vector3(0.05, 0.02, 0.15)
    mesh.material_override = mat_key
    key.add_child(mesh)

    var area = Area3D.new()
    area.name = "InteractionArea"
    area.add_child(CollisionShape3D.new())
    area.get_child(0).shape = BoxShape3D.new()
    area.get_child(0).shape.size = Vector3(0.3, 0.3, 0.3)
    key.add_child(area)

    var script = GDScript.new()
    script.source_code = """
extends Node3D
var area: Area3D
var key_id: String
func _ready():
    area = $InteractionArea
    key_id = get_name().replace("Key_", "")
    area.body_entered.connect(_on_body_entered)
    area.body_exited.connect(_on_body_exited)
func _on_body_entered(body):
    if body.name == "Player":
        get_parent().get_parent()._show_interaction("E: Schlüssel aufheben")
func _on_body_exited(body):
    if body.name == "Player":
        get_parent().get_parent()._hide_interaction()
func interact():
    get_parent().get_parent().inventory["keys"][key_id] = true
    get_parent().get_parent()._update_inventory_ui()
    get_parent().get_parent()._show_message("Schlüssel: " + key_id.replace("_", " ").capitalize())
    if key_id == "keller_key":
        get_parent().get_parent()._complete_task("find_keller_key")
    elif key_id == "attic_key":
        get_parent().get_parent()._complete_task("find_attic_key")
    elif key_id == "master_key":
        get_parent().get_parent()._complete_task("find_master_key")
    queue_free()
    return true
"""
    key.set_script(script)

    interactive_objects.append(key)
    return key

func _create_note(parent: Node3D, pos: Vector3, note_id: String, text: String) -> Node3D:
    var note = Node3D.new()
    note.name = "Note_" + note_id
    note.position = pos
    parent.add_child(note)

    var mesh = MeshInstance3D.new()
    mesh.mesh = BoxMesh.new()
    mesh.mesh.size = Vector3(0.15, 0.01, 0.2)
    mesh.material_override = mat_paper
    note.add_child(mesh)

    var text_node = Node3D.new()
    text_node.name = "Text"
    text_node.set_meta("text", text)
    note.add_child(text_node)

    var area = Area3D.new()
    area.name = "InteractionArea"
    area.add_child(CollisionShape3D.new())
    area.get_child(0).shape = BoxShape3D.new()
    area.get_child(0).shape.size = Vector3(0.3, 0.3, 0.3)
    note.add_child(area)

    var script = GDScript.new()
    script.source_code = """
extends Node3D
var area: Area3D
var note_id: String
var text: String
func _ready():
    area = $InteractionArea
    note_id = get_name().replace("Note_", "")
    text = get_child(0).get_meta("text") if get_child_count() > 0 else ""
    area.body_entered.connect(_on_body_entered)
    area.body_exited.connect(_on_body_exited)
func _on_body_entered(body):
    if body.name == "Player":
        get_parent().get_parent()._show_interaction("E: Notiz lesen")
func _on_body_exited(body):
    if body.name == "Player":
        get_parent().get_parent()._hide_interaction()
func interact():
    get_parent().get_parent().inventory["notes"][note_id] = text
    get_parent().get_parent()._update_inventory_ui()
    get_parent().get_parent()._show_message("Notiz: " + note_id.replace("_", " ").capitalize())
    get_parent().get_parent()._show_note(note_id)
    return true
"""
    note.set_script(script)

    interactive_objects.append(note)
    return note

func _create_combination_lock(parent: Node3D, pos: Vector3, mat: Material, code: Array, target_door: Node3D) -> Node3D:
    var lock = Node3D.new()
    lock.name = "CombinationLock_" + str(parent.get_children().size())
    lock.position = pos
    parent.add_child(lock)

    var base = MeshInstance3D.new()
    base.mesh = BoxMesh.new()
    base.mesh.size = Vector3(0.4, 0.3, 0.15)
    base.material_override = mat
    lock.add_child(base)

    var display = MeshInstance3D.new()
    display.mesh = BoxMesh.new()
    display.mesh.size = Vector3(0.35, 0.2, 0.02)
    display.position = Vector3(0, 0.1, 0.08)
    display.material_override = mat_black
    lock.add_child(display)

    var area = Area3D.new()
    area.name = "InteractionArea"
    area.add_child(CollisionShape3D.new())
    area.get_child(0).shape = BoxShape3D.new()
    area.get_child(0).shape.size = Vector3(0.6, 0.5, 0.3)
    lock.add_child(area)

    var script = GDScript.new()
    script.source_code = """
extends Node3D
@export var code: Array = []
@export var target_door: Node3D
var area: Area3D
var current_combination: Array = [0, 0, 0]
var current_digit: int = 0
func _ready():
    area = $InteractionArea
    area.body_entered.connect(_on_body_entered)
    area.body_exited.connect(_on_body_exited)
func _on_body_entered(body):
    if body.name == "Player":
        get_parent().get_parent()._show_interaction("E: Kombinationsschloss (Code: 7-3-9)")
func _on_body_exited(body):
    if body.name == "Player":
        get_parent().get_parent()._hide_interaction()
func interact():
    current_digit = (current_digit + 1) % 3
    current_combination[current_digit] = (current_combination[current_digit] + 1) % 10
    var correct = true
    for i in range(3):
        if current_combination[i] != code[i]:
            correct = false
            break
    if correct:
        get_parent().get_parent()._show_message("Kombinationsschloss geöffnet!")
        get_parent().get_parent()._complete_task("solve_combination_lock")
        if target_door:
            target_door.is_locked = false
            target_door.key_id = ""
            return true
    else:
        get_parent().get_parent()._show_message("Aktuell: " + str(current_combination[0]) + "-" + str(current_combination[1]) + "-" + str(current_combination[2]))
    return true
"""
    lock.set_script(script)
    lock.code = code
    lock.target_door = target_door

    interactive_objects.append(lock)
    return lock

func _create_secret_room(parent: Node3D, pos: Vector3, size: Vector3, mats: Dictionary, room_id: String) -> Node3D:
    var room = Node3D.new()
    room.name = "SecretRoom_" + room_id
    room.position = pos
    parent.add_child(room)

    _box(room, Vector3(0, size.y/2, -size.z/2), Vector3(size.x, size.y, 0.1), mats["wall"], true)
    _box(room, Vector3(0, size.y/2, size.z/2), Vector3(size.x, size.y, 0.1), mats["wall"], true)
    _box(room, Vector3(-size.x/2, size.y/2, 0), Vector3(0.1, size.y, size.z), mats["wall"], true)
    _box(room, Vector3(size.x/2, size.y/2, 0), Vector3(0.1, size.y, size.z), mats["wall"], true)
    _box(room, Vector3(0, 0.05, 0), Vector3(size.x, 0.1, size.z), mats["floor"], true)
    _box(room, Vector3(0, size.y - 0.05, 0), Vector3(size.x, 0.1, size.z), mats["ceiling"], true)

    var light = OmniLight3D.new()
    light.position = Vector3(0, size.y/2, 0)
    light.light_color = Color(0.8, 0.7, 0.5)
    light.light_energy = 0.3
    light.omni_range = size.length() * 0.8
    light.add_to_group("lights")
    room.add_child(light)

    return room

func _create_secret_passage(parent: Node3D, pos: Vector3, teleport_pos: Vector3, width: float, height: float, mats: Dictionary) -> Node3D:
    var passage = Node3D.new()
    passage.name = "SecretPassage_" + str(parent.get_children().size())
    passage.position = pos
    parent.add_child(passage)

    var collision = CollisionShape3D.new()
    collision.shape = BoxShape3D.new()
    collision.shape.size = Vector3(width, height, 0.5)
    collision.position = Vector3(0, height/2, 0)
    passage.add_child(collision)

    var area = Area3D.new()
    area.name = "TeleportArea"
    area.add_child(CollisionShape3D.new())
    area.get_child(0).shape = BoxShape3D.new()
    area.get_child(0).shape.size = Vector3(width, height, 0.5)
    area.monitoring = true
    area.body_entered.connect(func(body):
        if body.name == "Player":
            body.global_position = teleport_pos
            get_parent().get_parent()._show_message("Geheimgang durchquert!")
    )
    passage.add_child(area)

    passage.visible = false
    return passage

func _create_trapdoor(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, secret_room: Node3D = null, is_locked: bool = false, key_id: String = "") -> Node3D:
    var trapdoor = Node3D.new()
    trapdoor.name = "Trapdoor_" + str(parent.get_children().size())
    trapdoor.position = pos
    parent.add_child(trapdoor)

    var mesh = MeshInstance3D.new()
    mesh.mesh = BoxMesh.new()
    mesh.mesh.size = size
    mesh.material_override = mat
    trapdoor.add_child(mesh)

    var collision = CollisionShape3D.new()
    collision.shape = BoxShape3D.new()
    collision.shape.size = size
    trapdoor.add_child(collision)

    var area = Area3D.new()
    area.name = "InteractionArea"
    area.add_child(CollisionShape3D.new())
    area.get_child(0).shape = BoxShape3D.new()
    area.get_child(0).shape.size = Vector3(size.x + 1, 1.0, size.z + 1)
    trapdoor.add_child(area)

    var script = GDScript.new()
    script.source_code = """
extends Node3D
@export var is_locked: bool = false
@export var key_id: String = ""
@export var is_open: bool = false
@export var secret_room: Node3D
var area: Area3D
var mesh: MeshInstance3D
var collision: CollisionShape3D
func _ready():
    area = $InteractionArea
    mesh = $MeshInstance3D
    collision = $CollisionShape3D
    secret_room = get_parent().get_parent().get_node_or_null(get_name().replace("Trapdoor_", "SecretRoom_"))
    if secret_room:
        secret_room.visible = false
    area.body_entered.connect(_on_body_entered)
    area.body_exited.connect(_on_body_exited)
func _on_body_entered(body):
    if body.name == "Player":
        if is_locked:
            if not key_id.is_empty() and get_parent().get_parent().inventory["keys"].get(key_id, false):
                get_parent().get_parent()._show_interaction("E: Falltür entriegeln")
            else:
                get_parent().get_parent()._show_interaction("E: Falltür verriegelt")
        else:
            get_parent().get_parent()._show_interaction("E: Falltür " + ("schließen" if is_open else "öffnen"))
func _on_body_exited(body):
    if body.name == "Player":
        get_parent().get_parent()._hide_interaction()
func interact():
    if is_locked:
        if not key_id.is_empty() and get_parent().get_parent().inventory["keys"].get(key_id, false):
            is_locked = false
            get_parent().get_parent()._show_message("Falltür entriegelt!")
            return true
        else:
            get_parent().get_parent()._show_message("Falltür verriegelt!")
            return false
    is_open = !is_open
    if is_open:
        mesh.visible = false
        collision.disabled = true
        if secret_room:
            secret_room.visible = true
            get_parent().get_parent()._show_message("Geheimraum freigelegt!")
    else:
        mesh.visible = true
        collision.disabled = false
        if secret_room:
            secret_room.visible = false
    return true
"""
    trapdoor.set_script(script)
    trapdoor.is_locked = is_locked
    trapdoor.key_id = key_id
    trapdoor.secret_room = secret_room

    interactive_objects.append(trapdoor)
    return trapdoor

func _create_trap_floor(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, teleport_pos: Vector3) -> Node3D:
    var trap = Node3D.new()
    trap.name = "TrapFloor_" + str(parent.get_children().size())
    trap.position = pos
    parent.add_child(trap)

    var mesh = MeshInstance3D.new()
    mesh.mesh = BoxMesh.new()
    mesh.mesh.size = size
    mesh.material_override = mat
    trap.add_child(mesh)

    var collision = CollisionShape3D.new()
    collision.shape = BoxShape3D.new()
    collision.shape.size = size
    trap.add_child(collision)

    var area = Area3D.new()
    area.name = "InteractionArea"
    area.add_child(CollisionShape3D.new())
    area.get_child(0).shape = BoxShape3D.new()
    area.get_child(0).shape.size = size
    area.monitoring = true
    area.body_entered.connect(func(body):
        if body.name == "Player":
            body.global_position = teleport_pos
            get_parent().get_parent()._show_message("Du bist durch eine Falltür gefallen!")
    )
    trap.add_child(area)

    interactive_objects.append(trap)
    return trap

func _create_bed_with_hiding(parent: Node3D, pos: Vector3, blanket: Material, mats: Dictionary, hidden_item: Node3D = null) -> Node3D:
    var bed = Node3D.new()
    bed.name = "Bed_" + str(parent.get_children().size())
    bed.position = pos
    parent.add_child(bed)

    _box(bed, Vector3(0, 0.15, 0), Vector3(1.6, 0.3, 2.1), mats["wood_dark"], true)
    _box(bed, Vector3(0, 0.45, 0), Vector3(1.5, 0.15, 2.0), blanket, false)
    _box(bed, Vector3(0, 0.6, -1.05), Vector3(1.6, 0.9, 0.1), mats["wood_dark"], true)
    _box(bed, Vector3(-0.4, 0.55, -0.8), Vector3(0.5, 0.15, 0.35), mat_white, false)
    _box(bed, Vector3(0.4, 0.55, -0.8), Vector3(0.5, 0.15, 0.35), mat_white, false)

    var area = Area3D.new()
    area.name = "InteractionArea"
    area.add_child(CollisionShape3D.new())
    area.get_child(0).shape = BoxShape3D.new()
    area.get_child(0).shape.size = Vector3(2.0, 1.0, 2.5)
    bed.add_child(area)

    var script = GDScript.new()
    script.source_code = """
extends Node3D
var area: Area3D
var hidden_item: Node3D = null
var is_searched: bool = false
func _ready():
    area = $InteractionArea
    area.body_entered.connect(_on_body_entered)
    area.body_exited.connect(_on_body_exited)
func _on_body_entered(body):
    if body.name == "Player":
        if not is_searched and hidden_item:
            get_parent().get_parent()._show_interaction("E: Bett durchsuchen")
        else:
            get_parent().get_parent()._show_interaction("E: Bett")
func _on_body_exited(body):
    if body.name == "Player":
        get_parent().get_parent()._hide_interaction()
func interact():
    if not is_searched and hidden_item:
        is_searched = true
        hidden_item.visible = true
        get_parent().get_parent()._show_message("Etwas ist unter dem Bett!")
        return true
    return false
"""
    bed.set_script(script)
    bed.hidden_item = hidden_item
    if hidden_item:
        hidden_item.visible = false
        hidden_item.position = pos + Vector3(0, 0.2, -0.5)

    interactive_objects.append(bed)
    return bed

func _create_light_switch(parent: Node3D, pos: Vector3, mat: Material, controlled_lights: Array) -> Node3D:
    var light_switch = Node3D.new()
    light_switch.name = "LightSwitch_" + str(parent.get_children().size())
    light_switch.position = pos
    parent.add_child(light_switch)

    var base = MeshInstance3D.new()
    base.mesh = BoxMesh.new()
    base.mesh.size = Vector3(0.1, 0.1, 0.05)
    base.material_override = mat
    light_switch.add_child(base)

    var switch_plate = MeshInstance3D.new()
    switch_plate.mesh = BoxMesh.new()
    switch_plate.mesh.size = Vector3(0.08, 0.08, 0.02)
    switch_plate.position = Vector3(0, 0, 0.03)
    switch_plate.material_override = mat_white
    light_switch.add_child(switch_plate)

    var area = Area3D.new()
    area.name = "InteractionArea"
    area.add_child(CollisionShape3D.new())
    area.get_child(0).shape = BoxShape3D.new()
    area.get_child(0).shape.size = Vector3(0.3, 0.3, 0.3)
    light_switch.add_child(area)

    var script = GDScript.new()
    script.source_code = """
extends Node3D
var area: Area3D
var controlled_lights: Array = []
var is_on: bool = true
func _ready():
    area = $InteractionArea
    area.body_entered.connect(_on_body_entered)
    area.body_exited.connect(_on_body_exited)
func _on_body_entered(body):
    if body.name == "Player":
        get_parent().get_parent()._show_interaction("E: Licht " + ("aus" if is_on else "an"))
func _on_body_exited(body):
    if body.name == "Player":
        get_parent().get_parent()._hide_interaction()
func interact():
    is_on = !is_on
    for light_path in controlled_lights:
        var light = get_parent().get_parent().get_node_or_null(light_path)
        if light:
            light.visible = is_on
            if is_on:
                light.light_energy = light.get_meta("original_energy", 1.0)
            else:
                light.light_energy = 0.0
    get_parent().get_parent()._show_message("Licht " + ("an" if is_on else "aus"))
    return true
"""
    light_switch.set_script(script)
    light_switch.controlled_lights = controlled_lights
    for light in controlled_lights:
        var light_node = parent.get_node_or_null(light)
        if light_node:
            light_node.set_meta("original_energy", light_node.light_energy)

    interactive_objects.append(light_switch)
    return light_switch

# ============================================================
# ETAGEN-AUFBAU
# ============================================================

func _build_eg() -> void:
    var m = eg_mats
    var eg = Node3D.new()
    eg.name = "EG"
    add_child(eg)
    var y = EG_Y

    # Boden & Decke
    _floor_hole(eg, 0, W, 0, D, y, m["floor"], 2, 4, 2, 6)  # Boden mit Loch für Treppe A
    _floor_hole(eg, 0, W, 0, D, y + CEIL + 0.2, m["ceiling"], 4, 6, 9, 13)  # Decke mit Loch für Treppe B

    # Aussenwaende
    _wall_x(eg, 0, W, 0, y, CEIL, EXT_T, m["wall"])
    _wall_x(eg, 0, W, D, y, CEIL, EXT_T, m["wall"])
    _wall_z(eg, 0, D, 0, y, CEIL, EXT_T, m["wall"])
    _wall_z(eg, 0, D, W, y, CEIL, EXT_T, m["wall"])

    # Innenwaende
    _wall_x(eg, 0, W, 8, y, CEIL, WALL_T, m["wall"], [[8.0, DOOR_W], [16.0, DOOR_W]])
    _wall_z(eg, 0, 8, 8, y, CEIL, WALL_T, m["wall"], [[4.0, DOOR_W]])
    _wall_z(eg, 0, 8, 16, y, CEIL, WALL_T, m["wall"], [[4.0, DOOR_W]])
    _wall_z(eg, 8, D, 12, y, CEIL, WALL_T, m["wall"], [[17.0, DOOR_W]])

    # Treppe A: EG -> OG
    _stairs(eg, 3.0, 2.0, 2.0, EG_Y, OG_Y, 1.6, mat_wood)

    # Treppe B: EG -> Basement
    _stairs(eg, 10.0, 17.0, 2.0, EG_Y, BASE_Y, 1.6, mat_wood)

    # --- WOCHNZIMMER (LINKS VORNE) ---
    # Sofa
    var sofa_eg1 = Node3D.new()
    sofa_eg1.name = "Sofa_EG1"
    sofa_eg1.position = Vector3(2, y, 3)
    _box(sofa_eg1, Vector3(0, 0.2, 0), Vector3(2.2, 0.4, 0.95), m["fabric"], true)
    _box(sofa_eg1, Vector3(0, 0.6, -0.4), Vector3(2.2, 0.6, 0.2), m["fabric"], true)
    _box(sofa_eg1, Vector3(-1.0, 0.5, 0), Vector3(0.2, 0.5, 0.95), m["fabric"], true)
    _box(sofa_eg1, Vector3(1.0, 0.5, 0), Vector3(0.2, 0.5, 0.95), m["fabric"], true)
    _box(sofa_eg1, Vector3(-0.5, 0.45, -0.2), Vector3(0.35, 0.15, 0.35), mat_white, false)
    _box(sofa_eg1, Vector3(0.5, 0.45, -0.2), Vector3(0.35, 0.15, 0.35), mat_white, false)
    eg.add_child(sofa_eg1)

    # Sessel
    var armchair_eg1 = Node3D.new()
    armchair_eg1.name = "Armchair_EG1"
    armchair_eg1.position = Vector3(2, y, 6)
    _box(armchair_eg1, Vector3(0, 0.2, 0), Vector3(0.9, 0.4, 0.9), m["fabric"], true)
    _box(armchair_eg1, Vector3(0, 0.6, -0.4), Vector3(0.9, 0.6, 0.15), m["fabric"], true)
    _box(armchair_eg1, Vector3(-0.4, 0.5, 0), Vector3(0.15, 0.5, 0.9), m["fabric"], true)
    _box(armchair_eg1, Vector3(0.4, 0.5, 0), Vector3(0.15, 0.5, 0.9), m["fabric"], true)
    eg.add_child(armchair_eg1)

    # Kaffeetisch
    var table_eg1 = Node3D.new()
    table_eg1.name = "Table_EG1"
    table_eg1.position = Vector3(2, y, 4.5)
    _box(table_eg1, Vector3(0, 0.42, 0), Vector3(1.2, 0.06, 0.7), m["wood_light"], true)
    for dx in [-0.5, 0.5]:
        for dz in [-0.25, 0.25]:
            _box(table_eg1, Vector3(dx, 0.21, dz), Vector3(0.06, 0.42, 0.06), m["wood"], false)
    eg.add_child(table_eg1)

    # TV
    var tv_eg1 = Node3D.new()
    tv_eg1.name = "TV_EG1"
    tv_eg1.position = Vector3(5, y, 2)
    _box(tv_eg1, Vector3(0, 0.1, 0), Vector3(0.6, 0.2, 0.5), m["wood_dark"], true)
    _box(tv_eg1, Vector3(0, 0.5, 0), Vector3(0.7, 0.6, 0.55), m["wood_dark"], true)
    _box(tv_eg1, Vector3(0, 0.5, 0.28), Vector3(0.55, 0.45, 0.02), mat_black, false)
    _box(tv_eg1, Vector3(0.2, 0.4, 0.29), Vector3(0.08, 0.08, 0.01), mat_gold, false)
    eg.add_child(tv_eg1)

    # Kamin
    var fireplace_eg1 = Node3D.new()
    fireplace_eg1.name = "Fireplace_EG1"
    fireplace_eg1.position = Vector3(5, y, 7)
    _box(fireplace_eg1, Vector3(0, 0.6, 0), Vector3(1.8, 1.2, 0.5), m["brick"], true)
    _box(fireplace_eg1, Vector3(0, 1.3, 0.1), Vector3(2.0, 0.15, 0.55), m["wood_dark"], false)
    _box(fireplace_eg1, Vector3(0, 0.4, 0.26), Vector3(0.9, 0.8, 0.02), mat_black, false)
    var light_fire = OmniLight3D.new()
    light_fire.position = Vector3(0, 0.5, 0.3)
    light_fire.light_color = Color(1.0, 0.5, 0.15)
    light_fire.light_energy = 1.5
    light_fire.omni_range = 4.0
    light_fire.add_to_group("lights")
    fireplace_eg1.add_child(light_fire)
    eg.add_child(fireplace_eg1)

    # --- KUECHE (LINKS HINTEN) ---
    # Arbeitsplatte
    var counter_eg1 = Node3D.new()
    counter_eg1.name = "Counter_EG1"
    counter_eg1.position = Vector3(2, y, 15)
    _box(counter_eg1, Vector3(0, 0.85, 0), Vector3(2.0, 0.1, 0.7), m["wood_light"], true)
    _box(counter_eg1, Vector3(0, 0.425, 0), Vector3(1.95, 0.42, 0.65), m["wood_dark"], true)
    for i in range(3):
        _box(counter_eg1, Vector3(0.2, 0.25 + i*0.25, 0.33), Vector3(0.04, 0.03, 0.02), mat_gold, false)
    eg.add_child(counter_eg1)

    # Spuele
    var sink_eg1 = Node3D.new()
    sink_eg1.name = "Sink_EG1"
    sink_eg1.position = Vector3(3, y, 15)
    _box(sink_eg1, Vector3(0, 0.85, 0), Vector3(0.8, 0.1, 0.5), m["metal"], true)
    _box(sink_eg1, Vector3(0, 0.4, 0), Vector3(0.1, 0.8, 0.1), m["metal"], false)
    _box(sink_eg1, Vector3(0.25, 1.0, -0.15), Vector3(0.05, 0.15, 0.1), m["metal"], false)
    eg.add_child(sink_eg1)

    # Herd
    var stove_eg1 = Node3D.new()
    stove_eg1.name = "Stove_EG1"
    stove_eg1.position = Vector3(4, y, 15)
    _box(stove_eg1, Vector3(0, 0.45, 0), Vector3(0.8, 0.9, 0.7), mat_black, true)
    _box(stove_eg1, Vector3(0, 0.92, 0), Vector3(0.8, 0.04, 0.7), m["metal"], false)
    for i in range(2):
        for j in range(2):
            _cyl(stove_eg1, Vector3(-0.2 + i*0.4, 0.95, -0.18 + j*0.36), 0.1, 0.02, mat_metal_rusty, false)
    eg.add_child(stove_eg1)

    # Kuehlschrank
    var fridge_eg1 = Node3D.new()
    fridge_eg1.name = "Fridge_EG1"
    fridge_eg1.position = Vector3(5, y, 15)
    _box(fridge_eg1, Vector3(0, 0.85, 0), Vector3(0.75, 1.7, 0.65), mat_white, true)
    _box(fridge_eg1, Vector3(0, 1.2, 0.33), Vector3(0.02, 1.4, 0.02), mat_black, false)
    _box(fridge_eg1, Vector3(0.3, 1.1, 0.34), Vector3(0.04, 0.15, 0.03), m["metal"], false)
    eg.add_child(fridge_eg1)

    # --- ESSTISCH (RECHTS VORNE) ---
    # Tisch
    var table_eg2 = Node3D.new()
    table_eg2.name = "Table_EG2"
    table_eg2.position = Vector3(15, y, 5)
    _box(table_eg2, Vector3(0, 0.75, 0), Vector3(1.8, 0.05, 1.0), m["wood"], true)
    for dx in [-0.72, 0.72]:
        for dz in [-0.36, 0.36]:
            _box(table_eg2, Vector3(dx, 0.375, dz), Vector3(0.08, 0.75, 0.08), m["wood"], false)
    eg.add_child(table_eg2)

    # Stuehle
    for i in range(4):
        var chair = Node3D.new()
        chair.name = "Chair_EG" + str(i+1)
        var angle = i * PI/2
        chair.position = Vector3(15 + cos(angle) * 0.8, y, 5 + sin(angle) * 0.5)
        chair.rotation.y = angle + PI/2
        _box(chair, Vector3(0, 0.45, 0), Vector3(0.5, 0.05, 0.5), m["wood"], true)
        _box(chair, Vector3(0, 0.7, -0.22), Vector3(0.5, 0.5, 0.05), m["wood"], true)
        for dx in [-0.2, 0.2]:
            for dz in [-0.2, 0.2]:
                _box(chair, Vector3(dx, 0.225, dz), Vector3(0.05, 0.45, 0.05), m["wood"], false)
        eg.add_child(chair)

    # --- SCHLAFZIMMER (RECHTS HINTEN) ---
    # Bett
    var bed_eg1 = _create_bed_with_hiding(eg, Vector3(18, y, 15), m["fabric"], m)
    var attic_key = _create_key(eg, Vector3(18, y + 0.2, 15), "attic_key")
    attic_key.visible = false
    bed_eg1.hidden_item = attic_key

    # Kleiderschrank
    var wardrobe_eg1 = Node3D.new()
    wardrobe_eg1.name = "Wardrobe_EG1"
    wardrobe_eg1.position = Vector3(22, y, 15)
    _box(wardrobe_eg1, Vector3(0, 1.1, 0), Vector3(1.3, 2.2, 0.7), m["wood_dark"], true)
    _box(wardrobe_eg1, Vector3(0, 1.1, 0.36), Vector3(0.02, 2.0, 0.01), mat_black, false)
    _box(wardrobe_eg1, Vector3(-0.08, 1.2, 0.37), Vector3(0.04, 0.15, 0.03), mat_gold, false)
    _box(wardrobe_eg1, Vector3(0.08, 1.2, 0.37), Vector3(0.04, 0.15, 0.03), mat_gold, false)
    eg.add_child(wardrobe_eg1)

    # Nachttisch
    var nightstand_eg1 = Node3D.new()
    nightstand_eg1.name = "Nightstand_EG1"
    nightstand_eg1.position = Vector3(20, y, 18)
    _box(nightstand_eg1, Vector3(0, 0.3, 0), Vector3(0.55, 0.6, 0.5), m["wood_dark"], true)
    _box(nightstand_eg1, Vector3(0, 0.6, 0), Vector3(0.6, 0.05, 0.55), m["wood_light"], false)
    eg.add_child(nightstand_eg1)

    # --- VERRIEGELTE TUER (BRAUCHT KELLER-SCHLUESSEL) ---
    var door_eg1 = _create_door(eg, Vector3(4, y, 8), Vector3(DOOR_W, DOOR_H, 0.1), m["wood_dark"], true, "keller_key", "keller")

    # --- GEHEIMTUER HINTER BILD ---
    var secret_door_eg1 = _create_door(eg, Vector3(0, y, 10), Vector3(DOOR_W, DOOR_H, 0.1), m["wood"], true, "", "secret")
    var painting_eg1 = _create_painting_with_secret(eg, Vector3(0.02, y + 1.1, 10), Vector3(1.0, 1.2, 0.05), 0, secret_door_eg1)

    # --- KISTEN & MOEBEL ---
    var crate_eg1 = _create_pushable_object(eg, Vector3(2, y, 10), Vector3(0.8, 0.8, 0.8), m["wood_light"])
    var crate_eg2 = _create_pushable_object(eg, Vector3(3, y, 10), Vector3(1.0, 1.0, 1.0), m["wood_light"])

    # --- LICHT ---
    var light1 = OmniLight3D.new()
    light1.position = Vector3(2, y + 2.5, 3)
    light1.light_color = Color(1.0, 0.85, 0.6)
    light1.light_energy = 1.2
    light1.omni_range = 6.0
    light1.add_to_group("lights")
    eg.add_child(light1)
    light_switches.append(light1)

    var light2 = OmniLight3D.new()
    light2.position = Vector3(15, y + 2.5, 5)
    light2.light_color = Color(1.0, 0.85, 0.6)
    light2.light_energy = 1.2
    light2.omni_range = 6.0
    light2.add_to_group("lights")
    eg.add_child(light2)
    light_switches.append(light2)

    var light3 = OmniLight3D.new()
    light3.position = Vector3(18, y + 2.5, 15)
    light3.light_color = Color(1.0, 0.8, 0.5)
    light3.light_energy = 0.8
    light3.omni_range = 5.0
    light3.add_to_group("lights")
    eg.add_child(light3)
    light_switches.append(light3)

    # Lichtschalter
    _create_light_switch(eg, Vector3(2, y + 1.5, 3 - 0.2), m["metal"], ["EG/Light"])
    _create_light_switch(eg, Vector3(15, y + 1.5, 5 - 0.2), m["metal"], ["EG/Light2"])

    # Notizen
    _create_note(eg, Vector3(2, y + 0.5, 1), "note_eg1", "Der Keller-Schlüssel ist irgendwo im Erdgeschoss versteckt. Suche unter den Möbeln.")
    _create_note(eg, Vector3(5, y + 0.5, 18), "note_eg2", "Die Tür zum Keller ist verriegelt. Ich brauche einen Schlüssel.")


func _build_og() -> void:
    var m = og_mats
    var og = Node3D.new()
    og.name = "OG"
    add_child(og)
    var y = OG_Y

    # Boden & Decke
    _floor_hole(og, 0, W, 0, D, y, m["floor"], 2, 4, 2, 6)  # Boden mit Loch für Treppe B
    _floor_hole(og, 0, W, 0, D, y + CEIL + 0.2, m["ceiling"], 4, 6, 9, 13)  # Decke mit Loch für Treppe C

    # Aussenwaende
    _wall_x(og, 0, W, 0, y, CEIL, EXT_T, m["wall"])
    _wall_x(og, 0, W, D, y, CEIL, EXT_T, m["wall"])
    _wall_z(og, 0, D, 0, y, CEIL, EXT_T, m["wall"])
    _wall_z(og, 0, D, W, y, CEIL, EXT_T, m["wall"])

    # Innenwaende
    _wall_x(og, 0, W, 8, y, CEIL, WALL_T, m["wall"], [[8.0, DOOR_W], [16.0, DOOR_W]])
    _wall_z(og, 0, 8, 8, y, CEIL, WALL_T, m["wall"], [[4.0, DOOR_W]])
    _wall_z(og, 0, 8, 16, y, CEIL, WALL_T, m["wall"], [[4.0, DOOR_W]])
    _wall_z(og, 8, D, 12, y, CEIL, WALL_T, m["wall"], [[17.0, DOOR_W]])

    # Treppe B: OG -> EG
    _stairs(og, 3.0, 2.0, 2.0, OG_Y, EG_Y, 1.6, mat_wood)

    # Treppe C: OG -> Attic
    _stairs(og, 10.0, 17.0, 2.0, OG_Y, ATTIC_Y, 1.6, mat_wood)

    # --- KINDERZIMMER (LINKS VORNE) ---
    # Bett
    var bed_og1 = _create_bed_with_hiding(og, Vector3(2, y, 3), mat_fabric_blue, m)
    var keller_key = _create_key(og, Vector3(2, y + 0.2, 3), "keller_key")
    keller_key.visible = false
    bed_og1.hidden_item = keller_key

    # Spielzeugkiste
    var crate_og1 = _create_pushable_object(og, Vector3(2, y, 6), Vector3(1.0, 0.6, 0.8), m["wood_light"])

    # Schrank
    var wardrobe_og1 = Node3D.new()
    wardrobe_og1.name = "Wardrobe_OG1"
    wardrobe_og1.position = Vector3(5, y, 2)
    _box(wardrobe_og1, Vector3(0, 1.1, 0), Vector3(1.3, 2.2, 0.7), m["wood_dark"], true)
    _box(wardrobe_og1, Vector3(0, 1.1, 0.36), Vector3(0.02, 2.0, 0.01), mat_black, false)
    og.add_child(wardrobe_og1)

    # --- BAD (LINKS HINTEN) ---
    # Badewanne
    var bathtub_og1 = Node3D.new()
    bathtub_og1.name = "Bathtub_OG1"
    bathtub_og1.position = Vector3(2, y, 15)
    _box(bathtub_og1, Vector3(0, 0.3, 0), Vector3(1.7, 0.6, 0.8), m["tile"], true)
    _box(bathtub_og1, Vector3(0, 0.55, 0), Vector3(1.5, 0.1, 0.6), mat_white, false)
    _box(bathtub_og1, Vector3(0.75, 0.85, 0), Vector3(0.05, 0.3, 0.05), m["metal"], false)
    og.add_child(bathtub_og1)

    # Toilette
    var toilet_og1 = Node3D.new()
    toilet_og1.name = "Toilet_OG1"
    toilet_og1.position = Vector3(5, y, 15)
    _box(toilet_og1, Vector3(0, 0.2, 0), Vector3(0.5, 0.4, 0.6), mat_ceramic, true)
    _box(toilet_og1, Vector3(0, 0.5, -0.25), Vector3(0.5, 0.4, 0.2), mat_ceramic, true)
    _cyl(toilet_og1, Vector3(0, 0.42, 0), 0.22, 0.05, mat_ceramic, false)
    og.add_child(toilet_og1)

    # Waschbecken
    var sink_og1 = Node3D.new()
    sink_og1.name = "Sink_OG1"
    sink_og1.position = Vector3(7, y, 15)
    _box(sink_og1, Vector3(0, 0.85, 0), Vector3(0.8, 0.1, 0.5), m["metal"], true)
    _box(sink_og1, Vector3(0, 0.4, 0), Vector3(0.1, 0.8, 0.1), m["metal"], false)
    _box(sink_og1, Vector3(0.25, 1.0, -0.15), Vector3(0.05, 0.15, 0.1), m["metal"], false)
    og.add_child(sink_og1)

    # Spiegel
    var mirror_og1 = Node3D.new()
    mirror_og1.name = "Mirror_OG1"
    mirror_og1.position = Vector3(7, y, 17)
    _box(mirror_og1, Vector3(0, 0, 0), Vector3(0.7, 1.2, 0.05), m["wood_dark"], false)
    _box(mirror_og1, Vector3(0, 0, 0.03), Vector3(0.55, 1.05, 0.01), mat_glass, false)
    og.add_child(mirror_og1)

    # --- BUECHERZIMMER (RECHTS VORNE) ---
    # Bücherregal
    var bookshelf_og1 = _create_rotating_bookshelf(og, Vector3(15, y, 2), Vector3(2.0, 2.4, 0.4), m)
    var secret_passage_og1 = _create_secret_passage(og, Vector3(15, y, 0), Vector3(15, y, -2), 2.0, 2.2, m)
    bookshelf_og1.secret_passage = secret_passage_og1

    # Schreibtisch
    var table_og2 = Node3D.new()
    table_og2.name = "Table_OG2"
    table_og2.position = Vector3(18, y, 2)
    _box(table_og2, Vector3(0, 0.75, 0), Vector3(1.4, 0.05, 0.7), m["wood"], true)
    for dx in [-0.56, 0.56]:
        for dz in [-0.28, 0.28]:
            _box(table_og2, Vector3(dx, 0.375, dz), Vector3(0.06, 0.75, 0.06), m["wood"], false)
    og.add_child(table_og2)

    # Stuhl
    var chair_og1 = Node3D.new()
    chair_og1.name = "Chair_OG1"
    chair_og1.position = Vector3(18, y, 3)
    chair_og1.rotation.y = PI
    _box(chair_og1, Vector3(0, 0.45, 0), Vector3(0.5, 0.05, 0.5), m["wood"], true)
    _box(chair_og1, Vector3(0, 0.7, -0.22), Vector3(0.5, 0.5, 0.05), m["wood"], true)
    for dx in [-0.2, 0.2]:
        for dz in [-0.2, 0.2]:
            _box(chair_og1, Vector3(dx, 0.225, dz), Vector3(0.05, 0.45, 0.05), m["wood"], false)
    og.add_child(chair_og1)

    # --- SCHLAFZIMMER (RECHTS HINTEN) ---
    # Bett
    var bed_og2 = Node3D.new()
    bed_og2.name = "Bed_OG2"
    bed_og2.position = Vector3(18, y, 15)
    _box(bed_og2, Vector3(0, 0.15, 0), Vector3(1.6, 0.3, 2.1), m["wood_dark"], true)
    _box(bed_og2, Vector3(0, 0.45, 0), Vector3(1.5, 0.15, 2.0), m["fabric"], false)
    _box(bed_og2, Vector3(0, 0.6, -1.05), Vector3(1.6, 0.9, 0.1), m["wood_dark"], true)
    _box(bed_og2, Vector3(-0.4, 0.55, -0.8), Vector3(0.5, 0.15, 0.35), mat_white, false)
    _box(bed_og2, Vector3(0.4, 0.55, -0.8), Vector3(0.5, 0.15, 0.35), mat_white, false)
    og.add_child(bed_og2)

    # Kommode
    var dresser_og1 = Node3D.new()
    dresser_og1.name = "Dresser_OG1"
    dresser_og1.position = Vector3(22, y, 15)
    _box(dresser_og1, Vector3(0, 0.45, 0), Vector3(1.2, 0.9, 0.5), m["wood_dark"], true)
    for i in range(3):
        _box(dresser_og1, Vector3(0, 0.15 + i*0.3, 0.26), Vector3(1.1, 0.25, 0.02), m["wood_light"], false)
        _box(dresser_og1, Vector3(0, 0.15 + i*0.3, 0.28), Vector3(0.15, 0.04, 0.02), mat_gold, false)
    og.add_child(dresser_og1)

    # --- VERRIEGELTE TUER (BRAUCHT DACHBODEN-SCHLUESSEL) ---
    var door_og1 = _create_door(og, Vector3(12, y, 8), Vector3(DOOR_W, DOOR_H, 0.1), m["wood_dark"], true, "attic_key", "attic")

    # --- LICHT ---
    var light1 = OmniLight3D.new()
    light1.position = Vector3(2, y + 2.5, 3)
    light1.light_color = Color(1.0, 0.85, 0.6)
    light1.light_energy = 1.0
    light1.omni_range = 5.0
    light1.add_to_group("lights")
    og.add_child(light1)
    light_switches.append(light1)

    var light2 = OmniLight3D.new()
    light2.position = Vector3(18, y + 2.5, 2)
    light2.light_color = Color(1.0, 0.85, 0.6)
    light2.light_energy = 1.0
    light2.omni_range = 5.0
    light2.add_to_group("lights")
    og.add_child(light2)
    light_switches.append(light2)

    var light3 = OmniLight3D.new()
    light3.position = Vector3(2, y + 2.5, 15)
    light3.light_color = Color(1.0, 0.85, 0.6)
    light3.light_energy = 1.0
    light3.omni_range = 5.0
    light3.add_to_group("lights")
    og.add_child(light3)
    light_switches.append(light3)

    var light4 = OmniLight3D.new()
    light4.position = Vector3(18, y + 2.5, 15)
    light4.light_color = Color(1.0, 0.8, 0.5)
    light4.light_energy = 0.8
    light4.omni_range = 5.0
    light4.add_to_group("lights")
    og.add_child(light4)
    light_switches.append(light4)

    # Notizen
    _create_note(og, Vector3(2, y + 0.5, 1), "note_og1", "Der Dachboden-Schlüssel ist unter dem Bett im Obergeschoss versteckt.")
    _create_note(og, Vector3(15, y + 0.5, 18), "note_og2", "Hinter dem Bücherregal könnte sich ein Geheimnis verbergen.")

func _build_attic() -> void:
    var m = attic_mats
    var at = Node3D.new()
    at.name = "Attic"
    add_child(at)
    var y = ATTIC_Y

    # Boden & Decke
    _floor_hole(at, 0, W, 0, D, y, m["floor"], 2, 4, 2, 6)  # Boden mit Loch für Treppe C
    _floor(at, 0, W, 0, D, y + CEIL + 0.2, m["ceiling"])  # Decke

    # Aussenwaende
    _wall_x(at, 0, W, 0, y, CEIL, EXT_T, m["wall"])
    _wall_x(at, 0, W, D, y, CEIL, EXT_T, m["wall"])
    _wall_z(at, 0, D, 0, y, CEIL, EXT_T, m["wall"])
    _wall_z(at, 0, D, W, y, CEIL, EXT_T, m["wall"])

    # Innenwaende
    _wall_x(at, 0, W, 8, y, CEIL, WALL_T, m["wall"], [[8.0, DOOR_W], [16.0, DOOR_W]])
    _wall_z(at, 0, 8, 8, y, CEIL, WALL_T, m["wall"], [[4.0, DOOR_W]])
    _wall_z(at, 0, 8, 16, y, CEIL, WALL_T, m["wall"], [[4.0, DOOR_W]])

    # Treppe C: Attic -> OG
    _stairs(at, 10.0, 17.0, 2.0, ATTIC_Y, OG_Y, 1.6, mat_wood)

    # --- LAGERBEREICH (LINKS) ---
    # Kisten
    var crate_at1 = _create_pushable_object(at, Vector3(2, y, 2), Vector3(1.0, 1.0, 1.0), m["wood_light"])
    var crate_at2 = _create_pushable_object(at, Vector3(4, y, 2), Vector3(0.8, 0.8, 0.8), m["wood_light"])
    var crate_at3 = _create_pushable_object(at, Vector3(6, y, 2), Vector3(1.2, 1.2, 1.2), m["wood_light"])

    # Fässer
    var barrel_at1 = _create_pushable_object(at, Vector3(2, y, 5), Vector3(0.7, 0.9, 0.7), m["wood_light"])
    var barrel_at2 = _create_pushable_object(at, Vector3(4, y, 5), Vector3(0.7, 0.9, 0.7), m["wood_light"])

    # Werkbank
    var workbench_at1 = Node3D.new()
    workbench_at1.name = "Workbench_AT1"
    workbench_at1.position = Vector3(2, y, 7)
    _box(workbench_at1, Vector3(0, 0.85, 0), Vector3(2.0, 0.1, 0.7), m["wood_light"], true)
    for dx in [-0.9, 0.9]:
        for dz in [-0.25, 0.25]:
            _box(workbench_at1, Vector3(dx, 0.4, dz), Vector3(0.1, 0.8, 0.1), m["wood_dark"], false)
    _box(workbench_at1, Vector3(-0.5, 0.95, 0), Vector3(0.25, 0.02, 0.08), m["metal"], false)
    _box(workbench_at1, Vector3(0.3, 0.95, 0), Vector3(0.15, 0.05, 0.15), mat_metal_rusty, false)
    at.add_child(workbench_at1)

    # --- STAUBIGER BEREICH (MITTE) ---
    # Alte Truhe
    var trunk_at1 = _create_pushable_object(at, Vector3(10, y, 4), Vector3(1.2, 0.6, 0.8), m["wood_dark"])

    # Standuhr
    var clock_at1 = Node3D.new()
    clock_at1.name = "Clock_AT1"
    clock_at1.position = Vector3(12, y, 4)
    _box(clock_at1, Vector3(0, 1.3, 0), Vector3(0.6, 2.6, 0.4), m["wood_dark"], true)
    _box(clock_at1, Vector3(0, 2.0, 0.21), Vector3(0.4, 0.4, 0.02), mat_white, false)
    _box(clock_at1, Vector3(0, 2.0, 0.22), Vector3(0.05, 0.15, 0.01), mat_black, false)
    _box(clock_at1, Vector3(0.05, 2.0, 0.22), Vector3(0.08, 0.02, 0.01), mat_black, false)
    _box(clock_at1, Vector3(0, 0.8, 0.21), Vector3(0.3, 0.6, 0.02), mat_black, false)
    at.add_child(clock_at1)

    # --- RECHTER BEREICH (ALTER WOHNRAUM) ---
    # Tisch
    var table_at1 = Node3D.new()
    table_at1.name = "Table_AT1"
    table_at1.position = Vector3(16, y, 16)
    _box(table_at1, Vector3(0, 0.75, 0), Vector3(1.8, 0.05, 1.0), m["wood"], true)
    for dx in [-0.72, 0.72]:
        for dz in [-0.36, 0.36]:
            _box(table_at1, Vector3(dx, 0.375, dz), Vector3(0.08, 0.75, 0.08), m["wood"], false)
    at.add_child(table_at1)

    # Stühle
    var chair_at1 = _create_pushable_object(at, Vector3(16, y, 15), Vector3(0.5, 0.8, 0.5), m["wood"])
    var chair_at2 = _create_pushable_object(at, Vector3(16, y, 17), Vector3(0.5, 0.8, 0.5), m["wood"])

    # Truhe mit Master-Key
    var trunk_at3 = _create_pushable_object(at, Vector3(20, y, 15), Vector3(1.0, 0.5, 0.6), m["wood_light"])
    var master_key = _create_key(at, Vector3(20, y + 0.6, 15), "master_key")
    master_key.visible = false
    # Verknuepfung wird in _build_attic gemacht

    # Kisten
    var crate_at4 = _create_pushable_object(at, Vector3(22, y, 19), Vector3(1.0, 1.0, 1.0), m["wood_light"])
    var crate_at5 = _create_pushable_object(at, Vector3(20, y, 19), Vector3(0.8, 0.8, 0.8), m["wood_light"])

    # Bücherregal
    var bookshelf_at1 = _create_rotating_bookshelf(at, Vector3(23, y, 17), m)

    # --- VERRIEGELTE TUER (BRAUCHT MASTER-KEY) ---
    var master_door = _create_door(at, Vector3(12, y, 0), Vector3(DOOR_W, DOOR_H, 0.1), m["wood_dark"], true, "master_key", "master")

    # --- KOMBINATIONSSCHLOSS ---
    var combination_door = _create_door(at, Vector3(12, y, 8), Vector3(DOOR_W, DOOR_H, 0.1), m["metal"], true, "", "combination")
    var combination_lock = _create_combination_lock(at, Vector3(12, y + 1.5, 8.5), m["metal"], [7, 3, 9], combination_door)

    # --- FALLTUER-FALLE ---
    var trap_floor = _create_trap_floor(at, Vector3(10, y, 10), Vector3(2, 2, 2), m["floor"], Vector3(10, BASE_Y + 1, 10))

    # --- GEHEIMGANG (WIRD FREIGELEGT, WENN KISTE VERSCHOBEN WIRD) ---
    var secret_passage_at1 = _create_secret_passage(at, Vector3(3, y, 2), Vector3(3, y, -2), 2.0, 2.2, m)
    crate_at1.secret_passage = secret_passage_at1

    # --- SPINNENNETZE & DETAILS ---
    var cobweb_at1 = Node3D.new()
    cobweb_at1.name = "Cobweb_AT1"
    cobweb_at1.position = Vector3(0.5, y + 1.8, 0.5)
    var mesh_cobweb = MeshInstance3D.new()
    mesh_cobweb.mesh = PlaneMesh.new()
    mesh_cobweb.mesh.size = Vector2(1.0, 1.0)
    mesh_cobweb.rotation.x = PI/2
    mesh_cobweb.material_override = _m(Color(0.7, 0.7, 0.7, 0.3), 0.9, 0.0, null)
    mesh_cobweb.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    cobweb_at1.add_child(mesh_cobweb)
    at.add_child(cobweb_at1)

    var cobweb_at2 = Node3D.new()
    cobweb_at2.name = "Cobweb_AT2"
    cobweb_at2.position = Vector3(11, y + 1.8, 0.5)
    var mesh_cobweb2 = MeshInstance3D.new()
    mesh_cobweb2.mesh = PlaneMesh.new()
    mesh_cobweb2.mesh.size = Vector2(1.0, 1.0)
    mesh_cobweb2.rotation.x = PI/2
    mesh_cobweb2.material_override = _m(Color(0.7, 0.7, 0.7, 0.3), 0.9, 0.0, null)
    mesh_cobweb2.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    cobweb_at2.add_child(mesh_cobweb2)
    at.add_child(cobweb_at2)

    var cobweb_at3 = Node3D.new()
    cobweb_at3.name = "Cobweb_AT3"
    cobweb_at3.position = Vector3(0.5, y + 1.8, 11)
    var mesh_cobweb3 = MeshInstance3D.new()
    mesh_cobweb3.mesh = PlaneMesh.new()
    mesh_cobweb3.mesh.size = Vector2(1.0, 1.0)
    mesh_cobweb3.rotation.x = PI/2
    mesh_cobweb3.material_override = _m(Color(0.7, 0.7, 0.7, 0.3), 0.9, 0.0, null)
    mesh_cobweb3.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    cobweb_at3.add_child(mesh_cobweb3)
    at.add_child(cobweb_at3)

    # Verstreute Papiere
    for i in range(5):
        var paper = Node3D.new()
        paper.name = "Paper_AT" + str(i+1)
        paper.position = Vector3(5 + randf_range(-1, 1), y + 0.01, 5 + randf_range(-1, 1))
        var mesh_paper = MeshInstance3D.new()
        mesh_paper.mesh = PlaneMesh.new()
        mesh_paper.mesh.size = Vector2(0.1, 0.15)
        mesh_paper.rotation.x = PI/2 + randf_range(-0.3, 0.3)
        mesh_paper.material_override = mat_paper
        paper.add_child(mesh_paper)
        at.add_child(paper)

    # Kerzenstaender
    var candle_at1 = Node3D.new()
    candle_at1.name = "Candle_AT1"
    candle_at1.position = Vector3(3, y, 10)
    _cyl(candle_at1, Vector3(0, 0.5, 0), 0.03, 1.0, m["metal"], false)
    _box(candle_at1, Vector3(0, 0.05, 0), Vector3(0.2, 0.1, 0.2), m["wood_dark"], true)
    _cyl(candle_at1, Vector3(0, 1.0, 0), 0.04, 0.2, mat_white, false)
    var light_candle = OmniLight3D.new()
    light_candle.position = Vector3(0, 1.1, 0)
    light_candle.light_color = Color(1.0, 0.8, 0.5)
    light_candle.light_energy = 0.5
    light_candle.omni_range = 2.0
    light_candle.add_to_group("lights")
    candle_at1.add_child(light_candle)
    at.add_child(candle_at1)

    # Tote Pflanze
    var plant_at1 = Node3D.new()
    plant_at1.name = "Plant_AT1"
    plant_at1.position = Vector3(9, y, 8)
    _cyl(plant_at1, Vector3(0, 0.1, 0), 0.15, 0.2, mat_ceramic, true)
    for i in range(5):
        var stem = MeshInstance3D.new()
        stem.mesh = CylinderMesh.new()
        stem.mesh.radius = 0.02
        stem.mesh.height = 0.3 + randf() * 0.2
        stem.position = Vector3(randf_range(-0.1, 0.1), 0.2 + randf() * 0.3, randf_range(-0.1, 0.1))
        stem.rotation.x = randf_range(-0.3, 0.3)
        stem.rotation.z = randf_range(-0.3, 0.3)
        stem.material_override = _m(Color(0.2, 0.15, 0.1), 0.8, 0.0, null)
        plant_at1.add_child(stem)
    at.add_child(plant_at1)

    # Verknuepfung der Truhe mit Master-Key
    trunk_at3.hidden_item = master_key

    # --- LICHT ---
    var light1 = OmniLight3D.new()
    light1.position = Vector3(6, y + 2.0, 6)
    light1.light_color = Color(1.0, 0.7, 0.4)
    light1.light_energy = 0.5
    light1.omni_range = 3.0
    light1.add_to_group("lights")
    at.add_child(light1)
    light_switches.append(light1)

    var light2 = OmniLight3D.new()
    light2.position = Vector3(18, y + 2.0, 17)
    light2.light_color = Color(0.8, 0.7, 0.5)
    light2.light_energy = 0.5
    light2.omni_range = 4.0
    light2.add_to_group("lights")
    at.add_child(light2)
    light_switches.append(light2)

    # Lichtschalter
    _create_light_switch(at, Vector3(18, y + 1.5, 17 - 0.2), m["metal"], ["Attic/Light2"])

    # Notizen
    _create_note(at, Vector3(2, y + 0.5, 1), "note_at1", "Der Hauptschlüssel ist in einer Truhe im Dachboden versteckt.")
    _create_note(at, Vector3(10, y + 0.5, 18), "note_at2", "Vorsicht vor der Falltür in der Mitte des Dachbodens!")


func _build_basement() -> void:
    var m = basement_mats
    var b = Node3D.new()
    b.name = "Basement"
    add_child(b)
    var y = BASE_Y

    # Boden & Decke
    _floor_hole(b, 0, W, 0, D, y, m["floor"], 2, 4, 2, 6)  # Boden mit Loch für Treppe D
    _floor_hole(b, 0, W, 0, D, y + CEIL + 0.2, m["concrete"], 4, 6, 9, 13)  # Decke mit Loch für Treppe A

    # Aussenwaende
    _wall_x(b, 0, W, 0, y, CEIL, EXT_T, m["wall"])
    _wall_x(b, 0, W, D, y, CEIL, EXT_T, m["wall"])
    _wall_z(b, 0, D, 0, y, CEIL, EXT_T, m["wall"])
    _wall_z(b, 0, D, W, y, CEIL, EXT_T, m["wall"])

    # Innenwaende
    _wall_x(b, 0, W, 8, y, CEIL, WALL_T, m["wall"], [[8.0, DOOR_W], [16.0, DOOR_W]])
    _wall_z(b, 0, 8, 8, y, CEIL, WALL_T, m["wall"], [[4.0, DOOR_W]])
    _wall_z(b, 0, 8, 16, y, CEIL, WALL_T, m["wall"], [[4.0, DOOR_W]])
    _wall_z(b, 8, D, 12, y, CEIL, WALL_T, m["wall"], [[17.0, DOOR_W]])

    # Treppe D: Basement -> SubBasement
    _stairs(b, 3.0, 2.0, 6.0, BASE_Y, SUB_Y, 1.6, mat_wood)

    # --- ROHRE AN DER DECKEN ---
    _cyl(b, Vector3(4, y + CEIL - 0.15, 4), 0.08, 8, m["metal_rusty"], false)
    _cyl(b, Vector3(12, y + CEIL - 0.15, 4), 0.08, 8, m["metal_rusty"], false)
    _cyl(b, Vector3(20, y + CEIL - 0.15, 4), 0.08, 8, m["metal_rusty"], false)
    _cyl(b, Vector3(4, y + CEIL - 0.3, 6), 0.08, 8, m["metal_rusty"], false)

    # --- LAGERBEREICH (LINKS) ---
    # Kisten
    var crate_b1 = _create_pushable_object(b, Vector3(2, y, 2), Vector3(1.0, 1.0, 1.0), m["wood_light"])
    var crate_b2 = _create_pushable_object(b, Vector3(4, y, 2), Vector3(0.8, 0.8, 0.8), m["wood_light"])
    var crate_b3 = _create_pushable_object(b, Vector3(6, y, 2), Vector3(1.2, 1.2, 1.2), m["wood_light"])

    # Faesser
    var barrel_b1 = _create_pushable_object(b, Vector3(2, y, 5), Vector3(0.7, 0.9, 0.7), m["wood_light"])
    var barrel_b2 = _create_pushable_object(b, Vector3(4, y, 5), Vector3(0.7, 0.9, 0.7), m["wood_light"])
    var barrel_b3 = _create_pushable_object(b, Vector3(6, y, 5), Vector3(0.7, 0.9, 0.7), m["wood_light"])

    # Werkbank
    var workbench_b1 = Node3D.new()
    workbench_b1.name = "Workbench_B1"
    workbench_b1.position = Vector3(2, y, 7)
    _box(workbench_b1, Vector3(0, 0.85, 0), Vector3(2.0, 0.1, 0.7), m["wood_light"], true)
    for dx in [-0.9, 0.9]:
        for dz in [-0.25, 0.25]:
            _box(workbench_b1, Vector3(dx, 0.4, dz), Vector3(0.1, 0.8, 0.1), m["wood_dark"], false)
    _box(workbench_b1, Vector3(-0.5, 0.95, 0), Vector3(0.25, 0.02, 0.08), m["metal"], false)
    _box(workbench_b1, Vector3(0.3, 0.95, 0), Vector3(0.15, 0.05, 0.15), mat_metal_rusty, false)
    b.add_child(workbench_b1)

    # Regal
    var shelf_b1 = _create_pushable_object(b, Vector3(7.5, y, 4), Vector3(0.4, 2.0, 3.0), m["wood_dark"])

    # Verstreute Papiere
    for i in range(5):
        var paper = Node3D.new()
        paper.name = "Paper_B" + str(i+1)
        paper.position = Vector3(4 + randf_range(-1, 1), y + 0.01, 3 + randf_range(-1, 1))
        var mesh_paper = MeshInstance3D.new()
        mesh_paper.mesh = PlaneMesh.new()
        mesh_paper.mesh.size = Vector2(0.1, 0.15)
        mesh_paper.rotation.x = PI/2 + randf_range(-0.3, 0.3)
        mesh_paper.material_override = mat_paper
        paper.add_child(mesh_paper)
        b.add_child(paper)

    # --- HEIZUNGSRAUM (MITTE) ---
    # Heizkessel
    var boiler_b1 = Node3D.new()
    boiler_b1.name = "Boiler_B1"
    boiler_b1.position = Vector3(10, y, 4)
    _cyl(boiler_b1, Vector3(0, 0.8, 0), 0.5, 1.6, m["metal_rusty"], true)
    _cyl(boiler_b1, Vector3(0, 1.7, 0), 0.1, 0.2, m["metal_rusty"], false)
    _box(boiler_b1, Vector3(0.3, 0.5, 0.4), Vector3(0.15, 0.1, 0.1), mat_gold, false)
    b.add_child(boiler_b1)

    # Waschmaschinen
    var washing_b1 = Node3D.new()
    washing_b1.name = "Washing_B1"
    washing_b1.position = Vector3(13, y, 2)
    _box(washing_b1, Vector3(0, 0.5, 0), Vector3(0.75, 1.0, 0.7), mat_white, true)
    _cyl(washing_b1, Vector3(0, 0.55, 0.36), 0.22, 0.02, mat_glass, false)
    _box(washing_b1, Vector3(0, 0.95, 0.36), Vector3(0.5, 0.08, 0.02), m["metal"], false)
    b.add_child(washing_b1)

    var washing_b2 = Node3D.new()
    washing_b2.name = "Washing_B2"
    washing_b2.position = Vector3(14, y, 2)
    _box(washing_b2, Vector3(0, 0.5, 0), Vector3(0.75, 1.0, 0.7), mat_white, true)
    _cyl(washing_b2, Vector3(0, 0.55, 0.36), 0.22, 0.02, mat_glass, false)
    _box(washing_b2, Vector3(0, 0.95, 0.36), Vector3(0.5, 0.08, 0.02), m["metal"], false)
    b.add_child(washing_b2)

    # Eimer
    var bucket_b1 = Node3D.new()
    bucket_b1.name = "Bucket_B1"
    bucket_b1.position = Vector3(13, y, 4)
    _cyl(bucket_b1, Vector3(0, 0.2, 0), 0.18, 0.4, m["metal_rusty"], true)
    _cyl(bucket_b1, Vector3(0, 0.4, 0), 0.18, 0.02, m["metal"], false)
    var handle = MeshInstance3D.new()
    handle.mesh = TorusMesh.new()
    handle.mesh.inner_radius = 0.15
    handle.mesh.outer_radius = 0.02
    handle.mesh.ring_radius = 0.1
    handle.rotation.x = PI/2
    handle.material_override = m["metal"]
    bucket_b1.add_child(handle)
    b.add_child(bucket_b1)

    var bucket_b2 = Node3D.new()
    bucket_b2.name = "Bucket_B2"
    bucket_b2.position = Vector3(14.5, y, 4.5)
    _cyl(bucket_b2, Vector3(0, 0.2, 0), 0.18, 0.4, m["metal_rusty"], true)
    _cyl(bucket_b2, Vector3(0, 0.4, 0), 0.18, 0.02, m["metal"], false)
    var handle2 = MeshInstance3D.new()
    handle2.mesh = TorusMesh.new()
    handle2.mesh.inner_radius = 0.15
    handle2.mesh.outer_radius = 0.02
    handle2.mesh.ring_radius = 0.1
    handle2.rotation.x = PI/2
    handle2.material_override = m["metal"]
    bucket_b2.add_child(handle2)
    b.add_child(bucket_b2)

    # Regal
    var shelf_b2 = _create_pushable_object(b, Vector3(15.5, y, 4), Vector3(0.4, 2.0, 3.0), m["wood_dark"])

    # Kiste
    var crate_b4 = _create_pushable_object(b, Vector3(9, y, 6), Vector3(0.8, 0.8, 0.8), m["wood_light"])

    # Rohr
    _cyl(b, Vector3(12, y + CEIL - 0.4, 5), 0.08, 6, m["metal_rusty"], false)

    # --- LAGERBEREICH (RECHTS) ---
    # Werkbank
    var workbench_b2 = Node3D.new()
    workbench_b2.name = "Workbench_B2"
    workbench_b2.position = Vector3(20, y, 4)
    _box(workbench_b2, Vector3(0, 0.85, 0), Vector3(2.0, 0.1, 0.7), m["wood_light"], true)
    for dx in [-0.9, 0.9]:
        for dz in [-0.25, 0.25]:
            _box(workbench_b2, Vector3(dx, 0.4, dz), Vector3(0.1, 0.8, 0.1), m["wood_dark"], false)
    _box(workbench_b2, Vector3(-0.5, 0.95, 0), Vector3(0.25, 0.02, 0.08), m["metal"], false)
    _box(workbench_b2, Vector3(0.3, 0.95, 0), Vector3(0.15, 0.05, 0.15), mat_metal_rusty, false)
    b.add_child(workbench_b2)

    # Regal
    var shelf_b3 = _create_pushable_object(b, Vector3(23.5, y, 4), Vector3(0.4, 2.2, 4.0), m["wood_dark"])

    # Kisten
    var crate_b5 = _create_pushable_object(b, Vector3(17, y, 2), Vector3(1.0, 1.0, 1.0), m["wood_light"])
    var crate_b6 = _create_pushable_object(b, Vector3(17, y, 6), Vector3(0.8, 0.8, 0.8), m["wood_light"])

    # Faesser
    var barrel_b4 = _create_pushable_object(b, Vector3(22, y, 6), Vector3(0.7, 0.9, 0.7), m["wood_light"])
    var barrel_b5 = _create_pushable_object(b, Vector3(19, y, 18), Vector3(0.7, 0.9, 0.7), m["wood_light"])

    # Bücherregal
    var bookshelf_b1 = Node3D.new()
    bookshelf_b1.name = "Bookshelf_B1"
    bookshelf_b1.position = Vector3(17, y, 7.8)
    _box(bookshelf_b1, Vector3(0, 1.2, 0), Vector3(2.0, 2.4, 0.4), m["wood_dark"], true)
    for i in range(5):
        _box(bookshelf_b1, Vector3(0, 0.24 + i*0.48, 0.02), Vector3(1.9, 0.05, 0.35), m["wood_light"], false)
    for i in range(5):
        for j in range(6):
            var bx = -0.85 + j * 0.3
            var by = 0.24 + i*0.48 + 0.15
            _box(bookshelf_b1, Vector3(bx, by, 0), Vector3(0.06, 0.25, 0.3), mat_fabric_red if (i+j)%3==0 else (mat_fabric_blue if (i+j)%3==1 else mat_fabric_green), false)
    b.add_child(bookshelf_b1)

    # --- VERRIEGELTE TUER (WIRD MIT KELLER-SCHLUESSEL GEOEFFNET) ---
    var door_b1 = _create_door(b, Vector3(4, y, 8), Vector3(DOOR_W, DOOR_H, 0.1), m["metal"], true, "keller_key", "keller")

    # --- GEHEIMTUER HINTER REGAL ---
    var secret_door_b1 = _create_door(b, Vector3(20, y, 0), Vector3(DOOR_W, DOOR_H, 0.1), m["metal"], true, "", "secret")
    var shelf_b4 = _create_pushable_object(b, Vector3(23.5, y, 17), Vector3(0.4, 2.0, 4.0), m["wood_dark"])
    var secret_room_b1 = _create_secret_room(b, Vector3(22, y, 19), Vector3(4, 3, 4), m, "1")
    secret_room_b1.visible = false
    # Verknuepfung: Regal bewegt sich und zeigt Geheimraum
    shelf_b4.set_meta("secret_room", secret_room_b1)

    # --- LICHT (BLAEULICH FUER KELLER) ---
    var light1 = OmniLight3D.new()
    light1.position = Vector3(4, y + 2.7, 4)
    light1.light_color = Color(0.5, 0.7, 1.0)
    light1.light_energy = 0.8
    light1.omni_range = 5.0
    light1.name = "Light_Storage_Basement"
    light1.add_to_group("lights")
    b.add_child(light1)
    light_switches.append(light1)

    var light2 = OmniLight3D.new()
    light2.position = Vector3(12, y + 2.7, 4)
    light2.light_color = Color(0.6, 0.7, 1.0)
    light2.light_energy = 0.8
    light2.omni_range = 5.0
    light2.name = "Light_Boiler_Basement"
    light2.add_to_group("lights")
    b.add_child(light2)
    light_switches.append(light2)

    var light3 = OmniLight3D.new()
    light3.position = Vector3(20, y + 2.7, 4)
    light3.light_color = Color(0.5, 0.7, 1.0)
    light3.light_energy = 0.8
    light3.omni_range = 5.0
    light3.name = "Light_Workshop_Basement"
    light3.add_to_group("lights")
    b.add_child(light3)
    light_switches.append(light3)

    var light4 = OmniLight3D.new()
    light4.position = Vector3(12, y + 2.7, 11)
    light4.light_color = Color(0.4, 0.6, 1.0)
    light4.light_energy = 0.6
    light4.omni_range = 7.0
    light4.name = "Light_Corridor_Basement"
    light4.add_to_group("lights")
    b.add_child(light4)
    light_switches.append(light4)

    var light5 = OmniLight3D.new()
    light5.position = Vector3(6, y + 2.7, 17)
    light5.light_color = Color(0.5, 0.6, 1.0)
    light5.light_energy = 0.6
    light5.omni_range = 5.0
    light5.name = "Light_Bathroom_Basement"
    light5.add_to_group("lights")
    b.add_child(light5)
    light_switches.append(light5)

    var light6 = OmniLight3D.new()
    light6.position = Vector3(18, y + 2.7, 17)
    light6.light_color = Color(0.5, 0.6, 1.0)
    light6.light_energy = 0.6
    light6.omni_range = 5.0
    light6.name = "Light_Storage2_Basement"
    light6.add_to_group("lights")
    b.add_child(light6)
    light_switches.append(light6)

    # Notizen
    _create_note(b, Vector3(2, y + 0.5, 1), "note_b1", "Hier im Keller gibt es viele alte Dinge. Vielleicht ist etwas Nützliches dabei.")
    _create_note(b, Vector3(15, y + 0.5, 18), "note_b2", "Hinter dem Regal könnte sich ein Geheimnis verbergen.")


func _build_sub_basement() -> void:
    var m = sub_mats
    var sb = Node3D.new()
    sb.name = "SubBasement"
    add_child(sb)
    var y = SUB_Y
    var w = 16.0
    var d = 12.0

    # Boden (MIT FLUSS IN DER MITTE)
    _floor_hole(sb, 0, w, 0, d, y + CEIL + 0.2, m["concrete"], 2, 4, 2, 6)  # Decke mit Loch für Treppe D
    _floor(sb, 0, w, 0, 2, y, m["floor"])  # Boden links
    _floor(sb, 0, w, 10, d, y, m["floor"])  # Boden rechts
    _floor(sb, 0, 3, 2, 10, y, m["floor"])  # Boden vorne
    _floor(sb, 13, w, 2, 10, y, m["floor"])  # Boden hinten
    _floor(sb, 3, 13, 2, 10, y - 0.5, mat_black)  # Fluss

    # Waende
    _wall_x(sb, 0, w, 0, y, CEIL, EXT_T, m["wall"])
    _wall_x(sb, 0, w, d, y, CEIL, EXT_T, m["wall"])
    _wall_z(sb, 0, d, 0, y, CEIL, EXT_T, m["wall"])
    _wall_z(sb, 0, d, w, y, CEIL, EXT_T, m["wall"])

    # --- BOOT ---
    var boat = Node3D.new()
    boat.name = "Boat"
    boat.position = Vector3(8, y + 0.15, 6)
    sb.add_child(boat)
    _box(boat, Vector3(0, 0, 0), Vector3(1.2, 0.3, 2.5), m["wood_light"], true)
    _box(boat, Vector3(0, 0.15, -0.6), Vector3(1.4, 0.15, 0.3), m["wood_dark"], false)
    _box(boat, Vector3(0, 0.15, 0.6), Vector3(1.4, 0.15, 0.3), m["wood_dark"], false)

    # --- KISTEN & FAESSER AM FLUSSUFER ---
    var crate_sb1 = _create_pushable_object(sb, Vector3(2, y, 11), Vector3(0.8, 0.8, 0.8), m["wood_light"])
    var barrel_sb1 = _create_pushable_object(sb, Vector3(4, y, 11), Vector3(0.7, 0.9, 0.7), m["wood_light"])
    var crate_sb2 = _create_pushable_object(sb, Vector3(6, y, 11), Vector3(1.0, 1.0, 1.0), m["wood_light"])
    var crate_sb3 = _create_pushable_object(sb, Vector3(12, y, 11), Vector3(0.9, 0.9, 0.9), m["wood_light"])
    var barrel_sb2 = _create_pushable_object(sb, Vector3(14, y, 11), Vector3(0.7, 0.9, 0.7), m["wood_light"])

    # --- KISTEN & FAESSER IN DEN ECKEN ---
    var crate_sb4 = _create_pushable_object(sb, Vector3(1, y, 1), Vector3(1.0, 1.0, 1.0), m["wood_light"])
    var crate_sb5 = _create_pushable_object(sb, Vector3(14, y, 1), Vector3(0.9, 0.9, 0.9), m["wood_light"])
    var crate_sb6 = _create_pushable_object(sb, Vector3(1, y, 11), Vector3(0.8, 0.8, 0.8), m["wood_light"])

    # --- LICHT (SEHR SCHWACH, BLAEULICH) ---
    var light1 = OmniLight3D.new()
    light1.position = Vector3(2, y + 2.5, 6)
    light1.light_color = Color(0.4, 0.5, 0.8)
    light1.light_energy = 0.5
    light1.omni_range = 3.0
    light1.name = "Light_Corner1_SubBasement"
    light1.add_to_group("lights")
    sb.add_child(light1)
    light_switches.append(light1)

    var light2 = OmniLight3D.new()
    light2.position = Vector3(14, y + 2.5, 6)
    light2.light_color = Color(0.4, 0.5, 0.8)
    light2.light_energy = 0.5
    light2.omni_range = 3.0
    light2.name = "Light_Corner2_SubBasement"
    light2.add_to_group("lights")
    sb.add_child(light2)
    light_switches.append(light2)

    var light3 = OmniLight3D.new()
    light3.position = Vector3(8, y + 2.5, 11)
    light3.light_color = Color(0.4, 0.5, 0.8)
    light3.light_energy = 0.5
    light3.omni_range = 4.0
    light3.name = "Light_Fluss_SubBasement"
    light3.add_to_group("lights")
    sb.add_child(light3)
    light_switches.append(light3)

    # Notizen
    _create_note(sb, Vector3(2, y + 0.5, 1), "note_sb1", "Dieser Raum ist sehr alt. Der Fluss in der Mitte sieht gefährlich aus.")

# ============================================================
# GRUSEL-EFFEKTE
# ============================================================

func _on_flicker_timer_timeout() -> void:
    for light in get_tree().get_nodes_in_group("lights"):
        if light is OmniLight3D and light.visible:
            var original_energy = light.light_energy
            light.light_energy = randf_range(0.5, 1.5) * original_energy
            var timer = Timer.new()
            timer.wait_time = 0.1 + randf() * 0.2
            timer.timeout.connect(func(): light.light_energy = original_energy)
            add_child(timer)
            timer.start()
    flicker_timer.start(randf_range(3.0, 8.0))

func _on_sound_timer_timeout() -> void:
    if ambient_sounds.size() > 0:
        var sound_path = ambient_sounds[randi() % ambient_sounds.size()]
        if ResourceLoader.exists(sound_path):
            var sound = AudioStreamPlayer3D.new()
            sound.stream = load(sound_path)
            sound.position = Vector3(randf_range(-10, 10), randf_range(0, 3), randf_range(-10, 10))
            sound.volume_db = randf_range(-15, -5)
            add_child(sound)
            sound.play()
    sound_timer.start(randf_range(5.0, 15.0))

func _on_ghost_timer_timeout() -> void:
    if enable_ghost_events and randf() < ghost_spawn_chance:
        var spawn_positions = [
            Vector3(5, EG_Y, 5), Vector3(15, OG_Y, 15),
            Vector3(10, ATTIC_Y, 10), Vector3(8, BASE_Y, 8),
            Vector3(12, SUB_Y, 6)
        ]
        var pos = spawn_positions[randi() % spawn_positions.size()]
        _spawn_ghost(pos)
    ghost_timer.start(60.0)

func _spawn_ghost(pos: Vector3) -> void:
    var ghost = Node3D.new()
    ghost.name = "Ghost"
    ghost.position = pos
    add_child(ghost)

    var mesh = MeshInstance3D.new()
    mesh.mesh = SphereMesh.new()
    mesh.mesh.radius = 0.5
    var ghost_mat = StandardMaterial3D.new()
    ghost_mat.albedo_color = Color(1, 1, 1, 0.3)
    ghost_mat.emission_enabled = true
    ghost_mat.emission_color = Color(0.5, 0.5, 1.0)
    ghost_mat.emission_energy = 2.0
    mesh.material_override = ghost_mat
    ghost.add_child(mesh)

    var light = OmniLight3D.new()
    light.light_color = Color(0.5, 0.5, 1.0)
    light.light_energy = 2.0
    light.omni_range = 5.0
    light.add_to_group("lights")
    ghost.add_child(light)

    var anim = AnimationPlayer.new()
    ghost.add_child(anim)

    var anim_float = Animation.new()
    anim_float.length = 2.0
    anim_float.track_insert_key(0, 0.0, 0.0)
    anim_float.track_insert_key(0, 0.5, 0.5)
    anim_float.track_insert_key(0, 1.0, 0.0)
    anim.add_animation("float", anim_float)

    var anim_rotate = Animation.new()
    anim_rotate.length = 4.0
    anim_rotate.track_insert_key(0, 0.0, 0.0)
    anim_rotate.track_insert_key(0, 1.0, TAU)
    anim.add_animation("rotate", anim_rotate)

    anim.play("float")
    anim.play("rotate")

    var timer = Timer.new()
    timer.wait_time = 5.0
    timer.timeout.connect(func(): ghost.queue_free())
    ghost.add_child(timer)
    timer.start()


# ============================================================
# HAUPTFUNKTIONEN
# ============================================================

func _ready() -> void:
    # Materialien initialisieren
    _init_materials()
    _init_etage_materials()

    # Welt erstellen
    _init_world()

    # Spieler erstellen
    _create_player()

    # UI erstellen
    _create_ui()

    # Etagen aufbauen
    _build_eg()
    _build_og()
    _build_attic()
    _build_basement()
    _build_sub_basement()

    # Alle interaktiven Objekte in Gruppe packen
    for obj in interactive_objects:
        obj.add_to_group("interactives")

    # UI aktualisieren
    _update_inventory_ui()
    _update_tasks_ui()

    # Spawn-Marker hinzufügen
    _add_spawn_marker()

    print("Granny 2 Ultimate Map geladen! Interaktive Objekte: ", interactive_objects.size())

func _input(event) -> void:
    if event is InputEventKey:
        if event.is_pressed():
            if event.keycode == KEY_TAB:
                inventory_ui.visible = !inventory_ui.visible
            elif event.keycode == KEY_J:
                tasks_ui.visible = !tasks_ui.visible
            elif event.keycode == KEY_N:
                if inventory["notes"].size() > 0:
                    var first_note = true
                    for note_id in inventory["notes"]:
                        if inventory["notes"][note_id]:
                            _show_note(note_id)
                            first_note = false
                            break
            elif event.keycode == KEY_ESCAPE:
                if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
                    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
                else:
                    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

            # Interaktion mit E-Taste
            elif event.keycode == KEY_E:
                if current_interactable != null:
                    if current_interactable.has_method("interact"):
                        current_interactable.interact()

            # Drag & Drop starten
            elif event.is_mouse_event() and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
                if raycast.is_colliding():
                    var collider = raycast.get_collider()
                    if collider is RigidBody3D:
                        is_dragging = true
                        dragged_object = collider
                        drag_offset = camera.global_transform.origin - collider.global_position
                        dragged_object.sleeping = false

            # Drag & Drop beenden
            elif event.is_mouse_event() and not event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
                is_dragging = false
                if dragged_object:
                    dragged_object.linear_velocity = Vector3.ZERO
                    dragged_object.angular_velocity = Vector3.ZERO
                    dragged_object = null

func _physics_process(delta) -> void:
    if is_dragging and dragged_object:
        var target_pos = camera.global_transform.origin - drag_offset
        dragged_object.apply_central_impulse((target_pos - dragged_object.global_position) * 20.0)

    # Raycast für Interaktion
    raycast.force_update_transform()
    if raycast.is_colliding():
        var collider = raycast.get_collider()
        if collider != current_interactable:
            if current_interactable != null:
                _hide_interaction()
            current_interactable = collider
            if collider.has_method("interact"):
                _show_interaction("E: Interagieren")
            else:
                current_interactable = null
                _hide_interaction()
    else:
        if current_interactable != null:
            _hide_interaction()
            current_interactable = null

func _add_spawn_marker() -> void:
    var m = Marker3D.new()
    m.name = "PlayerSpawn"
    m.position = Vector3(4, 0.1, 4)
    add_child(m)
