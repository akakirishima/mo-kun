import 'dart:math' as math;

import 'package:flutter/material.dart';

const _diaryFontFamily = 'NotoSerifJP';

class DiaryVerticalText extends StatelessWidget {
  const DiaryVerticalText({
    super.key,
    required this.text,
    required this.color,
    this.fontSize = 20,
    this.columnPitch = 34,
    this.rowPitch,
    this.columnKeyPrefix = 'diary-vertical-column',
    this.maxRowsPerColumn,
  });

  final String text;
  final Color color;
  final double fontSize;
  final double columnPitch;
  final double? rowPitch;
  final String columnKeyPrefix;
  final int? maxRowsPerColumn;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }

        final units = text.characters.toList();
        var adjustedFontSize = fontSize;
        late double lineHeight;
        late double columnWidth;
        late int rowsPerColumn;
        late int maxColumns;
        List<List<String>> columns = <List<String>>[];

        do {
          lineHeight = rowPitch ?? (adjustedFontSize * 1.12);
          lineHeight = math.max(lineHeight, adjustedFontSize + 1);
          columnWidth = math.min(columnPitch, constraints.maxWidth);
          rowsPerColumn = math.max(
            1,
            ((constraints.maxHeight - 2) / lineHeight).floor(),
          );
          if (maxRowsPerColumn != null) {
            rowsPerColumn = math.min(rowsPerColumn, maxRowsPerColumn!);
          }
          maxColumns = math.max(
            1,
            (constraints.maxWidth / columnPitch).floor(),
          );
          columns = _buildColumns(units, rowsPerColumn);
          if (columns.length <= maxColumns || adjustedFontSize <= 14) {
            break;
          }
          if (rowPitch != null) {
            break;
          }
          adjustedFontSize -= 1;
        } while (true);

        if (columns.length > maxColumns) {
          columns = columns
              .take(maxColumns)
              .map((column) => List<String>.from(column))
              .toList();
          final lastColumn = columns.last;
          if (lastColumn.isEmpty) {
            lastColumn.add('…');
          } else if (lastColumn.length >= rowsPerColumn) {
            lastColumn[lastColumn.length - 1] = '…';
          } else {
            lastColumn.add('…');
          }
        }

        return ClipRect(
          child: Align(
            alignment: Alignment.topRight,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < columns.length; i += 1)
                    SizedBox(
                      key: ValueKey<String>('$columnKeyPrefix-$i'),
                      width: columnWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          for (final character in columns[i])
                            _VerticalGlyph(
                              character: character,
                              color: color,
                              fontSize: adjustedFontSize,
                              lineHeight: lineHeight,
                              fontWeight: FontWeight.w600,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

const Set<String> _kinsokuForbiddenLineStart = <String>{
  '、',
  '。',
  '，',
  '．',
  '）',
  '」',
  '』',
  '】',
  '〉',
  '》',
  '］',
  '｝',
  '〕',
  '！',
  '？',
  '：',
  '；',
};

const Set<String> _kinsokuForbiddenLineEnd = <String>{
  '「',
  '『',
  '（',
  '【',
  '〈',
  '《',
  '［',
  '｛',
  '〔',
};

List<List<String>> _buildColumns(List<String> units, int rowsPerColumn) {
  final columns = <List<String>>[<String>[]];

  for (final unit in units) {
    if (unit == '\n') {
      if (columns.last.isNotEmpty) {
        columns.add(<String>[]);
      }
      continue;
    }

    var currentColumn = columns.last;
    if (currentColumn.length >= rowsPerColumn) {
      columns.add(<String>[]);
      currentColumn = columns.last;
    }

    if (currentColumn.length == rowsPerColumn - 1 &&
        _kinsokuForbiddenLineEnd.contains(unit) &&
        currentColumn.isNotEmpty) {
      columns.add(<String>[]);
      currentColumn = columns.last;
    }

    if (currentColumn.isEmpty &&
        _kinsokuForbiddenLineStart.contains(unit) &&
        columns.length > 1) {
      final previousColumn = columns[columns.length - 2];
      if (previousColumn.length > 1) {
        currentColumn.add(previousColumn.removeLast());
      }
    }

    if (currentColumn.length >= rowsPerColumn) {
      columns.add(<String>[]);
      currentColumn = columns.last;
    }
    currentColumn.add(unit);
  }

  if (columns.last.isEmpty) {
    columns.removeLast();
  }
  return columns;
}

class _VerticalGlyph extends StatelessWidget {
  const _VerticalGlyph({
    required this.character,
    required this.color,
    required this.fontSize,
    required this.lineHeight,
    required this.fontWeight,
  });

  final String character;
  final Color color;
  final double fontSize;
  final double lineHeight;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    if (character.trim().isEmpty) {
      return SizedBox(height: lineHeight);
    }

    return SizedBox(
      height: lineHeight,
      child: Center(
        child: Text(
          character,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: _diaryFontFamily,
            height: 1,
            decoration: TextDecoration.none,
            shadows: const [],
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}
