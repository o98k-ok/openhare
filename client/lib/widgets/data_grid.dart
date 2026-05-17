import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'const.dart';
import 'dart:math';
import 'data_type_icon.dart';
import 'package:db_driver/db_driver.dart';

const double kMinColumnWidth = 44.0; // 主要是确保序号列的宽度与SQL编辑的行号对齐
const double kMaxColumnWidth = 300.0;

const double tablePadding = 12.0;

const double borderWidth = 1.0;

class _CopyDataGridSelectionIntent extends Intent {
  const _CopyDataGridSelectionIntent();
}

class DataGridController extends ChangeNotifier {
  final List<DataGridColumn> columns;

  Position? selectedCellPosition;
  DataGridSelectionRange? selectedRange;

  DataGridController({
    required this.columns,
    this.selectedCellPosition,
  }) : selectedRange = selectedCellPosition != null ? DataGridSelectionRange.single(selectedCellPosition) : null;

  List<double> get columnWidths => columns.map((e) => e.size.width).toList();
  int get rowCount => columns.isEmpty ? 0 : columns.first.cells.length;
  int get columnCount => columns.length;

  void updateSelectedCell(Position p) {
    selectedCellPosition = p;
    selectedRange = DataGridSelectionRange.single(p);
    notifyListeners();
  }

  void updateSelectedCellRange(Position start, Position end) {
    selectedCellPosition = end;
    selectedRange = DataGridSelectionRange.fromPositions(start, end);
    notifyListeners();
  }

  void selectRowRange(int startRow, int endRow) {
    if (rowCount == 0 || columnCount == 0) return;
    selectedCellPosition = Position(rowIndex: endRow.clamp(0, rowCount - 1), columnIndex: 0);
    selectedRange = DataGridSelectionRange(
      startRow: min(startRow, endRow).clamp(0, rowCount - 1),
      endRow: max(startRow, endRow).clamp(0, rowCount - 1),
      startColumn: 0,
      endColumn: columnCount - 1,
    );
    notifyListeners();
  }

  void selectColumnRange(int startColumn, int endColumn) {
    if (rowCount == 0 || columnCount == 0) return;
    selectedCellPosition = Position(rowIndex: 0, columnIndex: endColumn.clamp(0, columnCount - 1));
    selectedRange = DataGridSelectionRange(
      startRow: 0,
      endRow: rowCount - 1,
      startColumn: min(startColumn, endColumn).clamp(0, columnCount - 1),
      endColumn: max(startColumn, endColumn).clamp(0, columnCount - 1),
    );
    notifyListeners();
  }

  bool isCellSelected(int rowIndex, int columnIndex) {
    final range = selectedRange;
    if (range == null) return false;
    return rowIndex >= range.startRow &&
        rowIndex <= range.endRow &&
        columnIndex >= range.startColumn &&
        columnIndex <= range.endColumn;
  }

  List<List<String>> selectedRowsTextMatrix() {
    final range = selectedRange;
    if (range == null || columns.isEmpty || columns.first.cells.isEmpty) {
      return const [];
    }
    final rows = <List<String>>[];
    for (int row = range.startRow; row <= range.endRow; row++) {
      final line = <String>[];
      for (int col = range.startColumn; col <= range.endColumn; col++) {
        line.add(columns[col].cells[row].data);
      }
      rows.add(line);
    }
    return rows;
  }

  List<String> selectedHeaders() {
    final range = selectedRange;
    if (range == null || columns.isEmpty) return const [];
    return [for (int col = range.startColumn; col <= range.endColumn; col++) columns[col].name];
  }

  String selectedAsTsv() {
    final rows = selectedRowsTextMatrix();
    if (rows.isEmpty) return '';
    final sb = StringBuffer();
    for (int i = 0; i < rows.length; i++) {
      if (i > 0) sb.writeln();
      sb.write(rows[i].map(_escapeTsv).join('\t'));
    }
    return sb.toString();
  }

  String _escapeTsv(String value) {
    if (!value.contains('\t') && !value.contains('\n') && !value.contains('\r') && !value.contains('"')) {
      return value;
    }
    final normalized = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    return '"${normalized.replaceAll('"', '""')}"';
  }

  Future<bool> copySelectionToClipboard({bool withHeaders = false}) async {
    final body = selectedAsTsv();
    if (body.isEmpty) return false;
    String text = body;
    if (withHeaders) {
      final headers = selectedHeaders();
      if (headers.isNotEmpty) {
        text = '${headers.map(_escapeTsv).join('\t')}\n$body';
      }
    }
    await Clipboard.setData(ClipboardData(text: text));
    return true;
  }

