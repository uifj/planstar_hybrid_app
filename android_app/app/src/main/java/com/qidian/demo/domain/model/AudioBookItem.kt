package com.qidian.demo.domain.model

/**
 * 有声书条目（对应原项目 repository.entity.AudioBookItem 的核心展示字段）。
 * 原实体还包含音质、授权、章节计费等音频业务字段，demo 听书页只呈现列表信息。
 */
data class AudioBookItem(
    var BookId: Long = 0,
    var BookName: String? = null,
    var Speaker: String? = null,
    var Duration: String? = null,
    var Cover: String? = null,
)
