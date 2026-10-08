package com.example.helloworld

import com.example.helloworld.ui.login.LoginViewModel
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LoginViewModelTest {

    private val viewModel = LoginViewModel()

    @Test
    fun emailValidation_isValidForCorrectFormat() {
        val email = "user@example.com"
        assertTrue(viewModel.isEmailValid(email))
    }

    @Test
    fun emailValidation_isInvalidForMalformedEmail() {
        val email = "invalid-email"
        assertFalse(viewModel.isEmailValid(email))
    }

    @Test
    fun emailValidation_isInvalidForEmptyEmail() {
        assertFalse(viewModel.isEmailValid(""))
    }

    @Test
    fun passwordValidation_isValidForMinLength() {
        val password = "password123"
        assertTrue(viewModel.isPasswordValid(password))
    }

    @Test
    fun passwordValidation_isInvalidForShortPassword() {
        val password = "123"
        assertFalse(viewModel.isPasswordValid(password))
    }
}
