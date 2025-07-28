@tool
extends EditorPlugin

# In-App Review Plugin - Editor Script
# Gerencia a habilitação/desabilitação do plugin no editor
# Autor: Lucas Rufino

const PLUGIN_NAME = "In-App Review"
const AUTOLOAD_NAME = "InAppReview"
const AUTOLOAD_PATH = "res://addons/in-app_review/in-app_review.gd"

func _enter_tree() -> void:
	print("[InApp Review Plugin] Inicializando plugin no editor...")
	
	# Adiciona o export plugin
	var export_plugin = preload("export_plugin.gd").new()
	add_export_plugin(export_plugin)
	
	# Adiciona o autoload automaticamente
	if not ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		print("[InApp Review Plugin] Adicionando autoload: " + AUTOLOAD_NAME)
		add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)
	else:
		print("[InApp Review Plugin] Autoload já existe: " + AUTOLOAD_NAME)
	
	# Configura os plugins Android se não estiverem configurados
	_configure_android_plugins()
	
	print("[InApp Review Plugin] Plugin habilitado com sucesso!")

func _exit_tree() -> void:
	print("[InApp Review Plugin] Removendo plugin do editor...")
	
	# Remove o autoload
	if ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		print("[InApp Review Plugin] Removendo autoload: " + AUTOLOAD_NAME)
		remove_autoload_singleton(AUTOLOAD_NAME)
	
	print("[InApp Review Plugin] Plugin desabilitado!")

func _configure_android_plugins() -> void:
	print("[InApp Review Plugin] Configurando plugins Android...")
	
	# Configura os caminhos dos AARs
	var debug_aar = "res://addons/in-app_review/bin/app-debug.aar"
	var release_aar = "res://addons/in-app_review/bin/app-release.aar"
	
	# Verifica se os AARs existem
	if not FileAccess.file_exists(debug_aar):
		print("[InApp Review Plugin] AVISO: AAR debug não encontrado: " + debug_aar)
	else:
		print("[InApp Review Plugin] AAR debug encontrado: " + debug_aar)
	
	if not FileAccess.file_exists(release_aar):
		print("[InApp Review Plugin] AVISO: AAR release não encontrado: " + release_aar)
	else:
		print("[InApp Review Plugin] AAR release encontrado: " + release_aar)
	
	# Configura o gradle build automaticamente
	_configure_gradle_settings()

func _configure_gradle_settings() -> void:
	print("[InApp Review Plugin] Configurando Gradle build...")
	
	# Configurações necessárias para o plugin funcionar
	var settings = {
		"android/gradle_build/use_gradle_build": true,
		"android/gradle_build/min_sdk": 24,
		"android/gradle_build/target_sdk": 35,
		"android/gradle_build/export_format": 1  # AAB format
	}
	
	var changed = false
	for setting in settings:
		if not ProjectSettings.has_setting(setting) or ProjectSettings.get_setting(setting) != settings[setting]:
			print("[InApp Review Plugin] Configurando: " + setting + " = " + str(settings[setting]))
			ProjectSettings.set_setting(setting, settings[setting])
			changed = true
	
	if changed:
		var error = ProjectSettings.save()
		if error == OK:
			print("[InApp Review Plugin] Configurações do projeto salvas com sucesso")
		else:
			print("[InApp Review Plugin] ERRO ao salvar configurações: " + str(error))

func get_plugin_name() -> String:
	return PLUGIN_NAME
