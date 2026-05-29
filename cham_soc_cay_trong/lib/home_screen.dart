import 'dart:convert';
import 'dart:typed_data';

import 'package:cham_soc_cay_trong/camera_screen.dart';
import 'package:cham_soc_cay_trong/cay_trong_cua_toi.dart';
import 'package:cham_soc_cay_trong/l10n/app_localizations.dart';
import 'package:cham_soc_cay_trong/more_screen.dart';
import 'package:cham_soc_cay_trong/pest_disease_guide_screen.dart';
import 'package:cham_soc_cay_trong/plant_category_screen.dart';
import 'package:cham_soc_cay_trong/topic_article_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'care_schedule_screen.dart';
import 'package:cham_soc_cay_trong/top_toast_util.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color lightBg = Colors.white;
  final Color greenCta = const Color(0xFF25BB57);
  final Color bottomNavBg = Colors.white;
  final Color bottomNavInactive = Colors.grey[400]!;

  int _selectedIndex = 0;
  int _homeRefreshToken = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        _homeRefreshToken++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _HomeTabBody(
        onSwitchTab: _onItemTapped,
        refreshToken: _homeRefreshToken,
      ),
      const PlantCategoryScreen(),
      MyGardenTab(),
      MoreScreen(
        onProfileUpdated: (String message) {
          _onItemTapped(0);
          TopToast.show(context, message, backgroundColor: Colors.green);
        },
      ),
    ];

    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CameraScreen(),
            ),
          );
        },
        backgroundColor: greenCta,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: bottomNavBg,
        elevation: 10,
        clipBehavior: Clip.antiAlias, // Giữ notch gọn gàng không bị chèn màu
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(
                  icon: Icons.home,
                  label: context.tr('nav.home'),
                  index: 0,
                ),
                _buildBottomNavItem(
                  icon: Icons.local_florist,
                  label: context.tr('nav.plantList'),
                  index: 1,
                ),
                const SizedBox(width: 40), // Khoảng trống cho FAB
                _buildBottomNavItem(
                  icon: Icons.yard,
                  label: context.tr('nav.yourGarden'),
                  index: 2,
                ),
                _buildBottomNavItem(
                  icon: Icons.apps,
                  label: context.tr('nav.more'),
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isActive = _selectedIndex == index;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? greenCta : bottomNavInactive),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? greenCta : bottomNavInactive,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTabBody extends StatefulWidget {
  final void Function(int) onSwitchTab;
  final int refreshToken;

  const _HomeTabBody({
    required this.onSwitchTab,
    required this.refreshToken,
  });

  @override
  State<_HomeTabBody> createState() => __HomeTabBodyState();
}

class __HomeTabBodyState extends State<_HomeTabBody> {
  final Color greenCta = const Color(0xFF25BB57);
  final Color darkText = Colors.black87;
  final Color greyText = Colors.grey[600]!;

