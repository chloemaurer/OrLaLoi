extends Control

@onready var empty_manches = [
$MancheUnVide, $MancheDeuxVide, $MancheTroisVide, $MancheQuatreVide, $MancheCinqVide, 
$MancheSixVide, $MancheSeptVide, $MancheHuitVide, $MancheNeufVide, $MancheDixVide
]

@onready var reset_manches = [
	 preload("uid://0fw4810f5hgt"),
	 preload("uid://cxi4w0adl10gf"),
	 preload("uid://d1tok5ke3hiyx"),
	 preload("uid://btchig2cm0ebn"),
	 preload("uid://4oe5jxv11730"),
	 preload("uid://dujpup0gg3wv8"),
	 preload("uid://ct623muwomadu"),
	 preload("uid://x0g50ubywhb2"),
	 preload("uid://bujo73mhqjlue"),
	 preload("uid://bmh4qx47anx7t"),
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
			# On remplit les wagons acquis
			if i < fill_manches.size():
				empty_manches[i].texture = fill_manches[i]
		else:
			# TRÈS IMPORTANT : On remet la texture vide ici !
			# C'est cette partie qui réinitialise visuellement les wagons
			if i < reset_manches.size():
				empty_manches[i].texture = reset_manches[i]

func reset_all_wagons():
	for i in range(empty_manches.size()):
		empty_manches[i].texture = reset_manches[i]
