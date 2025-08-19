import 'package:flutter/material.dart';
import '../screens/foodActions/createExercise_page.dart';
import '../screens/foodActions/createFood_page.dart';
import '../screens/foodActions/searchBarCode_page.dart';
import '../widgets/stylesheet.dart';

void openAddSheet(BuildContext context, {VoidCallback? onReload}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: false,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),

    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text("Add options", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ), /// headers


            _SheetItem(
              icon: Icons.qr_code_scanner,
              title: "Add food by barcode scanner",
              subtitle: "Scan a barcode to create + log (coming soon)",
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Barcode scanner is coming soon")),
                );
              },
            ),

            _SheetItem(
              icon: Icons.search,
              title: "Add food by searching barcode",
              subtitle: "Enter barcode number to find or create",
              onTap: () async {
                Navigator.pop(context);
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const BarcodeSearchScreen()),
                );
                onReload?.call(); // refresh
              },
            ),

            _SheetItem(
              icon: Icons.restaurant,
              title: "Create food",
              subtitle: "Add your own food with macros",
              onTap: () async {
                Navigator.pop(context);
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CreateFoodPage()),
                );
                onReload?.call(); // refresh
              },
            ),


            _SheetItem(
              icon: Icons.fitness_center,
              title: "Create exercise",
              subtitle: "Add an exercise with calories per unit",
              onTap: () async {
                Navigator.pop(context);
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CreateExercisePage()),
                );
                onReload?.call(); // refresh
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

class _SheetItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFF6B7E7A),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: AppTextStyles.bodyH),
      subtitle: Text(subtitle, style: AppTextStyles.bodyH_NotBold),
      onTap: onTap,
    );
  }
}

// to display records
class PillCard extends StatelessWidget {
  final Color accentColor;
  final String title;
  final String subtitle;

  const PillCard({
    super.key,
    required this.accentColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left rounded pill
        Container(
          width: 15,
          height: 70,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
          ),
        ),

        // Main body
        Expanded(
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: AppTextStyles.bodyH, maxLines: 1,overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyH_NotBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}