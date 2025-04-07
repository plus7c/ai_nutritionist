import 'package:flutter/material.dart';

import '../chatpage/chatpage.dart';
import '../home/mainhome.dart';
import '../meals/mealpageAndAddFoodPage.dart';
import '../photologger/foodloggerpage.dart';
import '../stats/stats_page.dart';

class AppTemplate extends StatefulWidget {
  const AppTemplate({super.key});

  @override
  _AppTemplateState createState() => _AppTemplateState();
}

class _AppTemplateState extends State<AppTemplate> {
  int _selectedIndex = 0;
  static final List<Widget> _widgetOptions = <Widget>[
    MainHome(),
    const ChatPage(),
    FoodLoggerPage(),
    StatsPage(),
    MealPage2(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: Colors.green,
        buttonBackgroundColor: Colors.orange,
        height: 90,
        index: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.chat, size: 30, color: Colors.white),
          Icon(Icons.camera_alt, size: 30, color: Colors.white),
          Icon(Icons.bar_chart, size: 30, color: Colors.white),
          Icon(Icons.set_meal, size: 30, color: Colors.white),
        ],
      ),
    );
  }
}

class CurvedNavigationBar extends StatefulWidget {
  final List<Widget> items;
  final int index;
  final Color color;
  final Color buttonBackgroundColor;
  final Color backgroundColor;
  final ValueChanged<int> onTap;
  final double height;

  const CurvedNavigationBar({
    super.key,
    required this.items,
    this.index = 0,
    this.color = Colors.white,
    this.buttonBackgroundColor = Colors.white,
    this.backgroundColor = Colors.blueAccent,
    required this.onTap,
    this.height = 75.0,
  });

  @override
  _CurvedNavigationBarState createState() => _CurvedNavigationBarState();
}

class _CurvedNavigationBarState extends State<CurvedNavigationBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _endingIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));
    _endingIndex = widget.index;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none, alignment: Alignment.bottomCenter,
        children: <Widget>[
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, widget.height),
            painter: CurvedPainter(widget.color),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: widget.items.map((item) {
              int index = widget.items.indexOf(item);
              return GestureDetector(
                onTap: () {
                  widget.onTap(index);
                  setState(() {
                    _endingIndex = index;
                  });
                  _animationController.forward(from: 0);
                },
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _endingIndex == index ? -_animation.value * 20 : 0),
                      child: child,
                    );
                  },
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: Center(child: item),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class CurvedPainter extends CustomPainter {
  final Color color;

  CurvedPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path = Path()
      ..moveTo(0, 20)
      ..quadraticBezierTo(size.width / 2, 0, size.width, 20)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}