import UIKit

/// 登录页（对应 Android `LoginActivity`）。
///
/// 分层：presentation 只调用 `LoginUseCase`，网络鉴权 / 本地回退 / 本地存储都在 data 层完成。
/// 登录成功后主动向 Flutter 推送登录态（`userLoginStatus`），避免 Flutter 页面轮询刷新。
@MainActor
final class LoginViewController: UIViewController {

    private let loginUseCase = ServiceLocator.shared.loginUseCase

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let statusBarScrim = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let fieldContainer = UIView()
    private let usernameField = UITextField()
    private let passwordField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let hintLabel = UILabel()
    private let passwordToggle = UIButton(type: .system)

    private var isLoggingIn = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.background
        setupViews()
        observeKeyboard()

        // 已登录则直接进入主界面（对应原项目"记住登录状态"）
        if DemoStore.shared.isLoggedIn {
            enterMain()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    // MARK: - UI

    private func setupViews() {
        // 状态栏底色（与品牌红一致），高度自动匹配状态栏 / 刘海安全区
        statusBarScrim.backgroundColor = AppTheme.primary
        statusBarScrim.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusBarScrim)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        titleLabel.text = "企划星"
        titleLabel.font = AppTheme.font(32, weight: .bold)
        titleLabel.textColor = AppTheme.primary
        titleLabel.textAlignment = .center

        subtitleLabel.text = "原生 + Flutter 混合开发 Demo"
        subtitleLabel.font = AppTheme.font(13)
        subtitleLabel.textColor = AppTheme.textGrey
        subtitleLabel.textAlignment = .center

        fieldContainer.backgroundColor = .white
        fieldContainer.layer.cornerRadius = 12
        fieldContainer.layer.masksToBounds = true

        configureField(
            usernameField,
            placeholder: "手机号 / 用户名",
            returnKeyType: .next
        )
        usernameField.addTarget(self, action: #selector(usernameDidReturn), for: .editingDidEndOnExit)

        configureField(
            passwordField,
            placeholder: "密码",
            returnKeyType: .done
        )
        passwordField.isSecureTextEntry = true
        passwordField.addTarget(self, action: #selector(doLogin), for: .editingDidEndOnExit)
        passwordField.rightView = passwordToggle
        passwordField.rightViewMode = .always

        passwordToggle.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        passwordToggle.tintColor = AppTheme.textTertiary
        passwordToggle.frame = CGRect(x: 0, y: 0, width: 44, height: 52)
        passwordToggle.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)

        let divider = UIView()
        divider.backgroundColor = AppTheme.divider
        divider.translatesAutoresizingMaskIntoConstraints = false

        [usernameField, divider, passwordField].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            fieldContainer.addSubview($0)
        }

        loginButton.setTitle("登 录", for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = AppTheme.font(16)
        loginButton.backgroundColor = AppTheme.primary
        loginButton.layer.cornerRadius = 26
        loginButton.addTarget(self, action: #selector(doLogin), for: .touchUpInside)

        hintLabel.text = "演示账号：demo　密码：123456（无网络时本地校验）"
        hintLabel.font = AppTheme.font(12)
        hintLabel.textColor = AppTheme.textGrey
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 0

        let titleSpacer = UIView()
        titleSpacer.translatesAutoresizingMaskIntoConstraints = false
        titleSpacer.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let subtitleSpacer = UIView()
        subtitleSpacer.translatesAutoresizingMaskIntoConstraints = false
        subtitleSpacer.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let buttonSpacer = UIView()
        buttonSpacer.translatesAutoresizingMaskIntoConstraints = false
        buttonSpacer.heightAnchor.constraint(equalToConstant: 36).isActive = true

        let hintSpacer = UIView()
        hintSpacer.translatesAutoresizingMaskIntoConstraints = false
        hintSpacer.heightAnchor.constraint(equalToConstant: 16).isActive = true

        contentStack.addArrangedSubview(titleSpacer)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(subtitleLabel)
        contentStack.addArrangedSubview(subtitleSpacer)
        contentStack.addArrangedSubview(fieldContainer)
        contentStack.addArrangedSubview(buttonSpacer)
        contentStack.addArrangedSubview(loginButton)
        contentStack.addArrangedSubview(hintSpacer)
        contentStack.addArrangedSubview(hintLabel)

        NSLayoutConstraint.activate([
            statusBarScrim.topAnchor.constraint(equalTo: view.topAnchor),
            statusBarScrim.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBarScrim.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBarScrim.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 32),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 28),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -28),

            fieldContainer.heightAnchor.constraint(equalToConstant: 105),
            usernameField.topAnchor.constraint(equalTo: fieldContainer.topAnchor),
            usernameField.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor),
            usernameField.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor),
            usernameField.heightAnchor.constraint(equalToConstant: 52),

            divider.topAnchor.constraint(equalTo: usernameField.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 0.5),

            passwordField.topAnchor.constraint(equalTo: divider.bottomAnchor),
            passwordField.leadingAnchor.constraint(equalTo: fieldContainer.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: fieldContainer.trailingAnchor),
            passwordField.heightAnchor.constraint(equalToConstant: 52),

            loginButton.heightAnchor.constraint(equalToConstant: 52),

            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func configureField(_ field: UITextField, placeholder: String, returnKeyType: UIReturnKeyType) {
        field.placeholder = placeholder
        field.font = AppTheme.font(15)
        field.textColor = AppTheme.textPrimary
        field.returnKeyType = returnKeyType
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.clearButtonMode = .whileEditing
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        field.leftView = padding
        field.leftViewMode = .always
    }

    // MARK: - 交互

    @objc private func usernameDidReturn() {
        passwordField.becomeFirstResponder()
    }

    @objc private func togglePasswordVisibility() {
        passwordField.isSecureTextEntry.toggle()
        let name = passwordField.isSecureTextEntry ? "eye.slash" : "eye"
        passwordToggle.setImage(UIImage(systemName: name), for: .normal)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func doLogin() {
        guard !isLoggingIn else { return }
        let username = usernameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordField.text ?? ""
        guard !username.isEmpty, !password.isEmpty else {
            showAlert("请输入账号和密码")
            return
        }

        setLoading(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.loginUseCase(username: username, password: password)
                // 登录态变化后主动推给已存在的 Flutter 引擎（未就绪的会入队补发）
                BaseFlutterContainer.shared.notifyLoginStateChanged()
                self.enterMain()
            } catch {
                self.setLoading(false)
                self.showAlert(error.localizedDescription)
            }
        }
    }

    private func setLoading(_ loading: Bool) {
        isLoggingIn = loading
        loginButton.isEnabled = !loading
        loginButton.setTitle(loading ? "登录中…" : "登 录", for: .normal)
    }

    /// 从桌面启动：登录成功后进入主界面；
    /// 从 Flutter / 原生页调起（模态呈现）：直接关闭，由调用方刷新登录态。
    private func enterMain() {
        if presentingViewController != nil {
            dismiss(animated: true)
        } else {
            AppRouter.shared.showMain()
        }
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }

    // MARK: - 键盘

    private func observeKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        let overlap = max(0, view.bounds.maxY - frame.minY)
        scrollView.contentInset.bottom = max(0, overlap - view.safeAreaInsets.bottom)
    }

    @objc private func keyboardWillHide() {
        scrollView.contentInset.bottom = 0
    }
}
