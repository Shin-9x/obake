class_name CompendiumScreen
extends Control
## One page per kind of entry: balls, omamori, pegs and bosses. Entries never seen show as
## silhouettes with "???"; locked ones also tell the feat that unlocks them.

signal closed

enum Page { BALLS, OMAMORI, PEGS, BOSSES }

const PAGE_KEYS: Array[String] = [
	"COMPENDIUM_BALLS", "COMPENDIUM_OMAMORI", "COMPENDIUM_PEGS", "COMPENDIUM_BOSSES"
]
const RARITY_KEYS: Array[String] = [
	"RARITY_BASE", "RARITY_COMMON", "RARITY_UNCOMMON", "RARITY_RARE", "RARITY_LEGENDARY"
]
const ENTRY_SIZE: Vector2 = Vector2(36, 36)
const ICON_MARGIN: float = 4.0
const COLUMNS: int = 10
const SILHOUETTE: Color = Color(0, 0, 0, 1)

var _content: RunContent
var _profile: Profile
var _feats: Dictionary[StringName, FeatDefinition] = {}
var _body: VBoxContainer
var _grid: GridContainer
var _detail: VBoxContainer
var _page: Page = Page.BALLS


func open(content: RunContent, progression: ProgressionDefinition, profile: Profile) -> void:
	_content = content
	_profile = profile
	_feats.clear()
	for feat: FeatDefinition in progression.feats:
		_feats[feat.unlocks.id] = feat
	UiKit.clear(self)
	var page: Control = UiKit.page(self)
	_body = UiKit.body(page, 10)
	_show_page(Page.BALLS)


## Entries of the page on show, in order.
func entries() -> Array[ItemDefinition]:
	var items: Array[ItemDefinition] = []
	match _page:
		Page.BALLS:
			for character: CharacterDefinition in _content.characters:
				for ball: BallDefinition in character.starting_balls:
					if ball.rarity == ItemDefinition.Rarity.BASE and not items.has(ball):
						items.append(ball)
			items.append_array(_content.balls)
		Page.OMAMORI:
			items.append_array(_content.omamori)
		Page.PEGS:
			items.append_array(_content.pegs)
		Page.BOSSES:
			items.append_array(_content.floor_bosses)
	return items


func is_discovered(item: ItemDefinition) -> bool:
	return _profile.discovered.has(item.id)


func _show_page(page: Page) -> void:
	_page = page
	UiKit.clear(_body)
	_body.add_child(UiKit.label("COMPENDIUM_TITLE", UiKit.TITLE_SIZE))
	var tabs: HBoxContainer = UiKit.row(6)
	tabs.alignment = BoxContainer.ALIGNMENT_BEGIN
	for index: int in PAGE_KEYS.size():
		var tab: Button = UiKit.button(PAGE_KEYS[index])
		tab.disabled = index == page
		tab.pressed.connect(_show_page.bind(index))
		tabs.add_child(tab)
	var back: Button = UiKit.button("BUTTON_BACK", true, AudioService.UI_BACK)
	back.pressed.connect(closed.emit)
	tabs.add_child(back)
	_body.add_child(tabs)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	for item: ItemDefinition in entries():
		_grid.add_child(_entry(item))
	_body.add_child(_grid)
	_detail = UiKit.column(2)
	_body.add_child(_detail)


func _entry(item: ItemDefinition) -> Button:
	var entry: Button = Button.new()
	entry.custom_minimum_size = ENTRY_SIZE
	entry.focus_mode = Control.FOCUS_NONE
	var picture: TextureRect = UiKit.icon(_picture(item), Vector2.ZERO)
	picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	picture.offset_left = ICON_MARGIN
	picture.offset_top = ICON_MARGIN
	picture.offset_right = -ICON_MARGIN
	picture.offset_bottom = -ICON_MARGIN
	if not is_discovered(item):
		picture.modulate = SILHOUETTE
	entry.add_child(picture)
	entry.pressed.connect(_show_detail.bind(item))
	return entry


func _show_detail(item: ItemDefinition) -> void:
	UiKit.clear(_detail)
	var width: float = UiKit.PAGE_SIZE.x - 32
	if is_discovered(item):
		var title: String = "%s · %s" % [tr(item.name_key), tr(RARITY_KEYS[item.rarity])]
		var colour: Color = UiKit.RARITY_COLOURS.get(item.rarity, UiKit.TEXT)
		_detail.add_child(UiKit.label(title, 0, colour, false))
		_detail.add_child(UiKit.paragraph(tr(item.description_key), width))
	else:
		_detail.add_child(UiKit.label("COMPENDIUM_UNKNOWN"))
	var feat: FeatDefinition = _feats.get(item.id)
	if feat != null and not _profile.has_feat(feat.id):
		var hint: String = tr("COMPENDIUM_LOCKED") % tr(feat.description_key)
		_detail.add_child(UiKit.paragraph(hint, width))


static func _picture(item: ItemDefinition) -> Texture2D:
	if item is BossDefinition:
		return (item as BossDefinition).portrait
	if item is BallDefinition and (item as BallDefinition).texture != null:
		return (item as BallDefinition).texture
	if item is PegDefinition and (item as PegDefinition).texture != null:
		return (item as PegDefinition).texture
	return item.icon
