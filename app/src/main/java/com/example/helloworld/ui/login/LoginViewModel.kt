package com.example.helloworld.ui.login

import android.util.Patterns
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.helloworld.R
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class LoginViewModel : ViewModel() {

    private val _loginFormState = MutableLiveData<LoginFormState>()
    val loginFormState: LiveData<LoginFormState> = _loginFormState

    private val _loginResult = MutableLiveData<LoginResult>()
    val loginResult: LiveData<LoginResult> = _loginResult

    private val _isLoading = MutableLiveData<Boolean>(false)
    val isLoading: LiveData<Boolean> = _isLoading

    fun loginDataChanged(username: String, password: String) {
        if (!isEmailValid(username)) {
            _loginFormState.value = LoginFormState(emailError = R.string.invalid_email)
        } else if (!isPasswordValid(password)) {
            _loginFormState.value = LoginFormState(passwordError = R.string.invalid_password)
        } else {
            _loginFormState.value = LoginFormState(isDataValid = true)
        }
    }

    fun login(email: String, password: String) {
        _isLoading.value = true
        viewModelScope.launch {
            // Simulate network authentication request delay
            delay(1200)
            _isLoading.value = false
            if (isEmailValid(email) && isPasswordValid(password)) {
                _loginResult.value = LoginResult(success = true)
            } else {
                _loginResult.value = LoginResult(error = R.string.login_failed)
            }
        }
    }

    companion object {
        private val EMAIL_REGEX = Regex("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")
    }

    fun isEmailValid(email: String): Boolean {
        if (email.isBlank()) return false
        return try {
            Patterns.EMAIL_ADDRESS?.matcher(email)?.matches() ?: EMAIL_REGEX.matches(email)
        } catch (_: Exception) {
            EMAIL_REGEX.matches(email)
        }
    }

    fun isPasswordValid(password: String): Boolean {
        return password.length >= 6
    }
}