  int get selectedRowCount {
    final range = selectedRange;
    if (range == null) return 0;
    return range.endRow - range.startRow + 1;
  }

  int get selectedColumnCount {
    final range = selectedRange;
    if (range == null) return 0;
    return range.endColumn - range.startColumn + 1;
  }

  DataGridSelectionRange? get normalizedSelectedRange {
    final range = selectedRange;
    if (range == null || columns.isEmpty || rowCount == 0) return null;
    return DataGridSelectionRange(
      startRow: range.startRow.clamp(0, rowCount - 1),
      endRow: range.endRow.clamp(0, rowCount - 1),
      startColumn: range.startColumn.clamp(0, columnCount - 1),
      endColumn: range.endColumn.clamp(0, columnCount - 1),
    );
  }

  void clearSelection() {
    selectedCellPosition = null;
    selectedRange = null;
    notifyListeners();
  }

  // 仅通知列宽变化
  void updateColumnWidth(int index, double width) {
    notifyListeners();
  }
}

class Position {
  final int rowIndex;
  final int columnIndex;

  const Position({required this.rowIndex, required this.columnIndex});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Position && other.rowIndex == rowIndex && other.columnIndex == columnIndex;
  }

  @override
  int get hashCode => Object.hash(rowIndex, columnIndex);
}

class DataGridSelectionRange {
  final int startRow;
  final int endRow;
  final int startColumn;
  final int endColumn;

  const DataGridSelectionRange({
    required this.startRow,
    required this.endRow,
    required this.startColumn,
    required this.endColumn,
  });

  factory DataGridSelectionRange.single(Position p) {
    return DataGridSelectionRange(
      startRow: p.rowIndex,
      endRow: p.rowIndex,
      startColumn: p.columnIndex,
      endColumn: p.columnIndex,
    );
  }

  factory DataGridSelectionRange.fromPositions(Position start, Position end) {
    return DataGridSelectionRange(
      startRow: min(start.rowIndex, end.rowIndex),
      endRow: max(start.rowIndex, end.rowIndex),
      startColumn: min(start.columnIndex, end.columnIndex),
      endColumn: max(start.columnIndex, end.columnIndex),
    );
  }
}

class RowSize extends ValueNotifier<double> {
  /// 最小宽度
  final double? minWidth;

  /// 最大宽度
  final double? maxWidth;

  RowSize({
    required double width,
    this.minWidth = kMinColumnWidth,
    this.maxWidth = kMaxColumnWidth,
  }) : super(width);

  /// 获取当前宽度（等同于 value）
  double get width => value;

  /// 设置宽度（等同于设置 value，但会进行范围限制）
  set width(double width) {
    value = width.clamp(minWidth ?? kMinColumnWidth, maxWidth ?? kMaxColumnWidth);
  }
}

/// 列定义
class DataGridColumn {
  /// 列名
  final String name;

  /// 数据类型
  final DataType? dataType;

  final List<DataGridCell> cells;

  /// 是否可调整大小（拖动调整列宽）
  final bool resizable;

  /// 列宽
  final RowSize size;

  /// 数据对齐方式
  final Alignment? dataAlignment;

  /// cell 里的文本颜色
  final Color? textColor;

  const DataGridColumn({
    required this.name,
    this.dataType,
    required this.cells,
    required this.size,
    this.resizable = true,
    this.dataAlignment = Alignment.centerLeft,
    this.textColor,
  });

  DataGridColumn.autoSize({
    required BuildContext context,
    required this.name,
    this.dataType,
    required this.cells,
    this.resizable = true,
    this.dataAlignment = Alignment.centerLeft,
    this.textColor,
  }) : size = _calculateAutoSize(context, name, dataType, cells);

