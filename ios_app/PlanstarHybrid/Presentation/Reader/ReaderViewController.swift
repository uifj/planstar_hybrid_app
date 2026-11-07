import UIKit

/// 阅读页（对应原项目 ui.activity.chapter 阅读模块 / Android `ReaderActivity`）。
///
/// - 点击正文切换顶部 / 底部工具栏
/// - 底部栏：目录、字号 A- / A+、进度、主题（白 / 羊皮纸 / 护眼绿 / 夜间黑）
/// - 章节末尾点击进入下一章，返回时先收起工具栏
/// - 阅读字号与主题通过本地存储记忆
@MainActor
final class ReaderViewController: UIViewController {

    private let book: BookItem
    private let chapters: [Chapter]
    private let loadChapterContent: LoadChapterContentUseCase

    private var currentChapter = 0
    private var fontSize: CGFloat
    private var themeIndex: Int
    private var barsVisible = false

    private let contentScrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let chapterTitleLabel = UILabel()
    private let chapterAuthorLabel = UILabel()
    private let contentLabel = UILabel()
    private let chapterEndLabel = UILabel()

    private let topBar = UIView()
    private let bookTitleLabel = UILabel()
    private let backButton = UIButton(type: .system)

    private let bottomBar = UIView()
    private let catalogButton = UIButton(type: .system)
    private let fontMinusButton = UIButton(type: .system)
    private let fontPlusButton = UIButton(type: .system)
    private let themeButton = UIButton(type: .system)
    private let progressLabel = UILabel()

    private var toastLabel: UILabel?

    init(bookId: Int64, title: String, author: String, chapterCount: Int) {
        let resolvedTitle = title.isEmpty ? "示例书籍" : title
        let resolvedAuthor = author.isEmpty ? "起点作者" : author
        self.book = BookItem(bookId: bookId, bookName: resolvedTitle, author: resolvedAuthor)
        let total = max(chapterCount, 1)
        self.chapters = ServiceLocator.shared.loadChaptersUseCase(bookId: bookId, total: total)
        self.loadChapterContent = ServiceLocator.shared.loadChapterContentUseCase
        self.fontSize = CGFloat(DemoStore.shared.readerFontSize)
        self.themeIndex = min(max(DemoStore.shared.readerTheme, 0), AppTheme.readerThemes.count - 1)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupContent()
        setupTopBar()
        setupBottomBar()
        setupGestures()
        applyTheme()
        renderChapter()
        setBarsVisible(false, animated: false)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateContentInsets()
        // 安全区晚于首次渲染确定：只有仍停留在顶部时才重新对齐，避免打断用户阅读位置
        if contentScrollView.contentOffset.y <= 0 {
            scrollToTop()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        themeIndex == AppTheme.readerThemes.count - 1 ? .lightContent : .darkContent
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        .fade
    }

    // MARK: - UI

    private func setupContent() {
        view.backgroundColor = AppTheme.readerThemes[themeIndex].background

        contentScrollView.alwaysBounceVertical = true
        contentScrollView.contentInsetAdjustmentBehavior = .never
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentScrollView)

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentScrollView.addSubview(contentStack)

        chapterTitleLabel.font = AppTheme.font(20, weight: .bold)
        chapterTitleLabel.textAlignment = .center
        chapterTitleLabel.numberOfLines = 0

        chapterAuthorLabel.font = AppTheme.font(12)
        chapterAuthorLabel.textAlignment = .center
        chapterAuthorLabel.numberOfLines = 0

        contentLabel.numberOfLines = 0

        chapterEndLabel.font = AppTheme.font(13)
        chapterEndLabel.textAlignment = .center
        chapterEndLabel.numberOfLines = 0

        contentStack.addArrangedSubview(chapterTitleLabel)
        contentStack.setCustomSpacing(8, after: chapterTitleLabel)
        contentStack.addArrangedSubview(chapterAuthorLabel)
        contentStack.setCustomSpacing(24, after: chapterAuthorLabel)
        contentStack.addArrangedSubview(contentLabel)
        contentStack.setCustomSpacing(24, after: contentLabel)
        contentStack.addArrangedSubview(chapterEndLabel)

        NSLayoutConstraint.activate([
            contentScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            contentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStack.bottomAnchor.constraint(equalTo: contentScrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.leadingAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.trailingAnchor, constant: -24),
        ])
    }

