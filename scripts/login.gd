extends Control
 
func _ready() -> void:
	Firebase.Auth.login_succeeded.connect(on_login_succeeded)
	Firebase.Auth.signup_succeeded.connect(on_signup_succeeded)
	Firebase.Auth.login_failed.connect(on_login_failed)
	Firebase.Auth.signup_failed.connect(on_signup_failed)
	if Firebase.Auth.check_auth_file():
		%Label.text = "Logged in"
		#get_tree().change_scene_to_file("res://Scenes/principal.tscn")
	
 
func on_login_succeeded(auth):
	print(auth)
	%Label.text = "Login success!"
	Firebase.Auth.save_auth(auth)
 
func on_signup_succeeded(auth):
	print(auth)
	%Label.text = "Sign up success!"
	Firebase.Auth.save_auth(auth)
	get_tree().change_scene_to_file("res://Scenes/principal.tscn")
 
func on_login_failed(error_code, message):
	print(error_code)
	print(message)
	%Label.text = "Login failed. Error: %s" % message

func on_signup_failed(error_code, message): 
	print(error_code)
	print(message)
	%Label.text = "Sign up failed. Error: %s" % message
 
func _on_google_button_pressed() -> void:
	var provider: AuthProvider = Firebase.Auth.get_GoogleProvider()
	Firebase.Auth.get_auth_localhost(provider, 8060)
