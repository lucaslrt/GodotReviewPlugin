extends Node

# InApp Review Plugin - Autoload Script
# Gerencia a biblioteca Google Play In-App Review no Godot
# Autor: Lucas Rufino
# Versão: 1.0.0

# Sinais para comunicação com o jogo
signal review_flow_completed(success: bool)
signal review_flow_failed(error_message: String)
signal review_info_loaded()
signal review_info_failed(error_message: String)
signal plugin_ready()

# Constantes
const PLUGIN_NAME = "InAppReview"
const PLUGIN_VERSION = "1.0.0"
const LOG_PREFIX = "[InAppReview] "

# Variáveis de controle
var _plugin_instance = null
var _is_android: bool = false
var _is_debug_mode: bool = false
var _is_plugin_ready: bool = false
var _is_review_info_loaded: bool = false
var _initialization_attempts: int = 0
var _max_initialization_attempts: int = 3

# Configurações de log
var _enable_verbose_logging: bool = true
var _log_to_file: bool = false

func _ready() -> void:
	_log_info("=== InApp Review Plugin Iniciando ===")
	_log_info("Versão: " + PLUGIN_VERSION)
	
	# Detecta se está rodando no Android
	_is_android = OS.get_name() == "Android"
	_log_info("Plataforma detectada: " + OS.get_name() + " (Android: " + str(_is_android) + ")")
	
	if not _is_android:
		_log_warning("Plugin funciona apenas no Android. Simulando comportamento para desenvolvimento.")
		_simulate_desktop_behavior()
		return
	
	# Detecta modo debug
	_detect_debug_mode()
	
	# Inicializa o plugin
	_initialize_plugin()

func _detect_debug_mode() -> void:
	_log_info("Detectando modo de execução...")
	
	# Verifica se está em debug através de várias formas
	_is_debug_mode = OS.is_debug_build()
	
	_log_info("Modo Debug detectado: " + str(_is_debug_mode))
	_log_info("Build Type: " + ("Debug" if _is_debug_mode else "Release"))

func _initialize_plugin() -> void:
	_log_info("Inicializando plugin Android...")
	
	if not _is_android:
		_log_error("Tentando inicializar plugin em plataforma não-Android")
		return
	
	# Carrega o .aar apropriado baseado no modo
	var aar_name = "app-debug.aar" if _is_debug_mode else "app-release.aar"
	_log_info("Carregando AAR: " + aar_name)
	
	# Obtém a instância do plugin
	if Engine.has_singleton(PLUGIN_NAME):
		_plugin_instance = Engine.get_singleton(PLUGIN_NAME)
		_log_info("Plugin singleton encontrado: " + PLUGIN_NAME)
		
		# Conecta os sinais do plugin Android
		_connect_android_signals()
		
		# Verifica se o plugin está em modo debug
		_verify_plugin_debug_mode()
		
		_is_plugin_ready = true
		_log_success("Plugin inicializado com sucesso!")
		plugin_ready.emit()
		
	else:
		_log_error("Plugin singleton não encontrado: " + PLUGIN_NAME)
		_log_error("Verifique se o .aar está corretamente configurado no projeto")
		_retry_initialization()

func _connect_android_signals() -> void:
	_log_info("Conectando sinais do plugin Android...")
	
	if not _plugin_instance:
		_log_error("Instância do plugin não disponível para conectar sinais")
		return
	
	# Conecta os sinais (usando o sistema de sinais do Godot 4.x)
	if not _plugin_instance.is_connected("review_flow_completed", _on_review_flow_completed):
		_plugin_instance.connect("review_flow_completed", _on_review_flow_completed)
		_log_debug("Sinal 'review_flow_completed' conectado")
	
	if not _plugin_instance.is_connected("review_flow_failed", _on_review_flow_failed):
		_plugin_instance.connect("review_flow_failed", _on_review_flow_failed)
		_log_debug("Sinal 'review_flow_failed' conectado")
	
	if not _plugin_instance.is_connected("review_info_loaded", _on_review_info_loaded):
		_plugin_instance.connect("review_info_loaded", _on_review_info_loaded)
		_log_debug("Sinal 'review_info_loaded' conectado")
	
	if not _plugin_instance.is_connected("review_info_failed", _on_review_info_failed):
		_plugin_instance.connect("review_info_failed", _on_review_info_failed)
		_log_debug("Sinal 'review_info_failed' conectado")
	
	_log_success("Todos os sinais conectados com sucesso")

