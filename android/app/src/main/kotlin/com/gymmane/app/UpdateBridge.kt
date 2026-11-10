package com.gymmane.app

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

object UpdateBridge {
    const val CHANNEL = "enogym/updates"
    private const val APPLICATION_ID = "com.echolin.gymmane"

    @Suppress("DEPRECATION")
    private fun version(info: PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()

    @Suppress("DEPRECATION")
    private fun signers(info: PackageInfo): Set<String> =
        (if (Build.VERSION.SDK_INT >= 28) info.signingInfo?.apkContentsSigners else info.signatures)
            ?.map { it.toCharsString() }?.toSet() ?: emptySet()

    @Suppress("DEPRECATION")
    private fun signatureFlags(): Int =
        if (Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES

    private fun cache(activity: Activity) = File(activity.cacheDir, "enogym-updates")

    @Suppress("DEPRECATION")
    fun attach(activity: Activity, channel: MethodChannel) {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "info" -> {
                    val info = activity.packageManager.getPackageInfo(activity.packageName, 0)
                    result.success(mapOf(
                        "packageName" to activity.packageName,
                        "versionCode" to version(info),
                        "sdk" to Build.VERSION.SDK_INT,
                        "abis" to Build.SUPPORTED_ABIS.toList(),
                        "cachePath" to cache(activity).absolutePath,
                    ))
                }
                "verify", "install" -> {
                    val name = call.argument<String>("fileName") ?: ""
                    val hash = call.argument<String>("sha256") ?: ""
                    val code = call.argument<Number>("versionCode")?.toLong() ?: 0
                    val versionName = call.argument<String>("versionName") ?: ""
                    val size = call.argument<Number>("size")?.toLong() ?: 0
                    if (!Regex("[0-9a-f]{64}").matches(hash) || name != "$hash.apk" || size <= 0 || code <= 0) {
                        result.error("integrity", null, null)
                        return@setMethodCallHandler
                    }
                    val file = File(cache(activity), name)
                    Thread {
                        val error = try {
                            validate(activity, file, hash, code, versionName, size)
                        } catch (_: Exception) {
                            "integrity"
                        }
                        activity.runOnUiThread {
                            if (error != null) {
                                file.delete()
                                result.error(error, null, null)
                            } else if (call.method == "verify") {
                                result.success(null)
                            } else if (activity.isFinishing || activity.isDestroyed || !activity.hasWindowFocus()) {
                                result.error("foreground", null, null)
                            } else {
                                try {
                                    if (Build.VERSION.SDK_INT >= 26 && !activity.packageManager.canRequestPackageInstalls()) {
                                        activity.startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                            Uri.parse("package:${activity.packageName}")))
                                        result.success("permission")
                                    } else {
                                        val uri = FileProvider.getUriForFile(activity,
                                            "${activity.packageName}.updates", file)
                                        activity.startActivity(Intent(Intent.ACTION_VIEW)
                                            .setDataAndType(uri, "application/vnd.android.package-archive")
                                            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
                                        result.success("opened")
                                    }
                                } catch (_: Exception) {
                                    result.error("installer", null, null)
                                }
                            }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun validate(activity: Activity, file: File, hash: String, code: Long, versionName: String, size: Long): String? {
        if (activity.packageName != APPLICATION_ID) return "unsupported"
        if (!file.isFile || file.length() != size) return "integrity"
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().buffered().use { input ->
            val buffer = ByteArray(65536)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                digest.update(buffer, 0, count)
            }
        }
        if (digest.digest().joinToString("") { "%02x".format(it) } != hash) return "integrity"
        val manager = activity.packageManager
        val current = manager.getPackageInfo(activity.packageName, signatureFlags())
        val incoming = manager.getPackageArchiveInfo(file.absolutePath, signatureFlags()) ?: return "integrity"
        if (incoming.packageName != APPLICATION_ID || signers(current).isEmpty() || signers(current) != signers(incoming)) return "signature"
        if (version(incoming) != code || incoming.versionName != versionName || code <= version(current)) return "version"
        if ((incoming.applicationInfo?.minSdkVersion ?: Int.MAX_VALUE) > Build.VERSION.SDK_INT) return "incompatible"
        return null
    }
}
