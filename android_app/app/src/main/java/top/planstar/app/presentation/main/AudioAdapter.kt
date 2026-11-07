package top.planstar.app.presentation.main

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import top.planstar.app.R
import top.planstar.app.databinding.ItemAudioBinding
import top.planstar.app.domain.model.AudioBookItem

/**
 * 听书列表适配器。
 *
 * 播放/暂停只改变按钮图标，因此通过 payload 做局部刷新，
 * 避免 notifyItemChanged 触发整行（封面、文本、进度条）重新绑定。
 */
class AudioAdapter : RecyclerView.Adapter<AudioAdapter.VH>() {

    private val items = mutableListOf<AudioBookItem>()
    private val playing = mutableSetOf<Int>()

    fun submit(list: List<AudioBookItem>) {
        items.clear()
        items.addAll(list)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
        val binding = ItemAudioBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        val holder = VH(binding)
        binding.btnPlay.setOnClickListener {
            val position = holder.bindingAdapterPosition
            if (position == RecyclerView.NO_POSITION) return@setOnClickListener
            if (!playing.remove(position)) playing.add(position)
            notifyItemChanged(position, PAYLOAD_PLAY_STATE)
        }
        return holder
    }

    override fun getItemCount(): Int = items.size

    override fun onBindViewHolder(holder: VH, position: Int) {
        onBindViewHolder(holder, position, mutableListOf())
    }

    override fun onBindViewHolder(holder: VH, position: Int, payloads: MutableList<Any>) {
        val book = items[position]
        if (payloads.isEmpty()) {
            holder.binding.tvTitle.text = book.BookName.orEmpty()
            holder.binding.tvSubtitle.text = "${book.Speaker.orEmpty()} · ${book.Duration.orEmpty()}"
            holder.binding.tvCoverChar.text = book.BookName.orEmpty().take(1)
            holder.binding.progressBar.progress = (position * 13) % 90
        }
        holder.binding.btnPlay.setImageResource(
            if (playing.contains(position)) R.drawable.ic_reader_pause else R.drawable.ic_reader_play
        )
    }

    class VH(val binding: ItemAudioBinding) : RecyclerView.ViewHolder(binding.root)

    private companion object {
        const val PAYLOAD_PLAY_STATE = "play_state"
    }
}
