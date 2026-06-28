extends AudioStreamPlayer2D

const MUSIC_1 = preload("uid://c487py1l576k3")
const MUSIC_2 = preload("uid://djj7shos1jp22")
const MUSIC_3 = preload("uid://bd0ug4vi8spah")
const MUSIC_4 = preload("uid://kmuk14kibi3r")
const MUSIC_5 = preload("res://Assets/Music and SFX/melody alteration - inspo- snowdin town.mp3")
const GAME_OVER_MUSIC = preload("uid://6tmbx7idvxa3")

var last_track : int


var music_dict := {
	1 : MUSIC_1,
	2 : MUSIC_2,
	3 : MUSIC_3,
	4 : MUSIC_4,
	5 : MUSIC_5
}

func _ready() -> void:
	var rand_track = randi_range(1, 2)
	while rand_track == last_track:
		rand_track = randi_range(1, 2)
	start_rand_track(rand_track)
	
	$"../Main".connect("game_over", start_game_over_track)


func _on_finished() -> void:
	await get_tree().create_timer(3.0).timeout
	var rand_track = randi_range(1, 5)
	while rand_track == last_track:
		rand_track = randi_range(1, 5)
	start_rand_track(rand_track)


func start_rand_track(rand_track):
	
	self.stream = music_dict[rand_track]
	play()
	last_track = rand_track


func start_game_over_track():
	stop()
	await get_tree().create_timer(0.3).timeout
	self.stream = GAME_OVER_MUSIC
	play()
