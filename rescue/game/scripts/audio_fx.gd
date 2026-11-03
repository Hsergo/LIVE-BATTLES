extends Node
## Sons originaux synthetises, aucune ressource sonore tierce.
## Garde le jeu utilisable sans peripherique audio.
const RATE := 22050
var player: AudioStreamPlayer
var clips: Dictionary = {}
var sound_on := true

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.name = "SoundPlayer"
	add_child(player)
	player.volume_db = -9.0
	clips["build"] = _tone(430, 620, 0.19, 0.36, false)
	clips["repair"] = _tone(390, 540, 0.23, 0.36, false)
	clips["rescue"] = _tone(520, 940, 0.42, 0.36, false)
	clips["success"] = _tone(650, 1150, 0.52, 0.40, false)
	clips["gift"] = _tone(710, 1350, 0.48, 0.33, false)
	clips["power"] = _tone(310, 780, 0.64, 0.46, false)
	clips["danger"] = _tone(150, 82, 0.74, 0.35, true)
	clips["join"] = _tone(410, 580, 0.24, 0.32, false)

func _tone(from_hz: float, to_hz: float, duration: float, volume: float, rumble: bool) -> AudioStreamWAV:
	var count := int(ceil(duration * float(RATE)))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	for index in range(count):
		var t := float(index) / float(RATE)
		var p := t / duration
		var freq := lerpf(from_hz, to_hz, p)
		phase += TAU * freq / float(RATE)
		var fade := pow(1.0 - p, 1.8) * minf(1.0, t * 60.0)
		var waveform := sin(phase) * 0.78 + sin(phase * (1.5 if rumble else 2.0)) * 0.22
		var value := int(clampf(waveform * fade * volume, -1.0, 1.0) * 32000.0)
		bytes[index * 2] = value & 255
		bytes[index * 2 + 1] = (value >> 8) & 255
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = RATE
	clip.stereo = false
	clip.data = bytes
	return clip

func play_effect(kind: String) -> void:
	if sound_on and clips.has(kind) and player != null:
		player.stop()
		player.stream = clips[kind]
		player.play()

func toggle_sound() -> bool:
	sound_on = not sound_on
	if not sound_on and player != null:
		player.stop()
	return sound_on
