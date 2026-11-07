package com.qidian.demo.di

import com.qidian.demo.data.local.MMKVStore
import com.qidian.demo.data.remote.ApiClient
import com.qidian.demo.data.remote.QdApiService
import com.qidian.demo.data.repository.BookRepositoryImpl
import com.qidian.demo.data.repository.LoginRepositoryImpl
import com.qidian.demo.data.repository.ReaderRepositoryImpl
import com.qidian.demo.domain.repository.BookRepository
import com.qidian.demo.domain.repository.LoginRepository
import com.qidian.demo.domain.repository.ReaderRepository
import com.qidian.demo.domain.usecase.GetBookDetailUseCase
import com.qidian.demo.domain.usecase.GetBookshelfUseCase
import com.qidian.demo.domain.usecase.LoadChapterContentUseCase
import com.qidian.demo.domain.usecase.LoadChaptersUseCase
import com.qidian.demo.domain.usecase.LoginUseCase
import com.qidian.demo.domain.usecase.LogoutUseCase

/**
 * 手动依赖注入容器（CleanDDD 组装根）。
 * 原项目使用自研 inject 模块按模块装配，demo 规模较小，用单例组装根即可，
 * 保持「presentation → domain ← data」的依赖方向，domain 不反向依赖 data。
 */
object ServiceLocator {

    private val apiClient: ApiClient by lazy { ApiClient(MMKVStore.baseUrl) }

    private val api: QdApiService by lazy { apiClient.service }

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
