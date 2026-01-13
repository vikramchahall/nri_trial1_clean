import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../auth/presentation/cubits/auth_states.dart' as app_auth;

import 'package:nri_trial1_clean/features/storage/data/search_repository.dart';

import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';

import '../widgets/search_app_bar.dart';
import '../widgets/following_feed_grid.dart';
import '../widgets/search_results_overlay.dart';



class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchCubit(const SearchRepository()),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, app_auth.AuthState>(
      builder: (context, authState) {
        final currentUser =
            authState is app_auth.Authenticated ? authState.user : null;

        return BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            final cubit = context.read<SearchCubit>();

            return Scaffold(
              appBar: SearchAppBar(
                controller: _controller,
                isSearching: state.isSearching,
                onChanged: cubit.onQueryChanged,
                onClear: () {
                  _controller.clear();
                  cubit.clear();
                  context.read<SearchCubit>().clear(); // clears results
  FocusScope.of(context).unfocus();
                },
              ),
              body: Stack(
                children: [
                  FollowingFeedGrid(
                    followingList: currentUser?.following ?? [],
                  ),
                  if (state.isSearching)
                    SearchResultsOverlay(
                      isLoading: state.isLoading,
                      results: state.results,
                      onClose: cubit.clear,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
