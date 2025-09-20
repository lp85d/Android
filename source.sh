#!/bin/bash
# Выходим из скрипта при любой ошибке
set -e

# Имя проекта жестко задано
PROJECT_NAME="ParsPost"

# --- Проверка, не существует ли уже директория ---
if [ -d "$PROJECT_NAME" ]; then
  echo "Error: Directory '$PROJECT_NAME' already exists."
  exit 1
fi

echo "Creating project structure for '$PROJECT_NAME'..."

# --- 1. Создание структуры директорий ---
mkdir -p "$PROJECT_NAME/app/src/main/java/com/example/parspost"
mkdir -p "$PROJECT_NAME/app/src/main/res/layout"
mkdir -p "$PROJECT_NAME/app/src/main/res/menu"
mkdir -p "$PROJECT_NAME/app/src/main/res/values"
mkdir -p "$PROJECT_NAME/app/src/main/res/xml"
mkdir -p "$PROJECT_NAME/app/src/main/res/drawable"
mkdir -p "$PROJECT_NAME/gradle/wrapper"

# --- 2. Создание конфигурационных файлов Gradle ---

# settings.gradle.kts
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

# Корневой build.gradle.kts
cat > "$PROJECT_NAME/build.gradle.kts" << EOF
plugins {
    alias(libs.plugins.android.application) apply false
}
EOF

# gradle/libs.versions.toml
cat > "$PROJECT_NAME/gradle/libs.versions.toml" << EOF
[versions]
agp = "8.4.1"
appcompat = "1.7.0"
material = "1.12.0"
constraintlayout = "2.1.4"
coreKtx = "1.13.1"
gradle = "8.7"
okhttp = "4.12.0"

[libraries]
appcompat = { group = "androidx.appcompat", name = "appcompat", version.ref = "appcompat" }
material = { group = "com.google.android.material", name = "material", version.ref = "material" }
constraintlayout = { group = "androidx.constraintlayout", name = "constraintlayout", version.ref = "constraintlayout" }
core-ktx = { group = "androidx.core", name = "core-ktx", version.ref = "coreKtx" }
okhttp = { group = "com.squareup.okhttp3", name = "okhttp", version.ref = "okhttp" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
EOF

# app/build.gradle.kts
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
    implementation(libs.okhttp)
}
EOF

# proguard-rules.pro
touch "$PROJECT_NAME/app/proguard-rules.pro"

# gradle.properties
cat > "$PROJECT_NAME/gradle.properties" << 'EOF'
org.gradle.jvmargs=-Xmx2048m
android.useAndroidX=true
android.nonTransitiveRClass=true
EOF

# gradle-wrapper.properties
cat > "$PROJECT_NAME/gradle/wrapper/gradle-wrapper.properties" << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

# --- 3. Создание ресурсов Android (res) ---

# AndroidManifest.xml
cat > "$PROJECT_NAME/app/src/main/AndroidManifest.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />

    <application
        android:allowBackup="true"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="@xml/backup_rules"
        android:icon="@android:drawable/ic_media_play"
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
            android:foregroundServiceType="mediaPlayback" />
    </application>
</manifest>
EOF

# xml/backup_rules.xml
cat > "$PROJECT_NAME/app/src/main/res/xml/backup_rules.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
</full-backup-content>
EOF

# xml/data_extraction_rules.xml
cat > "$PROJECT_NAME/app/src/main/res/xml/data_extraction_rules.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
    </cloud-backup>
    <device-transfer>
    </device-transfer>
</data-extraction-rules>
EOF

# drawable/ic_play.xml
cat > "$PROJECT_NAME/app/src/main/res/drawable/ic_play.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="?attr/colorOnPrimary">
  <path
      android:fillColor="@android:color/white"
      android:pathData="M8,5v14l11,-7z"/>
</vector>
EOF

# drawable/ic_stop.xml
cat > "$PROJECT_NAME/app/src/main/res/drawable/ic_stop.xml" << 'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="?attr/colorOnPrimary">
  <path
      android:fillColor="@android:color/white"
      android:pathData="M6,6h12v12H6z"/>
</vector>
EOF

# layout/activity_main.xml
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
        android:text="Status"
        android:textAlignment="center"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/appBarLayout" />

    <Button
        android:id="@+id/requestPermissionBtn"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="16dp"
        android:text="@string/check_permissions"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/statusText" />

    <ScrollView
        android:id="@+id/logScrollView"
        android:layout_width="0dp"
        android:layout_height="0dp"
        android:layout_margin="16dp"
        android:background="@android:color/black"
        android:visibility="gone"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/statusText">

        <TextView
            android:id="@+id/logText"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:fontFamily="monospace"
            android:padding="8dp"
            android:textColor="@android:color/white"
            android:textSize="12sp"
            android:text="Лог запросов появится здесь..." />

    </ScrollView>

</androidx.constraintlayout.widget.ConstraintLayout>
EOF

