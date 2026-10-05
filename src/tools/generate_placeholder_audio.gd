extends SceneTree
## Generates the placeholder sound effects under assets/sfx/ and the music loops under
## assets/music/, by simple additive synthesis. Run with `make placeholder-audio`; the output is
## committed, so this only runs when it changes. Noise comes from the project's PCG32, so the
## files are the same on every run.

const RATE: int = 22050
const SFX_DIR: String = "res://assets/sfx"
const MUSIC_DIR: String = "res://assets/music"
const SFX_PEAK: float = 0.8
const MUSIC_PEAK: float = 0.6
## Yo pentatonic on D, from D3 up two octaves, in hertz.
const SCALE: Array[float] = [
	146.83, 164.81, 196.0, 220.0, 246.94, 293.66, 329.63, 392.0, 440.0, 493.88, 587.33
]

var _noise: Pcg32 = Pcg32.new(7, 0)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SFX_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MUSIC_DIR))
	_save(_bell(880.0, 0.35), "peg_hit")
	_save(_thud(), "wall_bounce")
	_save(_arpeggio([1046.5, 1318.5, 1568.0], 0.05, 0.45), "bucket")
	_save(_glide(330.0, 0.5, 0.28, "triangle"), "ball_lost")
	_save(_arpeggio([1318.5, 1760.0], 0.06, 0.18, "square"), "mon")
	_save(_glide(600.0, 2.0, 0.2, "sine", 0.5), "mult")
	_save(_sparkle(), "times")
	_save(_explosion(), "explosion")
	_save(_crackle(), "fire")
	_save(_glide(500.0, 1.8, 0.09, "sine"), "split")
	_save(_whoosh(0.16, true), "launch")
	_save(_arpeggio([1046.5, 1318.5], 0.0, 0.4), "shot_scored")
	_save(_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.1, 0.9), "board_won")
	_save(_matsuri(), "matsuri")
	_save(_arpeggio([392.0, 311.13, 261.63], 0.22, 1.0, "triangle"), "board_lost")
	_save(_swell(), "power")
	_save(_taiko(0.35), "boss_hit")
	_save(_whoosh(0.22, false), "vanish")
	_save(_glide(1200.0, 1.0, 0.03, "sine"), "ui_click")
	_save(_arpeggio([660.0, 990.0], 0.06, 0.16), "ui_confirm")
	_save(_arpeggio([660.0, 440.0], 0.06, 0.16), "ui_back")
	_save(_arpeggio([1318.5, 1760.0, 2093.0], 0.05, 0.3, "square"), "purchase")
	_save(_arpeggio([783.99, 987.77, 1174.66, 1567.98, 1975.53], 0.07, 0.8), "unlock")
	_save(_menu_loop(), "menu_loop", MUSIC_DIR, MUSIC_PEAK)
	_save(_board_loop(), "board_loop", MUSIC_DIR, MUSIC_PEAK)
	quit()


## A bell: a fundamental with two inharmonic partials, decaying fast.
func _bell(frequency: float, seconds: float) -> PackedFloat32Array:
	var buffer: PackedFloat32Array = _buffer(seconds)
	_tone(buffer, 0.0, frequency, seconds, 1.0, "sine", 9.0)
	_tone(buffer, 0.0, frequency * 2.0, seconds, 0.35, "sine", 12.0)
	_tone(buffer, 0.0, frequency * 2.76, seconds, 0.2, "sine", 16.0)
	return buffer


func _thud() -> PackedFloat32Array:
	var buffer: PackedFloat32Array = _buffer(0.1)
	_tone(buffer, 0.0, 150.0, 0.1, 1.0, "sine", 30.0, 0.002, 0.6)
	_noise_burst(buffer, 0.0, 0.04, 0.3, 60.0, 0.3)
	return buffer


## Notes of [param frequencies] one after another, [param step] seconds apart.
func _arpeggio(
	frequencies: Array[float], step: float, seconds: float, shape: String = "sine"
) -> PackedFloat32Array:
	var buffer: PackedFloat32Array = _buffer(seconds + step * frequencies.size())
	for index: int in frequencies.size():
		_tone(buffer, step * index, frequencies[index], seconds, 0.6, shape, 6.0)
		_tone(buffer, step * index, frequencies[index] * 2.0, seconds, 0.15, "sine", 10.0)
	return buffer


