package com.gymmane.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class BackupNamesTest {
    @Test
    fun ordinaryRetentionLeavesOtherDevicesAndUnrecognizedFilesAlone() {
        val names = listOf(
            "gymmane-auto-server-2026-11-11-120000.zip",
            "gymmane-auto-phone-2026-11-11-120000.zip",
            "gymmane-auto-2026-11-11-120000.zip",
            "gymmane-auto-2026-11-12-120000.zip",
            "gymmane-auto-2026-11-10-120000 (1).zip",
        )
        val deleted = names.filter { BackupNames.belongsTo(it, "gymmane-auto-") }.sortedDescending().drop(1)
        assertEquals(listOf("gymmane-auto-2026-11-11-120000.zip"), deleted)
        assertEquals(listOf(names[1]), names.filter { BackupNames.belongsTo(it, "gymmane-auto-phone-") })
        assertFalse(BackupNames.belongsTo(names[0], ""))
        assertFalse(BackupNames.belongsTo(names[0], "gymmane-auto-ser"))
    }
}
