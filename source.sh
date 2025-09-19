#!/bin/bash

# Выходим из скрипта при любой ошибке
set -e

# Имя проекта жестко задано
PROJECT_NAME="ParsPost"

# --- Проверка, не существует ли уже директория ---
if [ -d "$PROJECT_NAME" ]; then
  echo "Ошибка: Директория '$PROJECT_NAME' уже существует."
  exit 1
fi

echo "Создание структуры проекта для '$PROJECT_NAME'..."

# --- 1. Создание структуры директорий ---
mkdir -p "$PROJECT_NAME/app/src/main/java/com/example/parspost"
mkdir -p "$PROJECT_NAME/app/src/main/res/layout"
mkdir -p "$PROJECT_NAME/app/src/main/res/menu"
mkdir -p "$PROJECT_NAME/app/src/main/res/values"
mkdir -p "$PROJECT_NAME/app/src/main/res/xml"
mkdir -p "$PROJECT_NAME/gradle/wrapper"

# --- 2. Создание конфигурационных файлов Gradle ---
cat > "$PROJECT_NAME/settings.gradle.kts" << EOF
pluginManagement {
  repositories {
    google()
    mavenCentral()
    gradlePluginPortal()
  }
}
dependencyResolutionManagement {
  repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
  repositories {
    google()
    mavenCentral()
  }
}

rootProject.name = "$PROJECT_NAME"
include(":app")
EOF

cat > "$PROJECT_NAME/build.gradle.kts" << EOF
plugins {
  alias(libs.plugins.android.application) apply false
}
EOF

cat > "$PROJECT_NAME/gradle/libs.versions.toml" << EOF
[versions]
agp = "8.4.1"
appcompat = "1.7.0"
material = "1.12.0"
constraintlayout = "2.1.4"
coreKtx = "1.13.1"
gradle = "8.7"

[libraries]
appcompat = { group = "androidx.appcompat", name = "appcompat", version.ref = "appcompat" }
material = { group = "com.google.android.material", name = "material", version.ref = "material" }
constraintlayout = { group = "androidx.constraintlayout", name = "constraintlayout", version.ref = "constraintlayout" }
core-ktx = { group = "androidx.core", name = "core-ktx", version.ref = "coreKtx" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
EOF

cat > "$PROJECT_NAME/app/build.gradle.kts" << 'EOF'
plugins {
  alias(libs.plugins.android.application)
}

android {
  namespace = "com.example.parspost"
  compileSdk = 34

  defaultConfig {
    applicationId = "com.example.parspost"
    minSdk = 26
    targetSdk = 34
    versionCode = 1
    versionName = "1.0"
  }

  buildTypes {
    release {
      isMinifyEnabled = false
      proguardFiles(
        getDefaultProguardFile("proguard-android-optimize.txt"),
        "proguard-rules.pro"
      )
    }
  }
  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_1_8
    targetCompatibility = JavaVersion.VERSION_1_8
  }
  buildFeatures {
    viewBinding = true
  }
}

dependencies {
  implementation(libs.appcompat)
  implementation(libs.material)
  implementation(libs.constraintlayout)
  implementation(libs.core.ktx)
}
EOF

touch "$PROJECT_NAME/app/proguard-rules.pro"

cat > "$PROJECT_NAME/gradle.properties" << 'EOF'
org.gradle.jvmargs=-Xmx2048m
android.useAndroidX=true
android.nonTransitiveRClass=true
EOF

cat > "$PROJECT_NAME/gradle/wrapper/gradle-wrapper.properties" << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

# --- 3. Создание ресурсов Android (res) ---
cat > "$PROJECT_NAME/app/src/main/AndroidManifest.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
  xmlns:tools="http://schemas.android.com/tools">

  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
  <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />

  <application
    android:allowBackup="true"
    android:dataExtractionRules="@xml/data_extraction_rules"
    android:fullBackupContent="@xml/backup_rules"
    android:icon="@android:drawable/ic_dialog_info"
    android:label="@string/app_name"
    android:supportsRtl="true"
    android:theme="@style/Theme.ParsPost"
    tools:targetApi="34">

    <activity
      android:name=".MainActivity"
      android:exported="true">
      <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
      </intent-filter>
    </activity>

    <activity android:name=".SettingsActivity" />

    <service
      android:name=".SoundService"
      android:enabled="true"
      android:exported="false"
      android:foregroundServiceType="dataSync" />
  </application>