    private func setupTopBar() {
        topBar.backgroundColor = .white
        topBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBar)

        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = AppTheme.textPrimary
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(backButton)

        bookTitleLabel.font = AppTheme.font(16)
        bookTitleLabel.text = book.bookName
        bookTitleLabel.textAlignment = .center
        bookTitleLabel.numberOfLines = 1
        bookTitleLabel.lineBreakMode = .byTruncatingTail
        bookTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(bookTitleLabel)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            backButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 8),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 48),
            backButton.heightAnchor.constraint(equalToConstant: 52),

            bookTitleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            bookTitleLabel.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 56),
            bookTitleLabel.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),

            topBar.bottomAnchor.constraint(equalTo: backButton.bottomAnchor),
        ])
    }

    private func setupBottomBar() {
        bottomBar.backgroundColor = .white
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBar)

        configureBarButton(catalogButton, title: "目录", action: #selector(showCatalog))
        configureBarButton(fontMinusButton, title: "A-", action: #selector(decreaseFontSize))
        configureBarButton(fontPlusButton, title: "A+", action: #selector(increaseFontSize))
        configureBarButton(themeButton, title: "主题", action: #selector(cycleTheme))

        progressLabel.font = AppTheme.font(12)
        progressLabel.textColor = AppTheme.textTertiary
        progressLabel.textAlignment = .center
        progressLabel.adjustsFontSizeToFitWidth = true

        let row = UIStackView(arrangedSubviews: [
            catalogButton, fontMinusButton, progressLabel, fontPlusButton, themeButton,
        ])
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.alignment = .fill
        row.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(row)

        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            row.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            row.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            row.heightAnchor.constraint(equalToConstant: 56),
            row.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func configureBarButton(_ button: UIButton, title: String, action: Selector) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = AppTheme.font(14)
        button.setTitleColor(AppTheme.textPrimary, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleContentTap(_:)))
        tap.cancelsTouchesInView = false
        contentScrollView.addGestureRecognizer(tap)
    }

    // MARK: - 渲染

    private func renderChapter() {
        guard chapters.indices.contains(currentChapter) else { return }
        chapterTitleLabel.text = chapters[currentChapter].chapterName
        chapterAuthorLabel.text = book.author
        renderContentText()

        let total = chapters.count
        progressLabel.text = "\((currentChapter + 1) * 100 / total)% · 第\(currentChapter + 1)章"
        chapterEndLabel.text = currentChapter >= total - 1
            ? "— 本章完 · 全书完 —"
            : "— 本章完 · 轻触进入下一章 —"
        scrollToTop()
    }

    private func renderContentText() {
        let text = loadChapterContent(book: book, chapterIndex: currentChapter)
        contentLabel.attributedText = ReaderViewController.makeContent(
            text,
            fontSize: fontSize,
            color: AppTheme.readerThemes[themeIndex].text
        )
    }

    private static func makeContent(_ text: String, fontSize: CGFloat, color: UIColor) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = 1.5
        return NSAttributedString(
            string: text,
            attributes: [
                .font: AppTheme.font(fontSize),
                .foregroundColor: color,
                .paragraphStyle: style,
            ]
        )
    }

    private func scrollToTop() {
        contentScrollView.setContentOffset(
            CGPoint(x: 0, y: -contentScrollView.contentInset.top),
            animated: false
        )
    }

    // MARK: - 工具栏

    private func setBarsVisible(_ visible: Bool, animated: Bool) {
        barsVisible = visible
        if visible {
            topBar.isHidden = false
            bottomBar.isHidden = false
        }
        let changes = {
            self.topBar.alpha = visible ? 1 : 0
            self.bottomBar.alpha = visible ? 1 : 0
            self.updateContentInsets()
        }
        guard animated else {
            changes()
            topBar.isHidden = !visible
            bottomBar.isHidden = !visible
            return
        }
        UIView.animate(withDuration: 0.2, animations: changes) { _ in
            guard !visible else { return }
            self.topBar.isHidden = true
            self.bottomBar.isHidden = true
        }
    }

    /// 工具栏收起时正文延伸到系统栏后面，通过 contentInset 保证文字不被状态栏 / 手势条遮挡。
    private func updateContentInsets() {
        let safeTop = view.safeAreaInsets.top
        let safeBottom = view.safeAreaInsets.bottom
        let top = barsVisible ? safeTop + 52 : safeTop
        let bottom = barsVisible ? safeBottom + 56 : safeBottom
        contentScrollView.contentInset = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
        contentScrollView.verticalScrollIndicatorInsets = UIEdgeInsets(
            top: top,
            left: 0,
            bottom: bottom,
            right: 0
        )
    }

    // MARK: - 交互

    @objc private func handleContentTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: contentScrollView)
        let endFrame = chapterEndLabel.convert(chapterEndLabel.bounds, to: contentScrollView)
        if endFrame.contains(point) {
            goNextChapter()
            return
        }
        setBarsVisible(!barsVisible)
    }

    @objc private func handleBack() {
        if barsVisible {
            setBarsVisible(false)
            return
        }
        close()
    }

    private func close() {
        if let navigationController, navigationController.viewControllers.first !== self {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func selectChapter(_ index: Int) {
        currentChapter = min(max(index, 0), chapters.count - 1)
        renderChapter()
    }

    private func goNextChapter() {
        guard currentChapter < chapters.count - 1 else {
            showToast("已是最后一章")
            return
        }
        selectChapter(currentChapter + 1)
    }

    @objc private func decreaseFontSize() {
        changeFontSize(-1)
    }

    @objc private func increaseFontSize() {
        changeFontSize(1)
    }

    private func changeFontSize(_ delta: CGFloat) {
        fontSize = min(max(fontSize + delta * 2, 14), 26)
        DemoStore.shared.readerFontSize = Int(fontSize)
        renderContentText()
        showToast("字号 \(Int(fontSize))")
    }

    @objc private func cycleTheme() {
        themeIndex = (themeIndex + 1) % AppTheme.readerThemes.count
        DemoStore.shared.readerTheme = themeIndex
        applyTheme()
        showToast(AppTheme.readerThemes[themeIndex].name)
    }

    private func applyTheme() {
        let theme = AppTheme.readerThemes[themeIndex]
        view.backgroundColor = theme.background
        contentScrollView.backgroundColor = theme.background
        topBar.backgroundColor = theme.background
        bottomBar.backgroundColor = theme.background

        bookTitleLabel.textColor = theme.text
        chapterTitleLabel.textColor = theme.text
        chapterAuthorLabel.textColor = theme.text
        chapterEndLabel.textColor = theme.text
        progressLabel.textColor = theme.text
        [catalogButton, fontMinusButton, fontPlusButton, themeButton].forEach {
            $0.setTitleColor(theme.text, for: .normal)
        }
        backButton.tintColor = theme.text

        if contentLabel.attributedText != nil {
            renderContentText()
        }

        // 夜间黑主题使用白色系统栏图标，其余主题使用深色图标
        setNeedsStatusBarAppearanceUpdate()
    }

    @objc private func showCatalog() {
        let catalog = CatalogViewController(
            chapters: chapters,
            currentIndex: currentChapter
        ) { [weak self] index in
            self?.selectChapter(index)
        }
        if let sheet = catalog.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
        }
        present(catalog, animated: true)
    }

    // MARK: - Toast

    private func showToast(_ message: String) {
        toastLabel?.removeFromSuperview()

        let label = UILabel()
        label.text = "  \(message)  "
        label.font = AppTheme.font(13)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -120),
            label.heightAnchor.constraint(equalToConstant: 34),
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 92),
        ])
        toastLabel = label

        UIView.animate(withDuration: 0.2, animations: {
            label.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.25, delay: 1.1, options: []) {
                label.alpha = 0
            } completion: { _ in
                label.removeFromSuperview()
                if self.toastLabel === label {
                    self.toastLabel = nil
                }
            }
        })
    }
}
