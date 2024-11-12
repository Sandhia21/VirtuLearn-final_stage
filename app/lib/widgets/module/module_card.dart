import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/dimensions.dart';
import '../../constants/text_styles.dart';
import '../../data/models/module.dart';

class ModuleCard extends StatelessWidget {
  final Module module;
  final VoidCallback onTap;
  final bool isInstructor;

  const ModuleCard({
    super.key,
    required this.module,
    required this.onTap,
    this.isInstructor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: Dimensions.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusMd),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.borderRadiusMd),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    color: AppColors.primary,
                    size: Dimensions.iconMd,
                  ),
                  const SizedBox(width: Dimensions.sm),
                  Expanded(
                    child: Text(
                      module.title,
                      style: TextStyles.h3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isInstructor)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        // Handle edit/delete actions
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit Module'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Module'),
                        ),
                      ],
                    ),
                ],
              ),
              if (module.description.isNotEmpty) ...[
                const SizedBox(height: Dimensions.sm),
                Text(
                  module.description,
                  style: TextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
