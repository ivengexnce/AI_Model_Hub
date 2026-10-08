package com.example.helloworld.ui.login

/**
 * Authentication result: success or error message.
 */
data class LoginResult(
    val success: Boolean = false,
    val error: Int? = null
)
