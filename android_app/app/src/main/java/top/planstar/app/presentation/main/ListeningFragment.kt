package top.planstar.app.presentation.main

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import top.planstar.app.core.ui.applyInsetsPadding
import top.planstar.app.databinding.FragmentListeningBinding
import top.planstar.app.domain.model.AudioBookItem

/** 听书页（原生）：模拟有声书列表与播放状态。 */
class ListeningFragment : Fragment() {

    private var _binding: FragmentListeningBinding? = null
    private val binding get() = _binding!!

    private val adapter = AudioAdapter()

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View {
        _binding = FragmentListeningBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        // 顶部安全区：状态栏 / 刘海 / 挖孔（横屏时同时避让左右）
        binding.headerBar.applyInsetsPadding(top = true, horizontal = true)
        binding.recyclerView.setHasFixedSize(true)
        binding.recyclerView.layoutManager = LinearLayoutManager(requireContext())
        binding.recyclerView.adapter = adapter
        adapter.submit(
            listOf(
                AudioBookItem(BookName = "元尊", Speaker = "主播：有声土豆", Duration = "时长 08:32"),
                AudioBookItem(BookName = "庆余年", Speaker = "主播：范闲工作室", Duration = "时长 12:47"),
                AudioBookItem(BookName = "诡秘之主", Speaker = "主播：愚者电台", Duration = "时长 15:20"),
                AudioBookItem(BookName = "凡人修仙传", Speaker = "主播：修仙FM", Duration = "时长 09:05"),
                AudioBookItem(BookName = "大奉打更人", Speaker = "主播：打更人广播", Duration = "时长 11:38"),
                AudioBookItem(BookName = "赘婿", Speaker = "主播：江宁说书人", Duration = "时长 14:02"),
            )
        )
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
