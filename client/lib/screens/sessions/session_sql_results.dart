import 'dart:convert';

import 'package:client/l10n/app_localizations.dart';
import 'package:client/models/ai.dart';
import 'package:client/models/sessions.dart';
import 'package:client/services/ai/agent.dart';
import 'package:client/services/ai/llm_sdk.dart';
import 'package:client/services/sessions/session_conn.dart';
import 'package:client/services/sessions/session_controller.dart';
import 'package:client/services/sessions/session_sql_result.dart';
import 'package:client/services/sessions/sessions.dart';
import 'package:client/widgets/button.dart';
import 'package:client/widgets/const.dart';
import 'package:client/widgets/data_grid.dart';
import 'package:client/widgets/divider.dart';
import 'package:client/widgets/empty.dart';
import 'package:client/widgets/loading.dart';
import 'package:client/widgets/tab_widget.dart';
import 'package:client/widgets/tooltip.dart';
import 'package:db_driver/db_driver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/styles/atom-one-light.dart';

class SqlResultTables extends ConsumerWidget {
  const SqlResultTables({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SessionSQLResultsModel? model = ref.watch(selectedSQLResultTabProvider);
    CommonTabStyle style = CommonTabStyle(
      maxWidth: 100,
      minWidth: 90,
      labelAlign: TextAlign.center,
      color: Theme.of(context).colorScheme.surfaceContainerLow, // sql result tab 的背景色
      selectedColor: Theme.of(context).colorScheme.surfaceContainerHigh, // sql result tab 的选中颜色
      hoverColor: Theme.of(context).colorScheme.surfaceContainer, // sql result tab 的鼠标移入色
    );

    Widget tab = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: CommonTabBar(
            height: 36,
            tabStyle: style,
            onReorder: (oldIndex, newIndex) {
              final sqlResultsServices = ref.read(sQLResultsServicesProvider.notifier);

              sqlResultsServices.reorderSQLResult(model!.sessionId, oldIndex, newIndex);
            },
            tabs: (model != null)
                ? [
                    for (var i = 0; i < model.results.length; i++)
                      CommonTabWrap(
                        label: "${model.results[i].resultId.value}",
                        selected: model.results[i] == model.selected,
                        onTap: () {
                          final sqlResultsServices = ref.read(sQLResultsServicesProvider.notifier);

                          sqlResultsServices.selectSQLResult(model.results[i].resultId);
                        },
                        onDeleted: () {
                          final sqlResultsServices = ref.read(sQLResultsServicesProvider.notifier);
                          sqlResultsServices.deleteSQLResult(model.results[i].resultId);
                        },
                        avatar: (model.results[i] != model.selected && model.results[i].state == SQLExecuteState.init)
                            ? const Loading.small()
                            : const Icon(
                                size: kIconSizeSmall,
                                Icons.grid_on,
                              ),
                      ),
                  ]
                : [],
          ),
        ),
        const SizedBox(width: kSpacingTiny / 2),
      ],
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                alignment: Alignment.centerLeft,
                constraints: const BoxConstraints(maxHeight: 32),
                child: tab,
              ),
              const SizedBox(height: kSpacingTiny),
              const PixelDivider(),
              const Expanded(child: SqlResultTable()),
            ],
          ),
        ),
      ],
    );
  }
}

enum _ResultSelectionScope {
  currentSelection,
  currentRow,
  currentColumn,
  selectedColumns,
  allRows,
}

class _ResultSelectionData {
  final List<String> headers;
  final List<List<String>> rows;
  final bool truncated;

  const _ResultSelectionData({
    required this.headers,
    required this.rows,
    required this.truncated,
  });

  bool get isEmpty => headers.isEmpty || rows.isEmpty;
}

class _AIProcessRequest {
  final String customPrompt;
  final _ResultSelectionScope scope;
  final Set<int> selectedColumns;
  final int maxRows;

  const _AIProcessRequest({
    required this.customPrompt,
    required this.scope,
    required this.selectedColumns,
    required this.maxRows,
  });
}

class SqlResultTable extends ConsumerStatefulWidget {
  const SqlResultTable({super.key});

  @override
  ConsumerState<SqlResultTable> createState() => _SqlResultTableState();
}

class _SqlResultTableState extends ConsumerState<SqlResultTable> {
  static const int _defaultAIMaxRows = 200;
  final Set<int> _selectedColumns = {};

