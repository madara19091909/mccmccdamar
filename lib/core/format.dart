import 'package:intl/intl.dart';

String formatNumber(int value) => NumberFormat.decimalPattern('ar').format(value);

String formatDate(DateTime value) => DateFormat('d MMMM yyyy', 'ar').format(value);

String formatDateTime(DateTime value) =>
    DateFormat('d MMMM yyyy - hh:mm a', 'ar').format(value);

String formatRelative(DateTime value, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(value);
  if (diff.isNegative || diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'قبل ${formatNumber(diff.inMinutes)} دقيقة';
  if (diff.inHours < 24) return 'قبل ${formatNumber(diff.inHours)} ساعة';
  if (diff.inDays < 30) return 'قبل ${formatNumber(diff.inDays)} يومًا';
  return formatDate(value);
}
