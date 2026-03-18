import 'package:flutter/material.dart';

class SponsorSheetPreview extends StatelessWidget {

  final String name;
  final String? logoUrl;

  const SponsorSheetPreview({
    super.key,
    required this.name,
    required this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 12),

            /// 3:1 logo
            AspectRatio(
              aspectRatio: 3 / 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: logoUrl != null
                    ? Image.network(
                  logoUrl!,
                  fit: BoxFit.cover,
                )
                    : Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.storefront, size: 40),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "About",
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Your business description will appear here in the full sponsor profile.",
            ),

          ],
        ),
      ),
    );

  }

}