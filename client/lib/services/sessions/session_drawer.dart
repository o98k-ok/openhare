import 'package:client/models/sessions.dart';
import 'package:client/services/sessions/sessions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_drawer.g.dart';

@Riverpod(keepAlive: true)
class SessionDrawerServices extends _$SessionDrawerServices {
  @override
  SessionDrawerModel build(SessionId sessionId) {
    return SessionDrawerModel(
      sessionId: sessionId,
      drawerPage: DrawerPage.metadataTree,
      isRightPageOpen: true,
    );
  }

  void showRightPage() {
    state = state.copyWith(isRightPageOpen: true);
  }

  void hideRightPage() {
    state = state.copyWith(isRightPageOpen: false);
  }

  void goToTree() {
    state = state.copyWith(drawerPage: DrawerPage.metadataTree);
  }
}

@Riverpod(keepAlive: true)
class SessionDrawerNotifier extends _$SessionDrawerNotifier {
  @override
  SessionDrawerModel build() {
    SessionModel? sessionModel = ref.watch(selectedSessionProvider);
    if (sessionModel == null) {
      return ref.watch(sessionDrawerServicesProvider(const SessionId(value: 0)));
    }
    return ref.watch(sessionDrawerServicesProvider(sessionModel.sessionId));
  }
}
