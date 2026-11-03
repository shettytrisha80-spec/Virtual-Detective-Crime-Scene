extends Node3D
## All geometry is generated locally. Case data is separate from presentation.
const CaseData = preload("res://scripts/case_data.gd")
const CYAN = Color("69d8ee")
const GOLD = Color("dfb777")
var evidence: Array[String] = []
var connections: Array[String] = []
var interviewed: Array[String] = []
var challenged: Array[String] = []
var started = false
var modal = true
var drawer_open = false
var service_open = false
var target_id = ""
var collected_inspect = ""
var selection = ""
var accused = "Alex"
var grounds: Array[String] = []
var xr_active = false
var player: CharacterBody3D
var camera: Camera3D
var ray: RayCast3D
var xr_origin: XROrigin3D
var right: XRController3D
var left: XRController3D
var xr_camera: XRCamera3D
var xr_ray: RayCast3D
var hud: CanvasLayer
var root_ui: Control
var overlay: PanelContainer
var panel_content: VBoxContainer
var objective: Label
var prompt: Label
var toast: Label
var case_label: Label
var crosshair: Label
var inspector: SubViewport
var inspect_object: Node3D
var board_canvas: Control
var drawer_mesh: Node3D
var service_door: StaticBody3D
var sound_players: Dictionary = {}
var cctv_time = 0.0
var cctv_view: Control
var cctv_figure: ColorRect
var cctv_label: Label
var toast_time = 0.0
var held_items: Dictionary = {}

func _ready() -> void:
 setup_input()
 bind_apartment($Apartment)
 build_player()
 build_ui()
 build_audio()
 show_menu()
 if "--smoke-test" in OS.get_cmdline_user_args():
  call_deferred("smoke_test")
 if "--visual-test" in OS.get_cmdline_user_args():
  call_deferred("visual_test")

func bind_apartment(node: Node) -> void:
 if node.has_meta("clue_id"):
  var id = str(node.get_meta("clue_id"))
  held_items[id] = node
  if id == "drawer": drawer_mesh = node
  if id == "door": service_door = node as StaticBody3D
 for child in node.get_children(): bind_apartment(child)

func setup_input() -> void:
 var bindings = {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "interact": KEY_E, "case_file": KEY_TAB, "board": KEY_B, "flashlight": KEY_F, "sprint": KEY_SHIFT}
 for action in bindings:
  if not InputMap.has_action(action):
   InputMap.add_action(action)
  var key = InputEventKey.new()
  key.physical_keycode = bindings[action]
  InputMap.action_add_event(action, key)

func mat(color: Color, metal: float = 0.0, rough: float = 0.8, glow: bool = false) -> StandardMaterial3D:
 var m = StandardMaterial3D.new()
 m.albedo_color = color
 m.metallic = metal
 m.roughness = rough
 if glow:
  m.emission_enabled = true
  m.emission = color
  m.emission_energy_multiplier = 1.3
 return m

func box(label: String, pos: Vector3, size: Vector3, color: Color, solid: bool = true, id: String = "") -> Node3D:
 var body: Node3D = StaticBody3D.new() if solid or id != "" else Node3D.new()
 body.name = label
 add_child(body, true)
 body.position = pos
 var mesh = MeshInstance3D.new()
 mesh.name = "Mesh"
 var cube = BoxMesh.new()
 cube.size = size
 mesh.mesh = cube
 mesh.material_override = mat(color)
 body.add_child(mesh)
 if body is StaticBody3D:
  var shape = CollisionShape3D.new()
  shape.name = "Collision"
  var bounds = BoxShape3D.new()
  bounds.size = size
  shape.shape = bounds
  body.add_child(shape)
 if id != "":
  body.set_meta("clue_id", id)
  held_items[id] = body
 return body

func sign_text(text: String, pos: Vector3, size: int = 36, color: Color = CYAN) -> Label3D:
 var l = Label3D.new()
 l.name = "SceneLabel"
 l.text = text
 l.position = pos
 l.font_size = size
 l.pixel_size = 0.008
 l.modulate = color
 l.no_depth_test = false
 add_child(l, true)
 return l

func light_at(pos: Vector3, color: Color, energy: float, radius: float) -> void:
 var l = OmniLight3D.new()
 l.name = "RoomLight"
 l.position = pos
 l.light_color = color
 l.light_energy = energy
 l.omni_range = radius
 l.shadow_enabled = true
 add_child(l, true)

