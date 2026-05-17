import 'package:client/models/ai.dart';
import 'package:client/models/settings.dart';
import 'package:client/screens/page_skeleton.dart';
import 'package:client/services/ai/agent.dart';
import 'package:client/services/settings/settings.dart';
import 'package:client/widgets/button.dart';
import 'package:client/widgets/const.dart';
import 'package:client/widgets/dialog.dart';
import 'package:client/widgets/divider.dart';
import 'package:client/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:client/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SettingModel model = ref.watch(settingProvider);

    return PageSkeleton(
      key: const Key("settings"),
      child: BodyPageSkeleton(
        header: Row(
          children: [
            Text(
              AppLocalizations.of(context)!.settings,
              style: Theme.of(context).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.preferences,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: kSpacingMedium),
            SystemSettingPage(model: model.systemSetting),
            const SizedBox(height: kSpacingMedium),
            const PixelDivider(),
            const SizedBox(height: kSpacingMedium),
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.llm_api,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: kSpacingMedium),
            const Expanded(
              child: LLMApiSettingPage(),
            ),
          ],
        ),
      ),
    );
  }
}

class SystemSettingPage extends ConsumerWidget {
  final SystemSettingModel model;
  const SystemSettingPage({super.key, required this.model});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  const Icon(Icons.language),
                  const SizedBox(width: kSpacingSmall),
                  Text(AppLocalizations.of(context)!.language),
                ],
              ),
            ),
            Row(
              children: [
                _SettingRadioOption(
                  title: const Text("English"),
                  value: "en",
                  selectedValue: model.language,
                  onTap: () => ref.read(systemSettingServiceProvider.notifier).setLanguage("en"),
                ),
                const SizedBox(width: 8),
                _SettingRadioOption(
                  title: const Text("中文"),
                  value: "zh",
                  selectedValue: model.language,
                  onTap: () => ref.read(systemSettingServiceProvider.notifier).setLanguage("zh"),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: kSpacingSmall),
        Row(
          children: [
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  const Icon(Icons.color_lens),
                  const SizedBox(width: kSpacingSmall),
                  Text(AppLocalizations.of(context)!.theme),
                ],
              ),
            ),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SettingRadioOption(
                    title: Text(AppLocalizations.of(context)!.theme_light),
                    value: "light",
                    selectedValue: model.theme,
                    swatchColors: const [
                      Color(0xff3e8ee8),
                      Color(0xfff06c97),
                      Color(0xffffb15f),
                    ],
                    onTap: () => ref.read(systemSettingServiceProvider.notifier).setTheme("light"),
                  ),
                  _SettingRadioOption(
                    title: const Text("薄荷"),
                    value: "mint",
                    selectedValue: model.theme,
                    swatchColors: const [
                      Color(0xff168a7a),
                      Color(0xff4e81bd),
                      Color(0xffdd9635),
                    ],
                    onTap: () => ref.read(systemSettingServiceProvider.notifier).setTheme("mint"),
                  ),
                  _SettingRadioOption(
                    title: const Text("日落"),
                    value: "sunset",
                    selectedValue: model.theme,
                    swatchColors: const [
                      Color(0xffd85b62),
                      Color(0xff8266c7),
                      Color(0xffe18c34),
                    ],
                    onTap: () => ref.read(systemSettingServiceProvider.notifier).setTheme("sunset"),
                  ),
                  _SettingRadioOption(
                    title: const Text("潟湖"),
                    value: "lagoon",
                    selectedValue: model.theme,
                    swatchColors: const [
                      Color(0xff2f72cf),
                      Color(0xff1595ad),
                      Color(0xff8a65d6),
                    ],
                    onTap: () => ref.read(systemSettingServiceProvider.notifier).setTheme("lagoon"),
                  ),
                  _SettingRadioOption(
                    title: Text(AppLocalizations.of(context)!.theme_dark),
                    value: "dark",
                    selectedValue: model.theme,
                    swatchColors: const [
                      Color(0xff84cbd2),
                      Color(0xffddca98),
                      Color(0xff172022),
                    ],
                    onTap: () => ref.read(systemSettingServiceProvider.notifier).setTheme("dark"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingRadioOption extends StatelessWidget {
  final Widget title;
  final String value;
  final String selectedValue;
  final List<Color> swatchColors;
  final VoidCallback onTap;

  const _SettingRadioOption({
    required this.title,
    required this.value,
    required this.selectedValue,
    this.swatchColors = const [],
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selectedValue == value;

    return SizedBox(
      width: 132,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(kSpacingSmall),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.surfaceContainerLow : colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: kIconSizeSmall,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: kSpacingSmall),
                Expanded(child: title),
                if (swatchColors.isNotEmpty) ...[
                  const SizedBox(width: kSpacingSmall),
                  _ThemeSwatch(colors: swatchColors),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  final List<Color> colors;

  const _ThemeSwatch({required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 14,
      child: Stack(
        children: [
          for (var i = 0; i < colors.length; i++)
            Positioned(
              left: i * 8,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LLMApiSettingPage extends ConsumerWidget {
  const LLMApiSettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ref.watch(lLMAgentProvider);

    return GridView.extent(
      maxCrossAxisExtent: 350,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        for (var id in models.agents.keys)
          LLMApiSettingItem(
            key: Key(id.value.toString()),
            model: models.agents[id]!,
            onUpdate: (m) {
              ref.read(lLMAgentServiceProvider.notifier).updateSetting(id, m);
            },
            onDelete: (m) {
              ref.read(lLMAgentServiceProvider.notifier).delete(m);
            },
          ),
        AddLLMApiSettingItem(
          onAdd: (m) {
            ref.read(lLMAgentServiceProvider.notifier).create(m);
          },
        ),
      ],
    );
  }
}

// todo: 表单输入框抽取公共库
InputDecoration _buildDialogInputDecoration(BuildContext context, {required String labelText}) {
  final defaultBorder = OutlineInputBorder(
    borderSide: BorderSide(
      color: Theme.of(context).colorScheme.outline,
    ),
  );
  final errorBorderStyle = OutlineInputBorder(
    borderSide: BorderSide(
      color: Theme.of(context).colorScheme.error,
    ),
  );

  return InputDecoration(
    labelText: labelText,
    border: defaultBorder,
    enabledBorder: defaultBorder,
    disabledBorder: defaultBorder,
    focusedBorder: defaultBorder,
    errorBorder: errorBorderStyle,
    focusedErrorBorder: errorBorderStyle,
  );
}

void showLLMApiSettingDialog(
  BuildContext context,
  String title,
  LLMAgentModel? model,
  Function(LLMAgentSettingModel) onSubmit,
) {
  final nameController = TextEditingController(text: model?.setting.name);
  final baseUrlController = TextEditingController(text: model?.setting.baseUrl);
  final apiKeyController = TextEditingController(text: model?.setting.apiKey);
  final modelNameController = TextEditingController(text: model?.setting.modelName);

  showDialog(
    context: context,
    builder: (context) {
      return CustomDialog(
        title: title,
        subtitle: AppLocalizations.of(context)!.llm_api_only_openai_compatible,
        titleIcon: Icon(Icons.extension, color: Theme.of(context).colorScheme.primary),
        maxWidth: 600,
        maxHeight: 420,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              AppLocalizations.of(context)!.cancel,
            ),
          ),
          const SizedBox(width: kSpacingSmall),
          TextButton(
            onPressed: () {
              onSubmit(
                LLMAgentSettingModel(
                  name: nameController.text,
                  baseUrl: baseUrlController.text,
                  apiKey: apiKeyController.text,
                  modelName: modelNameController.text,
                ),
              );
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context)!.submit),
          ),
        ],
        content: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: _buildDialogInputDecoration(
                context,
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: kSpacingMedium),
            TextField(
              controller: baseUrlController,
              decoration: _buildDialogInputDecoration(
                context,
                labelText: 'Base URL',
              ),
            ),
            const SizedBox(height: kSpacingMedium),
            TextField(
              controller: apiKeyController,
              decoration: _buildDialogInputDecoration(
                context,
                labelText: 'API Key',
              ),
            ),
            const SizedBox(height: kSpacingMedium),
            TextField(
              controller: modelNameController,
              decoration: _buildDialogInputDecoration(
                context,
                labelText: 'Model',
              ),
            ),
          ],
        ),
      );
    },
  );
}

class LLMApiSettingItem extends ConsumerWidget {
  final LLMAgentModel model;
  final Function(LLMAgentSettingModel) onUpdate;
  final Function(LLMAgentId) onDelete;

  const LLMApiSettingItem({
    super.key,
    required this.model,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(lLMAgentProvider).agents[model.id]!.status;

    return Container(
      constraints: const BoxConstraints(),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow, // LLM API配置卡片的背景颜色
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), // 添加模型的卡片边框颜色
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(kSpacingMedium, kSpacingSmall, kSpacingMedium, kSpacingSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    model.setting.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                RectangleIconButton.small(
                  icon: Icons.close,
                  onPressed: () {
                    onDelete(model.id); // todo: 需要二次确认
                  },
                ),
              ],
            ),
            const SizedBox(height: kSpacingSmall),
            _InfoRow(label: "Base URL", value: model.setting.baseUrl),
            const SizedBox(height: kSpacingTiny),
            _InfoRow(
              label: "API Key",
              value: model.setting.apiKey.length > 10
                  ? model.setting.apiKey.replaceRange(
                      4,
                      model.setting.apiKey.length - 4,
                      '*' * (model.setting.apiKey.length - 8),
                    )
                  : model.setting.apiKey,
            ),
            const SizedBox(height: kSpacingTiny),
            _InfoRow(label: "Model", value: model.setting.modelName),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Spacer(),
                switch (status.state) {
                  LLMAgentState.testing => const Loading.small(),
                  LLMAgentState.available => RectangleIconButton.small(
                    tooltip: AppLocalizations.of(context)!.button_tooltip_ai_test,
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green,
                    onPressed: () {
                      ref.read(lLMAgentServiceProvider.notifier).ping(model.id);
                    },
                  ),
                  LLMAgentState.unavailable => RectangleIconButton.small(
                    tooltip: status.error ?? "",
                    icon: Icons.error_outline,
                    iconColor: Colors.red,
                    onPressed: () {
                      ref.read(lLMAgentServiceProvider.notifier).ping(model.id);
                    },
                  ),
                  LLMAgentState.unknown => RectangleIconButton.small(
                    tooltip: AppLocalizations.of(context)!.button_tooltip_ai_test,
                    icon: Icons.flash_on,
                    onPressed: () {
                      ref.read(lLMAgentServiceProvider.notifier).ping(model.id);
                    },
                  ),
                },
                RectangleIconButton.small(
                  icon: Icons.edit,
                  onPressed: () {
                    showLLMApiSettingDialog(
                      context,
                      '${AppLocalizations.of(context)!.update}: ${model.setting.name}',
                      model,
                      onUpdate,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddLLMApiSettingItem extends StatelessWidget {
  final Function(LLMAgentSettingModel) onAdd;
  const AddLLMApiSettingItem({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow, // 添加模型的卡片的背景颜色
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), // 添加模型的卡片边框颜色
      ),
      child: Center(
        child: IconButton(
          onPressed: () {
            showLLMApiSettingDialog(
              context,
              AppLocalizations.of(context)!.create,
              null,
              onAdd,
            );
          },
          icon: Icon(
            Icons.add,
            size: kIconSizeLarge,
            color: Theme.of(context).colorScheme.onSurfaceVariant, // 添加模型的按钮颜色
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
