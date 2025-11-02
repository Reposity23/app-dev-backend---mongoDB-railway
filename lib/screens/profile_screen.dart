import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
        // In a real app, you would upload this image to a server
        // and update the user's profile URL in the AppProvider.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Consumer<AppProvider>(
              builder: (context, appProvider, child) => UserInfoHeader(
                profileImage: _profileImage,
                onTapImage: _pickImage,
                user: appProvider.currentUser,
              ),
            ),
            const SizedBox(height: 8),
            const MyPurchasesSection(),
            const SizedBox(height: 8),
            const MyWalletSection(),
            const SizedBox(height: 8),
            const FinancialServicesSection(),
            const SizedBox(height: 8),
            ActivitiesGrid(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class UserInfoHeader extends StatelessWidget {
  final File? profileImage;
  final VoidCallback onTapImage;
  final dynamic user; // Can be a User object from the provider

  const UserInfoHeader({
    Key? key,
    this.profileImage,
    required this.onTapImage,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTapImage,
            child: CircleAvatar(
              radius: 35,
              backgroundImage: profileImage != null
                  ? FileImage(profileImage!)
                  : (user?.imageUrl != null ? NetworkImage(user.imageUrl) : null) as ImageProvider?,
              child: profileImage == null && user?.imageUrl == null
                  ? const Icon(Icons.camera_alt_outlined, size: 30)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.username ?? 'Username',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(user?.email ?? 'user.email@example.com'),
            ],
          ),
        ],
      ),
    );
  }
}


// --- All the other section widgets remain the same ---

class MyPurchasesSection extends StatelessWidget {
  const MyPurchasesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SectionHeader(title: 'My Purchases', actionText: 'View Purchase History'),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                PurchaseStatusIcon(icon: Icons.wallet_outlined, label: 'To Pay'),
                PurchaseStatusIcon(icon: Icons.inventory_2_outlined, label: 'To Ship'),
                PurchaseStatusIcon(icon: Icons.local_shipping_outlined, label: 'To Receive'),
                PurchaseStatusIcon(icon: Icons.star_border_outlined, label: 'To Rate', notificationCount: 1),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MyWalletSection extends StatelessWidget {
  const MyWalletSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: 'My Wallet'),
            const SizedBox(height: 20),
            const IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  WalletItem(icon: Icons.account_balance_wallet_outlined, title: 'ToyPay', value: '₱20.00'),
                  VerticalDivider(),
                  WalletItem(icon: Icons.monetization_on_outlined, title: 'Coins', value: 'Check in!', hasNotification: true),
                  VerticalDivider(),
                  WalletItem(icon: Icons.credit_card_outlined, title: 'TPayLater', value: '₱52.00'),
                  VerticalDivider(),
                  WalletItem(icon: Icons.local_offer_outlined, title: 'Vouchers', value: '50+ Vouchers', hasNotification: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FinancialServicesSection extends StatelessWidget {
  const FinancialServicesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SectionHeader(title: 'Financial Services', actionText: 'See More'),
            const SizedBox(height: 8),
            ServiceRow(
              icon: Icons.account_balance,
              title: 'MariBank',
              subtitle: '60x free transfers & up to 4% interest',
              iconColor: Colors.orange[800],
            ),
            const Divider(),
            ServiceRow(
              icon: Icons.shield_outlined,
              title: 'Insurance',
              subtitle: 'Enjoy up to 12M 0% SpayLater',
              iconColor: Colors.green[600],
            ),
          ],
        ),
      ),
    );
  }
}

class ActivitiesGrid extends StatelessWidget {
  final List<Map<String, dynamic>> activities = [
    {'icon': Icons.loyalty_outlined, 'label': 'Shopee Loyalty', 'subtitle': 'Classic Member'},
    {'icon': Icons.favorite_border_outlined, 'label': 'My Likes'},
    {'icon': Icons.shopping_bag_outlined, 'label': 'Buy Again'},
    {'icon': Icons.history_outlined, 'label': 'Recently Viewed'},
  ];

  ActivitiesGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SectionHeader(title: 'More Activities', actionText: 'See All'),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                return ActivityCard(
                  icon: activities[index]['icon'],
                  label: activities[index]['label'],
                  subtitle: activities[index]['subtitle'],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


// --- Reusable Widgets ---

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;

  const SectionHeader({Key? key, required this.title, this.actionText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        if (actionText != null)
          Row(
            children: [
              Text(actionText!, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              Icon(Icons.chevron_right, color: Colors.grey[600], size: 18),
            ],
          ),
      ],
    );
  }
}

class PurchaseStatusIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final int notificationCount;

  const PurchaseStatusIcon({
    Key? key,
    required this.icon,
    required this.label,
    this.notificationCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Icon(icon, size: 28, color: Colors.grey[700]),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
          if (notificationCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text(
                  '$notificationCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class WalletItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool hasNotification;

  const WalletItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    this.hasNotification = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () {},
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 28, color: Colors.grey[700]),
                if (hasNotification)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12)),
            Text(value, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class ServiceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;

  const ServiceRow({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;

  const ActivityCard({
    Key? key,
    required this.icon,
    required this.label,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                if (subtitle != null)
                  Text(subtitle!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