## One note gliding to [param ratio] times its frequency.
func _glide(
	frequency: float, ratio: float, seconds: float, shape: String, shimmer: float = 0.0
) -> PackedFloat32Array:
	var buffer: PackedFloat32Array = _buffer(seconds)
	_tone(buffer, 0.0, frequency, seconds, 1.0, shape, 4.0 / seconds, 0.003, ratio)
	if shimmer > 0.0:
		_tone(buffer, 0.0, frequency * 3.0, seconds, shimmer, "sine", 6.0 / seconds, 0.01, ratio)
	return buffer


func _sparkle() -> PackedFloat32Array:
	var buffer: PackedFloat32Array = _buffer(0.4)
	for index: int in 3:
		var frequency: float = [880.0, 1320.0, 1760.0][index]
		_tone(buffer, 0.02 * index, frequency, 0.35, 0.5, "sine", 7.0, 0.004, 1.5)
	return buffer


func _explosion() -> PackedFloat32Array:
	var buffer: PackedFloat32Array = _buffer(0.45)
	_noise_burst(buffer, 0.0, 0.45, 1.0, 8.0, 0.15)
	_tone(buffer, 0.0, 70.0, 0.4, 0.8, "sine", 8.0, 0.002, 0.5)
	return buffer


func _crackle() -> PackedFloat32Array:
	var buffer: PackedFloat32Array = _buffer(0.35)
	for pop: int in 9:
		var start: float = _noise.next_below(300) / 1000.0
		_noise_burst(buffer, start, 0.02, 0.6, 120.0, 0.8)
	_noise_burst(buffer, 0.0, 0.35, 0.15, 6.0, 0.1)
	return buffer


## Filtered noise swelling up, or fading down.
func _whoosh(seconds: float, rising: bool) -> PackedFloat32Array:
	var buffer: PackedFloat32Array = _buffer(seconds)
	var smooth: float = 0.0
	for index: int in buffer.size():
		var progress: float = float(index) / buffer.size()
		var shape: float = progress if rising else 1.0 - progress
		smooth += (_white() - smooth) * (0.05 + 0.25 * shape)
		buffer[index] += smooth * sin(PI * progress) * 0.8
	return buffer


func _matsuri() -> PackedFloat32Array:
	var buffer: PackedFloat32Array = _buffer(1.4)
	for index: int in 8:
		_tone(buffer, 0.08 * index, SCALE[3 + index % 8] * 2.0, 0.5, 0.45, "sine", 6.0)
	_add_taiko(buffer, 0.0, 0.8)
	_add_taiko(buffer, 0.32, 0.6)
	_add_taiko(buffer, 0.64, 1.0)
	return buffer


func _swell() -> PackedFloat32Array:
	var buffer: PackedFloat32Array = _buffer(0.6)
	for index: int in buffer.size():
		var t: float = float(index) / RATE
		var envelope: float = sin(PI * t / 0.6)
		var vibrato: float = sin(TAU * 6.0 * t) * 8.0
		buffer[index] += sin(TAU * (520.0 + 300.0 * t + vibrato) * t) * envelope * 0.5
		buffer[index] += sin(TAU * (780.0 + 450.0 * t) * t) * envelope * 0.25
	return buffer


func _taiko(seconds: float) -> PackedFloat32Array:
	var buffer: PackedFloat32Array = _buffer(seconds)
	_add_taiko(buffer, 0.0, 1.0)
	return buffer


func _add_taiko(buffer: PackedFloat32Array, start: float, volume: float) -> void:
	_tone(buffer, start, 95.0, 0.35, volume, "sine", 10.0, 0.002, 0.7)
	_noise_burst(buffer, start, 0.03, volume * 0.4, 80.0, 0.4)


## A calm loop: plucked notes over a drone, eight bars at 72 beats per minute.
func _menu_loop() -> PackedFloat32Array:
	var beat: float = 60.0 / 72.0
	var buffer: PackedFloat32Array = _buffer(32 * beat)
	_drone(buffer, SCALE[0] / 2.0, 0.25)
	_drone(buffer, SCALE[3] / 2.0, 0.12)
	var note: int = 5
	for step: int in 32:
		if step % 4 == 3:
			continue
		note = clampi(note + _noise.next_below(5) - 2, 3, SCALE.size() - 1)
		_pluck(buffer, step * beat, SCALE[note], 0.5, 0.45)
	return buffer


