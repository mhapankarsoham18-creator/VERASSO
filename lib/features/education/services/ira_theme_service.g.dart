// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ira_theme_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(IraThemeService)
final iraThemeServiceProvider = IraThemeServiceProvider._();

final class IraThemeServiceProvider
    extends $NotifierProvider<IraThemeService, IraThemeState> {
  IraThemeServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'iraThemeServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$iraThemeServiceHash();

  @$internal
  @override
  IraThemeService create() => IraThemeService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IraThemeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IraThemeState>(value),
    );
  }
}

String _$iraThemeServiceHash() => r'65918c710bf5288aafe1ca73fa715dc811bd5cb0';

abstract class _$IraThemeService extends $Notifier<IraThemeState> {
  IraThemeState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<IraThemeState, IraThemeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<IraThemeState, IraThemeState>,
              IraThemeState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
