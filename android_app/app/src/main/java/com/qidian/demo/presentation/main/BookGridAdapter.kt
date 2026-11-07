package com.qidian.demo.presentation.main

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.qidian.demo.databinding.ItemBookGridBinding
import com.qidian.demo.domain.model.BookItem
import com.qidian.demo.domain.model.BookShelfItem

/**
 * 书架三列封面网格适配器（对应原项目书架样式）。
 *
 * 与原项目一致：适配器接收的是 BookShelfItem（而非裸 BookItem），
 * 普通书籍项通过 getBookItem() 取书封、书名、作者。
 *
 * 使用 ListAdapter + DiffUtil：切换/刷新书单时只重绑变化项，
 * 避免 notifyDataSetChanged 造成的整列表重绑与闪烁。
 */
class BookGridAdapter(
    private val onClick: (BookShelfItem) -> Unit,
) : ListAdapter<BookShelfItem, BookGridAdapter.VH>(DIFF) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
        val binding = ItemBookGridBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return VH(binding)
    }

    override fun onBindViewHolder(holder: VH, position: Int) {
        val item = getItem(position)
        val book = item.bookItem ?: BookItem()
        holder.binding.tvTitle.text = book.BookName.orEmpty()
        holder.binding.tvAuthor.text = book.Author.orEmpty()
        holder.binding.tvCoverChar.text = book.BookName.orEmpty().take(1)
        holder.itemView.setOnClickListener { onClick(item) }
    }

    class VH(val binding: ItemBookGridBinding) : RecyclerView.ViewHolder(binding.root)

    private companion object {
        val DIFF = object : DiffUtil.ItemCallback<BookShelfItem>() {
            override fun areItemsTheSame(oldItem: BookShelfItem, newItem: BookShelfItem): Boolean =
                (oldItem.bookItem?.BookId ?: 0L) == (newItem.bookItem?.BookId ?: 0L)

            override fun areContentsTheSame(oldItem: BookShelfItem, newItem: BookShelfItem): Boolean =
                oldItem == newItem
        }
    }
}