func build_world() -> void:
 var env = WorldEnvironment.new()
 env.name = "ApartmentEnvironment"
 var environment = Environment.new()
 environment.background_mode = Environment.BG_COLOR
 environment.background_color = Color("081525")
 environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.ambient_light_color = Color("94aec2")
 environment.ambient_light_energy = 0.5
 environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 env.environment = environment
 add_child(env)
 box("Foundation", Vector3(0,-0.16,0),Vector3(12,0.3,12),Color("18232b"))
 for i in range(24):
  box("Floorboard", Vector3(-5.75+i*.5,0.002,0),Vector3(.48,.018,12),Color("30383d") if i%2==0 else Color("354047"),false)
 box("Ceiling",Vector3(0,3.3,0),Vector3(12,.2,12),Color("202d39"))
 box("WestWall",Vector3(-6,1.6,0),Vector3(.2,3.3,12),Color("283c4b"))
 box("EastWall",Vector3(6,1.6,0),Vector3(.2,3.3,12),Color("283c4b"))
 box("SouthWall",Vector3(0,1.6,6),Vector3(12,3.3,.2),Color("213441"))
 box("NorthLeft",Vector3(-4.6,1.6,-6),Vector3(2.8,3.3,.2),Color("304756"))
 box("NorthRight",Vector3(3.3,1.6,-6),Vector3(5.4,3.3,.2),Color("304756"))
 box("WindowBottom",Vector3(-1.3,.48,-6),Vector3(3.8,1,.22),Color("304756"))
 box("WindowTop",Vector3(-1.3,3.05,-6),Vector3(3.8,.5,.22),Color("304756"))
 var window = box("WindowInspection",Vector3(-1.3,1.8,-6),Vector3(3.6,1.5,.035),Color("101e32"),true,"window")
 window.get_child(0).visible = false
 box("Sill",Vector3(-1.3,1,-5.8),Vector3(4,.12,.55),Color("657681"))
 for x in [-3.2,.6]:
  box("WindowFrame",Vector3(x,1.85,-5.89),Vector3(.08,1.8,.12),Color("768a92"))
 box("WindowCrossbar",Vector3(-1.3,2,-5.86),Vector3(3.8,.05,.12),Color("768a92"))
 for i in range(11):
  var glass = box("GlassShard",Vector3(-2.9+i*.3,1.08,-6.13),Vector3(.22,.014,.1),Color("8abac9"),false)
  glass.rotation.y = i*.73
 # City silhouettes beyond the window.
 for i in range(12):
  box("DistantBuilding",Vector3(-9+i*1.6,1,-13),Vector3(1.2,2.5+(i%4),1),Color("0b1220"),false)
  for j in range(3):
   box("CityLight",Vector3(-9+i*1.6,j*.6,-12.48),Vector3(.15,.14,.02),Color("667d92"),false)
 box("Rug",Vector3(-2,.032,1),Vector3(4.7,.025,4.2),Color("172f40"),false)
 for i in range(8):
  box("RugStripe",Vector3(-2,.05,-.9+i*.55),Vector3(4.5,.008,.035),Color("36515d"),false)
 box("CouchBase",Vector3(-4.7,.38,.5),Vector3(1.6,.65,3.7),Color("28373e"))
 box("CouchBack",Vector3(-5.35,.9,.5),Vector3(.34,1,3.8),Color("35434b"))
 for z in [-.72,.5,1.72]:
  box("Cushion",Vector3(-4.55,.76,z),Vector3(1.25,.25,1.08),Color("455158"))
 for z in [-1.5,2.5]:
  box("CouchArm",Vector3(-4.7,.75,z),Vector3(1.6,.7,.2),Color("34434c"))
 box("CoffeeTable",Vector3(-1.8,.58,.7),Vector3(2,.12,1.3),Color("6d5440"))
 for x in [-2.6,-1]:
  for z in [.2,1.2]:
   box("TableLeg",Vector3(x,.28,z),Vector3(.08,.56,.08),Color("17222d"))
 box("Desk",Vector3(2.9,.86,-4.5),Vector3(3,.16,1.3),Color("735c47"))
 # Domestic details give the primitive apartment a lived-in silhouette.
 box("ChairSeat",Vector3(3.4,.5,-2.9),Vector3(.65,.12,.65),Color("323e49"))
 box("ChairBack",Vector3(3.4,.95,-2.57),Vector3(.65,.85,.1),Color("3d4b54"))
 for x in [3.15,3.65]:
  for z in [-3.15,-2.65]:
   box("ChairLeg",Vector3(x,.25,z),Vector3(.05,.5,.05),Color("849098"))
 box("LampBase",Vector3(3.6,.97,-4.7),Vector3(.4,.07,.3),Color("263a42"),false)
 box("LampStem",Vector3(3.6,1.27,-4.7),Vector3(.035,.6,.035),GOLD,false)
 box("LampShade",Vector3(3.6,1.56,-4.6),Vector3(.5,.16,.35),Color("577379"),false)
 for i in range(5):
  box("Books",Vector3(-2.4,.69+i*.045,.6),Vector3(.45,.04,.6),Color("645d52") if i%2==0 else Color("416273"),false)
 for x in [-3.6,1.02]:
  for i in range(5):
   box("CurtainFold",Vector3(x+i*.07,1.9,-5.65),Vector3(.08,2.15,.1+(i%2)*.08),Color("233b50"),false)
 box("CurtainRail",Vector3(-1.3,3,-5.65),Vector3(5.5,.035,.035),Color("8e9795"),false)
 for z in [-5.84,5.84]:
  box("Skirting",Vector3(0,.15,z),Vector3(11.7,.24,.05),Color("50616b"),false)
 for x in [-5.84,5.84]:
  box("Skirting",Vector3(x,.15,0),Vector3(.05,.24,11.7),Color("50616b"),false)
 box("WallArtFrame",Vector3(-5.83,1.95,.6),Vector3(.08,1.15,1.8),Color("111f2b"),false)
 box("WallArtCanvas",Vector3(-5.77,1.95,.6),Vector3(.02,.95,1.6),Color("6b787f"),false)
 for i in range(5):
  box("AbstractArt",Vector3(-5.74,1.6+i*.13,.5+i*.11),Vector3(.015,.07,.9-i*.1),Color("2e5365"),false)
 for x in [1.6,4.2]:
  box("DeskLeg",Vector3(x,.43,-4.5),Vector3(.13,.86,1.1),Color("273746"))
 drawer_mesh = box("LockedDrawer",Vector3(3.8,.63,-4.27),Vector3(.8,.28,.9),Color("514234"),true,"drawer")
 box("DrawerHandle",Vector3(3.8,.63,-3.79),Vector3(.27,.045,.05),GOLD,false)
 box("Notebook",Vector3(2.05,.98,-4.25),Vector3(.55,.08,.72),Color("315d6b"),true,"notebook")
 box("Phone",Vector3(-1.8,.68,.7),Vector3(.23,.06,.45),Color("143148"),true,"phone")
 box("PhoneScreen",Vector3(-1.8,.713,.7),Vector3(.19,.005,.34),CYAN,false)
 box("BrassKey",Vector3(-4,.96,1.7),Vector3(.32,.07,.13),GOLD,true,"key")
 for i in range(4):
  var boot = box("BootPrint",Vector3(3.4-i*.55,.05,-1.5-i*.38),Vector3(.19,.025,.4),Color("11191f"),true,"footprint")
  boot.rotation.y = -.5
  box("HeelGap",boot.position+Vector3(.04,.02,.15),Vector3(.06,.01,.08),Color("354047"),false)
 box("BloodTrace",Vector3(2.6,.046,-3.3),Vector3(.58,.02,.4),Color("45212b"),true,"blood")
 var glass_cup = box("FallenGlass",Vector3(2.2,.1,-3.5),Vector3(.16,.15,.3),Color("7597a1"),false)
 glass_cup.rotation.y = .4
 # Side alcove is blocked until the drawer gives access authorization.
 box("PartitionLeft",Vector3(3.4,1.6,.7),Vector3(.18,3.2,2.6),Color("2c424e"))
 box("PartitionRight",Vector3(3.4,1.6,5.2),Vector3(.18,3.2,1.6),Color("2c424e"))
 service_door = box("ServiceDoor",Vector3(3.4,1.35,3.25),Vector3(.18,2.7,2.5),Color("3b5360"),true,"door") as StaticBody3D
 sign_text("SERVICE / CCTV\nACCESS RESTRICTED",Vector3(3.26,1.7,3.25),22).rotation.y = -PI/2
 box("TerminalTable",Vector3(4.8,.8,5),Vector3(1.6,.15,1),Color("46525c"))
 box("CCTVTerminal",Vector3(4.8,1.25,5.12),Vector3(1.3,.8,.15),Color("122939"),true,"terminal")
 var screen = box("MonitorScreen",Vector3(4.8,1.25,5.02),Vector3(1.16,.66,.015),Color("3e8792"),false)
 screen.get_child(0).material_override = mat(Color("296576"),0,.5,true)
 sign_text("CCTV // 03",Vector3(4.8,1.3,4.99),18).rotation.y = PI
 # Case station and interview radio near the entrance.
 box("CaseBoard",Vector3(-2,1.7,5.86),Vector3(3.5,1.7,.12),Color("143445"),true,"board")
 sign_text("CASE 031 // CONNECTIONS\n[E] EVIDENCE BOARD",Vector3(-2,1.8,5.76),28).rotation.y = PI
 box("RadioStand",Vector3(.8,.7,4.9),Vector3(1,.12,.7),Color("60513f"))
 box("InterviewRadio",Vector3(.8,.91,4.9),Vector3(.48,.3,.28),Color("253f50"),true,"interviews")
 sign_text("SECURE INTERVIEW LINE",Vector3(.8,1.6,5.5),18).rotation.y = PI
 box("EntryDoor",Vector3(1.5,1.35,5.84),Vector3(1.4,2.7,.14),Color("47515a"))
 for i in range(3):
  var tape = box("PoliceTape",Vector3(1.5,.5+i*.7,5.73),Vector3(1.5,.09,.02),GOLD,false)
  tape.rotation.z = .12 if i%2==0 else -.12
 for z in [-4.4,1.8]:
  box("CeilingFixture",Vector3(0,3.12,z),Vector3(1.6,.08,.25),Color("a4bdc8"),false)
 light_at(Vector3(0,2.9,-3),Color("90c4e0"),1.6,8)
 light_at(Vector3(-2,2.8,2),Color("638faa"),1.3,7)
 light_at(Vector3(4.7,2.7,4.5),Color("60b8c9"),1.2,5)
 light_at(Vector3(3,1.8,-4.5),Color("f0bc7b"),.7,3.5)
 light_at(Vector3(-1.5,2,-5.5),Color("427fdb"),1,5)
 # Evidence number tents.
 var locations = [Vector3(1.6,1,-4.1),Vector3(2.8,.2,-1.8),Vector3(-2.8,1.3,-5.65),Vector3(-2.4,.83,.7),Vector3(2.8,.2,-3.4)]
 for i in range(locations.size()):
  box("EvidenceMarker",locations[i],Vector3(.16,.2,.07),GOLD,false)
  sign_text("%02d" % (i+1),locations[i]+Vector3(0,.01,.04),15,Color("142634"))