</manifest>
EOF

cat > "$PROJECT_NAME/app/src/main/res/xml/backup_rules.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
</full-backup-content>
EOF

cat > "$PROJECT_NAME/app/src/main/res/xml/data_extraction_rules.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
  <cloud-backup>
  </cloud-backup>
  <device-transfer>
  </device-transfer>
</data-extraction-rules>
EOF

cat > "$PROJECT_NAME/app/src/main/res/layout/activity_main.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
  xmlns:app="http://schemas.android.com/apk/res-auto"
  xmlns:tools="http://schemas.android.com/tools"
  android:layout_width="match_parent"
  android:layout_height="match_parent"
  tools:context=".MainActivity">

  <com.google.android.material.appbar.AppBarLayout
    android:id="@+id/appBarLayout"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    app:layout_constraintTop_toTopOf="parent">

    <com.google.android.material.appbar.MaterialToolbar
      android:id="@+id/toolbar"
      android:layout_width="match_parent"
      android:layout_height="?attr/actionBarSize"
      app:title="@string/app_name" />

  </com.google.android.material.appbar.AppBarLayout>

  <TextView
    android:id="@+id/statusText"
    android:layout_width="0dp"
    android:layout_height="wrap_content"
    android:layout_margin="16dp"
    android:textAlignment="center"
    app:layout_constraintEnd_toEndOf="parent"
    app:layout_constraintStart_toStartOf="parent"
    app:layout_constraintTop_toBottomOf="@id/appBarLayout"
    tools:text="Status" />

  <Button
    android:id="@+id/requestPermissionBtn"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:layout_marginTop="16dp"
    android:text="@string/check_permissions"
    app:layout_constraintBottom_toBottomOf="parent"
    app:layout_constraintEnd_toEndOf="parent"
    app:layout_constraintStart_toStartOf="parent"
    app:layout_constraintTop_toBottomOf="@id/statusText" />

  <ScrollView
    android:id="@+id/logScrollView"
    android:layout_width="0dp"
    android:layout_height="0dp"
    android:layout_margin="16dp"
    android:background="#F5F5F5"
    android:visibility="gone"
    app:layout_constraintBottom_toBottomOf="parent"
    app:layout_constraintEnd_toEndOf="parent"
    app:layout_constraintStart_toStartOf="parent"
    app:layout_constraintTop_toBottomOf="@id/statusText">

    <TextView
      android:id="@+id/logTextView"
      android:layout_width="match_parent"
      android:layout_height="wrap_content"
      android:padding="8dp"
      android:fontFamily="monospace"
      android:textColor="#333333" />
  </ScrollView>

</androidx.constraintlayout.widget.ConstraintLayout>
EOF

cat > "$PROJECT_NAME/app/src/main/res/layout/activity_settings.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
  android:layout_width="match_parent"
  android:layout_height="match_parent"
  android:orientation="vertical"
  android:padding="16dp">

  <TextView
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:labelFor="@+id/urlEditText"
    android:text="@string/server_url_label" />

  <EditText
    android:id="@+id/urlEditText"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:layout_marginTop="8dp"
    android:autofillHints="url"
    android:hint="@string/enter_url_hint"
    android:inputType="textUri" />

  <TextView
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:layout_marginTop="16dp"
    android:labelFor="@+id/intervalEditText"
    android:text="@string/polling_interval_label" />

  <EditText
    android:id="@+id/intervalEditText"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:layout_marginTop="8dp"
    android:autofillHints="false"
    android:hint="@string/polling_interval_hint"
    android:inputType="number" />


  <Button
    android:id="@+id/saveButton"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:layout_gravity="end"
    android:layout_marginTop="16dp"
    android:text="@string/save" />
</LinearLayout>
EOF

