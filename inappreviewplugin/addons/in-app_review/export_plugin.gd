@tool
extends EditorExportPlugin

const PLUGIN_NAME = "InAppReview"
const PLUGIN_PATH = "res://addons/in-app_review/"

func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform is EditorExportPlatformAndroid

func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
	if debug:
		return PackedStringArray([PLUGIN_PATH + "bin/app-debug.aar"])
	else:
		return PackedStringArray([PLUGIN_PATH + "bin/app-release.aar"])

func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
	return PackedStringArray([
		"com.google.android.play:review:2.0.1",
		"com.google.android.play:review-ktx:2.0.1"
	])

# Adicione este método para incluir explicitamente o plugin
func _get_android_manifest_application_element_contents(platform: EditorExportPlatform, debug: bool) -> String:
	return """
		<meta-data
			android:name="org.godotengine.plugin.v1.InAppReview"
			android:value="com.pindorama.inappreviewgodotplugin.InAppReviewPlugin" />
	"""

func _get_name() -> String:
	return PLUGIN_NAME
