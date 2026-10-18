{{flutter_js}}
{{flutter_build_config}}

// Every build gets its own URL for the app code, so no browser or CDN can
// keep serving an old version after a deploy.
for (const build of _flutter.buildConfig.builds) {
  build.mainJsPath =
    (build.mainJsPath ?? "main.dart.js") + "?v=" + {{flutter_service_worker_version}};
}

_flutter.loader.load();