func _verify_plugin_debug_mode() -> void:
	if not _plugin_instance:
		return
	
	# Verifica se o plugin está no modo correto
	var plugin_debug_mode = _plugin_instance.call("isDebugMode")
	var plugin_debug_bool = bool(plugin_debug_mode)  # Converter para booleano
	
	_log_info("Plugin Debug Mode: " + str(plugin_debug_bool))
	_log_info("GDScript Debug Mode: " + str(_is_debug_mode))
	
	if plugin_debug_bool != _is_debug_mode:
		_log_warning("Discrepância entre modos debug detectada!")
		_log_warning("Recomenda-se verificar se o .aar correto está sendo usado")

func _retry_initialization() -> void:
	_initialization_attempts += 1
	_log_warning("Tentativa de inicialização " + str(_initialization_attempts) + "/" + str(_max_initialization_attempts))
	
	if _initialization_attempts < _max_initialization_attempts:
		_log_info("Reagendando inicialização em 1 segundo...")
		await get_tree().create_timer(1.0).timeout
		_initialize_plugin()
	else:
		_log_error("Falha na inicialização após " + str(_max_initialization_attempts) + " tentativas")
		_simulate_desktop_behavior()

func _simulate_desktop_behavior() -> void:
	_log_info("Simulando comportamento do plugin para desenvolvimento")
	_is_plugin_ready = true
	plugin_ready.emit()

# === MÉTODOS PÚBLICOS DA API ===

## Inicializa o sistema de review (carrega ReviewInfo)
func initialize_review() -> void:
	_log_info("=== Inicializando Review ===")
	
	if not _is_plugin_ready:
		_log_error("Plugin não está pronto. Aguarde o sinal 'plugin_ready'")
		review_info_failed.emit("Plugin não inicializado")
		return
	
	if not _is_android:
		_log_info("Simulando inicialização do review (modo desktop)")
		await get_tree().create_timer(0.5).timeout
		_is_review_info_loaded = true
		review_info_loaded.emit()
		return
	
	if not _plugin_instance:
		_log_error("Instância do plugin não disponível")
		review_info_failed.emit("Plugin não disponível")
		return
	
	_log_info("Chamando initializeReview() no plugin Android...")
	_plugin_instance.call("logDebug", "GDScript chamou initializeReview()")
	_plugin_instance.call("initializeReview")

## Mostra o diálogo de review (precisa chamar initialize_review() primeiro)
func launch_review_flow() -> void:
	_log_info("=== Lançando Review Flow ===")
	
	if not _is_plugin_ready:
		_log_error("Plugin não está pronto")
		review_flow_failed.emit("Plugin não inicializado")
		return
	
	if not _is_review_info_loaded:
		_log_error("ReviewInfo não foi carregado. Chame initialize_review() primeiro")
		review_flow_failed.emit("ReviewInfo não carregado")
		return
	
	if not _is_android:
		_log_info("Simulando launch review flow (modo desktop)")
		await get_tree().create_timer(1.0).timeout
		review_flow_completed.emit(true)
		return
	
	if not _plugin_instance:
		_log_error("Instância do plugin não disponível")
		review_flow_failed.emit("Plugin não disponível")
		return
	
	_log_info("Chamando launchReviewFlow() no plugin Android...")
	_plugin_instance.call("logDebug", "GDScript chamou launchReviewFlow()")
	_plugin_instance.call("launchReviewFlow")

## Método de conveniência que inicializa e mostra o review automaticamente
func show_review() -> void:
	_log_info("=== Mostrando Review (método de conveniência) ===")
	
	if not _is_plugin_ready:
		_log_error("Plugin não está pronto")
		review_flow_failed.emit("Plugin não inicializado")
		return
	
	if not _is_android:
		_log_info("Simulando show review completo (modo desktop)")
		await get_tree().create_timer(1.5).timeout
		review_flow_completed.emit(true)
		return
	
	if not _plugin_instance:
		_log_error("Instância do plugin não disponível")
		review_flow_failed.emit("Plugin não disponível")
		return
	
	_log_info("Chamando showReview() no plugin Android...")
	_plugin_instance.call("logDebug", "GDScript chamou showReview()")
	_plugin_instance.call("showReview")

