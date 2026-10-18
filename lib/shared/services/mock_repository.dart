import '../../features/food_diary/models/food_item.dart';
import '../../features/food_diary/models/meal.dart';
import '../../features/knowledge/models/article.dart';
import 'app_repository.dart';

class MockRepository implements AppRepository {
  @override
  List<FoodItem> get foods => const [
    FoodItem(
      id: 'breakfast_oat_banana_walnut',
      name: 'Cháo yến mạch chuối và óc chó',
      category: 'breakfast',
      emoji: '🥣',
    ),
    FoodItem(
      id: 'breakfast_wholegrain_avocado_tomato',
      name: 'Bánh mì nguyên cám với bơ và cà chua',
      category: 'breakfast',
      emoji: '🥑',
    ),
    FoodItem(
      id: 'breakfast_brown_rice_mushroom',
      name: 'Cháo gạo lứt nấm',
      category: 'breakfast',
      emoji: '🍚',
    ),
    FoodItem(
      id: 'breakfast_soymilk_bread',
      name: 'Sữa đậu nành và bánh mì nguyên cám',
      category: 'breakfast',
      emoji: '🥛',
    ),
    FoodItem(
      id: 'breakfast_oat_apple_almond',
      name: 'Yến mạch ngâm táo và hạnh nhân',
      category: 'breakfast',
      emoji: '🍎',
    ),
    FoodItem(
      id: 'breakfast_sweet_potato_soymilk',
      name: 'Khoai lang luộc và sữa đậu nành',
      category: 'breakfast',
      emoji: '🍠',
    ),
    FoodItem(
      id: 'breakfast_tofu_mushroom_spinach',
      name: 'Đậu phụ xào nấm và rau bina',
      category: 'breakfast',
      emoji: '🥬',
    ),
    FoodItem(
      id: 'breakfast_oat_pear_cinnamon',
      name: 'Cháo yến mạch lê và quế',
      category: 'breakfast',
      emoji: '🍐',
    ),
    FoodItem(
      id: 'breakfast_wholegrain_cereal_fruit',
      name: 'Ngũ cốc nguyên hạt với trái cây',
      category: 'breakfast',
      emoji: '🍓',
    ),
    FoodItem(
      id: 'breakfast_banana_oat_cake',
      name: 'Bánh chuối yến mạch',
      category: 'breakfast',
      emoji: '🍌',
    ),
    FoodItem(
      id: 'breakfast_wholegrain_hummus_bread',
      name: 'Bánh mì nguyên cám phết hummus',
      category: 'breakfast',
      emoji: '🍞',
    ),
    FoodItem(
      id: 'breakfast_brown_rice_pumpkin',
      name: 'Cháo gạo lứt bí đỏ',
      category: 'breakfast',
      emoji: '🎃',
    ),
    FoodItem(
      id: 'lunch_brown_rice_tofu_tomato',
      name: 'Cơm gạo lứt, đậu phụ sốt cà chua',
      category: 'lunch',
      emoji: '🍅',
    ),
    FoodItem(
      id: 'lunch_lentil_vegetable_soup',
      name: 'Súp đậu lăng rau củ',
      category: 'lunch',
      emoji: '🍲',
    ),
    FoodItem(
      id: 'lunch_ginger_steamed_fish_rice_greens',
      name: 'Cá hấp gừng, cơm và rau xanh',
      category: 'lunch',
      emoji: '🐟',
    ),
    FoodItem(
      id: 'lunch_chickpea_vegetable_curry',
      name: 'Cà ri đậu gà rau củ',
      category: 'lunch',
      emoji: '🍛',
    ),
    FoodItem(
      id: 'lunch_tofu_vegetable_soup_rice',
      name: 'Canh rau củ đậu phụ ăn với cơm',
      category: 'lunch',
      emoji: '🥕',
    ),
    FoodItem(
      id: 'lunch_wholegrain_noodles_tomato_mushroom',
      name: 'Mì nguyên cám sốt cà chua và nấm',
      category: 'lunch',
      emoji: '🍝',
    ),
    FoodItem(
      id: 'lunch_tofu_vegetable_spring_rolls',
      name: 'Gỏi cuốn đậu phụ rau củ',
      category: 'lunch',
      emoji: '🌯',
    ),
    FoodItem(
      id: 'lunch_brown_rice_edamame_vegetables',
      name: 'Cơm gạo lứt với edamame và rau củ',
      category: 'lunch',
      emoji: '🥗',
    ),
    FoodItem(
      id: 'lunch_pumpkin_mushroom_tofu_soup',
      name: 'Canh bí đỏ nấu nấm và đậu phụ',
      category: 'lunch',
      emoji: '🎃',
    ),
    FoodItem(
      id: 'lunch_chickpea_grain_salad',
      name: 'Salad đậu gà và ngũ cốc',
      category: 'lunch',
      emoji: '🥗',
    ),
    FoodItem(
      id: 'lunch_sardine_tomato_rice',
      name: 'Cá mòi sốt cà chua và cơm',
      category: 'lunch',
      emoji: '🐟',
    ),
    FoodItem(
      id: 'lunch_tofu_broccoli_mushroom',
      name: 'Đậu phụ xào bông cải và nấm',
      category: 'lunch',
      emoji: '🥦',
    ),
    FoodItem(
      id: 'lunch_wholegrain_pasta_white_beans',
      name: 'Mì Ý nguyên cám nấu đậu trắng',
      category: 'lunch',
      emoji: '🍝',
    ),
    FoodItem(
      id: 'lunch_steamed_egg_mushroom_tofu',
      name: 'Trứng hấp nấm và đậu phụ',
      category: 'lunch',
      emoji: '🥚',
    ),
    FoodItem(
      id: 'lunch_vegetable_lentil_soup',
      name: 'Súp rau củ đậu lăng',
      category: 'lunch',
      emoji: '🥣',
    ),
    FoodItem(
      id: 'dinner_baked_salmon_lemon_vegetables',
      name: 'Cá hồi nướng chanh và rau củ',
      category: 'dinner',
      emoji: '🍣',
    ),
    FoodItem(
      id: 'dinner_tomato_braised_lentils',
      name: 'Đậu lăng hầm cà chua',
      category: 'dinner',
      emoji: '🍅',
    ),
    FoodItem(
      id: 'dinner_braised_tofu_tomato',
      name: 'Đậu phụ kho cà chua',
      category: 'dinner',
      emoji: '🍲',
    ),
    FoodItem(
      id: 'dinner_vegetable_mushroom_tofu_hotpot',
      name: 'Lẩu rau nấm đậu phụ',
      category: 'dinner',
      emoji: '🍄',
    ),
    FoodItem(
      id: 'dinner_roasted_pumpkin_chickpea',
      name: 'Bí đỏ nướng với đậu gà',
      category: 'dinner',
      emoji: '🎃',
    ),
    FoodItem(
      id: 'dinner_steamed_fish_boiled_vegetables',
      name: 'Cá hấp gừng và rau luộc',
      category: 'dinner',
      emoji: '🐟',
    ),
    FoodItem(
      id: 'dinner_barley_mushroom_soup',
      name: 'Súp lúa mạch nấu nấm',
      category: 'dinner',
      emoji: '🥣',
    ),
    FoodItem(
      id: 'dinner_white_beans_tomato_spinach',
      name: 'Đậu trắng hầm cà chua và rau bina',
      category: 'dinner',
      emoji: '🥬',
    ),
    FoodItem(
      id: 'dinner_bitter_melon_tofu_mushroom',
      name: 'Canh khổ qua nhồi đậu phụ nấm',
      category: 'dinner',
      emoji: '🥒',
    ),
    FoodItem(
      id: 'dinner_wholegrain_noodles_zucchini_mushroom',
      name: 'Mì nguyên cám xào bí ngòi và nấm',
      category: 'dinner',
      emoji: '🍜',
    ),
    FoodItem(
      id: 'dinner_steamed_egg_tomato_tofu',
      name: 'Trứng hấp cà chua và đậu phụ',
      category: 'dinner',
      emoji: '🥚',
    ),
    FoodItem(
      id: 'dinner_grilled_sardine_lemon',
      name: 'Cá mòi nướng chanh',
      category: 'dinner',
      emoji: '🐟',
    ),
    FoodItem(
      id: 'dinner_roasted_eggplant_chickpea_tomato',
      name: 'Cà tím nướng đậu gà sốt cà chua',
      category: 'dinner',
      emoji: '🍆',
    ),
    FoodItem(
      id: 'dinner_brown_rice_tofu_edamame',
      name: 'Cơm gạo lứt với đậu phụ và edamame',
      category: 'dinner',
      emoji: '🍚',
    ),
    FoodItem(
      id: 'dinner_mixed_beans_vegetable_soup',
      name: 'Súp đậu và rau củ hỗn hợp',
      category: 'dinner',
      emoji: '🥣',
    ),
    FoodItem(
      id: 'snack_guava',
      name: 'Ổi tươi',
      category: 'snack',
      emoji: '🍐',
    ),
    FoodItem(
      id: 'snack_unsalted_nuts',
      name: 'Hỗn hợp hạt không muối',
      category: 'snack',
      emoji: '🥜',
    ),
    FoodItem(
      id: 'snack_orange_tangerine',
      name: 'Cam hoặc quýt tươi',
      category: 'snack',
      emoji: '🍊',
    ),
    FoodItem(
      id: 'snack_roasted_chickpeas',
      name: 'Đậu gà rang',
      category: 'snack',
      emoji: '🫘',
    ),
    FoodItem(id: 'nuts', name: 'Táo và óc chó', category: 'snack', emoji: '🍎'),
    FoodItem(
      id: 'snack_steamed_edamame',
      name: 'Đậu nành Nhật hấp',
      category: 'snack',
      emoji: '🫛',
    ),
    FoodItem(
      id: 'snack_unsweetened_soy_yogurt_fruit',
      name: 'Sữa chua đậu nành không đường với trái cây',
      category: 'snack',
      emoji: '🥣',
    ),
    FoodItem(
      id: 'snack_boiled_corn',
      name: 'Ngô luộc',
      category: 'snack',
      emoji: '🌽',
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
