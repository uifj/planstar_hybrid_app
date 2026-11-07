package top.planstar.app.di

import top.planstar.app.data.local.MMKVStore
import top.planstar.app.data.remote.ApiClient
import top.planstar.app.data.remote.PlanstarApiService
import top.planstar.app.data.repository.BookRepositoryImpl
import top.planstar.app.data.repository.LoginRepositoryImpl
import top.planstar.app.data.repository.ReaderRepositoryImpl
import top.planstar.app.domain.repository.BookRepository
import top.planstar.app.domain.repository.LoginRepository
import top.planstar.app.domain.repository.ReaderRepository
import top.planstar.app.domain.usecase.GetBookDetailUseCase
import top.planstar.app.domain.usecase.GetBookshelfUseCase
import top.planstar.app.domain.usecase.LoadChapterContentUseCase
import top.planstar.app.domain.usecase.LoadChaptersUseCase
import top.planstar.app.domain.usecase.LoginUseCase
import top.planstar.app.domain.usecase.LogoutUseCase

/**
 * 手动依赖注入容器（CleanDDD 组装根）。
 * 原项目使用自研 inject 模块按模块装配，demo 规模较小，用单例组装根即可，
 * 保持「presentation → domain ← data」的依赖方向，domain 不反向依赖 data。
 */
object ServiceLocator {

    private val apiClient: ApiClient by lazy { ApiClient(MMKVStore.baseUrl) }

    private val api: PlanstarApiService by lazy { apiClient.service }

    val bookRepository: BookRepository by lazy { BookRepositoryImpl { api } }

    val loginRepository: LoginRepository by lazy { LoginRepositoryImpl(api) }

    val readerRepository: ReaderRepository by lazy { ReaderRepositoryImpl() }

    val getBookshelfUseCase: GetBookshelfUseCase by lazy { GetBookshelfUseCase(bookRepository) }

    val getBookDetailUseCase: GetBookDetailUseCase by lazy { GetBookDetailUseCase(bookRepository) }

    val loginUseCase: LoginUseCase by lazy { LoginUseCase(loginRepository) }

    val logoutUseCase: LogoutUseCase by lazy { LogoutUseCase(loginRepository) }

    val loadChaptersUseCase: LoadChaptersUseCase by lazy { LoadChaptersUseCase(readerRepository) }

    val loadChapterContentUseCase: LoadChapterContentUseCase by lazy {
        LoadChapterContentUseCase(readerRepository)
    }
}
