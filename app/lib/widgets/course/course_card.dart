// import 'package:flutter/material.dart';

// import 'package:learn_smart/data/models/course.dart';
// import 'package:learn_smart/constants/constants.dart';

// class CourseCard extends StatelessWidget {
//   final Course course;
//   final VoidCallback onTap;
//   final bool isEnrolled;

//   const CourseCard({
//     Key? key,
//     required this.course,
//     required this.onTap,
//     this.isEnrolled = false,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: Dimensions.cardElevation,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(Dimensions.borderRadiusMd),
//       ),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(Dimensions.borderRadiusMd),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildImage(),
//             Padding(
//               padding: const EdgeInsets.all(Dimensions.md),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     course.name,
//                     style: TextStyles.h3,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: Dimensions.xs),
//                   Text(
//                     course.description,
//                     style: TextStyles.bodySmall,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: Dimensions.sm),
//                   _buildFooter(),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildImage() {
//     return Container(
//       height: 120,
//       decoration: BoxDecoration(
//         borderRadius: const BorderRadius.vertical(
//           top: Radius.circular(Dimensions.borderRadiusMd),
//         ),
//         image: DecorationImage(
//           image: NetworkImage('http://10.0.2.2:8000${course.imageUrl}'),
//           fit: BoxFit.cover,
//           onError: (_, __) =>
//               const AssetImage('assets/icons/default_course_image.png'),
//         ),
//       ),
//     );
//   }

//   Widget _buildFooter() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           'By ${course.createdByUsername}',
//           style: TextStyles.caption,
//         ),
//         Container(
//           padding: const EdgeInsets.symmetric(
//             horizontal: Dimensions.sm,
//             vertical: Dimensions.xs,
//           ),
//           decoration: BoxDecoration(
//             color: isEnrolled ? AppColors.success : AppColors.primary,
//             borderRadius: BorderRadius.circular(Dimensions.borderRadiusXs),
//           ),
//           child: Text(
//             isEnrolled ? 'Enrolled' : 'Enroll',
//             style: TextStyles.caption.copyWith(color: AppColors.textLight),
//           ),
//         ),
//       ],
//     );
//   }
// }
