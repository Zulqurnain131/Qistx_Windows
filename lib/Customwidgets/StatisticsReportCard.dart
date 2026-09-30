import 'package:flutter/material.dart';

class StatisticsReportCard extends StatelessWidget {
  final String title;
  final List<String>? filters; // Agar filters (Yearly/Month) chahiye hon
  final String? selectedFilter;
  final Function(String)? onFilterChanged;

  // Table Headers
  final String header1;
  final String header2;
  final String? header3;

  // Rows Data
  final List<ReportRowItem> items;

  const StatisticsReportCard({
    super.key,
    required this.title,
    this.filters,
    this.selectedFilter,
    this.onFilterChanged,
    required this.header1,
    required this.header2,
    this.header3,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Filters Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (filters != null && onFilterChanged != null)
              Row(
                children: filters!.map((filter) {
                  bool isSelected = selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => onFilterChanged!(filter),
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF5722)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF5722)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Main Card Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD8CC), width: 1.5),
          ),
          child: Column(
            children: [
              // Table Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      header1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: header3 != null ? 1 : 1,
                    child: Text(
                      header2,
                      textAlign: header3 != null
                          ? TextAlign.center
                          : TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  if (header3 != null)
                    Expanded(
                      flex: 1,
                      child: Text(
                        header3!,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
              const Divider(height: 16, thickness: 1),

              // Dynamic Items List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Column 1 (Name / Title / Subtitle)
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.col1Title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (item.col1Subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.col1Subtitle!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Column 2 (Days / Volume / Price)
                      Expanded(
                        flex: 1,
                        child: Text(
                          item.col2Text,
                          textAlign: header3 != null
                              ? TextAlign.center
                              : TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: item.col2Color ?? const Color(0xFFFF5722),
                          ),
                        ),
                      ),

                      // Column 3 (Amount / Revenue / Margin) - Optional
                      if (header3 != null)
                        Expanded(
                          flex: 1,
                          child: Text(
                            item.col3Text ?? "",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: item.col3Color ?? Colors.black87,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Model for Row Data
class ReportRowItem {
  final String col1Title;
  final String? col1Subtitle;
  final String col2Text;
  final Color? col2Color;
  final String? col3Text;
  final Color? col3Color;

  ReportRowItem({
    required this.col1Title,
    this.col1Subtitle,
    required this.col2Text,
    this.col2Color,
    this.col3Text,
    this.col3Color,
  });
}
