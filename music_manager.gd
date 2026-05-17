extends Node

func sfx_plant_rose() -> void:
	$SFX_PlantRose.play()

func sfx_plant_sunny() -> void:
	$SFX_PlantSunny.play()

func sfx_plant_lavender() -> void:
	$SFX_PlantLavender.play()

func sfx_plant_glory() -> void:
	$SFX_PlantGlory.play()

func sfx_remove_flower() -> void:
	$SFX_RemoveFlower.play()

func sfx_hover_button() -> void:
	$SFX_HoverButton.play()

func sfx_click_button_neutral() -> void:
	$SFX_ClickButtonNeutral.play()

func sfx_click_button_positive() -> void:
	$SFX_ClickButtonPositive.play()

func sfx_click_button_negative() -> void:
	$SFX_ClickButtonNegative.play()

func sfx_check_puzzle_correct() -> void:
	$SFX_CheckPuzzleCorrect.play()

func sfx_check_puzzle_wrong() -> void:
	$SFX_CheckPuzzleWrong.play()

func sfx_dialog_advance() -> void:
	$SFX_DialogAdvance.play()

func sfx_switch_tool() -> void:
	$SFX_SwitchTool.play()

func sfx_try_plant_fail() -> void:
	$SFX_TryPlantFail.play()

func sfx_reset() -> void:
	$SFX_Reset.play()


var slider_last_update_time: int = 0
var slider_timeout_msec: int = 200

func maybe_play_slider_update_sound() -> void:
	if Time.get_ticks_msec() > slider_last_update_time + slider_timeout_msec:
		$SliderUpdated.play()
		slider_last_update_time = Time.get_ticks_msec()