# layout/activity_settings.xml
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
        android:text="@string/server_url_label"
        android:labelFor="@+id/urlEditText"/>

    <EditText
        android:id="@+id/urlEditText"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="8dp"
        android:hint="@string/enter_url_hint"
        android:inputType="textUri"
        android:autofillHints="url" />

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="24dp"
        android:text="@string/poll_interval_label"
        android:labelFor="@+id/intervalEditText"/>

    <EditText
        android:id="@+id/intervalEditText"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="8dp"
        android:hint="@string/enter_interval_hint"
        android:inputType="number"
        android:autofillHints="number" />

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="4dp"
        android:text="@string/interval_description"
        android:textSize="12sp"
        android:textColor="?android:attr/textColorSecondary" />

    <Button
        android:id="@+id/saveButton"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_gravity="end"
        android:layout_marginTop="24dp"
        android:text="@string/save" />

</LinearLayout>
EOF

# menu/main_menu.xml
cat > "$PROJECT_NAME/app/src/main/res/menu/main_menu.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto">
    <item
        android:id="@+id/action_start_service"
        android:title="@string/start_service"
        android:icon="@drawable/ic_play"
        app:showAsAction="ifRoom" />
    <item
        android:id="@+id/action_stop_service"
        android:title="@string/stop_service"
        android:icon="@drawable/ic_stop"
        app:showAsAction="ifRoom" />
    <item
        android:id="@+id/action_settings"
        android:title="@string/settings"
        app:showAsAction="never" />
</menu>
EOF

# values/strings.xml
cat > "$PROJECT_NAME/app/src/main/res/values/strings.xml" << 'EOF'
<resources>
    <string name="app_name">ParsPost</string>
    <string name="check_permissions">Проверить разрешения</string>
    <string name="settings">Настройки</string>
    <string name="start_service">Запустить</string>
    <string name="stop_service">Остановить</string>
    <string name="save">Сохранить</string>
    <string name="server_url_label">URL сервера:</string>
    <string name="enter_url_hint">Введите URL</string>
    <string name="poll_interval_label">Интервал опроса (секунды):</string>
    <string name="enter_interval_hint">Введите интервал в секундах</string>
    <string name="interval_description">Как часто приложение будет отправлять запросы на сервер</string>
    <string name="url_saved">Настройки сохранены</string>
    <string name="service_running">Сервис запущен</string>
    <string name="service_stopped">Сервис остановлен</string>
    <string name="battery_optimization_enabled">Оптимизация батареи: ВКЛЮЧЕНА</string>
    <string name="battery_optimization_disabled">Оптимизация батареи: ВЫКЛЮЧЕНА (хорошо)</string>
    <string name="notification_permission_granted">Разрешение на уведомления: ЕСТЬ (хорошо)</string>
    <string name="notification_permission_denied">Разрешение на уведомления: НЕТ</string>
    <string name="invalid_interval">Интервал должен быть числом от 1 до 3600 секунд</string>
</resources>
EOF

# values/themes.xml
cat > "$PROJECT_NAME/app/src/main/res/values/themes.xml" << 'EOF'
<resources>
    <style name="Theme.ParsPost" parent="Theme.Material3.DayNight.NoActionBar">
    </style>
</resources>
EOF

# --- 4. Создание исходного кода Java ---

# MainActivity.java
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
import android.text.method.ScrollingMovementMethod;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.localbroadcastmanager.content.LocalBroadcastManager;

