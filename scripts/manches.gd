extends Control

@onready var empty_manches = [
$MancheUnVide, $MancheDeuxVide, $MancheTroisVide, $MancheQuatreVide, $MancheCinqVide, 
$MancheSixVide, $MancheSeptVide, $MancheHuitVide, $MancheNeufVide, $MancheDixVide
]

@onready var fill_manches = [
preload("uid://eu77wppshotv"),
preload("uid://dup5x38jho7t6"),
preload("uid://dn52d3tfcxhsq"),
preload("uid://d24bekjlqj123"),
preload("uid://bqlm8wq16k08k"),
preload("uid://dc476m4r8noyd"),
preload("uid://dm2qmeydhmey7"),
preload("uid://btl2i2x4etvqv"),
preload("uid://bepnrld44r5uy"),
preload("uid://b8vrupdagj82x")
]


func fill_wagon():
	var actual_manche = DatabaseConfig.manches
	for i in range(empty_manches.size()):
		if i < actual_manche:
			if i < fill_manches.size():
				empty_manches[i].texture = fill_manches[i]
		else:
			# Optionnel : remettre la texture vide si la manche redémarre
			# empty_manches[i].texture = preload("ton_image_vide.png")
			pass