  /// 构建表头 Widget
  static Widget buildHeaderWidget({
    required BuildContext context,
    required String name,
    DataType? dataType,
  }) {
    if (name.isEmpty) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: kSpacingSmall),
      child: Row(
        children: [
          if (dataType != null)
            Padding(
              padding: const EdgeInsets.only(right: kSpacingTiny),
              child: DataTypeIcon(type: dataType, size: kIconSizeSmall),
            ),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  /// 计算自动列宽
  static RowSize _calculateAutoSize(
    BuildContext context,
    String name,
    DataType? dataType,
    List<DataGridCell> cells,
  ) {
    final textStyle = Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(text: '', style: textStyle),
    );

    // 测量表头宽度：图标宽度 + padding + 文本宽度
    double headerWidth = kSpacingSmall * 2;
    if (dataType != null) {
      // 图标宽度 + 右边距 + 图标宽度（文字右侧留白，布局好看点）
      headerWidth += kIconSizeSmall * 2 + kSpacingTiny;
    }
    // 测量列名文本宽度
    textPainter.text = TextSpan(text: name, style: textStyle);
    textPainter.layout();
    headerWidth += textPainter.width;

    // 测量单元格宽度：边距 + 最长的文本宽度
    double maxCellWidth = kSpacingSmall * 2;

    if (cells.isNotEmpty) {
      final longestCellData = cells.map((cell) => cell.data).reduce((a, b) => a.length > b.length ? a : b);
      textPainter.text = TextSpan(text: longestCellData, style: textStyle);
      textPainter.layout();
      maxCellWidth += textPainter.width;
    }

    final finalWidth = max(headerWidth, maxCellWidth);

    return RowSize(
      width: finalWidth.clamp(kMinColumnWidth, kMaxColumnWidth),
      minWidth: kMinColumnWidth,
      maxWidth: double.infinity,
    );
  }
}

class DataGridCell {
  final String data;

  const DataGridCell({
    required this.data,
  });
}

/// 数据表格组件
class DataGrid extends StatefulWidget {
  /// 数据表格控制器
  final DataGridController controller;

  /// 表头的行高
  final double headerHeight;

  /// 数据行的行高
  final double rowHeight;

  /// 水平滚动控制器组，用于同步表头和数据体的水平滚动
  final LinkedScrollControllerGroup? horizontalScrollGroup;

  /// 垂直滚动控制器，用于数据行的垂直滚动
  final LinkedScrollControllerGroup? verticalScrollGroup;

  /// 单元格点击回调
  final void Function(Position position)? onCellTap;

  /// 单元格双击回调
  final void Function(Position position)? onCellDoubleTap;

  /// 触发快捷复制后的回调
  final void Function(int rows, int columns)? onCopySelection;

  /// 快捷复制时是否包含表头
  final bool copyWithHeaders;

  const DataGrid({
    super.key,
    required this.controller,
    this.rowHeight = 24.0,
    this.headerHeight = 32.0,
    this.horizontalScrollGroup,
    this.verticalScrollGroup,
    this.onCellTap,
    this.onCellDoubleTap,
    this.onCopySelection,
    this.copyWithHeaders = false,
  });

  @override
  State<DataGrid> createState() => _DataGridState();
}

class _DataGridState extends State<DataGrid> {
  DataGridColumn? _rowNumberColumn;
  final FocusNode _focusNode = FocusNode(debugLabel: 'DataGridFocus');
  Position? _cellDragAnchor;
  int? _rowDragAnchor;
  int? _columnDragAnchor;

  // 滚动控制器管理
  late final LinkedScrollControllerGroup _horizontalScrollGroup;
  late final ScrollController _headerHorizontalController;
  late final ScrollController _bodyHorizontalController;

  late final LinkedScrollControllerGroup _verticalScrollGroup;
  late final ScrollController _fixedColumnVerticalController;
  late final ScrollController _scrollableColumnVerticalController;

