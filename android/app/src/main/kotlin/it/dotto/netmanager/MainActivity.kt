package it.dotto.netmanager

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.telephony.CellInfo
import android.telephony.CellInfoGsm
import android.telephony.CellInfoLte
import android.telephony.CellInfoNr
import android.telephony.CellInfoWcdma
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.HashMap
import com.google.gson.Gson

class MainActivity: FlutterActivity() {
    private val CHANNEL = "it.dotto.netmanager/telephony"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissions" -> {
                    val perms = checkPermissions()
                    if (!perms) requestPermissions()
                    result.success(perms)
                }

                "requestPermissions" -> {
                    requestPermissions()
                    result.success(true)
                }

                "getCarrier" -> {
                    val carrier = getCarrier()
                    if (carrier != "NetManager") result.success(carrier)
                    else result.error("Unknown", "Unknown", null) //add proper error handling
                }

                "getNetworkData" -> {
                    val data = getNetworkData()
                    result.success(data)
                }

                "getNetworkGen" -> {
                    val gen = getNetworkGen()
                    result.success(gen)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun checkPermissions(): Boolean {
        return ActivityCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED &&
                ActivityCompat.checkSelfPermission(
                    context,
                    Manifest.permission.READ_PHONE_STATE
                ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestPermissions() {
        ActivityCompat.requestPermissions(
            context as Activity,
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.READ_PHONE_STATE,
            ),
            1
        )
    }

    private fun getTelephony(): TelephonyManager {
        return context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
    }

    private fun getCarrier(): String {
        return this.getTelephony().networkOperatorName
    }

    data class CellInfoData(
        val registered: Boolean, //Generic info
        val cellId: String,
        val type: String,

        val arfcn: String? = null, //GSM info
        val bsic: String? = null,
        val lac: String? = null,

        val uarfcn: String? = null, //WCDMA info
        val psc: String? = null,
        val ecno: String? = null,

        val earfcn: String? = null, //LTE info
        val pci: String? = null,
        val tac: String? = null,
        val bw: String? = null,
        val bands: String? = null,
        val rsrp: String? = null,
        val rsrq: String? = null,
        val snr: String? = null,
        val ta: String? = null,
        val rssi: String? = null
    )

    @SuppressLint("MissingPermission")
    private fun getNetworkData(): String {
        val cellInfoList: List<CellInfo> = this.getTelephony().getAllCellInfo()
        val dataList = mutableListOf<CellInfoData>()
        val gson = Gson()

        for (cellInfo in cellInfoList) {
            val data = when (cellInfo) {
                is CellInfoGsm -> CellInfoData(
                    registered = cellInfo.isRegistered(),
                    cellId = cellInfo.cellIdentity.cid.toString(),
                    type = "GSM",
                    arfcn = cellInfo.cellIdentity.arfcn.toString(),
                    bsic = cellInfo.cellIdentity.bsic.toString(),
                    lac = cellInfo.cellIdentity.lac.toString(),
                )
                is CellInfoWcdma -> CellInfoData(
                    registered = cellInfo.isRegistered(),
                    cellId = cellInfo.cellIdentity.cid.toString(),
                    type = "WCDMA",
                    uarfcn = cellInfo.cellIdentity.uarfcn.toString(),
                    psc = cellInfo.cellIdentity.psc.toString(),
                    lac = cellInfo.cellIdentity.lac.toString(),
                    ecno = cellInfo.cellSignalStrength.ecNo.toString(),
                )
                is CellInfoLte -> CellInfoData(
                    registered = cellInfo.isRegistered(),
                    cellId = cellInfo.cellIdentity.ci.toString(),
                    type = "LTE",
                    earfcn = cellInfo.cellIdentity.earfcn.toString(),
                    pci = cellInfo.cellIdentity.pci.toString(),
                    tac = cellInfo.cellIdentity.tac.toString(),
                    bw = cellInfo.cellIdentity.bandwidth.toString(),
                    bands = cellInfo.cellIdentity.bands.toString(),
                    rsrp = cellInfo.cellSignalStrength.rsrp.toString(),
                    rsrq = cellInfo.cellSignalStrength.rsrq.toString(),
                    rssi = cellInfo.cellSignalStrength.rssi.toString(),
                    snr = cellInfo.cellSignalStrength.rssnr.toString(),
                    ta = cellInfo.cellSignalStrength.timingAdvance.toString(),
                )
                else -> throw UnsupportedOperationException("Unsupported cell info type")
            }
            dataList.add(data)
        }

        return gson.toJson(dataList)
    }

    @SuppressLint("MissingPermission")
    private fun getNetworkGen(): Int {
        val telephony: TelephonyManager = this.getTelephony()
        if (!this.checkPermissions()) return -1

        return when (telephony.dataNetworkType) {
            TelephonyManager.NETWORK_TYPE_UNKNOWN -> -1

            TelephonyManager.NETWORK_TYPE_GPRS,
            TelephonyManager.NETWORK_TYPE_EDGE,
            TelephonyManager.NETWORK_TYPE_CDMA,
            TelephonyManager.NETWORK_TYPE_1xRTT,
            TelephonyManager.NETWORK_TYPE_GSM -> 2

            TelephonyManager.NETWORK_TYPE_UMTS,
            TelephonyManager.NETWORK_TYPE_EVDO_0,
            TelephonyManager.NETWORK_TYPE_EVDO_A,
            TelephonyManager.NETWORK_TYPE_EVDO_B,
            TelephonyManager.NETWORK_TYPE_HSDPA,
            TelephonyManager.NETWORK_TYPE_HSUPA,
            TelephonyManager.NETWORK_TYPE_HSPA,
            TelephonyManager.NETWORK_TYPE_EHRPD,
            TelephonyManager.NETWORK_TYPE_HSPAP,
            TelephonyManager.NETWORK_TYPE_TD_SCDMA -> 3

            TelephonyManager.NETWORK_TYPE_LTE,
            TelephonyManager.NETWORK_TYPE_IWLAN -> 4

            TelephonyManager.NETWORK_TYPE_NR -> 5

            else -> -1
        }
    }
}