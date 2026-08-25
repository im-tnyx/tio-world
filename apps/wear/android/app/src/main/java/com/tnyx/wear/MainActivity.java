package com.tnyx.wear;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String DEVICE_CHANNEL = "com.tnyx.wear/device";

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                DEVICE_CHANNEL
        ).setMethodCallHandler((call, result) -> {
            if ("isScreenRound".equals(call.method)) {
                result.success(getResources().getConfiguration().isScreenRound());
                return;
            }
            result.notImplemented();
        });
    }
}
