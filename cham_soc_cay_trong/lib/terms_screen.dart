import 'package:cham_soc_cay_trong/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          context.tr('settings.terms'),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Điều khoản và Dịch vụ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cập nhật lần cuối: 22/05/2026',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Chấp nhận điều khoản',
              'Bằng việc truy cập và sử dụng ứng dụng Chăm Sóc Cây Trồng, bạn đồng ý tuân thủ các điều khoản và dịch vụ được quy định dưới đây. Nếu bạn không đồng ý với bất kỳ phần nào của các điều khoản này, vui lòng không sử dụng ứng dụng của chúng tôi.',
            ),
            _buildSection(
              '2. Quyền và Trách nhiệm của Người dùng',
              '• Bạn cam kết cung cấp thông tin chính xác khi đăng ký tài khoản.\n• Bạn chịu trách nhiệm bảo mật thông tin tài khoản và mật khẩu của mình.\n• Không sử dụng ứng dụng cho các mục đích bất hợp pháp hoặc vi phạm quyền lợi của người khác.',
            ),
            _buildSection(
              '3. Dịch vụ cung cấp',
              'Ứng dụng Chăm Sóc Cây Trồng cung cấp các công cụ giúp người dùng nhận diện cây trồng, tạo lịch tưới nước, bón phân và theo dõi quá trình phát triển của cây. Chúng tôi không đảm bảo tính chính xác tuyệt đối của các tính năng nhận diện do phụ thuộc vào thuật toán AI và chất lượng hình ảnh.',
            ),
            _buildSection(
              '4. Quyền sở hữu trí tuệ',
              'Tất cả nội dung, hình ảnh, tính năng và giao diện của ứng dụng đều thuộc quyền sở hữu của Chăm Sóc Cây Trồng. Việc sao chép, chỉnh sửa hoặc sử dụng vào mục đích thương mại mà không có sự cho phép bằng văn bản là vi phạm pháp luật.',
            ),
            _buildSection(
              '5. Quyền riêng tư',
              'Chúng tôi coi trọng quyền riêng tư của bạn. Vui lòng tham khảo Chính sách Quyền riêng tư của chúng tôi để biết thêm chi tiết về cách chúng tôi thu thập, sử dụng và bảo vệ dữ liệu cá nhân của bạn.',
            ),
            _buildSection(
              '6. Thay đổi điều khoản',
              'Chúng tôi có quyền cập nhật và thay đổi các điều khoản này bất kỳ lúc nào. Những thay đổi sẽ có hiệu lực ngay khi được đăng tải trên ứng dụng. Việc bạn tiếp tục sử dụng ứng dụng đồng nghĩa với việc bạn chấp nhận những thay đổi đó.',
            ),
            _buildSection(
              '7. Liên hệ',
              'Nếu bạn có bất kỳ câu hỏi nào về các Điều khoản và Dịch vụ này, vui lòng liên hệ với chúng tôi qua email: nket865@gmail.com.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
