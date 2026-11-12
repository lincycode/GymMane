package com.gymmane.app

/** Retention must only consider files owned by this backup mode/device. */
internal object BackupNames {
    private val prefixPattern = Regex("^gymmane-auto-(?:[a-z]+-)?$")
    private val stampPattern = Regex("^\\d{4}-\\d{2}-\\d{2}-\\d{6}\\.zip$")

    fun belongsTo(name: String, prefix: String): Boolean =
        prefixPattern.matches(prefix) && name.startsWith(prefix) &&
            stampPattern.matches(name.removePrefix(prefix))
}
