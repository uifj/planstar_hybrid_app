package top.planstar.app.presentation.main

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.GridLayoutManager
import top.planstar.app.R
import top.planstar.app.core.ui.applyInsetsPadding
import top.planstar.app.databinding.FragmentBookshelfBinding
import top.planstar.app.di.ServiceLocator
import top.planstar.app.domain.model.BookItem
import top.planstar.app.presentation.reader.ReaderActivity
import kotlinx.coroutines.launch

/**
 * 书架页（原生）。
 *
 * 分层：presentation 只依赖 domain 用例（GetBookshelfUseCase），
 * 网络/本地回退逻辑封装在 data 层的 BookRepositoryImpl 中。
 */
class BookshelfFragment : Fragment() {

    private var _binding: FragmentBookshelfBinding? = null
    private val binding get() = _binding!!

    private val getBookshelf = ServiceLocator.getBookshelfUseCase

    private val adapter = BookGridAdapter { item ->
        val book = item.bookItem ?: BookItem()
        val intent = Intent(requireContext(), ReaderActivity::class.java).apply {
            putExtra(ReaderActivity.EXTRA_BOOK_ID, book.BookId)
            putExtra(ReaderActivity.EXTRA_TITLE, book.BookName.orEmpty())
            putExtra(ReaderActivity.EXTRA_AUTHOR, book.Author.orEmpty())
            putExtra(ReaderActivity.EXTRA_CHAPTERS, DEFAULT_READER_CHAPTERS)
        }
        startActivity(intent)
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View {
        _binding = FragmentBookshelfBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        // 顶部安全区：状态栏 / 刘海 / 挖孔（横屏时同时避让左右）
        binding.headerBar.applyInsetsPadding(top = true, horizontal = true)
        binding.recyclerView.setHasFixedSize(true)
        binding.recyclerView.layoutManager = GridLayoutManager(requireContext(), 3)
        binding.recyclerView.adapter = adapter
        load()
    }

    private fun load() {
        // 首屏直接渲染本地缓存：进书架即有内容，不等待网络。
        // 这样既没有长时间转圈，也不会让网络回包与 Tab 切换撞在同一批帧上。
        binding.progressBar.visibility = View.GONE
        binding.tvEmpty.visibility = View.GONE
        adapter.submitList(getBookshelf.cached())
        binding.tvSource.visibility = View.VISIBLE
        binding.tvSource.setText(R.string.bookshelf_source_local)

        // 后台刷新：只有网络真的拿到数据才更新，失败保持缓存不闪动
        viewLifecycleOwner.lifecycleScope.launch {
            val result = getBookshelf().getOrNull()
            val binding = _binding ?: return@launch
            if (result == null || !result.fromNetwork || result.items.isEmpty()) return@launch
            adapter.submitList(result.items)
            binding.tvSource.setText(R.string.bookshelf_source_network)
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    private companion object {
        const val DEFAULT_READER_CHAPTERS = 30
    }
}