## A festival loop: plucks in eighths, bass, taiko and shaker, eight bars at 112 per minute.
func _board_loop() -> PackedFloat32Array:
	var beat: float = 60.0 / 112.0
	var buffer: PackedFloat32Array = _buffer(32 * beat)
	var note: int = 6
	for step: int in 64:
		var start: float = step * beat / 2.0
		if step % 8 != 7:
			note = clampi(note + _noise.next_below(5) - 2, 4, SCALE.size() - 1)
			_pluck(buffer, start, SCALE[note], 0.3, 0.35)
		if step % 2 == 1:
			_noise_burst(buffer, start, 0.03, 0.12, 90.0, 0.9)
	for bar: int in 8:
		var root: float = SCALE[0] / 2.0 if bar % 2 == 0 else SCALE[2] / 2.0
		for hit: int in 4:
			_pluck(buffer, (bar * 4 + hit) * beat, root if hit % 2 == 0 else root * 1.5, 0.4, 0.4)
		_add_taiko(buffer, bar * 4 * beat, 0.7)
		_add_taiko(buffer, (bar * 4 + 2) * beat, 0.5)
	return buffer


func _pluck(
	buffer: PackedFloat32Array, start: float, frequency: float, seconds: float, volume: float
) -> void:
	_tone(buffer, start, frequency, seconds, volume, "sine", 7.0, 0.003)
	_tone(buffer, start, frequency * 2.0, seconds, volume * 0.3, "sine", 12.0, 0.003)


## A steady tone across the whole loop, tuned to a whole number of cycles so the loop is seamless.
func _drone(buffer: PackedFloat32Array, frequency: float, volume: float) -> void:
	var seconds: float = float(buffer.size()) / RATE
	var cycles: float = roundf(frequency * seconds)
	for index: int in buffer.size():
		var phase: float = float(index) / buffer.size()
		buffer[index] += sin(TAU * cycles * phase) * volume * (0.8 + 0.2 * sin(TAU * 2.0 * phase))


## Adds a note; samples past the end wrap to the start, so loops ring across their seam.
func _tone(
	buffer: PackedFloat32Array,
	start: float,
	frequency: float,
	seconds: float,
	volume: float,
	shape: String,
	decay: float,
	attack: float = 0.004,
	glide: float = 1.0
) -> void:
	var first: int = int(start * RATE)
	var count: int = int(seconds * RATE)
	var phase: float = 0.0
	for index: int in count:
		var t: float = float(index) / RATE
		var current: float = frequency * pow(glide, t / seconds)
		phase += current / RATE
		var envelope: float = minf(1.0, t / attack) * exp(-decay * t)
		buffer[(first + index) % buffer.size()] += _wave(shape, phase) * envelope * volume


func _noise_burst(
	buffer: PackedFloat32Array,
	start: float,
	seconds: float,
	volume: float,
	decay: float,
	brightness: float
) -> void:
	var first: int = int(start * RATE)
	var smooth: float = 0.0
	for index: int in int(seconds * RATE):
		var t: float = float(index) / RATE
		smooth += (_white() - smooth) * brightness
		buffer[(first + index) % buffer.size()] += smooth * exp(-decay * t) * volume


func _wave(shape: String, phase: float) -> float:
	var cycle: float = phase - floorf(phase)
	match shape:
		"square":
			return 0.6 if cycle < 0.5 else -0.6
		"triangle":
			return 4.0 * absf(cycle - 0.5) - 1.0
	return sin(TAU * cycle)


## Uniform noise in [-1, 1).
func _white() -> float:
	return _noise.next_below(65536) / 32768.0 - 1.0


func _buffer(seconds: float) -> PackedFloat32Array:
	var buffer: PackedFloat32Array = PackedFloat32Array()
	buffer.resize(int(seconds * RATE))
	return buffer


## Normalises to [param peak] and writes 16-bit mono PCM.
func _save(
	buffer: PackedFloat32Array, file_name: String, folder: String = SFX_DIR, peak: float = SFX_PEAK
) -> void:
	var loudest: float = 0.0
	for sample: float in buffer:
		loudest = maxf(loudest, absf(sample))
	var gain: float = peak / loudest if loudest > 0.0 else 1.0
	var data: PackedByteArray = PackedByteArray()
	data.resize(buffer.size() * 2)
	for index: int in buffer.size():
		data.encode_s16(index * 2, clampi(roundi(buffer[index] * gain * 32767.0), -32768, 32767))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	var path: String = folder.path_join(file_name + ".wav")
	var error: Error = stream.save_to_wav(ProjectSettings.globalize_path(path))
	print("%s: %s (%.2f s)" % [path, error_string(error), float(buffer.size()) / RATE])
