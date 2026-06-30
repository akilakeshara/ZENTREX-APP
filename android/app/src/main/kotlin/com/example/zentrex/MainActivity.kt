package com.example.zentrex

import android.app.ActivityManager
import android.content.Context
import android.os.Debug
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.zentrex/memory"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getMemoryInfo") {
                val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                
                // Device Memory
                val memoryInfo = ActivityManager.MemoryInfo()
                activityManager.getMemoryInfo(memoryInfo)
                val totalMem = memoryInfo.totalMem
                val availMem = memoryInfo.availMem

                // App Memory
                val myPid = android.os.Process.myPid()
                val processMemoryInfo = activityManager.getProcessMemoryInfo(intArrayOf(myPid))
                val appTotalPss = (processMemoryInfo[0].totalPss * 1024).toLong() // convert KB to Bytes

                val data = mapOf(
                    "deviceTotalMem" to totalMem,
                    "deviceAvailMem" to availMem,
                    "appTotalMem" to appTotalPss
                )
                result.success(data)
            } else {
                result.notImplemented()
            }
        }
    }
}
