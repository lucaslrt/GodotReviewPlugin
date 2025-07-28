package com.pindorama.inappreviewgodotplugin

import android.app.Activity
import android.util.Log
import android.view.View
import com.google.android.play.core.review.ReviewInfo
import com.google.android.play.core.review.ReviewManager
import com.google.android.play.core.review.ReviewManagerFactory
import com.google.android.play.core.review.testing.FakeReviewManager
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

class InAppReviewPlugin(godot: Godot) : GodotPlugin(godot) {

    companion object {
        private const val TAG = "InAppReview"
        private const val SIGNAL_REVIEW_FLOW_COMPLETED = "review_flow_completed"
        private const val SIGNAL_REVIEW_FLOW_FAILED = "review_flow_failed"
        private const val SIGNAL_REVIEW_INFO_LOADED = "review_info_loaded"
        private const val SIGNAL_REVIEW_INFO_FAILED = "review_info_failed"
    }

    private lateinit var reviewManager: ReviewManager
    private var reviewInfo: ReviewInfo? = null
    private var isDebugMode: Boolean = false

    override fun getPluginName(): String {
        return "InAppReview"
    }

    override fun getPluginSignals(): MutableSet<SignalInfo> {
        val signals = mutableSetOf<SignalInfo>()

        signals.add(SignalInfo(SIGNAL_REVIEW_FLOW_COMPLETED, Boolean::class.javaObjectType))
        signals.add(SignalInfo(SIGNAL_REVIEW_FLOW_FAILED, String::class.java))
        signals.add(SignalInfo(SIGNAL_REVIEW_INFO_LOADED))
        signals.add(SignalInfo(SIGNAL_REVIEW_INFO_FAILED, String::class.java))

        return signals
    }

    override fun onMainCreate(activity: Activity?): View? {
        Log.d(TAG, "InAppReview plugin initialized")

        // Detecta se está em modo debug baseado no BuildConfig ou package name
        isDebugMode = activity?.let { act ->
            try {
                val packageInfo = act.packageManager.getPackageInfo(act.packageName, 0)
                val appName = packageInfo.applicationInfo?.loadLabel(act.packageManager).toString()
                val isDebuggable = (packageInfo.applicationInfo?.flags?.and(android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE)) != 0
                Log.d(TAG, "App name: $appName, Is debuggable: $isDebuggable")
                isDebuggable
            } catch (e: Exception) {
                Log.e(TAG, "Error checking debug mode", e)
                false
            }
        } ?: false

        // Inicializa o ReviewManager apropriado
        activity?.let{
            reviewManager = if (isDebugMode) {
                Log.d(TAG, "Using FakeReviewManager for debug mode")
                ReviewManagerFactory.create(activity)/*FakeReviewManager(activity)*/
            } else {
                Log.d(TAG, "Using real ReviewManager for release mode")
                ReviewManagerFactory.create(activity)
            }
        }

        return null // Plugin não precisa retornar uma View
    }

    @UsedByGodot
    fun initializeReview() {
        Log.d(TAG, "initializeReview called")

        val activity = godot.getActivity()
        if (activity == null) {
            Log.e(TAG, "Activity is null")
            emitSignal(SIGNAL_REVIEW_INFO_FAILED, "Activity not available")
            return
        }

        Log.d(TAG, "Requesting review info...")
        val request = reviewManager.requestReviewFlow()

        request.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                reviewInfo = task.result
                Log.d(TAG, "Review info loaded successfully")
                emitSignal(SIGNAL_REVIEW_INFO_LOADED)
            } else {
                val exception = task.exception
                val errorMessage = exception?.message ?: "Unknown error"
                Log.e(TAG, "Failed to load review info: $errorMessage", exception)
                emitSignal(SIGNAL_REVIEW_INFO_FAILED, errorMessage)
            }
        }
    }

    @UsedByGodot
    fun launchReviewFlow() {
        Log.d(TAG, "launchReviewFlow called")

        val activity = godot.getActivity()
        if (activity == null) {
            Log.e(TAG, "Activity is null")
            emitSignal(SIGNAL_REVIEW_FLOW_FAILED, "Activity not available")
            return
        }

        val currentReviewInfo = reviewInfo
        if (currentReviewInfo == null) {
            Log.e(TAG, "ReviewInfo is null. Call initializeReview first")
            emitSignal(SIGNAL_REVIEW_FLOW_FAILED, "ReviewInfo not loaded. Call initialize_review first")
            return
        }

        Log.d(TAG, "Launching review flow...")
        val flow = reviewManager.launchReviewFlow(activity, currentReviewInfo)

        flow.addOnCompleteListener { task ->
            if (task.isSuccessful) {
                Log.d(TAG, "Review flow completed successfully")
                emitSignal(SIGNAL_REVIEW_FLOW_COMPLETED, java.lang.Boolean.valueOf(true))
            } else {
                val exception = task.exception
                val errorMessage = exception?.message ?: "Unknown error"
                Log.e(TAG, "Review flow failed: $errorMessage", exception)
                emitSignal(SIGNAL_REVIEW_FLOW_FAILED, errorMessage)
            }

            // Limpa o reviewInfo para forçar nova inicialização na próxima vez
            reviewInfo = null
        }
    }

    @UsedByGodot
    fun isReviewInfoLoaded(): Boolean {
        val loaded = reviewInfo != null
        Log.d(TAG, "isReviewInfoLoaded: $loaded")
        return loaded
    }

    @UsedByGodot
    fun isDebugMode(): Boolean {
        Log.d(TAG, "isDebugMode: $isDebugMode")
        return isDebugMode
    }

    @UsedByGodot
    fun showReview() {
        Log.d(TAG, "showReview called - this is a convenience method")

        if (isReviewInfoLoaded()) {
            Log.d(TAG, "ReviewInfo already loaded, launching flow directly")
            launchReviewFlow()
        } else {
            Log.d(TAG, "ReviewInfo not loaded, initializing first")
            initializeReview()

            // Aguarda um pouco e tenta lançar o flow
            godot.runOnUiThread {
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    if (isReviewInfoLoaded()) {
                        Log.d(TAG, "ReviewInfo loaded after initialization, launching flow")
                        launchReviewFlow()
                    } else {
                        Log.w(TAG, "ReviewInfo still not loaded after initialization")
                        emitSignal(SIGNAL_REVIEW_FLOW_FAILED, "Failed to initialize review info")
                    }
                }, 1000)
            }
        }
    }

    @UsedByGodot
    fun getPluginVersion(): String {
        return "1.0.0"
    }

    @UsedByGodot
    fun logDebug(message: String) {
        Log.d(TAG, "GDScript: $message")
    }
}