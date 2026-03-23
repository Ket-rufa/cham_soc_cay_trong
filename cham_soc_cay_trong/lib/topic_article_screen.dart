import 'package:flutter/material.dart';

class TopicSection {
  final String heading;
  final String body;
  final List<String> bullets;

  const TopicSection({
    required this.heading,
    required this.body,
    this.bullets = const [],
  });
}

class TopicArticle {
  final String title;
  final String subtitle;
  final String category;
  final String readTime;
  final IconData icon;
  final Color startColor;
  final Color endColor;
  final List<String> quickTips;
  final List<TopicSection> sections;

  const TopicArticle({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.readTime,
    required this.icon,
    required this.startColor,
    required this.endColor,
    required this.quickTips,
    required this.sections,
  });
}

const List<TopicArticle> demoTopicArticles = [
  TopicArticle(
    title: '5 loại rau dễ trồng tại nhà',
    subtitle: 'Bắt đầu với những loại rau ngắn ngày, ít công chăm mà vẫn dễ thu hoạch.',
    category: 'Rau tại nhà',
    readTime: '4 phút',
    icon: Icons.eco_outlined,
    startColor: Color(0xFF7CCF7A),
    endColor: Color(0xFF2FAE66),
    quickTips: [
      'Ưu tiên chậu có lỗ thoát nước.',
      'Đặt chậu nơi có nắng nhẹ 4-6 giờ mỗi ngày.',
      'Chỉ tưới khi lớp đất mặt đã bắt đầu khô.',
    ],
    sections: [
      TopicSection(
        heading: 'Vì sao nên bắt đầu từ rau dễ trồng',
        body:
            'Nếu mới tập trồng cây, bạn nên chọn rau lớn nhanh, dễ quan sát và dễ sửa sai. Nhóm rau này giúp bạn làm quen với đất, nước và ánh sáng mà không cần quy trình quá phức tạp.',
      ),
      TopicSection(
        heading: '5 lựa chọn để bắt đầu',
        body: 'Đây là những loại rau phù hợp với ban công, sân thượng hoặc cửa sổ có nắng:',
        bullets: [
          'Rau muống: lên nhanh, dễ nảy mầm, cắt xong vẫn có thể lên đợt mới.',
          'Cải xanh: chu kỳ ngắn, lá phát triển nhanh và dễ nhận biết thiếu nước.',
          'Xà lách: hợp với chậu nông, dễ ăn sống và không cần chăm quá tay.',
          'Mồng tơi: chịu nóng tốt, leo nhanh và thu hoạch được nhiều lần.',
          'Húng quế: vừa làm rau vừa xua một số côn trùng nhỏ.',
        ],
      ),
      TopicSection(
        heading: 'Cách trồng nhanh trong chậu',
        body: 'Bạn có thể bắt đầu đơn giản, không cần dùng quá nhiều vật tư.',
        bullets: [
          'Trộn đất tơi xốp với phân hữu cơ hoai mục.',
          'Gieo hạt mỏng, phủ một lớp đất nhẹ rồi phun sương.',
          'Khi cây có 2-3 lá thật, tỉa bớt cây yếu để cây còn lại có chỗ phát triển.',
          'Bổ sung phân hữu cơ loãng 7-10 ngày một lần.',
        ],
      ),
      TopicSection(
        heading: 'Dấu hiệu cây đang phát triển tốt',
        body:
            'Lá mới ra đều, màu xanh tự nhiên, thân đứng và đất không bị úi nước là những dấu hiệu tích cực. Nếu lá nhợt màu, mềm hoặc vàng nhanh, bạn nên kiểm tra lại lịch tưới và ánh sáng.',
      ),
    ],
  ),
  TopicArticle(
    title: 'Bao lâu nên tưới rau một lần?',
    subtitle: 'Không có lịch tưới cố định cho mọi vườn rau; hãy nhìn đất trước khi nhìn đồng hồ.',
    category: 'Tưới nước',
    readTime: '5 phút',
    icon: Icons.water_drop_outlined,
    startColor: Color(0xFF7EC8FF),
    endColor: Color(0xFF377DFF),
    quickTips: [
      'Tưới vào sáng sớm là dễ nhất.',
      'Chạm tay vào đất sâu 2-3 cm trước khi tưới.',
      'Ngày mát trời và ngày mưa cần giảm lượng nước.',
    ],
    sections: [
      TopicSection(
        heading: 'Điều gì quyết định tần suất tưới',
        body:
            'Tần suất tưới phụ thuộc vào thời tiết, kích thước chậu, loại đất và độ lớn của cây. Chậu nhỏ khô nhanh hơn chậu lớn. Đất tơi xốp thoát nước nhanh hơn đất nén chặt. Rau ăn lá thường cần độ ẩm ổn định hơn cây gia vị.',
      ),
      TopicSection(
        heading: 'Khung tham khảo để nhớ',
        body: 'Bạn có thể bắt đầu bằng mốc đơn giản sau rồi điều chỉnh theo thực tế:',
        bullets: [
          'Ngày nắng nóng: kiểm tra đất mỗi sáng, có thể cần tưới 1 lần/ngày.',
          'Ngày mát trời: thường 1-2 ngày mới cần tưới.',
          'Sau khi mới gieo hạt: giữ ẩm bằng phun sương nhẹ, tránh xói mặt đất.',
          'Khi cây đã lớn: tưới đẫm hơn nhưng giãn cách ra để rễ ăn sâu.',
        ],
      ),
      TopicSection(
        heading: 'Cách kiểm tra đất đúng nhất',
        body:
            'Đưa ngón tay xuống đất khoảng 2-3 cm. Nếu đất còn ẩm, chưa cần tưới. Nếu đất khô, vụn và rời, bạn mới bổ sung nước. Cách này chính xác hơn việc tưới theo giờ cố định.',
      ),
      TopicSection(
        heading: 'Lỗi thường gặp',
        body: 'Nhiều người tưới ít nhưng quá nhiều lần khiến rễ nông, cây yếu và dễ nấm bệnh.',
        bullets: [
          'Không để đĩa lót nước đọng quá lâu dưới chậu.',
          'Không tưới giữa trưa nắng gắt nếu không thật sự cần thiết.',
          'Nếu lá héo xuống dù buổi trưa, hãy chờ tới chiều kiểm tra lại trước khi kết luận cây thiếu nước.',
        ],
      ),
    ],
  ),
  TopicArticle(
    title: 'Xử lý sâu bệnh nhẹ không cần thuốc mạnh',
    subtitle: 'Phát hiện sớm và xử lý đúng điểm thường hiệu quả hơn phun rộng cả vườn.',
    category: 'Sâu bệnh',
    readTime: '6 phút',
    icon: Icons.shield_moon_outlined,
    startColor: Color(0xFFFFC977),
    endColor: Color(0xFFF27A3D),
    quickTips: [
      'Kiểm tra mặt dưới lá 2-3 ngày một lần.',
      'Cắt bỏ lá bị bệnh sớm để tránh lây lan.',
      'Giữ vườn thông thoáng để giảm ẩm độ tồn đọng.',
    ],
    sections: [
      TopicSection(
        heading: 'Nhận biết sớm trước khi bùng dịch',
        body:
            'Lá bị chấm trắng, đốm nâu nhỏ, vết nhai lỗ chỗm hoặc mặt dưới lá có côn trùng ti li là dấu hiệu bạn nên xử lý ngay. Xử lý ở giai đoạn nhẹ sẽ tiết kiệm công hơn rất nhiều so với để lan rộng.',
      ),
      TopicSection(
        heading: 'Các bước xử lý an toàn',
        body: 'Bạn có thể áp dụng quy trình nhẹ trước khi nghĩ đến thuốc mạnh:',
        bullets: [
          'Tách chậu bị nhiễm khỏi khu vực còn lại.',
          'Cắt bỏ lá hỏng, lá có trứng và lá chạm đất.',
          'Rửa nhẹ mặt dưới lá bằng nước sạch nếu sâu còn ít.',
          'Phun dung dịch xà phòng sinh học loãng vào lúc chiều mát.',
        ],
      ),
      TopicSection(
        heading: 'Phòng bệnh quan trọng hơn chữa bệnh',
        body: 'Môi trường bị ngậm nước, quá rậm hoặc thiếu gió là điều kiện để sâu bệnh quay lại.',
        bullets: [
          'Không trồng quá dày để lá nhanh khô sau khi tưới.',
          'Vệ sinh chậu, kệ và lá rụng định kỳ.',
          'Luân phiên vị trí cây nếu một góc vườn quá ẩm.',
        ],
      ),
      TopicSection(
        heading: 'Khi nào nên loại bỏ cây',
        body:
            'Nếu cây đã thối gốc, nhiễm nấm lan rộng hoặc côn trùng xuất hiện mật độ cao liên tục, nên loại bỏ cây bệnh để bảo vệ cả khay rau. Đất cũ cần được thay hoặc xử lý lại trước khi trồng đợt mới.',
      ),
    ],
  ),
];