cat > "$PROJECT_NAME/app/src/main/res/menu/main_menu.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android"
  xmlns:app="http://schemas.android.com/apk/res-auto">
  <item
    android:id="@+id/action_start_service"
    android:icon="@android:drawable/ic_media_play"
    android:title="@string/start_service"
    app:showAsAction="ifRoom" />
  <item
    android:id="@+id/action_stop_service"
    android:icon="@android:drawable/ic_media_stop"
    android:title="@string/stop_service"
    app:showAsAction="ifRoom" />
  <item
    android:id="@+id/action_settings"
    android:title="@string/settings"
    app:showAsAction="never" />
</menu>
EOF

cat > "$PROJECT_NAME/app/src/main/res/values/strings.xml" << 'EOF'
<resources>
  <string name="app_name">ParsPost</string>
  <string name="check_permissions">Проверить разрешения</string>
  <string name="settings">Настройки</string>
  <string name="start_service">Старт</string>
  <string name="stop_service">Стоп</string>
  <string name="save">Сохранить</string>
  <string name="server_url_label">URL сервера:</string>
  <string name="enter_url_hint">Введите URL</string>
  <string name="url_saved">Настройки сохранены</string>
  <string name="service_running">Сервис запущен</string>
  <string name="service_stopped">Сервис остановлен</string>
  <string name="battery_optimization_enabled">Оптимизация батареи: ВКЛ</string>
  <string name="battery_optimization_disabled">Оптимизация батареи: ВЫКЛ (OK)</string>
  <string name="notification_permission_granted">Уведомления: ЕСТЬ (OK)</string>
  <string name="notification_permission_denied">Уведомления: НЕТ</string>
  <string name="all_permissions_granted">Все разрешения предоставлены</string>
  <string name="polling_interval_label">Интервал опроса (секунды):</string>
  <string name="polling_interval_hint">например, 60</string>
</resources>
EOF

cat > "$PROJECT_NAME/app/src/main/res/values/themes.xml" << 'EOF'
<resources>
  <style name="Theme.ParsPost" parent="Theme.Material3.DayNight.NoActionBar">
  </style>
</resources>
EOF

# --- 4. Создание исходного кода Java ---
cat > "$PROJECT_NAME/app/src/main/java/com/example/parspost/MainActivity.java" << 'EOF'
package com.example.parspost;

import android.Manifest;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.provider.Settings;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;