# === MÉTODOS DE VERIFICAÇÃO ===

## Verifica se o plugin está pronto para uso
func is_plugin_ready() -> bool:
	return _is_plugin_ready

## Verifica se as informações de review foram carregadas
func is_review_info_loaded() -> bool:
	if not _is_android:
		return _is_review_info_loaded
	
	if not _plugin_instance:
		return false
	
	return _plugin_instance.call("isReviewInfoLoaded")

## Verifica se está em modo debug
func is_debug_mode() -> bool:
	return _is_debug_mode

## Obtém a versão do plugin
func get_plugin_version() -> String:
	return PLUGIN_VERSION

## Verifica se a plataforma é Android
func is_android_platform() -> bool:
	return _is_android

# === CALLBACKS DOS SINAIS ANDROID ===

func _on_review_flow_completed(success: bool) -> void:
	_log_success("Review flow completado com sucesso: " + str(success))
	review_flow_completed.emit(success)

func _on_review_flow_failed(error_message: String) -> void:
	_log_error("Review flow falhou: " + error_message)
	review_flow_failed.emit(error_message)

func _on_review_info_loaded() -> void:
	_log_success("Review info carregado com sucesso")
	_is_review_info_loaded = true
	review_info_loaded.emit()

func _on_review_info_failed(error_message: String) -> void:
	_log_error("Falha ao carregar review info: " + error_message)
	_is_review_info_loaded = false
	review_info_failed.emit(error_message)

# === SISTEMA DE LOGGING ===

func _log_info(message: String) -> void:
	var full_message = LOG_PREFIX + "[INFO] " + message
	print(full_message)
	
	if _plugin_instance and _is_android:
		_plugin_instance.call("logDebug", "[GDScript-INFO] " + message)

func _log_success(message: String) -> void:
	var full_message = LOG_PREFIX + "[SUCCESS] " + message
	print(full_message)
	
	if _plugin_instance and _is_android:
		_plugin_instance.call("logDebug", "[GDScript-SUCCESS] " + message)

func _log_warning(message: String) -> void:
	var full_message = LOG_PREFIX + "[WARNING] " + message
	print_rich("[color=yellow]" + full_message + "[/color]")
	
	if _plugin_instance and _is_android:
		_plugin_instance.call("logDebug", "[GDScript-WARNING] " + message)

func _log_error(message: String) -> void:
	var full_message = LOG_PREFIX + "[ERROR] " + message
	print_rich("[color=red]" + full_message + "[/color]")
	
	if _plugin_instance and _is_android:
		_plugin_instance.call("logDebug", "[GDScript-ERROR] " + message)

func _log_debug(message: String) -> void:
	if not _enable_verbose_logging:
		return
	
	var full_message = LOG_PREFIX + "[DEBUG] " + message
	print(full_message)
	
	if _plugin_instance and _is_android:
		_plugin_instance.call("logDebug", "[GDScript-DEBUG] " + message)

# === MÉTODOS DE CONFIGURAÇÃO ===

## Habilita/desabilita logs verbosos
func set_verbose_logging(enabled: bool) -> void:
	_enable_verbose_logging = enabled
	_log_info("Logging verboso: " + ("Habilitado" if enabled else "Desabilitado"))

## Obtém informações de debug do sistema
func get_debug_info() -> Dictionary:
	var info = {
		"plugin_version": PLUGIN_VERSION,
		"is_android": _is_android,
		"is_debug_mode": _is_debug_mode,
		"is_plugin_ready": _is_plugin_ready,
		"is_review_info_loaded": _is_review_info_loaded,
		"initialization_attempts": _initialization_attempts,
		"platform": OS.get_name(),
		"godot_version": Engine.get_version_info()
	}
	
	if _plugin_instance and _is_android:
		info["android_plugin_debug_mode"] = _plugin_instance.call("isDebugMode")
		info["android_plugin_version"] = _plugin_instance.call("getPluginVersion")
	
	return info

## Imprime informações de debug
func print_debug_info() -> void:
	_log_info("=== INFORMAÇÕES DE DEBUG ===")
	var info = get_debug_info()
	for key in info.keys():
		_log_info(str(key) + ": " + str(info[key]))
	_log_info("============================")
