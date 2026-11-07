/// 路由常量：字符串与原生侧 initialRoute 完全一致，改这里会破坏混合跳转。
const String routeBookCategory = '/book_category';
const String routeMine = '/mine';
const String routeBookDetail = '/book_detail';

/// 把原生传入的 initialRoute 归一化为已知路由。
///
/// 未知或空路由一律回书城：原生侧可能因版本不一致传入旧路由，
/// 白屏比回落首页更难排查。
String resolveInitialRoute(String initialRoute) {
  switch (initialRoute) {
    case routeMine:
      return routeMine;
    case routeBookDetail:
      return routeBookDetail;
    case routeBookCategory:
      return routeBookCategory;
    default:
      return routeBookCategory;
  }
}
