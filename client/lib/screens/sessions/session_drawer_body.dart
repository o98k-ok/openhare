import 'package:client/screens/sessions/session_drawer_metadata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionDrawerBody extends ConsumerWidget {
  const SessionDrawerBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      children: [
        Expanded(child: SessionDrawerMetadata()),
      ],
    );
  }
}
