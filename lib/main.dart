import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/config/supabase_config.dart';
import 'core/config/theme.dart';
import 'core/router/app_router.dart';

/// Riverpod provider for the router — keeps it in sync with auth state.
final routerProvider = Provider<GoRouter>((ref) => appRouter(ref));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();

  runApp(
    const ProviderScope(
      child: FitTrackOwnerApp(),
    ),
  );
}

class FitTrackOwnerApp extends ConsumerWidget {
  const FitTrackOwnerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (supabaseInitError != null) {
      return MaterialApp(
        title: 'FitTrack Owner — Setup Required',
        theme: appTheme,
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.containerPadding),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(AppSpacing.containerPadding),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(cornerRadius),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SETUP REQUIRED',
                      style: AppText.label.copyWith(color: AppColors.signal),
                    ),
                    const SizedBox(height: AppSpacing.stackSm),
                    Text(
                      'Missing Supabase Keys',
                      style: AppText.display.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    Text(
                      'FitTrack Owner requires Supabase credentials to be supplied at build time via --dart-define parameters.',
                      style: AppText.bodyLg.copyWith(color: AppColors.inkSecondary),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.stackMd),
                      color: AppColors.background,
                      child: SelectableText(
                        supabaseInitError!,
                        style: AppText.dataSm.copyWith(color: AppColors.inkPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'FitTrack Owner',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
