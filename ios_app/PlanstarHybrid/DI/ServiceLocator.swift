import Foundation

/// 手动依赖注入容器（CleanDDD 组装根），与 Android `ServiceLocator` 一一对应。
///
/// 保持「presentation → domain ← data」的依赖方向，domain 不反向依赖 data；
/// 网络栈同样延迟到首次真正使用时才构建，避免启动阶段的主线程开销。
final class ServiceLocator {

    static let shared = ServiceLocator()

    private init() {}

    lazy var apiClient = ApiClient(baseURL: DemoStore.shared.baseUrl)

    lazy var bookRepository: BookRepository = BookRepositoryImpl(apiClient: apiClient)

    lazy var loginRepository: LoginRepository = LoginRepositoryImpl(apiClient: apiClient)

    lazy var readerRepository: ReaderRepository = ReaderRepositoryImpl()

    lazy var getBookshelfUseCase = GetBookshelfUseCase(repository: bookRepository)

    lazy var getBookDetailUseCase = GetBookDetailUseCase(repository: bookRepository)

    lazy var loginUseCase = LoginUseCase(repository: loginRepository)

    lazy var logoutUseCase = LogoutUseCase(repository: loginRepository)

    lazy var loadChaptersUseCase = LoadChaptersUseCase(repository: readerRepository)

    lazy var loadChapterContentUseCase = LoadChapterContentUseCase(repository: readerRepository)
}
