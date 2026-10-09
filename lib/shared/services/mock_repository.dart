import '../../features/food_diary/models/food_item.dart';
import '../../features/food_diary/models/meal.dart';
import '../../features/knowledge/models/article.dart';
import 'app_repository.dart';

class MockRepository implements AppRepository {
  @override
  List<FoodItem> get foods => const [
    FoodItem(
      id: 'oats',
      name: 'Yến mạch ngâm qua đêm với quả mọng',
      category: 'Bữa sáng',
      emoji: '🫐',
    ),
    FoodItem(
      id: 'salad',
      name: 'Salad đậu ngũ sắc',
      category: 'Bữa trưa',
      emoji: '🥗',
    ),
    FoodItem(
      id: 'salmon',
      name: 'Cơm cá hồi gừng',
      category: 'Bữa tối',
      emoji: '🍣',
    ),
    FoodItem(
      id: 'nuts',
      name: 'Quả óc chó và trái cây',
      category: 'Bữa phụ',
      emoji: '🥜',
    ),
    FoodItem(
      id: 'soup',
      name: 'Súp rau củ miso',
      category: 'Bữa tối',
      emoji: '🍲',
    ),
  ];

  @override
  List<Meal> get meals => [
    Meal(
      id: 'm1',
      type: MealType.breakfast,
      date: DateTime.now(),
      items: [foods[0]],
    ),
    Meal(
      id: 'm2',
      type: MealType.lunch,
      date: DateTime.now(),
      items: [foods[1]],
    ),
  ];

  @override
  List<Article> get articles => [
    Article(
      id: 'a1',
      title: 'Niềm vui của việc ăn chậm',
      topic: 'Ăn uống tỉnh thức',
      summary:
          'Những khoảng dừng nhỏ có thể thay đổi cách cơ thể tiếp nhận bữa ăn.',
      content: 'Ăn chậm giúp các giác quan cảm nhận hương vị và cơ thể nhận biết cảm giác no. Hôm nay, hãy thử đặt đũa xuống giữa các lần gắp.',
    ),
    Article(
      id: 'a2',
      title: 'Đĩa ăn nhiều màu sắc tự nhiên',
      topic: 'Đa dạng thực phẩm',
      summary: 'Xây dựng đĩa ăn cân bằng bằng những dấu hiệu màu sắc đơn giản.',
      content: 'Hãy hướng đến nhiều màu sắc tự nhiên trong ngày: rau xanh, đậu, ngũ cốc nguyên hạt, trái cây và rau củ. Sự đa dạng khiến lựa chọn lành mạnh trở nên hấp dẫn hơn.',
    ),
    Article(
      id: 'a3',
      title: 'Sắp xếp căn bếp dễ dùng hơn',
      topic: 'Thói quen hằng ngày',
      summary: 'Một chút chuẩn bị sẽ giúp ngày mai nhẹ nhàng hơn.',
      content: 'Để trái cây đã rửa ở nơi dễ thấy, nấu thêm một phần ngũ cốc và đặt nước ở vị trí dễ lấy nhất.',
    ),
  ];
}
