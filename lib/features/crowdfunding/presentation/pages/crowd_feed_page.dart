import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../components/crowd_post_tile.dart';
import '../cubits/crowd_cubit.dart';
import '../cubits/crowd_states.dart';

class CrowdFeedPage extends StatefulWidget {
  const CrowdFeedPage({super.key});

  @override
  State<CrowdFeedPage> createState() => _CrowdFeedPageState();
}

class _CrowdFeedPageState extends State<CrowdFeedPage> {
  @override
  void initState() {
    super.initState();
    context.read<CrowdCubit>().fetchAllCrowds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "V I L L A G E  F E E D",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0, // 🔥 flat Instagram look
      ),
      body: BlocBuilder<CrowdCubit, CrowdState>(
        builder: (context, state) {
          if (state is CrowdLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CrowdLoaded) {
            final crowds = state.crowds;
            if (crowds.isEmpty) {
              return const Center(child: Text("No causes yet."));
            }

            return ListView.builder(
              padding: EdgeInsets.zero, // 🔥 removes gaps
              itemCount: crowds.length,
              itemBuilder: (context, index) {
                return CrowdPostTile(
                  crowdPost: crowds[index],
                );
              },
            );
          }

          return const Center(child: Text("Error loading feed"));
        },
      ),
    );
  }
}
