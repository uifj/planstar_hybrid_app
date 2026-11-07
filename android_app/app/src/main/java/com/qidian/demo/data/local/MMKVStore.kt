package com.qidian.demo.data.local

import com.tencent.mmkv.MMKV

/**
 * MMKV 本地存储（对应原项目 `com.qidian.QDReader` 中使用 MMKV 持久化登录态与阅读配置的方式）。
 *
 * 原项目按业务拆分多个 mmkv id；demo 只有一套演示数据，使用单进程单 id，
 * 避免多进程模式下 MULTI_PROCESS 带来的额外 mmap 与文件锁开销。
 */
object MMKVStore {

    private const val MMKV_ID = "qidian_demo"

    private const val KEY_TOKEN = "token"
    private const val KEY_NICKNAME = "nickname"
    private const val KEY_USER_ID = "user_id"
    private const val KEY_BASE_URL = "base_url"
    private const val KEY_READER_FONT_SIZE = "reader_font_size"
    private const val KEY_READER_THEME = "reader_theme"

    /** 默认请求域名（demo 使用 httpbin 回显验证网络链路） */
    const val DEFAULT_BASE_URL = "https://httpbin.org/"

    private lateinit var mmkv: MMKV

    fun init() {
        if (::mmkv.isInitialized) return
        mmkv = MMKV.mmkvWithID(MMKV_ID)
    }

    var token: String
        get() = mmkv.decodeString(KEY_TOKEN, "") ?: ""
        set(value) {
            mmkv.encode(KEY_TOKEN, value)
        }

    var nickname: String
        get() = mmkv.decodeString(KEY_NICKNAME, "") ?: ""
        set(value) {
            mmkv.encode(KEY_NICKNAME, value)
        }

    var userId: Long
        get() = mmkv.decodeLong(KEY_USER_ID, 0)
        set(value) {
            mmkv.encode(KEY_USER_ID, value)
        }

    var baseUrl: String
        get() = mmkv.decodeString(KEY_BASE_URL, DEFAULT_BASE_URL) ?: DEFAULT_BASE_URL
        set(value) {
            mmkv.encode(KEY_BASE_URL, value)
        }

    /** 阅读字号（对应原项目阅读设置记忆） */
    var readerFontSize: Int
        get() = mmkv.decodeInt(KEY_READER_FONT_SIZE, 18)
        set(value) {
            mmkv.encode(KEY_READER_FONT_SIZE, value)
        }

    /** 阅读主题索引：0 白色 / 1 羊皮纸 / 2 护眼绿 / 3 夜间黑 */
    var readerTheme: Int
        get() = mmkv.decodeInt(KEY_READER_THEME, 0)
        set(value) {
            mmkv.encode(KEY_READER_THEME, value)
        }

    fun saveLogin(token: String, nickname: String, userId: Long) {
        this.token = token
        this.nickname = nickname
        this.userId = userId
    }

    fun clearLogin() {
        mmkv.removeValuesForKeys(arrayOf(KEY_TOKEN, KEY_NICKNAME, KEY_USER_ID))
    }
}