  String userName = '';
  Uint8List? userAvatarBytes;
  String? userAvatarUrl;
  List<TopicArticle> _topicArticles = demoTopicArticles;
  bool _isLoadingTopicArticles = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadTopicArticles();
  }

  @override
  void didUpdateWidget(covariant _HomeTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String savedName = prefs.getString('userName') ?? '';
    final String? avatarUrl = prefs.getString('userAvatarUrl');
    final String? avatarBase64 = prefs.getString('userAvatarBase64');

    Uint8List? avatarBytes;
    if (avatarBase64 != null && avatarBase64.isNotEmpty) {
      try {
        avatarBytes = base64Decode(avatarBase64);
      } catch (_) {
        avatarBytes = null;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      userName = savedName;
      userAvatarUrl = avatarUrl;
      userAvatarBytes = avatarBytes;
    });
  }

  Future<void> _loadTopicArticles() async {
    setState(() {
      _isLoadingTopicArticles = true;
    });

    try {
      final url = Uri.parse('${Config.apiUrl}/articles');
      final response = await http.get(url, headers: Config.apiHeaders);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final dynamic rawArticles = decoded is Map ? decoded['data'] : decoded;

        if (rawArticles is List) {
          final articles = rawArticles
              .whereType<Map>()
              .map((item) => TopicArticle.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList();

          if (articles.isNotEmpty && mounted) {
            setState(() {
              _topicArticles = articles;
            });
          }
        }
      }
    } catch (_) {
      // Giữ dữ liệu mẫu khi API chưa chạy hoặc chưa migrate bảng articles.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTopicArticles = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildProfileBar(),
            const SizedBox(height: 24),
            _buildIdentifySectionTitle(),
            const SizedBox(height: 16),
            _buildImageUploadBox(context),
            const SizedBox(height: 20),
            _buildIdentifyButton(context),
            const SizedBox(height: 24),
            _buildFunctionButtons(),
            const SizedBox(height: 32),
            _buildTopicsSection(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: greenCta,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              userName.isEmpty ? context.tr('home.newUser') : userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: SizedBox(
                width: 44,
                height: 44,
                child: _buildAvatarImage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage() {
    if (userAvatarBytes != null) {
      return Image.memory(
        userAvatarBytes!,
        fit: BoxFit.cover,
      );
    }

    if (userAvatarUrl != null && userAvatarUrl!.isNotEmpty) {
      return Image.network(
        Config.getImageUrl(userAvatarUrl!),
        headers: Config.imageHeaders,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Image.asset(
            'assets/avatar.png',
            fit: BoxFit.cover,
          );
        },
      );
    }

    return Image.asset(
      'assets/avatar.png',
      fit: BoxFit.cover,
    );
  }

  Widget _buildIdentifySectionTitle() {
    return Row(
      children: [
        Icon(Icons.eco_rounded, color: greenCta, size: 28),
        const SizedBox(width: 8),
        Text(
          context.tr('home.identifyTitle'),
          style: TextStyle(
            color: darkText,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadBox(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CameraScreen(),
          ),
        );
      },
      child: Container(
        height: 250,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.grey[400]!,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                color: Colors.grey[400],
                size: 80,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('home.identifyHint'),
                style: TextStyle(
                  color: greyText,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentifyButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CameraScreen(),
            ),
          );
        },
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        label: Text(
          context.tr('home.identifyNow'),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: greenCta,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFunctionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFunctionItem(
          Icons.calendar_month_rounded,
          context.tr('home.careSchedule'),
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CareScheduleScreen(),
              ),
            );
          },
        ),
        _buildFunctionItem(
          Icons.menu_book_rounded,
          context.tr('home.guide'),
          const Color(0xFFE3F2FD),
          const Color(0xFF1565C0),
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            final plantId = prefs.getString('active_plant_id');
            final plantName = prefs.getString('active_plant_name');

            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PestDiseaseGuideScreen(
                  plantId: plantId ?? '',
                  plantName: (plantName != null && plantName.isNotEmpty)
                      ? plantName
                      : context.tr('common.all'),
                ),
              ),
            );
          },
        ),
        _buildFunctionItem(
          Icons.biotech_rounded,
          "Nhận diện bệnh",
          const Color(0xFFFBE9E7),
          const Color(0xFFD84315),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const CameraScreen(initialDiseaseMode: true),
              ),
            );
          },
        ),
        _buildFunctionItem(
          Icons.yard_outlined,
          context.tr('nav.yourGarden'),
          const Color(0xFFF0FFF4),
          const Color(0xFF38A169),
          onTap: () => widget.onSwitchTab(2),
        ),
      ],
    );
  }

  Widget _buildFunctionItem(
    IconData icon,
    String label,
    Color bgColor,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: Ink(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                splashColor: iconColor.withOpacity(0.15),
                highlightColor: iconColor.withOpacity(0.08),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 30),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: darkText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('home.topics'),
          style: TextStyle(
            color: darkText,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingTopicArticles)
          const LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: Colors.transparent,
          ),
        if (_isLoadingTopicArticles) const SizedBox(height: 12),
        SizedBox(
          height: 228,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _topicArticles
                .map((article) => _buildTopicCard(context, article))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTopicCard(BuildContext context, TopicArticle article) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TopicArticleScreen(article: article),
          ),
        );
      },
      child: Container(
        width: 188,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TopicArtwork(
              article: article,
              height: 132,
              compact: true,
            ),
            const SizedBox(height: 10),
            Text(
              article.title,
              style: TextStyle(
                color: darkText,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              article.subtitle,
              style: TextStyle(
                color: greyText,
                fontSize: 12,
                height: 1.35,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