func build_player() -> void:
 player = CharacterBody3D.new()
 player.name = "DesktopPlayer"
 player.position = Vector3(0,.15,3.8)
 add_child(player)
 var collision = CollisionShape3D.new()
 var capsule = CapsuleShape3D.new()
 capsule.radius = .24
 capsule.height = 1.7
 collision.shape = capsule
 collision.position.y = .85
 player.add_child(collision)
 camera = Camera3D.new()
 camera.position.y = 1.6
 camera.fov = 76
 camera.current = true
 player.add_child(camera)
 ray = RayCast3D.new()
 ray.target_position = Vector3(0,0,-3.4)
 ray.add_exception(player)
 camera.add_child(ray)
 var torch = SpotLight3D.new()
 torch.name = "Flashlight"
 torch.light_color = Color("c4e6f6")
 torch.light_energy = 2.4
 torch.spot_range = 10
 torch.spot_angle = 32
 torch.shadow_enabled = true
 camera.add_child(torch)
 xr_origin = XROrigin3D.new()
 xr_origin.name = "XROrigin3D"
 xr_origin.position = Vector3(0,.1,3.8)
 add_child(xr_origin)
 xr_camera = XRCamera3D.new()
 xr_origin.add_child(xr_camera)
 xr_camera.current = false
 left = XRController3D.new()
 left.tracker = "left_hand"
 left.name = "LeftController"
 xr_origin.add_child(left)
 right = XRController3D.new()
 right.tracker = "right_hand"
 right.name = "RightController"
 xr_origin.add_child(right)
 xr_ray = RayCast3D.new()
 xr_ray.target_position = Vector3(0,0,-4)
 xr_ray.add_exception(player)
 right.add_child(xr_ray)
 var beam = MeshInstance3D.new()
 var beam_mesh = BoxMesh.new()
 beam_mesh.size = Vector3(.005,.005,4)
 beam.mesh = beam_mesh
 beam.position.z = -2
 beam.material_override = mat(CYAN,0,.5,true)
 right.add_child(beam)
 right.button_pressed.connect(func(button: String):
  if button == "trigger_click" and not modal: interact(target_id)
 )

func build_audio() -> void:
 for key in ["room","police","static","click","discover","drawer","phone","wrong","solved"]:
  var p = AudioStreamPlayer.new()
  p.stream = load("res://audio/"+key+".wav")
  p.volume_db = -9 if key in ["room","police","static"] else -5
  add_child(p)
  sound_players[key] = p
  if key in ["room","police","static"]:
   p.finished.connect(p.play)
 if DisplayServer.get_name() != "headless":
  sound_players.room.play()
  sound_players.police.play()

func sound(key: String) -> void:
 if DisplayServer.get_name() != "headless": sound_players[key].play()

