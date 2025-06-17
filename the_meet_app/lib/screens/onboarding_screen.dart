import 'package:flutter/material.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'Discover and Join Meets',
      'description': 'Find interesting meetups happening around you. Connect with people who share your interests.',
      'color': const Color(0xFF6C63FF),
      'icon': Icons.explore,
    },
    {
      'title': 'Create Your Own Meets',
      'description': 'Organize walks, location meetups, activities or attend events together with new friends.',
      'color': const Color(0xFF00C853),
      'icon': Icons.add_location_alt,
    },
    {
      'title': 'Safe and Secure',
      'description': 'Your safety is our priority. All users are verified and meets follow our community guidelines.',
      'color': const Color(0xFFFF5722),
      'icon': Icons.shield,
    },
    {
      'title': 'Chat with Participants',
      'description': 'Communicate with other meetup attendees before, during, and after your meetups.',
      'color': const Color(0xFF2196F3),
      'icon': Icons.chat_bubble,
    },
    {
      'title': 'Ready to Get Started?',
      'description': 'Join our community today and start making meaningful connections.',
      'color': const Color(0xFF9C27B0),
      'icon': Icons.emoji_people,
      'isLast': true,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToAuthScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Widget buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.deepPurple : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) {
                    final data = _onboardingData[index];
                    return OnboardingPage(
                      title: data['title'],
                      description: data['description'],
                      color: data['color'],
                      icon: data['icon'],
                      isLast: data['isLast'] ?? false,
                      onGetStarted: _goToAuthScreen,
                    );
                  },
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _onboardingData.length,
                        (index) => buildDot(index: index),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentPage != _onboardingData.length - 1)
                            TextButton(
                              onPressed: _goToAuthScreen,
                              child: const Text('Skip'),
                            )
                          else
                            const SizedBox(width: 60),
                          ElevatedButton(
                            onPressed: () {
                              if (_currentPage == _onboardingData.length - 1) {
                                _goToAuthScreen();
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.ease,
                                );
                              }
                            },
                            child: Text(_currentPage == _onboardingData.length - 1 ? 'Get Started' : 'Next'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final bool isLast;
  final VoidCallback onGetStarted;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    this.isLast = false,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, size: 56, color: color),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          if (isLast) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onGetStarted,
              child: const Text('Get Started'),
            ),
          ],
        ],
      ),
    );
  }
}
