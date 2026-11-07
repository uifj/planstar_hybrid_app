package com.qidian.demo.presentation.login

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.qidian.demo.R
import com.qidian.demo.core.ui.applyInsetsPadding
import com.qidian.demo.core.ui.applyStatusBarScrim
import com.qidian.demo.core.ui.enableEdgeToEdge
import com.qidian.demo.data.local.MMKVStore
import com.qidian.demo.databinding.ActivityLoginBinding
import com.qidian.demo.di.ServiceLocator
import com.qidian.demo.presentation.flutter.BaseFlutterContainer
import com.qidian.demo.presentation.main.MainActivity
import kotlinx.coroutines.launch

/**
 * 登录页。
 *
 * 分层：presentation 只调用 LoginUseCase，网络鉴权 / 本地回退 / MMKV 持久化都在 data 层完成。
 */
class LoginActivity : AppCompatActivity() {

    private lateinit var binding: ActivityLoginBinding
    private val loginUseCase = ServiceLocator.loginUseCase

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 沉浸式 + 状态栏红色底（白图标），导航栏透明（深色图标）
        enableEdgeToEdge(lightStatusBar = false, lightNavBar = true)
        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // 安全区：顶部避让状态栏/刘海，底部避让导航栏与软键盘
        binding.loginScroll.applyInsetsPadding(top = true, bottom = true, horizontal = true, ime = true)
        binding.statusBarScrim.applyStatusBarScrim()

        // 已登录则直接进入主界面（对应原项目"记住登录状态"）
        if (MMKVStore.token.isNotEmpty()) {
            enterMain()
            return
        }

        binding.btnLogin.setOnClickListener { doLogin() }
        binding.etPassword.setOnEditorActionListener { _, _, _ ->
            doLogin()
            true
        }
    }

    private fun doLogin() {
        val username = binding.etUsername.text?.toString()?.trim().orEmpty()
        val password = binding.etPassword.text?.toString().orEmpty()
        if (username.isEmpty() || password.isEmpty()) {
            Toast.makeText(this, getString(R.string.login_error_empty), Toast.LENGTH_SHORT).show()
            return
        }
        binding.btnLogin.isEnabled = false
        binding.btnLogin.text = getString(R.string.login_loading)

        lifecycleScope.launch {
            loginUseCase(username, password)
                .onSuccess {
                    // 登录态变化后主动推给已存在的 Flutter 引擎（未就绪的会入队补发），
                    // 避免 Flutter 页面靠 onResume 轮询/刷新来同步状态。
                    BaseFlutterContainer.notifyLoginStateChanged()
                    enterMain()
                }
                .onFailure { e ->
                    Toast.makeText(
                        this@LoginActivity,
                        e.message ?: "登录失败",
                        Toast.LENGTH_SHORT,
                    ).show()
                    binding.btnLogin.isEnabled = true
                    binding.btnLogin.text = getString(R.string.login_button)
                }
        }
    }

    /**
     * 从桌面启动：登录成功后进入主界面；
     * 从"我的"页调起（非任务根）：直接回退，由主界面刷新登录态，避免重复创建 MainActivity。
     */
    private fun enterMain() {
        if (isTaskRoot) {
            startActivity(Intent(this, MainActivity::class.java))
        }
        finish()
    }
}
