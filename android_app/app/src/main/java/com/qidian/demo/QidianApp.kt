package com.qidian.demo

import android.app.Application
import android.content.Context
import com.qidian.demo.data.local.MMKVStore
import com.tencent.mmkv.MMKV

class QidianApp : Application() {

    override fun onCreate() {
        super.onCreate()
        appContext = this
        // 初始化腾讯 MMKV（对应原 APK 的 MMKV 存储依赖）
        // 本工程只有单进程，使用默认单进程模式：省去跨进程锁与额外的 mmap 开销，
        // 每次读写都更快（MULTI_PROCESS_MODE 只在真正多进程共享数据时才需要）。
        MMKV.initialize(this)
        MMKVStore.init()
    }

    companion object {
        lateinit var appContext: Context
            private set
    }
}
