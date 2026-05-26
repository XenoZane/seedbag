extends Node

var do_repeat_sound: bool = true

func _ready() -> void:
	pass
	#if OS.has_feature("wasm"):
		#do_repeat_sound = false

func sfx_plant_rose() -> void:
	play_sfx($SFX_PlantRose)

func sfx_plant_sunny() -> void:
	play_sfx($SFX_PlantSunny)

func sfx_plant_lavender() -> void:
	play_sfx($SFX_PlantLavender)

func sfx_plant_glory() -> void:
	play_sfx($SFX_PlantGlory)

func sfx_remove_flower() -> void:
	play_sfx($SFX_RemoveFlower)

func sfx_hover_button() -> void:
	play_sfx($SFX_HoverButton)

func sfx_click_button_neutral() -> void:
	play_sfx($SFX_ClickButtonNeutral)

func sfx_click_button_positive() -> void:
	play_sfx($SFX_ClickButtonPositive)

func sfx_click_button_negative() -> void:
	play_sfx($SFX_ClickButtonNegative)

func sfx_check_puzzle_correct() -> void:
	play_sfx($SFX_CheckPuzzleCorrect)

func sfx_check_puzzle_wrong() -> void:
	play_sfx($SFX_CheckPuzzleWrong)

func sfx_dialog_advance() -> void:
	play_sfx($SFX_DialogAdvance)

func sfx_switch_tool() -> void:
	play_sfx($SFX_SwitchTool)

func sfx_try_plant_fail() -> void:
	play_sfx($SFX_TryPlantFail)

func sfx_reset() -> void:
	play_sfx($SFX_Reset)

func play_sfx(sfx_node: AudioStreamPlayer) -> void:
	if do_repeat_sound or !sfx_node.playing:
		sfx_node.play()

var slider_last_update_time: int = 0
var slider_timeout_msec: int = 200

func maybe_play_slider_update_sound() -> void:
	if Time.get_ticks_msec() > slider_last_update_time + slider_timeout_msec:
		$SliderUpdated.play()
		slider_last_update_time = Time.get_ticks_msec()