import com.example.parspost.databinding.ActivityMainBinding;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class MainActivity extends AppCompatActivity {

  private ActivityMainBinding binding;
  public static final String PREFS_NAME = "ParsPostPrefs";
  public static final String KEY_URL = "serverUrl";
  public static final String KEY_INTERVAL = "serverInterval";
  public static final String DEFAULT_URL = "https://httpbin.org/get";
  public static final int DEFAULT_INTERVAL = 60; // 60 секунд

  private final ActivityResultLauncher<String> requestPermissionLauncher =
    registerForActivityResult(new ActivityResultContracts.RequestPermission(), isGranted -> {
      updateStatusAndUi();
    });

  private final BroadcastReceiver logReceiver = new BroadcastReceiver() {
    @Override
    public void onReceive(Context context, Intent intent) {
      if (SoundService.ACTION_LOG_UPDATE.equals(intent.getAction())) {
        String logMessage = intent.getStringExtra(SoundService.EXTRA_LOG_MESSAGE);
        if (logMessage != null) {
          String currentTime = new SimpleDateFormat("HH:mm:ss", Locale.getDefault()).format(new Date());
          binding.logTextView.append(currentTime + ": " + logMessage + "\n\n");
          binding.logScrollView.post(() -> binding.logScrollView.fullScroll(View.FOCUS_DOWN));
        }
      }
    }
  };

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    binding = ActivityMainBinding.inflate(getLayoutInflater());
    setContentView(binding.getRoot());
    setSupportActionBar(binding.toolbar);
    binding.requestPermissionBtn.setOnClickListener(v -> checkAndRequestPermissions());
  }

  @Override
  protected void onResume() {
    super.onResume();
    updateStatusAndUi();
    invalidateOptionsMenu();
    registerReceiver(logReceiver, new IntentFilter(SoundService.ACTION_LOG_UPDATE));
  }

  @Override
  protected void onPause() {
    super.onPause();
    unregisterReceiver(logReceiver);
  }

  @Override
  public boolean onCreateOptionsMenu(Menu menu) {
    getMenuInflater().inflate(R.menu.main_menu, menu);
    return true;
  }

  @Override
  public boolean onPrepareOptionsMenu(Menu menu) {
    MenuItem startItem = menu.findItem(R.id.action_start_service);
    MenuItem stopItem = menu.findItem(R.id.action_stop_service);
    if (SoundService.isRunning) {
      startItem.setVisible(false);
      stopItem.setVisible(true);
    } else {
      startItem.setVisible(true);
      stopItem.setVisible(false);
    }
    return super.onPrepareOptionsMenu(menu);
  }

  @Override
  public boolean onOptionsItemSelected(@NonNull MenuItem item) {
    int id = item.getItemId();
    if (id == R.id.action_start_service) {
      startSoundService();
      return true;
    } else if (id == R.id.action_stop_service) {
      stopSoundService();
      return true;
    } else if (id == R.id.action_settings) {
      startActivity(new Intent(this, SettingsActivity.class));
      return true;
    }
    return super.onOptionsItemSelected(item);
  }

  private void startSoundService() {
    if (!areAllPermissionsGranted()) {
      Toast.makeText(this, "Сначала предоставьте все разрешения", Toast.LENGTH_SHORT).show();
      return;
    }

    SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
    String url = prefs.getString(KEY_URL, DEFAULT_URL);
    int interval = prefs.getInt(KEY_INTERVAL, DEFAULT_INTERVAL);

    Intent serviceIntent = new Intent(this, SoundService.class);
    serviceIntent.putExtra("url", url);
    serviceIntent.putExtra("interval", interval);
    ContextCompat.startForegroundService(this, serviceIntent);

    binding.getRoot().postDelayed(() -> {
      updateStatusAndUi();
      invalidateOptionsMenu();
    }, 200);
  }

  private void stopSoundService() {
    Intent serviceIntent = new Intent(this, SoundService.class);
    stopService(serviceIntent);
    binding.getRoot().postDelayed(() -> {
      updateStatusAndUi();
      invalidateOptionsMenu();
    }, 200);
  }

  private void updateStatusAndUi() {
    String serviceStatus = SoundService.isRunning ? getString(R.string.service_running) : getString(R.string.service_stopped);
    String batteryStatus = isBatteryOptimizationIgnored() ? getString(R.string.battery_optimization_disabled) : getString(R.string.battery_optimization_enabled);
    String notificationStatus = hasNotificationPermission() ? getString(R.string.notification_permission_granted) : getString(R.string.notification_permission_denied);
    binding.statusText.setText(String.format("%s | %s | %s", serviceStatus, batteryStatus, notificationStatus));

    if (areAllPermissionsGranted()) {
      binding.requestPermissionBtn.setVisibility(View.GONE);
      binding.logScrollView.setVisibility(View.VISIBLE);
    } else {
      binding.requestPermissionBtn.setVisibility(View.VISIBLE);
      binding.logScrollView.setVisibility(View.GONE);
    }
  }

  private boolean isBatteryOptimizationIgnored() {
    PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
    return pm.isIgnoringBatteryOptimizations(getPackageName());
  }

  private boolean hasNotificationPermission() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      return ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED;
    }
    return true; // Разрешение не требуется для версий ниже
  }

  private boolean areAllPermissionsGranted() {
    return isBatteryOptimizationIgnored() && hasNotificationPermission();
  }

  private void checkAndRequestPermissions() {
    if (!isBatteryOptimizationIgnored()) {
      Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
      intent.setData(Uri.parse("package:" + getPackageName()));
      startActivity(intent);
    }
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      if (!hasNotificationPermission()) {
        requestPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS);
      }
    }
    binding.getRoot().postDelayed(this::updateStatusAndUi, 200);
  }
}
EOF

