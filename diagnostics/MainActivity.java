package dev.pulserelay.blecheck;
import android.app.Activity;
import android.os.Bundle;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.*;
import android.widget.TextView;
import android.util.Log;
import java.util.LinkedHashMap;
public class MainActivity extends Activity {
  TextView text; BluetoothLeScanner scanner;
  LinkedHashMap<String,String> devices = new LinkedHashMap<>();
  ScanCallback callback = new ScanCallback() {
    public void onScanResult(int type, ScanResult r) {
      String name = r.getScanRecord() == null ? null : r.getScanRecord().getDeviceName();
      String value = (name == null ? "(unnamed)" : name) + "  " + r.getDevice().getAddress() + "  " + r.getRssi() + " dBm";
      if (!devices.containsKey(r.getDevice().getAddress())) Log.i("PulseRelayBLE", value);
      devices.put(r.getDevice().getAddress(), value);
      runOnUiThread(() -> text.setText("Live BLE scan\n\n" + String.join("\n",devices.values())));
    }
    public void onScanFailed(int code) { text.setText("Scan failed: " + code); Log.e("PulseRelayBLE","Scan failed: " + code); }
  };
  public void onCreate(Bundle b) {
    super.onCreate(b); text = new TextView(this); text.setPadding(24,48,24,24); text.setText("Scanning nearby BLE devices..."); setContentView(text);
    try { scanner = getSystemService(BluetoothManager.class).getAdapter().getBluetoothLeScanner(); scanner.startScan(null,new ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build(),callback); }
    catch(Exception e) { text.setText(e.toString()); Log.e("PulseRelayBLE",e.toString()); }
  }
  protected void onDestroy() { if(scanner != null) scanner.stopScan(callback); super.onDestroy(); }
}
