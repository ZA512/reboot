package com.za512.reboot

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import org.json.JSONObject
import java.nio.charset.StandardCharsets
import java.security.KeyStore
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

internal data class WeeklyWidgetState(
    val displayAmount: String,
    val validBeforeDate: String,
)

/** Encrypted, app-private cache containing no transaction or account details. */
internal object WeeklyWidgetStateStore {
    private const val preferencesName = "reboot_weekly_widget_v1"
    private const val encryptedStateKey = "encrypted_state"
    private const val initializationVectorKey = "initialization_vector"
    private const val keyAlias = "reboot_weekly_widget_state_v1"
    private const val cipherTransformation = "AES/GCM/NoPadding"
    private val additionalData =
        "REBOOT weekly widget state v1".toByteArray(StandardCharsets.UTF_8)

    fun write(context: Context, state: WeeklyWidgetState) {
        require(state.displayAmount.isNotBlank() && state.displayAmount.length <= 32)
        require(isValidIsoDate(state.validBeforeDate))
        val plaintext =
            JSONObject()
                .put("displayAmount", state.displayAmount)
                .put("validBeforeDate", state.validBeforeDate)
                .toString()
                .toByteArray(StandardCharsets.UTF_8)
        val cipher = Cipher.getInstance(cipherTransformation)
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateKey())
        cipher.updateAAD(additionalData)
        val encrypted = cipher.doFinal(plaintext)
        val saved =
            context
                .getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
                .edit()
                .putString(encryptedStateKey, Base64.encodeToString(encrypted, Base64.NO_WRAP))
                .putString(
                    initializationVectorKey,
                    Base64.encodeToString(cipher.iv, Base64.NO_WRAP),
                ).commit()
        check(saved) { "The encrypted widget state could not be committed." }
    }

    fun read(context: Context): WeeklyWidgetState? {
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val encryptedValue = preferences.getString(encryptedStateKey, null) ?: return null
        val initializationVector =
            preferences.getString(initializationVectorKey, null) ?: return null
        return try {
            val cipher = Cipher.getInstance(cipherTransformation)
            cipher.init(
                Cipher.DECRYPT_MODE,
                getOrCreateKey(),
                GCMParameterSpec(128, Base64.decode(initializationVector, Base64.NO_WRAP)),
            )
            cipher.updateAAD(additionalData)
            val plaintext =
                cipher.doFinal(Base64.decode(encryptedValue, Base64.NO_WRAP))
                    .toString(StandardCharsets.UTF_8)
            val json = JSONObject(plaintext)
            val state =
                WeeklyWidgetState(
                    displayAmount = json.getString("displayAmount"),
                    validBeforeDate = json.getString("validBeforeDate"),
                )
            if (
                state.displayAmount.isBlank() ||
                    state.displayAmount.length > 32 ||
                    !isValidIsoDate(state.validBeforeDate)
            ) {
                clear(context)
                null
            } else {
                state
            }
        } catch (_: Exception) {
            clear(context)
            null
        }
    }

    fun clear(context: Context) {
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE).edit().clear().apply()
    }

    fun isStale(state: WeeklyWidgetState): Boolean = todayIsoDate() >= state.validBeforeDate

    fun isValidIsoDate(value: String?): Boolean {
        if (value == null || !Regex("\\d{4}-\\d{2}-\\d{2}").matches(value)) return false
        return runCatching {
            isoDateFormatter().parse(value)?.let { isoDateFormatter().format(it) == value } == true
        }.getOrDefault(false)
    }

    private fun todayIsoDate(): String = isoDateFormatter().format(Date())

    private fun isoDateFormatter() =
        SimpleDateFormat("yyyy-MM-dd", Locale.ROOT).apply { isLenient = false }

    @Synchronized
    private fun getOrCreateKey(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (keyStore.getKey(keyAlias, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                keyAlias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            ).setKeySize(256)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true)
                .build(),
        )
        return generator.generateKey()
    }
}
