package io.flutter.app;

import android.content.Context;
import android.util.Log;

import androidx.annotation.CallSuper;
import androidx.multidex.MultiDex;

/**
 * Enhanced Flutter application with improved error handling.
 * This class adds better error handling for Flutter engine initialization and
 * handles multidex support for Android applications.
 */
public class FlutterMultiDexApplication extends FlutterApplication {
    private static final String TAG = "FlutterMultiDexApp";

    @Override
    @CallSuper
    protected void attachBaseContext(Context base) {
        super.attachBaseContext(base);
        MultiDex.install(this);
    }

    @Override
    public void onCreate() {
        try {
            // Force class loading of Flutter engine to fail early if there are issues
            Class.forName("io.flutter.embedding.engine.FlutterEngine");
            Log.i(TAG, "Flutter engine class loaded successfully");
            
            super.onCreate();
            Log.i(TAG, "Application onCreate completed successfully");
        } catch (Throwable e) {
            Log.e(TAG, "Error initializing Flutter engine", e);
            // Print a more detailed error to help diagnose the issue
            Log.e(TAG, "Flutter initialization failed: " + e.getMessage());
            
            // Try to recover and continue initialization
            try {
                super.onCreate();
                Log.i(TAG, "Attempted recovery of application initialization");
            } catch (Exception recovery) {
                Log.e(TAG, "Recovery failed", recovery);
            }
        }
    }
} 