# Exemplo de uso do Plugin InApp Review
# Adicione este código em qualquer script do seu jogo

extends Control

func _ready():
	# Conecta os sinais do plugin (que é autoload)
	InAppReview.plugin_ready.connect(_on_plugin_ready)
	InAppReview.review_flow_completed.connect(_on_review_completed)
	InAppReview.review_flow_failed.connect(_on_review_failed)
	InAppReview.review_info_loaded.connect(_on_review_info_loaded)
	InAppReview.review_info_failed.connect(_on_review_info_failed)
	
	print("Aguardando plugin estar pronto...")

func _on_plugin_ready():
	print("Plugin InApp Review está pronto!")
	
	# Imprime informações de debug
	InAppReview.print_debug_info()
	
	# Exemplo: Mostrar review após 5 segundos (para teste)
	await get_tree().create_timer(5.0).timeout
	show_review_example()

func show_review_example():
	print("Tentando mostrar review...")
	
	# Método 1: Usar o método de conveniência (recomendado para a maioria dos casos)
	InAppReview.show_review()
	
	# Método 2: Processo manual (maior controle)
	# InAppReview.initialize_review()
	# await InAppReview.review_info_loaded
	# InAppReview.launch_review_flow()

func _on_review_completed(success: bool):
	print("Review completado! Sucesso: ", success)
	# Aqui você pode implementar lógica como salvar que o usuário já fez review
	
func _on_review_failed(error_message: String):
	print("Review falhou: ", error_message)
	# Aqui você pode implementar tratamento de erro ou retry

func _on_review_info_loaded():
	print("Review info carregado com sucesso")
	
func _on_review_info_failed(error_message: String):
	print("Falha ao carregar review info: ", error_message)

# Exemplo de botão para mostrar review
func _on_review_button_pressed():
	if not InAppReview.is_plugin_ready():
		print("Plugin ainda não está pronto")
		return
		
	if InAppReview.is_debug_mode():
		print("Executando em modo debug - usando FakeReviewManager")
	else:
		print("Executando em modo release - usando ReviewManager real")
	
	InAppReview.show_review()


func _on_button_pressed() -> void:
	show_review_example()
	pass # Replace with function body.