func style(bg: Color, border: Color = Color("28485f"), radius: int = 12) -> StyleBoxFlat:
 var s = StyleBoxFlat.new()
 s.bg_color = bg
 s.border_color = border
 s.set_border_width_all(1)
 s.set_corner_radius_all(radius)
 s.content_margin_left = 20
 s.content_margin_right = 20
 s.content_margin_top = 12
 s.content_margin_bottom = 12
 return s

func build_ui() -> void:
 hud = CanvasLayer.new()
 add_child(hud)
 root_ui = Control.new()
 root_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
 hud.add_child(root_ui)
 var theme = Theme.new()
 theme.default_font_size = 18
 theme.set_color("font_color","Label",Color("c9dce7"))
 theme.set_color("font_color","Button",Color("d8edf4"))
 theme.set_stylebox("normal","Button",style(Color("173144")))
 theme.set_stylebox("hover","Button",style(Color("245066"),CYAN))
 theme.set_stylebox("pressed","Button",style(Color("306579"),CYAN))
 theme.set_stylebox("disabled","Button",style(Color("17232d"),Color("26343e")))
 root_ui.theme = theme
 var top = PanelContainer.new()
 top.position = Vector2(28,22)
 top.size = Vector2(570,110)
 top.add_theme_stylebox_override("panel",style(Color("101f30")))
 root_ui.add_child(top)
 var stack = VBoxContainer.new()
 top.add_child(stack)
 case_label = add_label(stack,"VD / FORENSIC OPERATIONS                         CASE 031",17,CYAN)
 objective = add_label(stack,"Enter the apartment",20)
 var help = Label.new()
 help.text = "WASD  MOVE     E  INTERACT     TAB  CASE FILE     B  BOARD     F  LIGHT     ESC  PAUSE"
 help.add_theme_font_size_override("font_size",15)
 help.position = Vector2(30,860)
 root_ui.add_child(help)
 crosshair = Label.new()
 crosshair.text = "+"
 crosshair.position = Vector2(711,435)
 crosshair.add_theme_font_size_override("font_size",25)
 crosshair.modulate = CYAN
 root_ui.add_child(crosshair)
 prompt = Label.new()
 prompt.position = Vector2(390,735)
 prompt.size = Vector2(660,70)
 prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 root_ui.add_child(prompt)
 toast = Label.new()
 toast.position = Vector2(680,34)
 toast.size = Vector2(720,70)
 toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 toast.add_theme_color_override("font_color",GOLD)
 root_ui.add_child(toast)
 overlay = PanelContainer.new()
 overlay.position = Vector2(210,148)
 overlay.size = Vector2(1020,660)
 overlay.add_theme_stylebox_override("panel",style(Color(.035,.074,.12,.98),Color("396275"),16))
 root_ui.add_child(overlay)
 var scroll = ScrollContainer.new()
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 overlay.add_child(scroll)
 panel_content = VBoxContainer.new()
 panel_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 panel_content.add_theme_constant_override("separation",14)
 scroll.add_child(panel_content)
 # Independent lit preview scene permits physical clue rotation without mutating evidence.
 inspector = SubViewport.new()
 inspector.size = Vector2i(450,220)
 inspector.own_world_3d = true
 inspector.transparent_bg = true
 add_child(inspector)
 var preview_camera = Camera3D.new()
 preview_camera.position = Vector3(0,1.3,2.6)
 preview_camera.rotation.x = -.4
 inspector.add_child(preview_camera)
 var lamp = OmniLight3D.new()
 lamp.position = Vector3(0,2,2)
 lamp.light_energy = 3
 inspector.add_child(lamp)
 inspect_object = Node3D.new()
 inspector.add_child(inspect_object)

func add_label(parent: Node, text: String, font_size: int = 20, color: Color = Color("c9dce7")) -> Label:
 var l = Label.new()
 l.text = text
 l.add_theme_font_size_override("font_size",font_size)
 l.add_theme_color_override("font_color",color)
 l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 parent.add_child(l)
 return l

func button(parent: Node, text: String, callback: Callable) -> Button:
 var b = Button.new()
 b.text = text
 b.clip_text = true
 b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 b.custom_minimum_size.y = 44
 b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 parent.add_child(b)
 b.pressed.connect(func(): sound("click"); callback.call())
 return b

func clear_panel(title: String, subtitle: String = "") -> void:
 modal = true
 target_id = ""
 overlay.show()
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 cctv_view = null
 cctv_figure = null
 cctv_label = null
 if sound_players.has("static"): sound_players.static.stop()
 for c in panel_content.get_children():
  panel_content.remove_child(c)
  c.queue_free()
 add_label(panel_content,title,32,CYAN)
 if subtitle != "": add_label(panel_content,subtitle,17,GOLD)
 prompt.text = ""

func close_panel() -> void:
 modal = false
 overlay.hide()
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 sound_players.static.stop()
 cctv_view = null
 cctv_figure = null
 cctv_label = null
 update_objective()

func show_menu() -> void:
 clear_panel("VIRTUAL DETECTIVE", "CRIME SCENE VR  /  AN ORIGINAL INVESTIGATION")
 add_label(panel_content,"THE SILENT AUDIT",46)
 add_label(panel_content,"Apartment 031. A dead auditor. An open window. Three people with something to hide.\n\nRead the room. Challenge the timeline. Make a case that survives scrutiny.",22)
 button(panel_content,"START  /  ENTER CRIME SCENE",show_intro)
 button(panel_content,"OPENXR STATUS / SETUP",show_xr)
 add_label(panel_content,"Desktop playable • Generated environment • Original procedural sound\nWASD + mouse to explore. Interact with E. Use TAB for the case file.",16)
 button(panel_content,"QUIT",func(): get_tree().quit())

func show_intro() -> void:
 clear_panel("BRIEFING / 23:17", "VICTIM: ELLIS WARD  •  LOCATION: APARTMENT 031")
 add_label(panel_content,"Ellis Ward was found after a disturbance. Responders have secured the apartment and removed the victim. A break-in is suspected.\n\nAlex, a friend, demanded repayment. Maya, the roommate, was away. Ryan, the security employee, says nobody used the service door.\n\nRecover the facts before deciding whose story fails. Every suspect can be interviewed through the secure radio by the entry.",22)
 add_label(panel_content,"1  Search the apartment and inspect objects.\n2  Find the key, open the drawer, then recover CCTV.\n3  Connect evidence and challenge all three accounts.\n4  Submit a suspect and three supporting exhibits.",20,CYAN)
 button(panel_content,"BEGIN INVESTIGATION",func(): started = true; close_panel())

