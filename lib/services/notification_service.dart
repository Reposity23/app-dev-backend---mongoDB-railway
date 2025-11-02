import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  void show(
    BuildContext context,
    {required String name, required String toyName}
  ) {
    // Play the sound
    _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    
    // Get the overlay state
    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16, // Position below status bar
        left: 16,
        right: 16,
        child: TopSnackBar(
          name: name,
          toyName: toyName,
          onDismiss: () {
            overlayEntry?.remove();
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class TopSnackBar extends StatefulWidget {
  final String name;
  final String toyName;
  final VoidCallback onDismiss;

  const TopSnackBar({Key? key, required this.name, required this.toyName, required this.onDismiss}) : super(key: key);

  @override
  _TopSnackBarState createState() => _TopSnackBarState();
}

class _TopSnackBarState extends State<TopSnackBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -2.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(text: widget.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const TextSpan(text: ', your order '),
                          TextSpan(text: widget.toyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const TextSpan(text: ' has been delivered!'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Leaving a review is much appreciated!',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.grey[500]),
                onPressed: () {
                   _controller.reverse().then((_) => widget.onDismiss());
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
