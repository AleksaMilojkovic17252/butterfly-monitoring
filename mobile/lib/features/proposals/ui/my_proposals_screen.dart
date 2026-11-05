import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/proposals/data/proposal_repository.dart';
import 'package:mobile/features/proposals/ui/widgets/proposal_tile.dart';

/// The researcher's route proposals of a project (T108), at
/// `/projects/:id/proposals`: each with its status, the admin's note and the
/// code of the transect made from it. Read-only: the phone only creates
/// proposals, so there is no detail screen, edit or withdraw. Reads Drift
/// only, so it works offline.
class MyProposalsScreen extends ConsumerWidget {
  const MyProposalsScreen({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposals = ref.watch(myProposalsProvider(projectId));
    return Scaffold(
      appBar: AppBar(title: const Text('My proposals')),
      body: SafeArea(
        top: false,
        child: switch (proposals) {
          AsyncData(:final value) when value.isEmpty => const Center(
            child: Text('No route proposals yet.'),
          ),
          AsyncData(:final value) => ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: value.length,
            itemBuilder: (context, i) => ProposalTile(proposal: value[i]),
          ),
          AsyncError(:final error) => Center(child: Text('$error')),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}