func show_xr() -> void:
 clear_panel("OPENXR / DEVICE READINESS")
 var xr = XRServer.find_interface("OpenXR")
 add_label(panel_content,"This project includes an XROrigin3D, tracked camera, both controllers, right-hand interaction ray, and shared evidence interaction. Desktop is the default.\n\nFor a headset: enable XR > OpenXR > Enabled in Project Settings, restart the project through an active PC OpenXR runtime, then activate below. The default Godot OpenXR action map supplies trigger_click.\n\nCurrent limitation: case-file panels use the desktop mirror and mouse; locomotion uses WASD. This is a VR-ready prototype, not a headset-only release.",20)
 button(panel_content,"ACTIVATE OPENXR",func():
  if xr != null and (xr.is_initialized() or xr.initialize()):
   get_viewport().use_xr = true
   xr_camera.current = true
   xr_active = true
   notify("OpenXR active. Right trigger interacts; desktop mirror handles panels.")
  else: notify("No initialized OpenXR runtime. See setup instructions above.")
 )
 button(panel_content,"BACK",show_menu)

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion:
  if not modal and not xr_active:
   player.rotation.y -= event.relative.x*.0022
   camera.rotation.x = clampf(camera.rotation.x-event.relative.y*.0022,-1.4,1.4)
  elif modal and collected_inspect != "" and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
   inspect_object.rotation.y += event.relative.x*.012
   inspect_object.rotation.x += event.relative.y*.012
 if event.is_action_pressed("ui_cancel"):
  if started:
   if modal: close_panel()
   else: show_pause()
 if not started: return
 if event.is_action_pressed("case_file"): show_case()
 if event.is_action_pressed("board"): show_board()
 if event.is_action_pressed("flashlight"): camera.get_node("Flashlight").visible = not camera.get_node("Flashlight").visible
 if event.is_action_pressed("interact") and not modal: interact(target_id)

func _physics_process(delta: float) -> void:
 if not started or modal: return
 var move = Input.get_vector("left","right","forward","back")
 var direction = player.transform.basis * Vector3(move.x,0,move.y)
 var speed = 3.8 if Input.is_action_pressed("sprint") else 2.5
 player.velocity.x = direction.x*speed
 player.velocity.z = direction.z*speed
 player.velocity.y -= 18*delta
 player.move_and_slide()
 if xr_active: xr_origin.position = player.position
 var active_ray = xr_ray if xr_active else ray
 active_ray.force_raycast_update()
 target_id = ""
 if active_ray.is_colliding():
  var hit = active_ray.get_collider()
  if hit != null and hit.has_meta("clue_id"): target_id = str(hit.get_meta("clue_id"))
 var title = ""
 if CaseData.CLUES.has(target_id): title = CaseData.CLUES[target_id][0]
 else: title = {"drawer":"Locked desk drawer", "door":"Service alcove", "terminal":"CCTV terminal", "board":"Evidence board", "interviews":"Interview radio"}.get(target_id,"")
 prompt.text = ("[E]  " + title) if target_id != "" else ""
 crosshair.modulate = GOLD if target_id != "" else CYAN

func _process(delta: float) -> void:
 if toast_time > 0:
  toast_time -= delta
  if toast_time <= 0: toast.text = ""
 if modal and collected_inspect != "": inspect_object.rotation.y += delta*.23
 if is_instance_valid(cctv_view):
  cctv_time += delta
  var phase = fmod(cctv_time,12.0)
  cctv_figure.position.x = 100+phase*42 if phase < 8 else 436-(phase-8)*70
  cctv_label.text = "CAM 03 // RECOVERED BUFFER      " + ("22:28:14  SERVICE ENTRY" if phase < 4 else "22:35:18  WINDOW GLASS FALLS OUTWARD" if phase < 8 else "22:36:02  EXIT / RIGHT HEEL")

func notify(text: String) -> void:
 toast.text = text
 toast_time = 5

func update_objective() -> void:
 case_label.text = "VD / CASE 031                              %02d / 08 EXHIBITS" % evidence.size()
 if not evidence.has("key"): objective.text = "Search the room • find the drawer key"
 elif not drawer_open: objective.text = "Use the brass key on the desk drawer"
 elif not evidence.has("cctv"): objective.text = "Open service alcove • recover CCTV"
 elif connections.size() < 3: objective.text = "Connect related exhibits on the board [B]"
 elif challenged.size() < 3: objective.text = "Interview and challenge all three suspects [TAB]"
 else: objective.text = "Review the case • submit your accusation [TAB]"

func interact(id: String) -> void:
 if id == "": return
 match id:
  "drawer":
   if not evidence.has("key"): notify("Locked. Find the brass key near the couch."); sound("wrong")
   else:
    if not drawer_open:
     drawer_open = true
     drawer_mesh.position.z += .45
     sound("drawer")
    show_inspect("ledger")
  "door":
   if not evidence.has("ledger"): notify("Restricted. Recover the original ledger from the drawer.")
   else:
    service_open = true
    service_door.position.y = -4
    sound("drawer")
    notify("Service alcove unlocked. Examine the terminal.")
  "terminal":
   if evidence.has("ledger"): show_terminal()
   else: notify("Terminal locked. The drawer contains the override code.")
  "board": show_board()
  "interviews": show_interviews()
  _:
   if CaseData.CLUES.has(id): show_inspect(id)

