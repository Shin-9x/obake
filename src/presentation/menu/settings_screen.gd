class_name SettingsScreen
extends Control
## Every setting on one page. Changes apply at once; sliders are saved when the player leaves.

signal closed

const LABEL_WIDTH: float = 200.0
const CONTROL_WIDTH: float = 200.0
const LANGUAGE_KEYS: Array[String] = ["LANGUAGE_SYSTEM", "LANGUAGE_EN", "LANGUAGE_IT"]
const SCALING_KEYS: Array[String] = ["SCALING_INTEGER", "SCALING_FRACTIONAL"]

var _body: VBoxContainer


func open() -> void:
	UiKit.clear(self)
	var page: Control = UiKit.page(self)
	_body = UiKit.body(page, 12)
	var values: GameSettings = Settings.values
	_body.add_child(UiKit.label("SETTINGS_TITLE", UiKit.TITLE_SIZE))
	_slider("SETTINGS_MASTER", values.master_volume, _set_master)
	_slider("SETTINGS_MUSIC", values.music_volume, _set_music)
	_slider("SETTINGS_SFX", values.sfx_volume, _set_sfx)
	_options(
		"SETTINGS_LANGUAGE",
		LANGUAGE_KEYS,
		GameSettings.LANGUAGES.find(values.language),
		_set_language
	)
	_options("SETTINGS_SCALING", SCALING_KEYS, values.scaling, _set_scaling)
	if Settings.is_desktop():
		_toggle("SETTINGS_FULLSCREEN", values.fullscreen, _set_fullscreen)
	_toggle("SETTINGS_SHAKE", values.screen_shake, _set_shake)
	var speeds: Array[String] = []
	for speed: int in GameSettings.FAST_FORWARD_SPEEDS:
		speeds.append(tr("SETTINGS_SPEED") % speed)
	_options(
		"SETTINGS_FAST_FORWARD",
		speeds,
		GameSettings.FAST_FORWARD_SPEEDS.find(values.fast_forward_speed),
		_set_fast_forward
	)
	if DisplayServer.is_touchscreen_available():
		_slider(
			"SETTINGS_DRAG",
			values.drag_sensitivity,
			_set_drag,
			GameSettings.MIN_DRAG_SENSITIVITY,
			GameSettings.MAX_DRAG_SENSITIVITY
		)
		_toggle("SETTINGS_VIBRATION", values.vibration, _set_vibration)
	var back: Button = UiKit.button("BUTTON_BACK", true, AudioService.UI_BACK)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(_close)
	_body.add_child(back)


func back() -> void:
	_close()


func _row(key: String, control: Control) -> void:
	var row: HBoxContainer = UiKit.row(8)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	var label: Label = UiKit.label(key)
	label.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	row.add_child(label)
	control.custom_minimum_size = Vector2(CONTROL_WIDTH, 0)
	row.add_child(control)
	_body.add_child(row)


func _slider(
	key: String, value: int, setter: Callable, low: int = 0, high: int = GameSettings.MAX_VOLUME
) -> void:
	var slider: HSlider = HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = 5
	slider.value = value
	slider.value_changed.connect(func(changed: float) -> void: setter.call(int(changed)))
	_row(key, slider)


func _options(key: String, labels: Array[String], selected: int, setter: Callable) -> void:
	var options: OptionButton = OptionButton.new()
	for label: String in labels:
		options.add_item(label)
	options.selected = maxi(0, selected)
	options.item_selected.connect(setter)
	_row(key, options)


func _toggle(key: String, value: bool, setter: Callable) -> void:
	var toggle: CheckButton = CheckButton.new()
	toggle.button_pressed = value
	toggle.toggled.connect(setter)
	_row(key, toggle)


func _set_master(value: int) -> void:
	Settings.values.master_volume = value
	Settings.apply()


func _set_music(value: int) -> void:
	Settings.values.music_volume = value
	Settings.apply()


func _set_sfx(value: int) -> void:
	Settings.values.sfx_volume = value
	Settings.apply()
	AudioService.play(AudioService.UI_CLICK)


func _set_drag(value: int) -> void:
	Settings.values.drag_sensitivity = value


func _set_language(index: int) -> void:
	Settings.values.language = GameSettings.LANGUAGES[index]
	Settings.commit()
	open()


func _set_scaling(index: int) -> void:
	Settings.values.scaling = index as GameSettings.Scaling
	Settings.commit()


func _set_fullscreen(on: bool) -> void:
	Settings.values.fullscreen = on
	Settings.commit()


func _set_shake(on: bool) -> void:
	Settings.values.screen_shake = on
	Settings.commit()


func _set_fast_forward(index: int) -> void:
	Settings.values.fast_forward_speed = GameSettings.FAST_FORWARD_SPEEDS[index]
	Settings.commit()


func _set_vibration(on: bool) -> void:
	Settings.values.vibration = on
	Settings.commit()


func _close() -> void:
	Settings.commit()
	closed.emit()
