import 'package:client/models/sessions.dart';
import 'package:client/screens/instances/instance_tables.dart';
import 'package:client/screens/settings/settings.dart';
import 'package:client/screens/about/about.dart';
import 'package:client/screens/sessions/sessions.dart';
import 'package:client/services/sessions/sessions.dart';
import 'package:client/services/settings/settings.dart';
import 'package:client/widgets/const.dart';
import 'package:client/widgets/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:client/l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'package:client/screens/tasks/task.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class App extends HookConsumerWidget {
  App({super.key});

  final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/sessions',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: "/sessions",
        pageBuilder: (context, state) => const NoTransitionPage<void>(child: SessionsPage()),
      ),
      GoRoute(
        path: "/tasks",
        pageBuilder: (context, state) => const NoTransitionPage<void>(child: TaskPage()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => const NoTransitionPage<void>(child: SettingsPage()),
      ),
      // About 页面
      GoRoute(
        path: '/about',
        pageBuilder: (context, state) => const NoTransitionPage<void>(child: AboutPage()),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        pageBuilder: (BuildContext context, GoRouterState state, Widget child) {
          return NoTransitionPage<void>(child: child);
        },
        routes: [
          GoRoute(
            path: "/instances",
            redirect: (context, state) {
              if (lastInstancePage == '/instances/add') {
                return '/instances/list';
              }
              return lastInstancePage;
            },
          ),
          GoRoute(
            path: '/instances/list',
            pageBuilder: (context, state) {
              lastInstancePage = '/instances/list';
              return const NoTransitionPage<void>(child: InstancesPage());
            },
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        windowManager.addListener(_WindowListener(ref));
      });
      return null;
    }, []);

    final model = ref.watch(systemSettingProvider);

    return MaterialApp.router(
      title: 'openhare',
      theme: defaultTheme(model.theme),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(model.language),
    );
  }
}

String lastInstancePage = "/instances/list";

class ScaffoldWithNavRail extends StatefulWidget {
  final Widget child;

  const ScaffoldWithNavRail({
    super.key,
    required this.child,
  });

  @override
  State<ScaffoldWithNavRail> createState() => _ScaffoldWithNavRailState();
}

class _ScaffoldWithNavRailState extends State<ScaffoldWithNavRail> {
  bool extended = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedIndex = _calculateSelectedIndex(context);
    final destinations = _destinations(context);

    return Row(
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: extended ? navigationSidebarExpandedWidth : navigationSidebarCollapsedWidth,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(
                  colorScheme.primary.withValues(alpha: theme.brightness == Brightness.light ? 0.05 : 0.08),
                  colorScheme.surface,
                ),
                colorScheme.surface,
              ],
            ),
            border: Border(
              right: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(horizontal: extended ? 14 : 0, vertical: 14),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      colorScheme.primary.withValues(alpha: theme.brightness == Brightness.light ? 0.05 : 0.08),
                      colorScheme.surfaceContainerLow,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(
                                alpha: theme.brightness == Brightness.light ? 0.06 : 0.2,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Image.asset('assets/icons/logo.png'),
                      ),
                      if (extended) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'openhare',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                destinations[selectedIndex].label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      IconButton(
                        onPressed: () {
                          setState(() {
                            extended = !extended;
                          });
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerLowest,
                          foregroundColor: colorScheme.onSurfaceVariant,
                          minimumSize: const Size(40, 40),
                        ),
                        icon: Icon(
                          extended ? Icons.menu_open_rounded : Icons.menu_rounded,
                          size: kIconSizeMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.separated(
                    itemCount: destinations.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final item = destinations[index];
                      final selected = index == selectedIndex;
                      final itemColor = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;
                      final itemBackground = selected
                          ? Color.alphaBlend(
                              colorScheme.primary.withValues(alpha: theme.brightness == Brightness.light ? 0.08 : 0.12),
                              colorScheme.primaryContainer,
                            )
                          : Colors.transparent;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _onItemTapped(index, context),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            padding: EdgeInsets.symmetric(horizontal: extended ? 14 : 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: itemBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? colorScheme.primary.withValues(alpha: 0.16) : Colors.transparent,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: colorScheme.primary.withValues(
                                          alpha: theme.brightness == Brightness.light ? 0.12 : 0.18,
                                        ),
                                        blurRadius: 18,
                                        offset: const Offset(0, 10),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? colorScheme.surfaceContainerLowest
                                        : colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: item.iconBuilder(itemColor),
                                ),
                                if (extended) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: extended ? 1 : 0,
                  child: IgnorePointer(
                    ignoring: !extended,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Text(
                        destinations[selectedIndex].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }

  List<_SidebarDestination> _destinations(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _SidebarDestination(
        label: l10n.sessions,
        iconBuilder: (color) => Icon(Icons.terminal_rounded, size: kIconSizeMedium, color: color),
      ),
      _SidebarDestination(
        label: l10n.scheduled_task,
        iconBuilder: (color) => Icon(Icons.schedule_rounded, size: kIconSizeMedium, color: color),
      ),
      _SidebarDestination(
        label: l10n.db_instance,
        iconBuilder: (color) => HugeIcon(
          icon: HugeIcons.strokeRoundedDatabase,
          color: color,
          size: kIconSizeMedium + 2,
        ),
      ),
      _SidebarDestination(
        label: l10n.settings,
        iconBuilder: (color) => Icon(Icons.tune_rounded, size: kIconSizeMedium, color: color),
      ),
      _SidebarDestination(
        label: l10n.about,
        iconBuilder: (color) => Icon(Icons.info_outline_rounded, size: kIconSizeMedium, color: color),
      ),
    ];
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/sessions')) {
      return 0;
    }
    if (location.startsWith('/tasks')) {
      return 1;
    }
    if (location.startsWith('/instances')) {
      return 2;
    }
    if (location.startsWith('/settings')) {
      return 3;
    }
    if (location.startsWith('/about')) {
      return 4;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    if (index == _ScaffoldWithNavRailState._calculateSelectedIndex(context)) {
      return;
    }
    switch (index) {
      case 0:
        GoRouter.of(context).go('/sessions');
        break;
      case 1:
        GoRouter.of(context).go('/tasks');
        break;
      case 2:
        GoRouter.of(context).go('/instances');
        break;
      case 3:
        GoRouter.of(context).go('/settings');
        break;
      case 4:
        GoRouter.of(context).go('/about');
        break;
    }
  }
}

class _SidebarDestination {
  const _SidebarDestination({
    required this.label,
    required this.iconBuilder,
  });

  final String label;
  final Widget Function(Color color) iconBuilder;
}

class _WindowListener with WindowListener {
  final WidgetRef ref;

  _WindowListener(this.ref);

  @override
  void onWindowClose() async {
    SessionDetailListModel sessions = ref.read(sessionTabProvider);
    for (var session in sessions.sessions) {
      ref.read(sessionsServicesProvider.notifier).saveCode(session.sessionId);
    }
    await windowManager.destroy();
  }
}