func show_inspect(id: String) -> void:
 collected_inspect = id
 clear_panel(CaseData.CLUES[id][0],"FORENSIC EXAMINATION  /  RIGHT-DRAG TO ROTATE PREVIEW")
 for child in inspect_object.get_children():
  inspect_object.remove_child(child)
  child.queue_free()
 var mesh = MeshInstance3D.new()
 var shape = BoxMesh.new()
 shape.size = Vector3(.8,.08,1.1) if id in ["notebook","ledger","phone"] else Vector3(.7,.12,.35)
 mesh.mesh = shape
 mesh.material_override = mat(GOLD if id == "key" else Color("4a8599"),.3)
 inspect_object.add_child(mesh)
 if id == "key":
  shape.size = Vector3(.65,.06,.08)
  var ring = MeshInstance3D.new()
  var torus = TorusMesh.new()
  torus.inner_radius = .11
  torus.outer_radius = .19
  ring.mesh = torus
  ring.position.x = -.45
  ring.material_override = mat(GOLD,.65)
  inspect_object.add_child(ring)
  for x in [.15,.28]:
   var tooth = MeshInstance3D.new()
   var tooth_shape = BoxMesh.new()
   tooth_shape.size = Vector3(.06,.06,.15)
   tooth.mesh = tooth_shape
   tooth.position = Vector3(x,0,.06)
   tooth.material_override = ring.material_override
   inspect_object.add_child(tooth)
 elif id in ["notebook","ledger","phone"]:
  var inset = MeshInstance3D.new()
  var inset_mesh = BoxMesh.new()
  inset_mesh.size = Vector3(.71,.012,.97)
  inset.mesh = inset_mesh
  inset.position.y = .049
  inset.material_override = mat(Color("b9d7dd") if id != "phone" else Color("132c42"))
  inspect_object.add_child(inset)
  for i in range(6):
   var ink = MeshInstance3D.new()
   var stroke = BoxMesh.new()
   stroke.size = Vector3(.48,.005,.016)
   ink.mesh = stroke
   ink.position = Vector3(0,.058,-.35+i*.13)
   ink.material_override = mat(Color("264052") if id != "phone" else CYAN)
   inspect_object.add_child(ink)
 var preview = TextureRect.new()
 preview.texture = inspector.get_texture()
 preview.custom_minimum_size = Vector2(450,160)
 preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 panel_content.add_child(preview)
 add_label(panel_content,CaseData.CLUES[id][1],20)
 button(panel_content,"EXHIBIT FILED • RETURN" if evidence.has(id) else "COLLECT / ADD TO CASE FILE",func(): collect(id); collected_inspect = ""; close_panel())
 button(panel_content,"LEAVE WITHOUT COLLECTING",func(): collected_inspect = ""; close_panel())

func collect(id: String) -> void:
 if not evidence.has(id):
  evidence.append(id)
  sound("phone" if id == "phone" else "discover")
  notify("Evidence filed: "+CaseData.CLUES[id][0])
  if id == "key" and held_items.has(id):
   held_items[id].hide()
   held_items[id].collision_layer = 0
 update_objective()

func show_terminal() -> void:
 clear_panel("CCTV / ARCHIVE ACCESS", "TERMINAL 03  •  LOCAL BUFFER RECOVERY")
 add_label(panel_content,"Enter the four-digit override from the original access ledger.",22)
 var code = LineEdit.new()
 code.placeholder_text = "Override code"
 code.max_length = 4
 code.custom_minimum_size.y = 50
 panel_content.add_child(code)
 button(panel_content,"RECOVER FOOTAGE",func():
  if code.text == "0311": show_cctv()
  else: sound("wrong"); notify("Invalid override. Review exhibit 06 in the case file.")
 )
 button(panel_content,"RETURN",close_panel)

func show_cctv() -> void:
 clear_panel("CCTV / RECOVERED SEQUENCE", "RECONSTRUCTED SILHOUETTES • NO FACIAL IDENTIFICATION")
 if DisplayServer.get_name() != "headless": sound_players.static.play()
 cctv_time = 0
 cctv_view = Control.new()
 cctv_view.custom_minimum_size = Vector2(880,210)
 panel_content.add_child(cctv_view)
 var bg = ColorRect.new()
 bg.color = Color("15282d")
 bg.size = Vector2(960,210)
 cctv_view.add_child(bg)
 for i in range(6):
  var door = ColorRect.new()
  door.position = Vector2(i*160+20,18)
  door.size = Vector2(65,165)
  door.color = Color("34494c")
  cctv_view.add_child(door)
 cctv_figure = ColorRect.new()
 cctv_figure.color = Color("081317")
 cctv_figure.position = Vector2(100,65)
 cctv_figure.size = Vector2(27,120)
 cctv_view.add_child(cctv_figure)
 for i in range(42):
  var line = ColorRect.new()
  line.position = Vector2(0,i*5)
  line.size = Vector2(960,1)
  line.color = Color(0,0,0,.35)
  line.mouse_filter = Control.MOUSE_FILTER_IGNORE
  cctv_view.add_child(line)
 cctv_label = add_label(panel_content,"",18,CYAN)
 add_label(panel_content,CaseData.CLUES.cctv[1],20)
 button(panel_content,"FILE CCTV EVIDENCE",func(): collect("cctv"); close_panel())

func show_case() -> void:
 clear_panel("CASE FILE / ELLIS WARD", "RECOVERED FACTS • WORKING HYPOTHESES")
 add_label(panel_content,"Evidence %d/8     Connections %d/4     Interviews %d/3     Challenges %d/3" % [evidence.size(),connections.size(),interviewed.size(),challenged.size()],20,GOLD)
 add_label(panel_content,suspicion_text(),20,CYAN)
 var row = HBoxContainer.new()
 panel_content.add_child(row)
 button(row,"EVIDENCE BOARD",show_board)
 button(row,"INTERVIEWS",show_interviews)
 button(row,"FINAL ACCUSATION",show_accusation)
 for id in evidence:
  button(panel_content,CaseData.CLUES[id][0]+"  /  REVIEW",func(): show_inspect(id))
 if evidence.is_empty(): add_label(panel_content,"No exhibits filed. Inspect highlighted objects with E and collect them.",20)
 button(panel_content,"RETURN TO SCENE",close_panel)

func suspicion_text() -> String:
 var a = 30.0 + (12 if evidence.has("phone") else 0) - (14 if challenged.has("Alex") else 0)
 var r = 30.0 + connections.size()*18 + (25 if challenged.has("Ryan") else 0)
 var m = 30.0 - (12 if challenged.has("Maya") else 0)
 var total = a+r+m
 var ap = roundi(a/total*100)
 var rp = roundi(r/total*100)
 return "WORKING SUSPICION   Alex %d%%   /   Ryan %d%%   /   Maya %d%%\nHeuristic case weights, not proof or forensic probabilities." % [ap,rp,100-ap-rp]