cat > "$PROJECT_NAME/app/src/main/java/com/example/parspost/SoundService.java" << 'EOF'
package com.example.parspost;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class SoundService extends Service {
  private static final String CHANNEL_ID = "SoundServiceChannel";
  public static volatile boolean isRunning = false;

  public static final String ACTION_LOG_UPDATE = "com.example.parspost.LOG_UPDATE";
  public static final String EXTRA_LOG_MESSAGE = "log_message";

  private ExecutorService executorService;
  private Handler handler;
  private Runnable pollingRunnable;
  private String requestUrl;
  private int intervalSeconds;

  @Override
  public void onCreate() {
    super.onCreate();
    createNotificationChannel();
    executorService = Executors.newSingleThreadExecutor();
    handler = new Handler(Looper.getMainLooper());
  }

  @Override
  public int onStartCommand(Intent intent, int flags, int startId) {
    if (intent == null) return START_NOT_STICKY;

    isRunning = true;
    requestUrl = intent.getStringExtra("url");
    intervalSeconds = intent.getIntExtra("interval", 60);

    Intent notificationIntent = new Intent(this, MainActivity.class);
    PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE);
    Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
      .setContentTitle("ParsPost Service")
      .setContentText("Сервис запущен. URL: " + requestUrl)
      .setSmallIcon(android.R.drawable.ic_popup_sync)
      .setContentIntent(pendingIntent)
      .build();
    startForeground(1, notification);

    startPolling();
    broadcastLog("Сервис запущен. Интервал: " + intervalSeconds + " сек.");

    return START_STICKY;
  }

  private void startPolling() {
    pollingRunnable = new Runnable() {
      @Override
      public void run() {
        performRequest();
        handler.postDelayed(this, intervalSeconds * 1000L);
      }
    };
    handler.post(pollingRunnable);
  }

  private void performRequest() {
    executorService.execute(() -> {
      HttpURLConnection connection = null;
      try {
        URL url = new URL(requestUrl);
        connection = (HttpURLConnection) url.openConnection();
        connection.setRequestMethod("GET");
        connection.setConnectTimeout(15000); // 15 seconds
        connection.setReadTimeout(15000); // 15 seconds

        int responseCode = connection.getResponseCode();
        StringBuilder response = new StringBuilder();
        response.append("Код ответа: ").append(responseCode).append("\n");

        BufferedReader in = new BufferedReader(new InputStreamReader(
          responseCode >= 200 && responseCode < 300 ? connection.getInputStream() : connection.getErrorStream()));
        String inputLine;
        while ((inputLine = in.readLine()) != null) {
          response.append(inputLine);
        }
        in.close();

        broadcastLog(response.toString());

      } catch (Exception e) {
        broadcastLog("Ошибка: " + e.getMessage());
      } finally {
        if (connection != null) {
          connection.disconnect();
        }
      }
    });
  }

  private void broadcastLog(String message) {
    Intent intent = new Intent(ACTION_LOG_UPDATE);
    intent.putExtra(EXTRA_LOG_MESSAGE, message);
    sendBroadcast(intent);
  }

  @Override
  public void onDestroy() {
    super.onDestroy();
    isRunning = false;
    if (handler != null && pollingRunnable != null) {
      handler.removeCallbacks(pollingRunnable);
    }
    if (executorService != null) {
      executorService.shutdown();
    }
    broadcastLog("Сервис остановлен.");
  }

  @Nullable
  @Override
  public IBinder onBind(Intent intent) {
    return null;
  }

  private void createNotificationChannel() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      NotificationChannel serviceChannel = new NotificationChannel(
        CHANNEL_ID, "Sound Service Channel", NotificationManager.IMPORTANCE_DEFAULT);
      getSystemService(NotificationManager.class).createNotificationChannel(serviceChannel);
    }
  }
}
EOF

cat > "$PROJECT_NAME/app/src/main/java/com/example/parspost/SettingsActivity.java" << 'EOF'
package com.example.parspost;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import com.example.parspost.databinding.ActivitySettingsBinding;

