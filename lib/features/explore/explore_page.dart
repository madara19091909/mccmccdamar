import 'package:echo/core/format.dart';
import 'package:echo/logic/memory_query.dart';
import 'package:echo/navigation/app_routes.dart';
import 'package:echo/state/memory_controller.dart';
import 'package:echo/widgets/empty_state.dart';
import 'package:echo/widgets/memory_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<MemoryController>().searchText,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickRange(MemoryController controller) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      initialDateRange: controller.dateRange,
    );
    if (range != null) controller.setDateRange(range);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MemoryController>();
    final theme = Theme.of(context);

    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final results = controller.filteredMemories;
    final range = controller.dateRange;

    Widget body;
    if (controller.memories.isEmpty) {
      body = EmptyState(
        icon: Icons.travel_explore_rounded,
        title: 'لا توجد ذكريات بعد',
        message: 'عندما تضيف ذكرياتك ستجدها هنا لتبحث فيها وترتبها وتصفّيها.',
        actionLabel: 'إضافة ذكرى',
        onAction: () => AppRoutes.openMemoryForm(context),
      );
    } else if (results.isEmpty) {
      body = EmptyState(
        icon: Icons.search_off_rounded,
        title: 'لا نتائج مطابقة',
        message: 'جرّب كلمات بحث أخرى أو أزل التصفية.',
        actionLabel: 'مسح التصفية',
        onAction: () {
          _searchController.clear();
          controller.resetFilters();
        },
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final memory = results[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MemoryCard(
              memory: memory,
              category: controller.categoryById(memory.categoryId),
              onTap: () => AppRoutes.openMemory(context, memory.id),
            ),
          );
        },
      );
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'استكشاف الذكريات',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                key: const Key('date_range_button'),
                tooltip: 'تصفية حسب التاريخ',
                icon: const Icon(Icons.date_range_rounded),
                onPressed: () => _pickRange(controller),
              ),
              PopupMenuButton<MemorySort>(
                key: const Key('sort_button'),
                tooltip: 'فرز',
                icon: const Icon(Icons.sort_rounded),
                initialValue: controller.sort,
                onSelected: controller.setSort,
                itemBuilder: (context) => const <PopupMenuEntry<MemorySort>>[
                  PopupMenuItem<MemorySort>(
                    value: MemorySort.newest,
                    child: Text('الأحدث أولًا'),
                  ),
                  PopupMenuItem<MemorySort>(
                    value: MemorySort.oldest,
                    child: Text('الأقدم أولًا'),
                  ),
                  PopupMenuItem<MemorySort>(
                    value: MemorySort.importance,
                    child: Text('الأكثر أهمية'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            key: const Key('search_field'),
            controller: _searchController,
            onChanged: controller.setSearchText,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'ابحث في العنوان أو النص أو الوسوم',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.searchText.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'مسح البحث',
                      onPressed: () {
                        _searchController.clear();
                        controller.setSearchText('');
                      },
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: <Widget>[
              if (range != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: InputChip(
                    label: Text(
                      '${formatDate(range.start)} - ${formatDate(range.end)}',
                    ),
                    onDeleted: () => controller.setDateRange(null),
                  ),
                ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  label: const Text('الكل'),
                  selected: controller.categoryFilter == null,
                  onSelected: (_) => controller.setCategoryFilter(null),
                ),
              ),
              for (final category in controller.categories)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(category.name),
                    selected: controller.categoryFilter == category.id,
                    onSelected: (selected) => controller
                        .setCategoryFilter(selected ? category.id : null),
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}