import com.example.parspost.databinding.ActivityMainBinding;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class MainActivity extends AppCompatActivity {

    private ActivityMainBinding binding;
    public static final String PREFS_NAME = "ParsPostPrefs";
    public static final String KEY_URL = "serverUrl";
    public static final String KEY_INTERVAL = "pollInterval";
    public static final String DEFAULT_URL = "https://httpbin.org/status/200";
    public static final int DEFAULT_INTERVAL = 30; // секунд

    private boolean allPermissionsGranted = false;
    private StringBuilder logBuilder = new StringBuilder();

    private final ActivityResultLauncher<String> requestPermissionLauncher =
            registerForActivityResult(new ActivityResultContracts.RequestPermission(), isGranted -> {
                if (isGranted) {
                    Toast.makeText(this, "Notification permission granted", Toast.LENGTH_SHORT).show();
                } else {
                    Toast.makeText(this, "Notification permission denied", Toast.LENGTH_SHORT).show();
                }
                updateStatus();
            });

    private final BroadcastReceiver logReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String message = intent.getStringExtra("message");
            if (message != null) {
                addLogMessage(message);
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
        binding.logText.setMovementMethod(new ScrollingMovementMethod());
        
        // Регистрируем получатель для логов
        IntentFilter filter = new IntentFilter("com.example.parspost.LOG_MESSAGE");
        LocalBroadcastManager.getInstance(this).registerReceiver(logReceiver, filter);
    }

    @Override
    protected void onResume() {
        super.onResume();
        updateStatus();
        invalidateOptionsMenu();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        LocalBroadcastManager.getInstance(this).unregisterReceiver(logReceiver);
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
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        String url = prefs.getString(KEY_URL, DEFAULT_URL);
        int interval = prefs.getInt(KEY_INTERVAL, DEFAULT_INTERVAL);

        Intent serviceIntent = new Intent(this, SoundService.class);
        serviceIntent.putExtra("url", url);
        serviceIntent.putExtra("interval", interval);
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent);
        } else {
            startService(serviceIntent);
        }
        
        binding.getRoot().postDelayed(() -> {
            updateStatus();
            invalidateOptionsMenu();
        }, 100);
    }

    private void stopSoundService() {
        Intent serviceIntent = new Intent(this, SoundService.class);
        stopService(serviceIntent);
        binding.getRoot().postDelayed(() -> {
            updateStatus();
            invalidateOptionsMenu();
        }, 100);
    }

    private void updateStatus() {
        String serviceStatus = SoundService.isRunning ? getString(R.string.service_running) : getString(R.string.service_stopped);
        PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
        
        String batteryStatus;
        if (pm.isIgnoringBatteryOptimizations(getPackageName())) {
            batteryStatus = getString(R.string.battery_optimization_disabled);
        } else {
            batteryStatus = getString(R.string.battery_optimization_enabled);
        }
        
        String notificationStatus;
        boolean hasNotificationPermission = true;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            hasNotificationPermission = ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED;
            if (hasNotificationPermission) {
                notificationStatus = getString(R.string.notification_permission_granted);
            } else {
                notificationStatus = getString(R.string.notification_permission_denied);
            }
        } else {
            notificationStatus = "Разрешение на уведомления: не требуется (Android < 13)";
        }

        binding.statusText.setText(String.format("%s\n%s\n%s", serviceStatus, batteryStatus, notificationStatus));

        // Проверяем, все ли разрешения получены
        boolean batteryOptimizationDisabled = pm.isIgnoringBatteryOptimizations(getPackageName());
        allPermissionsGranted = batteryOptimizationDisabled && hasNotificationPermission;

        // Показываем/скрываем элементы интерфейса
        if (allPermissionsGranted) {
            binding.requestPermissionBtn.setVisibility(View.GONE);
            binding.logScrollView.setVisibility(View.VISIBLE);
        } else {
            binding.requestPermissionBtn.setVisibility(View.VISIBLE);
            binding.logScrollView.setVisibility(View.GONE);
        }
    }

    private void checkAndRequestPermissions() {
        PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
        if (!pm.isIgnoringBatteryOptimizations(getPackageName())) {
            Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
            intent.setData(Uri.parse("package:" + getPackageName()));
            startActivity(intent);
        } else {
            Toast.makeText(this, "Оптимизация батареи уже отключена.", Toast.LENGTH_SHORT).show();
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                requestPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS);
            } else {
                Toast.makeText(this, "Разрешение на уведомления уже предоставлено.", Toast.LENGTH_SHORT).show();
            }
        }
        updateStatus();
    }

    private void addLogMessage(String message) {
        SimpleDateFormat sdf = new SimpleDateFormat("HH:mm:ss", Locale.getDefault());
        String timestamp = sdf.format(new Date());
        String logEntry = "[" + timestamp + "] " + message + "\n";
        
        logBuilder.append(logEntry);
        
        // Ограничиваем размер лога (последние 100 строк)
        String[] lines = logBuilder.toString().split("\n");
        if (lines.length > 100) {
            logBuilder = new StringBuilder();
            for (int i = lines.length - 100; i < lines.length; i++) {
                logBuilder.append(lines[i]).append("\n");
            }
        }
        
        runOnUiThread(() -> {
            binding.logText.setText(logBuilder.toString());
            // Автопрокрутка вниз
            binding.logScrollView.post(() -> binding.logScrollView.fullScroll(View.FOCUS_DOWN));
        });
    }
}
EOF

# SoundService.java
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
import androidx.localbroadcastmanager.content.LocalBroadcastManager;

import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

public class SoundService extends Service {
    private static final String CHANNEL_ID = "SoundServiceChannel";
    public static volatile boolean isRunning = false;
    
    private ExecutorService executorService;
    private Handler mainHandler;
    private OkHttpClient httpClient;
    private String targetUrl;
    private int pollInterval;
    private Runnable pollRunnable;

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
        executorService = Executors.newSingleThreadExecutor();
        mainHandler = new Handler(Looper.getMainLooper());
        httpClient = new OkHttpClient.Builder()
                .connectTimeout(10, java.util.concurrent.TimeUnit.SECONDS)
                .readTimeout(10, java.util.concurrent.TimeUnit.SECONDS)
                .build();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        isRunning = true;
        targetUrl = intent.getStringExtra("url");
        pollInterval = intent.getIntExtra("interval", 30) * 1000; // конвертируем в миллисекунды
        
        Intent notificationIntent = new Intent(this, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE);
        
        Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("ParsPost Service")
                .setContentText("Опрос сервера каждые " + (pollInterval / 1000) + " сек")
                .setSmallIcon(android.R.drawable.ic_media_play)
                .setContentIntent(pendingIntent)
                .build();
        
        startForeground(1, notification);
        startPolling();
        
        sendLogMessage("Сервис запущен. URL: " + targetUrl + ", интервал: " + (pollInterval / 1000) + "с");
        
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        isRunning = false;
        stopPolling();
        if (executorService != null) {
            executorService.shutdown