public class SettingsActivity extends AppCompatActivity {
  private ActivitySettingsBinding binding;
  private SharedPreferences prefs;

  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    binding = ActivitySettingsBinding.inflate(getLayoutInflater());
    setContentView(binding.getRoot());
    setTitle(R.string.settings);
    prefs = getSharedPreferences(MainActivity.PREFS_NAME, MODE_PRIVATE);
    loadCurrentSettings();
    binding.saveButton.setOnClickListener(v -> saveSettings());
  }

  private void loadCurrentSettings() {
    String currentUrl = prefs.getString(MainActivity.KEY_URL, MainActivity.DEFAULT_URL);
    int currentInterval = prefs.getInt(MainActivity.KEY_INTERVAL, MainActivity.DEFAULT_INTERVAL);
    binding.urlEditText.setText(currentUrl);
    binding.intervalEditText.setText(String.valueOf(currentInterval));
  }

  private void saveSettings() {
    String newUrl = binding.urlEditText.getText().toString().trim();
    String intervalStr = binding.intervalEditText.getText().toString().trim();
    int newInterval;

    if (newUrl.isEmpty()) {
      binding.urlEditText.setError("URL не может быть пустым");
      return;
    }

    try {
      newInterval = Integer.parseInt(intervalStr);
      if (newInterval <= 0) {
        binding.intervalEditText.setError("Интервал должен быть > 0");
        return;
      }
    } catch (NumberFormatException e) {
      binding.intervalEditText.setError("Введите корректное число");
      return;
    }

    SharedPreferences.Editor editor = prefs.edit();
    editor.putString(MainActivity.KEY_URL, newUrl);
    editor.putInt(MainActivity.KEY_INTERVAL, newInterval);
    editor.apply();

    Toast.makeText(this, R.string.url_saved, Toast.LENGTH_SHORT).show();
    finish();
  }
}
EOF

# --- 5. Создание исполняемых файлов Gradle Wrapper ---
cat > "$PROJECT_NAME/gradlew" << 'EOF'
#!/usr/bin/env sh
# Determine the Java command to run.
if [ -n "$JAVA_HOME" ] ; then
    if [ -x "$JAVA_HOME/jre/sh/java" ] ; then
        JAVACMD="$JAVA_HOME/jre/sh/java"
    else
        JAVACMD="$JAVA_HOME/bin/java"
    fi
    if [ ! -x "$JAVACMD" ] ; then
        echo "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME"
        echo "Please set the JAVA_HOME variable in your environment to match the location of your Java installation."
        exit 1
    fi
else
    JAVACMD="java"
    which java >/dev/null 2>&1 || { echo "ERROR: JAVA_HOME is not set and no 'java' command can be found in your PATH." ; echo "Please set the JAVA_HOME variable in your environment to match the location of your Java installation." ; exit 1; }
fi

# Determine the script directory.
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Add default JVM options for the Gradle daemon.
DEFAULT_JVM_OPTS="-Xmx2048m"

# The classpath for the launcher.
CLASSPATH="$SCRIPT_DIR/gradle/wrapper/gradle-wrapper.jar"

# Set Gradle properties.
export GRADLE_OPTS="$DEFAULT_JVM_OPTS"

# Launch the Gradle build.
exec "$JAVACMD" $GRADLE_OPTS -classpath "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"
EOF

cat > "$PROJECT_NAME/gradlew.bat" << 'EOF'
@if "%DEBUG%" == "" @echo off
@rem Find java.exe
if defined JAVA_HOME goto findJavaFromJavaHome
set JAVA_EXE=java.exe
%JAVA_EXE% -version >NUL 2>&1
if "%ERRORLEVEL%" == "0" goto execute
echo.
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.
goto fail
:findJavaFromJavaHome
set JAVA_EXE=%JAVA_HOME%/bin/java.exe
if exist "%JAVA_EXE%" goto execute
echo.
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME%
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.
goto fail
:execute
@rem Setup the command line args
set CLASSPATH=%APP_HOME%\gradle\wrapper\gradle-wrapper.jar
@rem Execute Gradle
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %* -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain
:fail
if not defined GRADLE_EXIT_CONSOLE (
  exit /b 1
)
exit 1
:mainEnd
if "%OS%"=="Windows_NT" endlocal
:omega
EOF

# --- 6. Установка прав и сборка проекта ---
chmod +x "$PROJECT_NAME/gradlew"
echo "Проект '$PROJECT_NAME' создан успешно."

# --- Добавленная строка: Сборка приложения ---
echo "Сборка APK..."
cd "$PROJECT_NAME"
./gradlew assembleDebug

echo "Процесс сборки завершен. Проверьте лог на наличие ошибок."
