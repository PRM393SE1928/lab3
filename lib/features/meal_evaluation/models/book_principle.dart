enum PrincipleSourceType { bookVerified, longevaCriteria, generalNutrition }

class BookPrinciple {
  const BookPrinciple({
    required this.id,
    required this.name,
    required this.description,
    required this.sourceType,
    this.sourceChapter,
    this.sourcePage,
    this.sourcePdfPage,
    this.evaluationCriteria = const [],
    this.applicableAgeGroups = const [],
  });

  final String id;
  final String name;
  final String description;
  final PrincipleSourceType sourceType;
  final String? sourceChapter;
  final int? sourcePage;
  final int? sourcePdfPage;
  final List<String> evaluationCriteria;
  final List<String> applicableAgeGroups;

  String get sourceLabel => switch (sourceType) {
    PrincipleSourceType.bookVerified => 'Đã xác minh từ sách',
    PrincipleSourceType.longevaCriteria => 'Tiêu chí LONGEVA',
    PrincipleSourceType.generalNutrition => 'Dinh dưỡng tham khảo',
  };

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'sourceType': sourceType.name,
    'sourceChapter': sourceChapter,
    'sourcePage': sourcePage,
    'sourcePdfPage': sourcePdfPage,
    'evaluationCriteria': evaluationCriteria,
    'applicableAgeGroups': applicableAgeGroups,
  };
}

class BookPrinciplesRepository {
  const BookPrinciplesRepository();

  List<BookPrinciple> get principles => const [
    BookPrinciple(
      id: 'book_plant_based_nuts_fish',
      name: 'Ưu tiên thực vật, các loại hạt và một phần cá',
      description: 'Đoạn nghiên cứu người sống trăm tuổi mô tả chế độ chủ yếu thực vật, các loại hạt và một phần cá.',
      sourceChapter: 'Chapter 4 – The Longevity Diet',
      sourceType: PrincipleSourceType.bookVerified,
      sourcePage: 79,
      sourcePdfPage: 11,
      evaluationCriteria: [
        'Đối chiếu món đã xác nhận; không yêu cầu mọi bữa đều có cá hoặc hạt.',
        'Một bữa không đủ để kết luận tần suất ăn hoặc chế độ ăn dài hạn.',
      ],
      applicableAgeGroups: ['age18To59', 'age60Plus'],
    ),
    BookPrinciple(
      id: 'book_complex_carbohydrates',
      name: 'Carbohydrate phức hợp từ đậu và thực vật',
      description: 'Nguồn mô tả carbohydrate phức hợp từ đậu và thực phẩm thực vật; bảng so sánh nêu đậu và ngũ cốc chưa tinh chế.',
      sourceChapter: 'Chapter 4 – The Longevity Diet',
      sourceType: PrincipleSourceType.bookVerified,
      sourcePage: 79,
      sourcePdfPage: 11,
      evaluationCriteria: [
        'Chỉ kết luận khi biết rõ loại thực phẩm; cơm trắng không tự động là ngũ cốc nguyên hạt.',
        'Không suy đoán tỷ lệ dinh dưỡng hoặc lượng carbohydrate từ ảnh.',
      ],
      applicableAgeGroups: ['age18To59', 'age60Plus'],
    ),
    BookPrinciple(
      id: 'book_limit_sugars_and_fats',
      name: 'Hạn chế đường và chất béo bão hòa hoặc trans',
      description: 'Đoạn nghiên cứu người sống trăm tuổi mô tả mức đường và chất béo bão hòa/trans thấp.',
      sourceChapter: 'Chapter 4 – The Longevity Diet',
      sourceType: PrincipleSourceType.bookVerified,
      sourcePage: 79,
      sourcePdfPage: 11,
      evaluationCriteria: [
        'Nếu chưa có thành phần, loại dầu hoặc lượng đường do người dùng cung cấp, trả INSUFFICIENT_DATA.',
        'Không suy đoán loại dầu, đường, muối hoặc lượng chất béo chỉ từ ảnh.',
      ],
      applicableAgeGroups: ['age18To59', 'age60Plus'],
    ),
    BookPrinciple(
      id: 'book_food_sources',
      name: 'Nguồn đạm và chất béo trong chế độ ăn',
      description: 'Bảng so sánh ghi đậu, ngũ cốc chưa tinh chế và dầu ô liu ở mức cao; thịt, bơ và một số sản phẩm động vật ở mức rất thấp. Đây là mô tả chế độ ăn dài hạn cho người lớn.',
      sourceChapter: 'Chapter 9 – bảng so sánh Mediterranean / Longevity Diet',
      sourceType: PrincipleSourceType.bookVerified,
      sourcePage: 165,
      sourcePdfPage: 34,
      evaluationCriteria: [
        'Chỉ đối chiếu nguồn thực phẩm đã xác nhận; không gán lượng dầu hay kết luận khẩu phần.',
        'Bảng tiếp tục ở trang in 166 (PDF 35). Không đánh giá chế độ dài hạn từ một bữa.',
      ],
      applicableAgeGroups: ['age18To59', 'age60Plus'],
    ),
    BookPrinciple(
      id: 'book_age_context',
      name: 'Điều chỉnh theo tuổi và dữ liệu còn thiếu',
      description: 'Bảng tại trang in 166 phân biệt mức protein trước và sau khoảng 65–70 tuổi, đồng thời nhấn mạnh duy trì khối cơ ở tuổi cao.',
      sourceChapter: 'Chapter 9 – bảng so sánh Mediterranean / Longevity Diet',
      sourceType: PrincipleSourceType.bookVerified,
      sourcePage: 166,
      sourcePdfPage: 35,
      evaluationCriteria: [
        'Không dùng ngưỡng nhóm tuổi 60+ như thể tương đương 65–70 tuổi.',
        'Không đặt mục tiêu protein, cân nặng, nhịn ăn hoặc năng lượng từ một ảnh và hồ sơ cơ bản.',
        'Với người dưới 18 tuổi, không áp dụng chế độ hạn chế của người lớn.',
        'Không có tuổi hoặc khẩu phần thì nêu thiếu dữ liệu.',
      ],
      applicableAgeGroups: ['age18To59', 'age60Plus'],
    ),
  ];

  List<Map<String, Object?>> get forAi =>
      principles.map((principle) => principle.toJson()).toList();
}