class TopicArtwork extends StatelessWidget {
  final TopicArticle article;
  final double height;
  final bool compact;

  const TopicArtwork({
    super.key,
    required this.article,
    this.height = 180,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 18 : 28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            article.startColor,
            article.endColor,
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double iconSize = compact ? 36 : 58;
          final double labelFont = compact ? 10 : 12;
          final double titleFont = compact ? 15 : 20;

          return Stack(
            children: [
              Positioned(
                top: -18,
                right: -10,
                child: _BlurCircle(
                  size: compact ? 72 : 110,
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),
              Positioned(
                bottom: -26,
                left: -12,
                child: _BlurCircle(
                  size: compact ? 86 : 132,
                  color: Colors.black.withValues(alpha: 0.10),
                ),
              ),
              Positioned(
                top: compact ? 14 : 18,
                left: compact ? 14 : 20,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 10 : 12,
                    vertical: compact ? 5 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    article.category.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: labelFont,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: compact ? 18 : 24,
                bottom: compact ? 16 : 24,
                child: Transform.rotate(
                  angle: -0.12,
                  child: Container(
                    width: compact ? 68 : 92,
                    height: compact ? 68 : 92,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(compact ? 20 : 28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Icon(
                      article.icon,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: compact ? 14 : 20,
                right: compact ? 86 : 128,
                bottom: compact ? 16 : 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      article.title,
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleFont,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 10),
                    Text(
                      compact ? article.readTime : article.subtitle,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: compact ? 11 : 13,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class TopicArticleScreen extends StatelessWidget {
  final TopicArticle article;

  const TopicArticleScreen({
    super.key,
    required this.article,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          article.category,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TopicArtwork(article: article, height: 220),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: Icons.menu_book_outlined,
                  label: article.readTime,
                ),
                _MetaChip(
                  icon: article.icon,
                  label: article.category,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              article.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              article.subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.black54,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mẹo nhanh',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...article.quickTips.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 7),
                            decoration: BoxDecoration(
                              color: article.endColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...article.sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: _SectionBlock(
                  title: section.heading,
                  body: section.body,
                  bullets: section.bullets,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final String title;
  final String body;
  final List<String> bullets;

  const _SectionBlock({
    required this.title,
    required this.body,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.65,
              color: Colors.black87,
            ),
          ),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...bullets.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '•',
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.2,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bullet,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _BlurCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
