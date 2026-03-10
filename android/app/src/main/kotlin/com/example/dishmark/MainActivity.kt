package com.example.dishmark

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private companion object {
        const val NAVIGATION_CHANNEL = "dishmark/navigation"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NAVIGATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "launchNavigation") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val mapType = call.argument<String>("mapType")
                val latitude = call.argument<Double>("latitude")
                val longitude = call.argument<Double>("longitude")
                val placeName = call.argument<String>("placeName") ?: "目的地"

                if (mapType == null || latitude == null || longitude == null) {
                    result.error("INVALID_ARGS", "Missing map arguments", null)
                    return@setMethodCallHandler
                }
                result.success(
                    launchNavigation(
                        mapType = mapType,
                        latitude = latitude,
                        longitude = longitude,
                        placeName = placeName
                    )
                )
            }
    }

    private fun launchNavigation(
        mapType: String,
        latitude: Double,
        longitude: Double,
        placeName: String
    ): Boolean {
        val candidateUris = buildNavigationUris(
            mapType = mapType,
            latitude = latitude,
            longitude = longitude,
            placeName = placeName
        )
        for (uriString in candidateUris) {
            if (tryLaunchUri(uriString)) {
                return true
            }
        }
        return false
    }

    private fun buildNavigationUris(
        mapType: String,
        latitude: Double,
        longitude: Double,
        placeName: String
    ): List<String> {
        val encodedName = Uri.encode(placeName)
        return when (mapType) {
            "amap" -> listOf(
                "androidamap://navi?sourceApplication=dishmark&lat=$latitude&lon=$longitude&dev=0&style=2",
                "androidamap://route?sourceApplication=dishmark&dlat=$latitude&dlon=$longitude&dname=$encodedName&dev=0&t=0"
            )

            "tencent" -> listOf(
                "qqmap://map/routeplan?type=drive&tocoord=$latitude,$longitude&to=$encodedName&referer=dishmark",
                "qqmap://map/routeplan?type=drive&from=我的位置&to=$encodedName&tocoord=$latitude,$longitude&policy=1&referer=dishmark"
            )

            "baidu" -> listOf(
                "baidumap://map/direction?destination=latlng:$latitude,$longitude|name:$encodedName&mode=driving&coord_type=gcj02&src=dishmark",
                "baidumap://map/navi?location=$latitude,$longitude&query=$encodedName&src=dishmark"
            )

            "apple" -> listOf("https://maps.apple.com/?daddr=$latitude,$longitude&dirflg=d")
            else -> emptyList()
        }
    }

    private fun tryLaunchUri(uriString: String): Boolean {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uriString)).apply {
            addCategory(Intent.CATEGORY_DEFAULT)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        return try {
            intent.resolveActivity(packageManager) ?: return false
            startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: Exception) {
            false
        }
    }
}
