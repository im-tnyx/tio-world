package com.tnyx.tio;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.UserManager;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

/**
 * Dependency-free Health Connect surface-presence probe for O7C1.
 *
 * This bridge intentionally does not claim SDK readiness or authorization. It
 * only reports whether a Health Connect framework/provider surface can be found
 * on the current Android profile. A future O7C2 adapter must use the official
 * Health Connect client to determine SDK status and permission state.
 */
final class HealthConnectAvailabilityBridge {
    static final String CHANNEL_NAME = "com.tnyx.tio/health_connect_availability";
    private static final String METHOD_GET_AVAILABILITY = "getAvailability";
    private static final String HEALTH_CONNECT_PROVIDER = "com.google.android.apps.healthdata";
    private static final String HEALTH_CONNECT_SETTINGS_ACTION =
            "androidx.health.ACTION_HEALTH_CONNECT_SETTINGS";
    private static final String HEALTH_CONNECT_SERVICE = "health_connect";

    private HealthConnectAvailabilityBridge() {
    }

    static void register(Context context, BinaryMessenger messenger) {
        MethodChannel channel = new MethodChannel(messenger, CHANNEL_NAME);
        channel.setMethodCallHandler((call, result) -> {
            if (!METHOD_GET_AVAILABILITY.equals(call.method)) {
                result.notImplemented();
                return;
            }
            result.success(isSurfacePresent(context) ? "present" : "absent");
        });
    }

    private static boolean isSurfacePresent(Context context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            return false;
        }

        UserManager userManager = (UserManager) context.getSystemService(Context.USER_SERVICE);
        if (userManager != null && userManager.isManagedProfile()) {
            return false;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            return context.getSystemService(HEALTH_CONNECT_SERVICE) != null;
        }

        Intent settingsIntent = new Intent(HEALTH_CONNECT_SETTINGS_ACTION)
                .setPackage(HEALTH_CONNECT_PROVIDER);
        PackageManager packageManager = context.getPackageManager();
        return packageManager.resolveActivity(
                settingsIntent,
                PackageManager.MATCH_DEFAULT_ONLY
        ) != null;
    }
}
