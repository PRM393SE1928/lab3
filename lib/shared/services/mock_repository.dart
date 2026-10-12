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
      emoji: '🥣',
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
    Meal(
      id: 'm3',
      type: MealType.snack,
      date: DateTime.now().subtract(const Duration(days: 1)),
      items: [foods[3]],
    ),
  ];

  @override
  List<Article> get articles => [
    Article(
      id: 'a1',
      title: 'Nguyên tắc đĩa ăn trường thọ',
      topic: 'Dinh dưỡng',
      readMinutes: 4,
      summary: 'Tạo bữa ăn cân bằng bằng cách tăng rau, đậu, ngũ cốc nguyên hạt và chất béo tốt.',
      content: 'Một đĩa ăn trường thọ không cần phức tạp. Hãy bắt đầu với nửa đĩa là rau củ nhiều màu, một phần tư là ngũ cốc nguyên hạt và phần còn lại là đạm tốt như đậu, cá hoặc trứng. Khi có thể, ưu tiên thực phẩm ít chế biến, gia vị vừa phải và chất béo tốt từ hạt, quả bơ hoặc dầu ô liu.\n\nĐiểm quan trọng là tính lặp lại. Một bữa hoàn hảo không có nhiều ý nghĩa bằng một nhịp ăn đủ tốt được duy trì hằng ngày.',
    ),
    Article(
      id: 'a2',
      title: 'Ăn chậm để no đúng lúc',
      topic: 'Thói quen',
      readMinutes: 3,
      summary: 'Ăn chậm giúp cơ thể nhận biết tín hiệu no và giảm ăn quá mức trong những ngày bận.',
      content: 'Cơ thể cần thời gian để gửi tín hiệu no. Khi ăn quá nhanh, bạn dễ ăn nhiều hơn nhu cầu thật. Hãy thử đặt đũa xuống giữa các lần gắp, nhai kỹ hơn và tránh vừa ăn vừa lướt điện thoại.\n\nMột mẹo nhỏ là bắt đầu bữa ăn bằng vài ngụm nước và một phần rau. Cách này giúp bữa ăn nhẹ nhàng hơn mà không cần kiêng khem cực đoan.',
    ),
    Article(
      id: 'a3',
      title: 'Đậu và hạt trong bữa ăn sinh viên',
      topic: 'Nguyên liệu',
      readMinutes: 5,
      summary: 'Đậu, hạt và ngũ cốc nguyên hạt rẻ, dễ chuẩn bị và là nền tảng tốt cho chế độ ăn bền vững.',
      content: 'Đậu, hạt và ngũ cốc nguyên hạt thường xuất hiện trong các mô hình ăn uống gắn với sức khỏe lâu dài. Với sinh viên, đây cũng là nhóm thực phẩm dễ mua và dễ bảo quản. Bạn có thể thêm đậu vào salad, nấu cháo yến mạch buổi sáng hoặc dùng một nắm hạt nhỏ cho bữa phụ.\n\nKhông cần thay đổi toàn bộ thực đơn. Chỉ cần thêm một nguyên liệu tốt vào bữa ăn quen thuộc là bạn đã tạo được bước tiến đáng kể.',
    ),
    Article(
      id: 'a4',
      title: 'Chuẩn bị bữa ăn cho tuần bận rộn',
      topic: 'Lập kế hoạch',
      readMinutes: 4,
      summary: 'Một ít chuẩn bị trước giúp bạn tránh bỏ bữa hoặc chọn đồ ăn nhanh khi lịch học dày.',
      content: 'Cuối tuần, hãy chuẩn bị sẵn một loại tinh bột, một nguồn đạm và vài loại rau dễ phối. Ví dụ: cơm gạo lứt, trứng luộc, đậu phụ áp chảo, rau đã rửa và trái cây. Khi cần ăn nhanh, bạn chỉ việc ghép các phần này lại.\n\nSự tiện lợi quyết định rất nhiều đến lựa chọn ăn uống. Khi thực phẩm tốt đã sẵn sàng, bạn ít phải dựa vào quyết tâm trong lúc đói.',
    ),
    Article(
      id: 'a5',
      title: 'Đọc điểm bữa ăn trong Progress',
      topic: 'Theo dõi',
      readMinutes: 2,
      summary: 'Điểm số giúp bạn nhìn xu hướng theo ngày và tuần, không phải để phán xét từng bữa ăn.',
      content: 'Progress tổng hợp điểm từ các bữa ăn đã ghi nhận. Nếu một ngày có nhiều bữa, ứng dụng lấy điểm trung bình để phản ánh chất lượng chung trong ngày. Điểm tuần là trung bình của các ngày có dữ liệu.\n\nHãy dùng điểm số như tín hiệu định hướng: ngày nào thấp thì xem lại thiếu rau, thiếu ngũ cốc nguyên hạt hay thiếu đa dạng. Ngày nào cao thì ghi nhớ công thức đã hiệu quả với bạn.',
    ),
  ];
}