func show_board() -> void:
 selection = ""
 clear_panel("EVIDENCE BOARD / CONNECT THE FACTS", "SELECT TWO EXHIBITS TO TEST A CONNECTION")
 add_label(panel_content,"Look for shared times, routes, physical marks, or motive. Supported links remain on the board.",18)
 var graph = Control.new()
 graph.custom_minimum_size = Vector2(880,150)
 graph.draw.connect(func():
  var ids = ["notebook","ledger","phone","footprint","cctv","window","key","blood"]
  var positions = {}
  for i in range(ids.size()): positions[ids[i]] = Vector2(60+(i%4)*220,28+(i/4)*78)
  for link in connections:
   var ends = link.split("|")
   graph.draw_line(positions[ends[0]],positions[ends[1]],Color("44899e"),2,true)
  for id in ids:
   var pos: Vector2 = positions[id]
   graph.draw_circle(pos,6,CYAN if evidence.has(id) else Color("354959"))
   graph.draw_string(ThemeDB.fallback_font,pos+Vector2(12,5),str(id).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,14,CYAN if evidence.has(id) else Color("536776"))
 )
 panel_content.add_child(graph)
 var grid = GridContainer.new()
 grid.columns = 2
 grid.add_theme_constant_override("h_separation",12)
 panel_content.add_child(grid)
 for id in evidence:
  var b = button(grid,CaseData.CLUES[id][0],func(): select_link(id))
  b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 if evidence.size() < 2: add_label(panel_content,"Collect at least two exhibits to connect them.",20)
 for key in connections: add_label(panel_content,"● ───────── ●  "+CaseData.LINKS[key],17,CYAN)
 add_label(panel_content,suspicion_text(),17)
 button(panel_content,"INTERVIEW SUSPECTS",show_interviews)
 button(panel_content,"RETURN TO SCENE",close_panel)

func select_link(id: String) -> void:
 if selection == "": selection = id; notify("Selected "+CaseData.CLUES[id][0]+". Choose another exhibit."); return
 if selection == id: selection = ""; notify("Selection cleared."); return
 var pair = CaseData.pair(selection,id)
 selection = ""
 if CaseData.LINKS.has(pair):
  if not connections.has(pair): connections.append(pair); sound("discover")
  notify("Connection established.")
  show_board()
 else: notify("No direct corroboration. Try matching time, route, boot damage, or audit motive.")
 update_objective()

func show_interviews() -> void:
 clear_panel("SECURE LINE / SUSPECT INTERVIEWS", "ASK FOR AN ACCOUNT, THEN CHALLENGE IT WITH CORROBORATED FACTS")
 for person in ["Alex","Ryan","Maya"]:
  button(panel_content,person.to_upper()+"  /  "+CaseData.PEOPLE[person][0]+("  ✓" if challenged.has(person) else ""),func(): show_person(person))
 add_label(panel_content,"Challenges unlock from connected evidence. All suspects must be heard before you submit a final accusation.",20)
 button(panel_content,"CASE FILE",show_case)
 button(panel_content,"RETURN",close_panel)

func can_challenge(person: String) -> bool:
 match person:
  "Alex": return evidence.has("phone") and connections.has("cctv|footprint")
  "Ryan": return connections.has("ledger|phone") and connections.has("cctv|footprint")
  "Maya": return connections.has("cctv|window")
 return false

func show_person(person: String) -> void:
 if not interviewed.has(person): interviewed.append(person)
 clear_panel("INTERVIEW / "+person.to_upper(),CaseData.PEOPLE[person][0])
 add_label(panel_content,"INITIAL ACCOUNT\n“"+CaseData.PEOPLE[person][1]+"”",22)
 var challenge = button(panel_content,"PRESENT CONTRADICTIONS / CHALLENGE ACCOUNT",func():
  if not challenged.has(person): challenged.append(person)
  show_person(person)
  update_objective()
 )
 challenge.disabled = not can_challenge(person)
 if not can_challenge(person):
  var requirements = {"Alex":"Connect the footprint to CCTV and collect the phone.","Ryan":"Connect phone ↔ ledger and footprint ↔ CCTV.","Maya":"Connect broken window ↔ CCTV."}
  add_label(panel_content,"Required: "+requirements[person],18,GOLD)
 if challenged.has(person):
  add_label(panel_content,"RESPONSE\n“"+CaseData.PEOPLE[person][2]+"”",21)
  add_label(panel_content,"DETECTIVE NOTE / "+CaseData.PEOPLE[person][3],18,CYAN)
 button(panel_content,"OTHER SUSPECTS",show_interviews)
 button(panel_content,"EVIDENCE BOARD",show_board)

func accusation_ready() -> bool:
 return evidence.size() == 8 and connections.size() >= 3 and challenged.size() == 3

func show_accusation() -> void:
 clear_panel("FINAL ACCUSATION / BUILD YOUR CASE", "SELECT A SUSPECT AND EXACTLY THREE EXHIBITS")
 if not accusation_ready():
  add_label(panel_content,"Before submitting: collect all 8 exhibits, establish at least 3 supported links, and challenge all 3 suspects.\n\nCurrent: %d/8 exhibits • %d links • %d/3 challenges." % [evidence.size(),connections.size(),challenged.size()],22)
  button(panel_content,"BACK TO CASE FILE",show_case)
  return
 var suspects = HBoxContainer.new()
 panel_content.add_child(suspects)
 for person in ["Alex","Ryan","Maya"]:
  button(suspects,("● " if accused == person else "○ ")+person,func(): accused = person; show_accusation())
 add_label(panel_content,"Supporting exhibits (%d/3). Focus on identity, physical corroboration, and the agreed meeting." % grounds.size(),18,GOLD)
 var grid = GridContainer.new()
 grid.columns = 2
 panel_content.add_child(grid)
 for id in evidence:
  button(grid,("✓ " if grounds.has(id) else "○ ")+CaseData.CLUES[id][0],func():
   if grounds.has(id): grounds.erase(id)
   elif grounds.size() < 3: grounds.append(id)
   else: notify("Three exhibits selected. Remove one to choose another.")
   show_accusation()
  )
 var submit = button(panel_content,"SUBMIT ACCUSATION",func(): show_ending(is_correct(accused,grounds)))
 submit.disabled = grounds.size() != 3
 button(panel_content,"REVIEW CASE",show_case)