  void _initRowNumberColumn() {
    if (widget.controller.columns.isEmpty || widget.controller.columns[0].cells.isEmpty) return;
    _rowNumberColumn = DataGridColumn.autoSize(
      context: context,
      name: '',
      resizable: false,
      dataAlignment: Alignment.center,
      textColor: Theme.of(context).colorScheme.onSurfaceVariant, // line number 字体颜色
      cells: <DataGridCell>[
        for (int i = 0; i < widget.controller.columns[0].cells.length; i++) DataGridCell(data: '${i + 1}'),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    // 初始化滚动控制器
    _horizontalScrollGroup = widget.horizontalScrollGroup ?? LinkedScrollControllerGroup();
    _headerHorizontalController = _horizontalScrollGroup.addAndGet();
    _bodyHorizontalController = _horizontalScrollGroup.addAndGet();

    // 初始化垂直滚动联动组
    _verticalScrollGroup = widget.verticalScrollGroup ?? LinkedScrollControllerGroup();
    _fixedColumnVerticalController = _verticalScrollGroup.addAndGet();
    _scrollableColumnVerticalController = _verticalScrollGroup.addAndGet();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    // 清理滚动控制器
    _headerHorizontalController.dispose();
    _bodyHorizontalController.dispose();
    _fixedColumnVerticalController.dispose();
    _scrollableColumnVerticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _initRowNumberColumn();
    return Listener(
      onPointerDown: (_) {
        _focusNode.requestFocus();
      },
      onPointerUp: (_) {
        _clearDragAnchors();
      },
      onPointerCancel: (_) {
        _clearDragAnchors();
      },
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.keyC, meta: true): _CopyDataGridSelectionIntent(),
          SingleActivator(LogicalKeyboardKey.keyC, control: true): _CopyDataGridSelectionIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _CopyDataGridSelectionIntent: CallbackAction<_CopyDataGridSelectionIntent>(
              onInvoke: (_) {
                _copySelectionToClipboard();
                return null;
              },
            ),
          },
          child: Focus(
            focusNode: _focusNode,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // 固定列部分 - 只有垂直滚动
                      _buildFixedColumns(context),
                      // 可滚动列部分 - 有垂直和水平滚动
                      _buildScrollableColumns(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _clearDragAnchors() {
    _cellDragAnchor = null;
    _rowDragAnchor = null;
    _columnDragAnchor = null;
  }

  Future<void> _copySelectionToClipboard() async {
    final copied = await widget.controller.copySelectionToClipboard(withHeaders: widget.copyWithHeaders);
    if (!copied || !mounted) return;
    final rows = widget.controller.selectedRowCount;
    final columns = widget.controller.selectedColumnCount;
    widget.onCopySelection?.call(rows, columns);
  }

  void _handleCellPointerDown(Position position) {
    _rowDragAnchor = null;
    _columnDragAnchor = null;
    _cellDragAnchor = position;
    widget.controller.updateSelectedCellRange(position, position);
  }

  void _handleCellPointerEnter(Position position, int buttons) {
    if (_cellDragAnchor == null || buttons == 0) return;
    widget.controller.updateSelectedCellRange(_cellDragAnchor!, position);
  }

  void _handleColumnPointerDown(int columnIndex) {
    _rowDragAnchor = null;
    _cellDragAnchor = null;
    _columnDragAnchor = columnIndex;
    widget.controller.selectColumnRange(columnIndex, columnIndex);
  }

  void _handleColumnPointerEnter(int columnIndex, int buttons) {
    if (_columnDragAnchor == null || buttons == 0) return;
    widget.controller.selectColumnRange(_columnDragAnchor!, columnIndex);
  }

  void _handleRowPointerDown(int rowIndex) {
    _columnDragAnchor = null;
    _cellDragAnchor = null;
    _rowDragAnchor = rowIndex;
    widget.controller.selectRowRange(rowIndex, rowIndex);
  }

  void _handleRowPointerEnter(int rowIndex, int buttons) {
    if (_rowDragAnchor == null || buttons == 0) return;
    widget.controller.selectRowRange(_rowDragAnchor!, rowIndex);
  }

  /// 构建表头
  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: widget.headerHeight,
      child: Row(
        children: [
          // 固定列表头
          if (_rowNumberColumn != null)
            _DataGridHeaderCell(
              controller: widget.controller,
              column: _rowNumberColumn!,
              index: 0,
              headerHeight: widget.headerHeight,
              selectable: false,
            ),
          // 可滚动列表头
          Expanded(
            child: SingleChildScrollView(
              controller: _headerHorizontalController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                child: Row(
                  children: [
                    for (int i = 0; i < widget.controller.columns.length; i++)
                      _DataGridHeaderCell(
                        controller: widget.controller,
                        column: widget.controller.columns[i],
                        index: i,
                        headerHeight: widget.headerHeight,
                        selectable: true,
                        onPointerDown: () => _handleColumnPointerDown(i),
                        onPointerEnter: (buttons) => _handleColumnPointerEnter(i, buttons),
                        onTap: () => widget.controller.selectColumnRange(i, i),
                      ),
                    const SizedBox(width: tablePadding),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(
    BuildContext context,
    DataGridColumn column,
    int columnIndex, {
    bool isRowHeader = false,
  }) {
    return ValueListenableBuilder<double>(
      valueListenable: column.size,
      builder: (context, width, child) {
        return Column(
          children: [
            for (int i = 0; i < column.cells.length; i++)
              _DataGridCell(
                position: Position(rowIndex: i, columnIndex: columnIndex),
                width: width,
                rowHeight: widget.rowHeight,
                data: column.cells[i].data,
                controller: widget.controller,
                onCellTap: widget.onCellTap,
                onCellDoubleTap: widget.onCellDoubleTap,
                alignment: column.dataAlignment,
                textColor: column.textColor,
                onPointerDown: () {
                  if (isRowHeader) {
                    _handleRowPointerDown(i);
                  } else {
                    _handleCellPointerDown(Position(rowIndex: i, columnIndex: columnIndex));
                  }
                },
                onPointerEnter: (buttons) {
                  if (isRowHeader) {
                    _handleRowPointerEnter(i, buttons);
                  } else {
                    _handleCellPointerEnter(Position(rowIndex: i, columnIndex: columnIndex), buttons);
                  }
                },
                isRowHeader: isRowHeader,
              ),
          ],
        );
      },
    );
  }

  /// 构建固定列部分
  Widget _buildFixedColumns(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        scrollbars: false,
      ),
      child: SingleChildScrollView(
        controller: _fixedColumnVerticalController,
        scrollDirection: Axis.vertical,
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_rowNumberColumn != null) _buildColumn(context, _rowNumberColumn!, 0, isRowHeader: true),
              ],
            ),
            const SizedBox(height: tablePadding), // 底部留白
          ],
        ),
      ),
    );
  }

  /// 构建可滚动列部分
  Widget _buildScrollableColumns(BuildContext context) {
    return Expanded(
      child: Scrollbar(
        controller: _scrollableColumnVerticalController,
        thumbVisibility: false,
        notificationPredicate: (notification) => notification.metrics.axis == Axis.vertical,
        child: Scrollbar(
          controller: _bodyHorizontalController,
          thumbVisibility: false,
          notificationPredicate: (notification) => notification.metrics.axis == Axis.horizontal,
          child: CustomScrollView(
            controller: _scrollableColumnVerticalController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: SingleChildScrollView(
                  controller: _bodyHorizontalController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Stack(
                    children: [
                      // 选中状态层（全局绘制选中行的背景和选中单元格的内边框）
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _SelectionLayerPainter(
                              controller: widget.controller,
                              rowHeight: widget.rowHeight,
                              colorScheme: Theme.of(context).colorScheme,
                            ),
                          ),
                        ),
                      ),
                      // 数据列内容层
                      Column(
                        children: [
                          Row(
                            children: [
                              for (int j = 0; j < widget.controller.columns.length; j++)
                                _buildColumn(context, widget.controller.columns[j], j),
                              const SizedBox(width: tablePadding), // 右侧留白
                            ],
                          ),
                          const SizedBox(height: tablePadding), // 底部留白
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 表头单元格 Widget
class _DataGridHeaderCell extends StatefulWidget {
  final DataGridController controller;
  final DataGridColumn column;
  final int index;
  final double headerHeight;
  final bool selectable;
  final VoidCallback? onTap;
  final VoidCallback? onPointerDown;
  final void Function(int buttons)? onPointerEnter;

  const _DataGridHeaderCell({
    required this.controller,
    required this.column,
    required this.index,
    required this.headerHeight,
    this.selectable = false,
    this.onTap,
    this.onPointerDown,
    this.onPointerEnter,
  });

  @override
  State<_DataGridHeaderCell> createState() => _DataGridHeaderCellState();
}

class _DataGridHeaderCellState extends State<_DataGridHeaderCell> {
  double? _dragStartX;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.column.size,
      builder: (context, width, child) {
        return SizedBox(
          width: width,
          child: DataGridCellWidget(
            child: SizedBox(
              width: width,
              height: widget.headerHeight,
              child: Stack(
                children: [
                  // 表头内容
                  Positioned.fill(
                    child: MouseRegion(
                      onEnter: (event) {
                        widget.onPointerEnter?.call(event.buttons);
                      },
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (_) {
                          widget.onPointerDown?.call();
                        },
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.selectable ? widget.onTap : null,
                          child: DataGridColumn.buildHeaderWidget(
                            context: context,
                            name: widget.column.name,
                            dataType: widget.column.dataType,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 拖动手柄（只有可调整大小的列才显示）
                  if (widget.column.resizable)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeColumn,
                        child: GestureDetector(
                          onHorizontalDragStart: (details) {
                            _dragStartX = details.globalPosition.dx;
                          },
                          onHorizontalDragUpdate: (details) {
                            if (_dragStartX != null) {
                              final delta = details.globalPosition.dx - _dragStartX!;
                              // 直接更新 RowSize 的 width，会自动触发 ValueNotifier 的通知
                              widget.column.size.width = widget.column.size.width + delta;
                              // 通知controller 刷新选中单元格和列宽
                              widget.controller.updateColumnWidth(widget.index, widget.column.size.width);
                              _dragStartX = details.globalPosition.dx;
                            }
                          },
                          onHorizontalDragEnd: (_) {
                            _dragStartX = null;
                          },
                          child: Container(
                            width: 8.0,
                            color: Colors.transparent,
                          ),
                        ),
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

/// 数据单元格 Widget
class _DataGridCell extends StatelessWidget {
  final Position position;
  final double width;
  final double rowHeight;
  final String data;
  final DataGridController controller;
  final void Function(Position position)? onCellTap;
  final void Function(Position position)? onCellDoubleTap;
  final Alignment? alignment;
  final Color? textColor;
  final VoidCallback? onPointerDown;
  final void Function(int buttons)? onPointerEnter;
  final bool isRowHeader;

  const _DataGridCell({
    required this.position,
    required this.width,
    required this.rowHeight,
    required this.data,
    required this.controller,
    this.onCellTap,
    this.onCellDoubleTap,
    this.alignment,
    this.textColor,
    this.onPointerDown,
    this.onPointerEnter,
    this.isRowHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    return DataGridCellWidget(
      child: SizedBox(
        width: width,
        height: rowHeight,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) {
            onPointerDown?.call();
          },
          child: MouseRegion(
            onEnter: (event) {
              onPointerEnter?.call(event.buttons);
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (isRowHeader) {
                  controller.selectRowRange(position.rowIndex, position.rowIndex);
                  return;
                }
                controller.updateSelectedCell(position);
                onCellTap?.call(position);
              },
              onDoubleTap: () {
                if (isRowHeader) return;
                controller.updateSelectedCell(position);
                onCellDoubleTap?.call(position);
              },
              child: Container(
                alignment: alignment ?? Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: kSpacingSmall),
                child: Text(
                  data,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 带边框的 Cell 组件 - 只用于绘制网格边框
class DataGridCellWidget extends StatelessWidget {
  final Color? borderColor;

  final Widget child;

  const DataGridCellWidget({
    super.key,
    required this.child,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _DataGridCellPainter(
          borderColor: borderColor ?? Theme.of(context).colorScheme.outlineVariant, // 表格网格颜色
        ),
        child: child,
      ),
    );
  }
}

/// Cell 边框绘制器 - 只绘制右边和下边,
/// 为什么不用container的边框，因为边框有抗锯齿的特性，线条会粗细不均.
class _DataGridCellPainter extends CustomPainter {
  /// 边框的颜色
  final Color borderColor;

  const _DataGridCellPainter({
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制边框
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = false; // 关闭抗锯齿

    // 绘制右边框
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint);

    // 绘制下边框
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _DataGridCellPainter oldDelegate) {
    return borderColor != oldDelegate.borderColor;
  }
}

/// 选中状态层绘制器 - 全局绘制选中行的背景和选中单元格的内边框
class _SelectionLayerPainter extends CustomPainter {
  final DataGridController controller;
  final double rowHeight;
  final ColorScheme colorScheme;

  _SelectionLayerPainter({
    required this.controller,
    required this.rowHeight,
    required this.colorScheme,
  }) : super(
         repaint: controller,
       );

  @override
  void paint(Canvas canvas, Size size) {
    final range = controller.normalizedSelectedRange;
    if (range == null) return;

    final x = controller.columnWidths.take(range.startColumn).fold(0.0, (sum, width) => sum + width);
    final selectedWidth = controller.columnWidths
        .skip(range.startColumn)
        .take(range.endColumn - range.startColumn + 1)
        .fold(0.0, (sum, width) => sum + width);
    final y = range.startRow * rowHeight;
    final selectedHeight = (range.endRow - range.startRow + 1) * rowHeight;

    final backgroundPaint = Paint()
      ..color = colorScheme.surfaceContainerLow
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;
    canvas.drawRect(Rect.fromLTWH(x, y, selectedWidth, selectedHeight), backgroundPaint);

    final selectedBorderPaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = false;
    final selectedRect = Rect.fromLTWH(
      x + borderWidth * 2,
      y + borderWidth * 2,
      max(0, selectedWidth - borderWidth * 4),
      max(0, selectedHeight - borderWidth * 4),
    );
    canvas.drawRect(selectedRect, selectedBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _SelectionLayerPainter oldDelegate) {
    return rowHeight != oldDelegate.rowHeight || colorScheme != oldDelegate.colorScheme;
  }
}