  List<DataGridColumn> buildColumns(
    BuildContext context,
    List<BaseQueryColumn> columns,
    List<QueryResultRow> rows,
  ) {
    List<DataGridColumn> result = [];
    for (int i = 0; i < columns.length; i++) {
      final column = columns[i];
      result.add(
        DataGridColumn.autoSize(
          context: context,
          name: column.name,
          dataType: column.dataType(),
          cells: <DataGridCell>[
            for (int j = 0; j < rows.length; j++)
              DataGridCell(
                data: rows[j].values[i].getSummary() ?? '',
              ),
          ],
        ),
      );
    }
    return result;
  }

  Widget buildEmptyBody(BuildContext context) {
    return EmptyPage(
      child: Text(
        AppLocalizations.of(context)!.display_msg_no_data,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant), // 没有数据时显示的文字颜色
      ),
    );
  }

  Widget buildSuccessBody(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: Theme.of(context).colorScheme.primaryContainer, // SQL执行成功图标颜色
          ),
          const SizedBox(height: kSpacingSmall),
          Text(AppLocalizations.of(context)!.display_msg_execution_success),
        ],
      ),
    );
  }

  Widget buildErrorBody(BuildContext context, SQLResultDetailModel model) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSpacingLarge, kSpacingSmall, kSpacingLarge, kSpacingSmall),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: kIconSizeLarge, color: Theme.of(context).colorScheme.error), // SQL执行错误时图标颜色
            const SizedBox(height: kSpacingMedium),
            TooltipText(text: '${model.error}${model.query}'),
          ],
        ),
      ),
    );
  }

  Widget buildWaitingBody(BuildContext context, WidgetRef ref, SQLResultDetailModel model) {
    return Container(
      alignment: Alignment.topLeft,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Loading.large(),
            const SizedBox(height: kSpacingMedium),
            FilledButton(
              onPressed: () async {
                SessionModel? sessionModel = ref
                    .read(sessionsServicesProvider.notifier)
                    .getSession(
                      model.resultId.sessionId,
                    );

                if (sessionModel == null || sessionModel.connId == null) {
                  return;
                }
                await ref.read(sessionConnsServicesProvider.notifier).killQuery(sessionModel.connId!);
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        ),
      ),
    );
  }

  String _valueToText(BaseQueryValue value) {
    final text = value.getString();
    if (text != null) {
      return text;
    }
    final bytes = value.getBytes();
    if (bytes.isNotEmpty) {
      return base64Encode(bytes);
    }
    return '';
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  String? _tryFormatJson(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    dynamic candidate = trimmed;

    for (int i = 0; i < 3; i++) {
      if (candidate is Map || candidate is List) {
        return const JsonEncoder.withIndent('  ').convert(candidate);
      }
      if (candidate is! String) {
        return null;
      }
      final text = candidate.trim();
      if (text.isEmpty) return null;

      // 支持两类数据：
      // 1) 原生 JSON：{"a":1} / [1,2]
      // 2) JSON 字符串："{\"a\":1}"，需要先反转义再继续解析
      if (!(text.startsWith('{') || text.startsWith('[') || text.startsWith('"'))) {
        // 兼容部分 Redis 返回形态：'{"a":1}'
        if (text.length >= 2 && text.startsWith("'") && text.endsWith("'")) {
          candidate = text.substring(1, text.length - 1);
          continue;
        }
        return null;
      }
      try {
        candidate = jsonDecode(text);
      } catch (_) {
        // 兼容部分 Redis 返回形态：{\"a\":1}（无外层引号，内部被转义）
        if (text.contains(r'\"')) {
          final unescaped = text
              .replaceAll(r'\"', '"')
              .replaceAll(r'\\n', '\n')
              .replaceAll(r'\\r', '\r')
              .replaceAll(r'\\t', '\t');
          try {
            candidate = jsonDecode(unescaped);
            continue;
          } catch (_) {}
        }
        return null;
      }
    }
    return null;
  }

  _ResultSelectionData? _buildSelectionData(
    BaseQueryResult data,
    DataGridController controller, {
    required _ResultSelectionScope scope,
    required Set<int> selectedColumns,
    int maxRows = _defaultAIMaxRows,
  }) {
    if (data.columns.isEmpty || data.rows.isEmpty) {
      _showMessage('当前没有可处理的数据');
      return null;
    }

    final selected = controller.selectedCellPosition;
    final selectedRange = controller.normalizedSelectedRange;
    List<int> columnIndexes;
    switch (scope) {
      case _ResultSelectionScope.currentSelection:
        if (selectedRange == null) {
          _showMessage('请先在结果表中选择一个区域');
          return null;
        }
        columnIndexes = [
          for (int i = selectedRange.startColumn; i <= selectedRange.endColumn; i++) i,
        ];
      case _ResultSelectionScope.currentRow:
        columnIndexes = List<int>.generate(data.columns.length, (i) => i);
      case _ResultSelectionScope.currentColumn:
        if (selected == null) {
          _showMessage('请先点击一个单元格');
          return null;
        }
        columnIndexes = [selected.columnIndex];
      case _ResultSelectionScope.selectedColumns:
        if (selectedColumns.isEmpty) {
          _showMessage('请至少选择一列');
          return null;
        }
        columnIndexes = selectedColumns.toList()..sort();
      case _ResultSelectionScope.allRows:
        columnIndexes = List<int>.generate(data.columns.length, (i) => i);
    }

    List<QueryResultRow> sourceRows;
    switch (scope) {
      case _ResultSelectionScope.currentSelection:
        if (selectedRange == null) {
          _showMessage('请先在结果表中选择一个区域');
          return null;
        }
        sourceRows = data.rows.sublist(selectedRange.startRow, selectedRange.endRow + 1);
      case _ResultSelectionScope.currentRow:
        if (selected == null) {
          _showMessage('请先点击一个单元格');
          return null;
        }
        sourceRows = [data.rows[selected.rowIndex]];
      case _ResultSelectionScope.currentColumn:
      case _ResultSelectionScope.selectedColumns:
      case _ResultSelectionScope.allRows:
        sourceRows = data.rows;
    }

    final limitedRows = sourceRows.take(maxRows).toList(growable: false);
    final headers = columnIndexes.map((i) => data.columns[i].name).toList(growable: false);
    final rows = limitedRows
        .map(
          (row) => columnIndexes.map((i) => _valueToText(row.values[i])).toList(growable: false),
        )
        .toList(growable: false);

    return _ResultSelectionData(
      headers: headers,
      rows: rows,
      truncated: sourceRows.length > limitedRows.length,
    );
  }

  String _scopeLabel(_ResultSelectionScope scope) {
    return switch (scope) {
      _ResultSelectionScope.currentSelection => '当前选区',
      _ResultSelectionScope.currentRow => '当前行',
      _ResultSelectionScope.currentColumn => '当前列',
      _ResultSelectionScope.selectedColumns => '已选多列',
      _ResultSelectionScope.allRows => '全部结果',
    };
  }

  Future<_AIProcessRequest?> _showAIRequestDialog(BaseQueryResult data, DataGridController controller) async {
    final promptController = TextEditingController();
    final maxRowsController = TextEditingController(text: '$_defaultAIMaxRows');
    final selected = controller.selectedCellPosition;
    final selectedRange = controller.normalizedSelectedRange;
    _ResultSelectionScope scope = selectedRange != null
        ? _ResultSelectionScope.currentSelection
        : (selected == null ? _ResultSelectionScope.allRows : _ResultSelectionScope.currentRow);
    var selectedColumns = _selectedColumns.isNotEmpty
        ? {..._selectedColumns}
        : (selected != null ? {selected.columnIndex} : <int>{});

    final result = await showDialog<_AIProcessRequest>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('OpenAI 处理结果'),
              content: SizedBox(
                width: 560,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<_ResultSelectionScope>(
                      initialValue: scope,
                      decoration: const InputDecoration(labelText: '处理范围'),
                      items: _ResultSelectionScope.values
                          .map(
                            (s) => DropdownMenuItem<_ResultSelectionScope>(
                              value: s,
                              child: Text(_scopeLabel(s)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() {
                            scope = v;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: kSpacingSmall),
                    if (scope == _ResultSelectionScope.selectedColumns)
                      Row(
                        children: [
                          Expanded(
                            child: Text('已选列: ${selectedColumns.length}'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDialog<Set<int>>(
                                context: context,
                                builder: (context) {
                                  final tmp = {...selectedColumns};
                                  return StatefulBuilder(
                                    builder: (context, setPickerState) {
                                      return AlertDialog(
                                        title: const Text('选择多列'),
                                        content: SizedBox(
                                          width: 420,
                                          child: ListView(
                                            shrinkWrap: true,
                                            children: [
                                              for (int i = 0; i < data.columns.length; i++)
                                                CheckboxListTile(
                                                  dense: true,
                                                  value: tmp.contains(i),
                                                  title: Text(data.columns[i].name),
                                                  onChanged: (v) {
                                                    setPickerState(() {
                                                      if (v == true) {
                                                        tmp.add(i);
                                                      } else {
                                                        tmp.remove(i);
                                                      }
                                                    });
                                                  },
                                                ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: Text(AppLocalizations.of(context)!.cancel),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(tmp),
                                            child: Text(AppLocalizations.of(context)!.submit),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  selectedColumns = picked;
                                });
                              }
                            },
                            child: const Text('选择列'),
                          ),
                        ],
                      ),
                    const SizedBox(height: kSpacingSmall),
                    TextField(
                      controller: maxRowsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '最多行数（当前选区/全部/多列/当前列时生效）',
                      ),
                    ),
                    const SizedBox(height: kSpacingSmall),
                    TextField(
                      controller: promptController,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: '自定义提示词',
                        hintText: '例如：把结果按金额降序总结，并输出前三条异常数据',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () {
                    final prompt = promptController.text.trim();
                    if (prompt.isEmpty) {
                      return;
                    }
                    final maxRows = int.tryParse(maxRowsController.text.trim()) ?? _defaultAIMaxRows;
                    Navigator.of(context).pop(
                      _AIProcessRequest(
                        customPrompt: prompt,
                        scope: scope,
                        selectedColumns: selectedColumns,
                        maxRows: maxRows.clamp(1, 5000),
                      ),
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.submit),
                ),
              ],
            );
          },
        );
      },
    );

    promptController.dispose();
    maxRowsController.dispose();
    return result;
  }

  Future<void> _processWithOpenAI(
    BaseQueryResult data,
    DataGridController controller,
  ) async {
    final llmAgents = ref.read(lLMAgentProvider);
    final lastUsed = llmAgents.lastUsedLLMAgent;
    if (lastUsed == null) {
      _showMessage('未找到可用的 OpenAI 配置，请先配置模型');
      return;
    }

    final req = await _showAIRequestDialog(data, controller);
    if (req == null) {
      return;
    }

    final selection = _buildSelectionData(
      data,
      controller,
      scope: req.scope,
      selectedColumns: req.selectedColumns,
      maxRows: req.maxRows,
    );
    if (selection == null || selection.isEmpty) {
      return;
    }

    setState(() {
      _selectedColumns
        ..clear()
        ..addAll(req.selectedColumns);
    });

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 72,
          child: Row(
            children: [
              Loading.medium(),
              SizedBox(width: kSpacingMedium),
              Expanded(child: Text('OpenAI 正在处理结果...')),
            ],
          ),
        ),
      ),
    );

    String output;
    try {
      ref.read(lLMAgentServiceProvider.notifier).updateLastUsedLLMAgent(lastUsed.id);
      final llm = LLMProvider.create(lastUsed.setting, '');
      try {
        final payload = {
          'columns': selection.headers,
          'rows': selection.rows,
          'rowCount': selection.rows.length,
          'truncated': selection.truncated,
        };
        final query =
            '''
你是一个 SQL 查询结果处理助手。请严格基于给定结果进行处理。

用户自定义提示词：
${req.customPrompt}

查询结果(JSON)：
${jsonEncode(payload)}

输出要求：
1. 直接输出处理结果。
2. 不要重复原始 JSON。
3. 如果数据不足以完成任务，明确指出缺失信息。
''';

        final response = await llm.call([
          AIChatMessageItem.userMessage(
            AIChatUserMessageModel(
              id: AIChatMessageId.generate(),
              content: query,
            ),
          ),
        ]);
        output = response.content.trim();
      } finally {
        llm.dispose();
      }
    } catch (e) {
      output = '';
      if (mounted) {
        _showMessage('OpenAI 处理失败: $e');
      }
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (!mounted || output.isEmpty) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('OpenAI 处理结果'),
          content: SizedBox(
            width: 680,
            child: SelectableText(output),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: output));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已复制 AI 处理结果')),
                  );
                }
              },
              child: const Text('复制结果'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCellDetailDialog(BaseQueryValue value, BaseQueryColumn column) async {
    final rawText = _valueToText(value);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _CellDetailDialog(
          rawText: rawText,
          columnName: column.name,
          tryFormatJson: _tryFormatJson,
        );
      },
    );
  }

  Widget _buildResultActionBar(
    BuildContext context,
    BaseQueryResult data,
    DataGridController controller,
  ) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: kSpacingSmall),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: kIconSizeSmall,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: kSpacingTiny),
          Expanded(
            child: Text(
              '拖拽选择单元格，点列头选整列，点左侧行号选整行，按 Command/Ctrl + C 复制',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          RectangleIconButton.small(
            tooltip: 'OpenAI 处理结果',
            icon: Icons.auto_awesome,
            iconColor: Colors.orange[700],
            onPressed: () => _processWithOpenAI(data, controller),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(selectedSQLResultProvider);
    if (model == null) {
      return buildEmptyBody(context);
    }
    if (model.state == SQLExecuteState.done) {
      // 非查询语句没有返回值，此时展示空页面
      if (model.data!.columns.isEmpty) {
        return buildSuccessBody(context);
      }
      final controller = SQLResultController.sqlResultController(
        model.resultId,
        () => DataGridController(
          columns: buildColumns(context, model.data!.columns, model.data!.rows),
        ),
      );

      return Column(
        children: [
          _buildResultActionBar(context, model.data!, controller.controller),
          const PixelDivider(),
          Expanded(
            child: DataGrid(
              key: ValueKey(model.resultId),
              controller: controller.controller,
              horizontalScrollGroup: controller.horizontalScrollGroup,
              verticalScrollGroup: controller.verticalScrollGroup,
              onCopySelection: (rows, columns) {
                _showMessage('已复制 $rows 行 $columns 列');
              },
              onCellDoubleTap: (postion) {
                _showCellDetailDialog(
                  model.data!.rows[postion.rowIndex].values[postion.columnIndex],
                  model.data!.rows[postion.rowIndex].columns[postion.columnIndex],
                );
              },
            ),
          ),
        ],
      );
    } else if (model.state == SQLExecuteState.error) {
      return buildErrorBody(context, model);
    } else {
      return buildWaitingBody(context, ref, model);
    }
  }
}

class _CellDetailDialog extends StatefulWidget {
  final String rawText;
  final String columnName;
  final String? Function(String raw) tryFormatJson;

  const _CellDetailDialog({
    required this.rawText,
    required this.columnName,
    required this.tryFormatJson,
  });

  @override
  State<_CellDetailDialog> createState() => _CellDetailDialogState();
}

class _CellDetailDialogState extends State<_CellDetailDialog> {
  static final Map<String, CodeHighlightThemeMode> _jsonLanguage = {
    'json': CodeHighlightThemeMode(mode: langJson),
  };

  bool _jsonView = false;
  String? _formattedJson;
  late final CodeLineEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController.fromText(widget.rawText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _currentText => _jsonView ? (_formattedJson ?? widget.rawText) : widget.rawText;

  void _toggleJsonView() {
    if (_jsonView) {
      setState(() {
        _jsonView = false;
        _controller.text = widget.rawText;
      });
      return;
    }
    final formatted = _formattedJson ?? widget.tryFormatJson(widget.rawText);
    if (formatted == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前内容不是合法 JSON'), duration: Duration(seconds: 2)),
      );
      return;
    }
    setState(() {
      _formattedJson = formatted;
      _jsonView = true;
      _controller.text = formatted;
    });
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _currentText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(
              widget.columnName.isEmpty ? '结果详情' : widget.columnName,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: _jsonView ? '显示原始内容' : 'JSON 格式化',
            icon: Icon(
              Icons.data_object,
              color: _jsonView ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: _toggleJsonView,
          ),
          IconButton(
            tooltip: '复制',
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
          ),
        ],
      ),
      content: SizedBox(
        width: 720,
        height: 480,
        child: CodeEditor(
          controller: _controller,
          readOnly: true,
          wordWrap: false,
          style: CodeEditorStyle(
            codeTheme: _jsonView
                ? CodeHighlightTheme(
                    languages: _jsonLanguage,
                    theme: atomOneLightTheme,
                  )
                : null,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