func is_correct(person: String, exhibits: Array[String]) -> bool:
 return person == "Ryan" and exhibits.has("ledger") and exhibits.has("cctv") and (exhibits.has("footprint") or exhibits.has("phone"))

func show_ending(correct: bool) -> void:
 clear_panel("CASE SOLVED" if correct else "WRONG ANSWER / CASE NOT PROVEN", "CASE 031  •  FINAL REVIEW")
 sound("solved" if correct else "wrong")
 if correct:
  add_label(panel_content,"Ryan Vale returned to recover the audit log. His credential records the visit, CCTV corroborates the route, and the damaged boot and messages connect him to the confrontation. His denial fails against independent exhibits.\n\nThe window was staged to suggest an outside intruder. Alex's threat was a distraction; Maya's account was consistent with the recovered timeline.",23)
  add_label(panel_content,"A conclusion is strongest when motive, access, and physical evidence agree.",20,CYAN)
 else:
  add_label(panel_content,"The submitted case does not establish the suspect's identity through independent evidence. A motive alone is insufficient.\n\nReview the original credential record, corroborating footage, and physical or message evidence. You can revise the accusation without losing your investigation.",23)
  button(panel_content,"RECONSIDER ACCUSATION",show_accusation)
 button(panel_content,"RETURN TO CASE FILE",show_case)
 button(panel_content,"NEW INVESTIGATION",func(): get_tree().reload_current_scene())
 button(panel_content,"QUIT",func(): get_tree().quit())

func show_pause() -> void:
 clear_panel("INVESTIGATION PAUSED")
 button(panel_content,"RESUME",close_panel)
 button(panel_content,"CASE FILE",show_case)
 var volume = HSlider.new()
 volume.min_value = -40
 volume.max_value = 0
 volume.value = AudioServer.get_bus_volume_db(0)
 add_label(panel_content,"MASTER AUDIO LEVEL",18)
 panel_content.add_child(volume)
 volume.value_changed.connect(func(value: float): AudioServer.set_bus_volume_db(0,value))
 button(panel_content,"RESTART CASE",func(): get_tree().reload_current_scene())
 button(panel_content,"QUIT",func(): get_tree().quit())

func smoke_test() -> void:
 # Integration checks use the actual state transitions and panels.
 await get_tree().physics_frame
 await get_tree().physics_frame
 var probes = {
  "notebook": [Vector3(2,1.6,-3.2),Vector3(2.05,.98,-4.25)],
  "phone": [Vector3(-1.5,1.6,1.9),Vector3(-1.8,.68,.7)],
  "key": [Vector3(-3,1.6,1.7),Vector3(-4,.96,1.7)],
  "footprint": [Vector3(2.7,1.6,-.5),Vector3(2.85,.05,-1.88)],
  "window": [Vector3(-1.3,1.6,-4.5),Vector3(-1.3,1.6,-6)],
  "blood": [Vector3(2,1.6,-2.5),Vector3(2.6,.046,-3.3)],
  "drawer": [Vector3(3.9,1.6,-2),Vector3(3.8,.64,-3.84)],
  "door": [Vector3(2.4,1.6,3.25),Vector3(3.4,1.35,3.25)],
  "terminal": [Vector3(4.8,1.6,4),Vector3(4.8,1.25,5.12)]
 }
 for id in probes:
  var query = PhysicsRayQueryParameters3D.create(probes[id][0],probes[id][1])
  var result = get_world_3d().direct_space_state.intersect_ray(query)
  assert(not result.is_empty(), "Ray missed " + id)
  assert(result.collider.get_meta("clue_id", "") == id, "Clue obstructed: " + id)
 print("RAY PASS: nine world interaction targets are reachable")
 started = true
 close_panel()
 interact("drawer")
 assert(not drawer_open, "Drawer must require key")
 interact("door")
 assert(not service_open, "Service alcove must require ledger")
 for id in ["notebook","footprint","window","phone","key","blood"]: collect(id)
 interact("drawer")
 assert(drawer_open)
 collect("ledger")
 interact("door")
 assert(service_open)
 show_terminal()
 show_cctv()
 collect("cctv")
 for pair in CaseData.LINKS:
  var ids = pair.split("|")
  select_link(ids[0])
  select_link(ids[1])
 assert(connections.size() == 4)
 for person in CaseData.PEOPLE:
  assert(can_challenge(person))
  show_person(person)
  challenged.append(person)
  show_person(person)
 assert(accusation_ready())
 var valid: Array[String] = ["ledger","cctv","footprint"]
 var invalid: Array[String] = ["phone","key","blood"]
 assert(is_correct("Ryan",valid))
 assert(not is_correct("Alex",valid))
 assert(not is_correct("Ryan",invalid))
 show_case()
 show_accusation()
 show_ending(false)
 show_ending(true)
 print("SMOKE PASS: progression locks, eight clues, four links, interviews, accusation and both endings")
 for audio_player in sound_players.values(): audio_player.stop()
 await get_tree().create_timer(.25).timeout
 await get_tree().process_frame
 await get_tree().process_frame
 get_tree().quit()

func visual_test() -> void:
 await get_tree().create_timer(1.0).timeout
 get_viewport().get_texture().get_image().save_png("res://tests/menu.png")
 started = true
 close_panel()
 player.position = Vector3(.4,.1,3.8)
 camera.rotation.x = -.12
 await get_tree().create_timer(1.0).timeout
 get_viewport().get_texture().get_image().save_png("res://tests/apartment.png")
 show_inspect("notebook")
 await get_tree().create_timer(.5).timeout
 get_viewport().get_texture().get_image().save_png("res://tests/inspect.png")
 for id in CaseData.CLUES: collect(id)
 for pair in CaseData.LINKS: connections.append(pair)
 show_board()
 await get_tree().create_timer(.5).timeout
 get_viewport().get_texture().get_image().save_png("res://tests/board.png")
 get_tree().quit()
