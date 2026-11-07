import UIKit

/// 原项目设计令牌（提取自 `com.qidian.QDReader` 资源表）。
/// 与 Android 侧 `res/values/colors.xml` 一一对应，保证双端视觉一致。
enum AppTheme {

    // MARK: - 品牌色 / 文本色（对应 colors.xml）
    static let primary = UIColor(hex: 0xE5353E)
    static let primaryDark = UIColor(hex: 0xD23E3B)
    static let textPrimary = UIColor(hex: 0x333333)
    static let textSecondary = UIColor(hex: 0x666666)
    static let textTertiary = UIColor(hex: 0x999999)
    static let textGrey = UIColor(hex: 0x9E9E9E)
    static let background = UIColor(hex: 0xF5F5F5)
    static let divider = UIColor(hex: 0xE6E6E6)

    /// 书封渐变（对应 drawable/bg_book_cover.xml：45° 由 #5C6BC0 到 #7E57C2）
    static let coverStart = UIColor(hex: 0x5C6BC0)
    static let coverEnd = UIColor(hex: 0x7E57C2)

    // MARK: - 阅读主题（对应 ReaderActivity 的四种阅读模式）
    static let readerThemes: [ReaderTheme] = [
        ReaderTheme(name: "白色", background: UIColor(hex: 0xFFFFFF), text: UIColor(hex: 0x333333)),
        ReaderTheme(name: "羊皮纸", background: UIColor(hex: 0xF5E8D1), text: UIColor(hex: 0x5A4A32)),
        ReaderTheme(name: "护眼绿", background: UIColor(hex: 0xD7EFD5), text: UIColor(hex: 0x3B4A3B)),
        ReaderTheme(name: "夜间黑", background: UIColor(hex: 0x000000), text: UIColor(hex: 0x8A8A8A)),
    ]

    // MARK: - 字体

    /// 原项目自带字体（阅文正文字体），未注册成功时回退系统字体。
    static func font(_ size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let base = UIFont(name: "YuewenFont-Regular", size: size)
            ?? UIFont(name: "YuewenFont", size: size)
            ?? UIFont.systemFont(ofSize: size, weight: weight)
        guard weight.rawValue >= UIFont.Weight.semibold.rawValue,
              let descriptor = base.fontDescriptor.withSymbolicTraits(.traitBold) else {
            return base
        }
        return UIFont(descriptor: descriptor, size: size)
    }

    // MARK: - 全局外观

    static func configureAppearance() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = .white
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: textGrey,
            .font: font(11),
        ]
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: primary,
            .font: font(11),
        ]
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
        UITabBar.appearance().tintColor = primary
        UITabBar.appearance().unselectedItemTintColor = textGrey
    }
}

/// 阅读主题色板
struct ReaderTheme {
    let name: String
    let background: UIColor
    let text: UIColor
}

extension UIColor {

    /// 0xRRGGBB 形式的十六进制色值
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
