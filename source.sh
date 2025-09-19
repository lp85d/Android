#!/bin/bash

# Цвета и логирование (дублируются для автономности)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'
log() { echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }
debug() { echo -e "${PURPLE}[DEBUG] $1${NC}"; }

# Создание тестового MP3 файла
create_test_mp3() {
    local mp3_path="$1"
    debug "Создание MP3 файла: $mp3_path"
    
    local mp3_dir=$(dirname "$mp3_path")
    mkdir -p "$mp3_dir"
    
    if [ ! -f "$mp3_path" ]; then
        log "Создание тестового MP3 файла..."
        
        # Создание мелодичного звука
        if ! ffmpeg -f lavfi -i "sine=frequency=440:duration=1,sine=frequency=554:duration=1,sine=frequency=659:duration=1" \
                   -filter_complex "concat=n=3:v=0:a=1" \
                   -ac 2 -ar 44100 -b:a 128k "$mp3_path" -y >/dev/null 2>&1; then
            ffmpeg -f lavfi -i "sine=frequency=440:duration=2" \
                   -ac 2 -ar 44100 -b:a 128k "$mp3_path" -y >/dev/null 2>&1
        fi
        
        if [ -f "$mp3_path" ]; then
            log "✅ MP3 файл создан: $mp3_path"
        else
            echo -e "\033[0;31m[ERROR] Не удалось создать MP3 файл\033[0m"
            exit 1
        fi
    else
        info "MP3 файл уже существует: $mp3_path"
    fi
}

# Основная функция для создания всех файлов проекта
create_project_files() {
    local project_dir="$1"
    log "Создание файлов проекта в $project_dir..."

    # Создаем основную директорию проекта и необходимые подкаталоги
    mkdir -p "$project_dir"
    local dirs=(
        "app/src/main/java/com/example/mysoundapp"
        "app/src/main/res/layout"
        "app/src/main/res/raw"
        "app/src/main/res/values"
        "app/src/main/res/xml"
        "app/src/main/res/mipmap-hdpi"
        "app/src/main/res/mipmap-mdpi"
        "app/src/main/res/menu"
    )
    for dir in "${dirs[@]}"; do
        mkdir -p "$project_dir/$dir"
    done

    cd "$project_dir"

    # settings.gradle
    cat > settings.gradle << 'EOF'
pluginManagement {
    repositories {
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "ParsPost"
include ':app'
EOF
    debug "Создан settings.gradle"

    # root build.gradle
    cat > build.gradle << 'EOF'
plugins {
    id 'com.android.application' version '8.6.0' apply false
}
task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF
    debug "Создан root build.gradle"

    # app/build.gradle
    cat > app/build.gradle << 'EOF'
plugins {
    id 'com.android.application'
}
android {
    namespace 'com.example.mysoundapp'
    compileSdk 34
    defaultConfig {
        applicationId "com.example.mysoundapp"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }
    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug {
            debuggable true
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}
dependencies {
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
}
EOF
    debug "Создан app/build.gradle"

    # gradle.properties
    cat > gradle.properties << 'EOF'
android.useAndroidX=true
android.enableJetifier=true
org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=512m
EOF
    debug "Создан gradle.properties"

    # AndroidManifest.xml
    cat > app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
    <application
        android:allowBackup="true"
        android:icon="@android:drawable/ic_media_play"
        android:label="ParsPost"
        android:theme="@style/Theme.AppCompat.Light.DarkActionBar"
        android:requestLegacyExternalStorage="true"
        tools:targetApi="33">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="portrait">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <service
            android:name=".SoundService"
            android:exported="false"
            android:foregroundServiceType="mediaPlayback" />
    </application>
</manifest>
EOF
    debug "Создан AndroidManifest.xml"

    # MainActivity.java
    cat > app/src/main/java/com/example/mysoundapp/MainActivity.java << 'EOF'
package com.example.mysoundapp;

import android.app.Activity;
import android.app.ActivityManager;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.provider.Settings;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

public class MainActivity extends Activity {
    private TextView statusText;
    private LinearLayout buttonContainer;
    private EditText urlInput;
    private String customUrl = "https://httpbin.org/status/200";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        Button startServiceBtn = findViewById(R.id.startServiceBtn);
        Button stopServiceBtn = findViewById(R.id.stopServiceBtn);
        Button requestPermissionBtn = findViewById(R.id.requestPermissionBtn);
        Button updateUrlBtn = findViewById(R.id.updateUrlBtn);
        statusText = findViewById(R.id.statusText);
        buttonContainer = findViewById(R.id.buttonContainer);
        urlInput = findViewById(R.id.urlInput);
        updateStatus();

        startServiceBtn.setOnClickListener(v -> {
            Intent serviceIntent = new Intent(this, SoundService.class);
            serviceIntent.putExtra("customUrl", customUrl);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent);
            } else {
                startService(serviceIntent);
            }
            Toast.makeText(this, "Служба запущена", Toast.LENGTH_SHORT).show();
            updateStatus();
        });

        stopServiceBtn.setOnClickListener(v -> {
            Intent serviceIntent = new Intent(this, SoundService.class);
            stopService(serviceIntent);
            Toast.makeText(this, "Служба остановлена", Toast.LENGTH_SHORT).show();
            updateStatus();
        });

        requestPermissionBtn.setOnClickListener(v -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PowerManager pm = (PowerManager) getSystemService(POWER_SERVICE);
                if (!pm.isIgnoringBatteryOptimizations(getPackageName())) {
                    Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
                    intent.setData(Uri.parse("package:" + getPackageName()));
                    startActivity(intent);
                } else {
                    Toast.makeText(this, "Разрешение уже предоставлено", Toast.LENGTH_SHORT).show();
                    hideButtons();
                }
            }
            updateStatus();
        });

        updateUrlBtn.setOnClickListener(v -> {
            String newUrl = urlInput.getText().toString().trim();
            if (!newUrl.isEmpty()) {
                customUrl = newUrl;
                Toast.makeText(this, "URL обновлён: " + customUrl, Toast.LENGTH_SHORT).show();
            } else {
                Toast.makeText(this, "Введите действительный URL", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        updateStatus();
        checkBatteryOptimization();
    }

    private void updateStatus() {
        boolean isServiceRunning = isServiceRunning(SoundService.class);
        boolean isBatteryOptimized = true;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PowerManager pm = (PowerManager) getSystemService(POWER_SERVICE);
            isBatteryOptimized = !pm.isIgnoringBatteryOptimizations(getPackageName());
        }
        StringBuilder status = new StringBuilder();
        status.append("Статус службы: ").append(isServiceRunning ? "Работает ✅" : "Остановлена ❌").append("\n");
        status.append("Оптимизация батареи: ").append(isBatteryOptimized ? "Включена ⚠️" : "Отключена ✅").append("\n");
        status.append("URL сервера: ").append(customUrl);
        statusText.setText(status.toString());
    }

    private boolean isServiceRunning(Class<?> serviceClass) {
        ActivityManager manager = (ActivityManager) getSystemService(Context.ACTIVITY_SERVICE);
        for (ActivityManager.RunningServiceInfo service : manager.getRunningServices(Integer.MAX_VALUE)) {
            if (serviceClass.getName().equals(service.service.getClassName())) {
                return true;
            }
        }
        return false;
    }

    private void checkBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PowerManager pm = (PowerManager) getSystemService(POWER_SERVICE);
            if (!pm.isIgnoringBatteryOptimizations(getPackageName())) {
                buttonContainer.setVisibility(View.VISIBLE);
            } else {
                buttonContainer.setVisibility(View.GONE);
            }
        }
    }

    private void hideButtons() {
        buttonContainer.setVisibility(View.GONE);
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.main_menu, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        int itemId = item.getItemId();
        if (itemId == R.id.action_start_service) {
            Intent startIntent = new Intent(this, SoundService.class);
            startIntent.putExtra("customUrl", customUrl);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(startIntent);
            } else {
                startService(startIntent);
            }
            Toast.makeText(this, "Служба запущена", Toast.LENGTH_SHORT).show();
            updateStatus();
            return true;
        } else if (itemId == R.id.action_stop_service) {
            Intent stopIntent = new Intent(this, SoundService.class);
            stopService(stopIntent);
            Toast.makeText(this, "Служба остановлена", Toast.LENGTH_SHORT).show();
            updateStatus();
            return true;
        } else if (itemId == R.id.action_request_permission) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PowerManager pm = (PowerManager) getSystemService(POWER_SERVICE);
                if (!pm.isIgnoringBatteryOptimizations(getPackageName())) {
                    Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
                    intent.setData(Uri.parse("package:" + getPackageName()));
                    startActivity(intent);
                } else {
                    Toast.makeText(this, "Разрешение уже предоставлено", Toast.LENGTH_SHORT).show();
                }
            }
            updateStatus();
            return true;
        } else if (itemId == R.id.action_change_url) {
            String newUrl = urlInput.getText().toString().trim();
            if (!newUrl.isEmpty()) {
                customUrl = newUrl;
                Toast.makeText(this, "URL обновлён: " + customUrl, Toast.LENGTH_SHORT).show();
            } else {
                Toast.makeText(this, "Введите действительный URL", Toast.LENGTH_SHORT).show();
            }
            updateStatus();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }
}
EOF
    debug "Создан MainActivity.java"

    # SoundService.java
    cat > app/src/main/java/com/example/mysoundapp/SoundService.java << 'EOF'
package com.example.mysoundapp;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.media.MediaPlayer;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.PowerManager;
import android.util.Log;
import java.net.HttpURLConnection;
import java.net.URL;

public class SoundService extends Service {
    private static final String TAG = "SoundService";
    private static final String CHANNEL_ID = "SoundServiceChannel";
    private static final int NOTIFICATION_ID = 1;
    private static final int CHECK_INTERVAL = 30000;
    private Handler handler = new Handler(Looper.getMainLooper());
    private Runnable checkServerRunnable;
    private MediaPlayer mediaPlayer;
    private PowerManager.WakeLock wakeLock;
    private boolean isRunning = false;
    private String customUrl;

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "Service создан");
        createNotificationChannel();
        acquireWakeLock();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "Service запущен");
        if (intent != null && intent.hasExtra("customUrl")) {
            customUrl = intent.getStringExtra("customUrl");
        } else {
            customUrl = "https://httpbin.org/status/200";
        }
        if (!isRunning) {
            startForeground(NOTIFICATION_ID, createNotification("Запуск мониторинга..."));
            startServerChecking();
            isRunning = true;
        }
        return START_STICKY;
    }

    private void acquireWakeLock() {
        PowerManager powerManager = (PowerManager) getSystemService(POWER_SERVICE);
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "ParsPost:WakeLock");
        wakeLock.acquire(10*60*1000L);
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID, "Sound Service Channel", NotificationManager.IMPORTANCE_LOW
            );
            channel.setDescription("Канал для службы мониторинга звука");
            getSystemService(NotificationManager.class).createNotificationChannel(channel);
        }
    }

    private Notification createNotification(String text) {
        Notification.Builder builder = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ?
            new Notification.Builder(this, CHANNEL_ID) : new Notification.Builder(this);
        return builder.setContentTitle("ParsPost работает").setContentText(text)
                .setSmallIcon(android.R.drawable.ic_media_play).setOngoing(true).build();
    }

    private void startServerChecking() {
        checkServerRunnable = new Runnable() {
            @Override
            public void run() {
                checkServerAndPlaySound();
                if (isRunning) handler.postDelayed(this, CHECK_INTERVAL);
            }
        };
        handler.post(checkServerRunnable);
    }

    private void checkServerAndPlaySound() {
        new Thread(() -> {
            try {
                URL url = new URL(customUrl);
                HttpURLConnection c = (HttpURLConnection) url.openConnection();
                c.setRequestMethod("GET");
                c.setConnectTimeout(5000);
                c.setReadTimeout(5000);
                int responseCode = c.getResponseCode();
                if (responseCode >= 200 && responseCode < 400) {
                    handler.post(() -> {
                        playSound();
                        updateNotification("Сервер отвечает ✅ (код: " + responseCode + ")");
                    });
                } else {
                    handler.post(() -> updateNotification("Сервер не отвечает ❌ (код: " + responseCode + ")"));
                }
                c.disconnect();
            } catch (Exception e) {
                handler.post(() -> updateNotification("Ошибка проверки ⚠️: " + e.getMessage()));
            }
        }).start();
    }

    private void updateNotification(String text) {
        getSystemService(NotificationManager.class).notify(NOTIFICATION_ID, createNotification(text));
    }

    private void playSound() {
        try {
            if (mediaPlayer != null && mediaPlayer.isPlaying()) return;
            if (mediaPlayer != null) mediaPlayer.release();
            mediaPlayer = MediaPlayer.create(this, R.raw.sound);
            if (mediaPlayer != null) {
                mediaPlayer.setOnCompletionListener(mp -> { mp.release(); mediaPlayer = null; });
                mediaPlayer.start();
            }
        } catch (Exception e) {
            Log.e(TAG, "Ошибка воспроизведения звука", e);
        }
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        isRunning = false;
        if (handler != null) handler.removeCallbacks(checkServerRunnable);
        if (mediaPlayer != null) mediaPlayer.release();
        if (wakeLock != null && wakeLock.isHeld()) wakeLock.release();
    }

    @Override
    public IBinder onBind(Intent intent) { return null; }
}
EOF
    debug "Создан SoundService.java"

    # activity_main.xml
    cat > app/src/main/res/layout/activity_main.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="24dp"
    android:gravity="center"
    android:background="#f5f5f5">
    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="ParsPost"
        android:textSize="28sp"
        android:textStyle="bold"
        android:gravity="center"
        android:textColor="#333333"
        android:layout_marginBottom="32dp" />
    <TextView
        android:id="@+id/statusText"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Статус: Неизвестен"
        android:textSize="16sp"
        android:gravity="center"
        android:background="#ffffff"
        android:padding="16dp"
        android:layout_marginBottom="24dp"
        android:elevation="2dp" />
    <EditText
        android:id="@+id/urlInput"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Введите URL сервера"
        android:textSize="16sp"
        android:padding="12dp"
        android:background="#ffffff"
        android:layout_marginBottom="12dp"
        android:elevation="2dp" />
    <Button
        android:id="@+id/updateUrlBtn"
        android:layout_width="match_parent"
        android:layout_height="56dp"
        android:layout_marginBottom="12dp"
        android:text="Обновить URL"
        android:textSize="16sp"
        android:background="#2196F3"
        android:textColor="#ffffff"
        android:elevation="4dp" />
    <LinearLayout
        android:id="@+id/buttonContainer"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:visibility="visible">
        <Button
            android:id="@+id/startServiceBtn"
            android:layout_width="match_parent"
            android:layout_height="56dp"
            android:layout_marginBottom="12dp"
            android:text="▶️ Запустить службу мониторинга"
            android:textSize="16sp"
            android:background="#4CAF50"
            android:textColor="#ffffff"
            android:elevation="4dp" />
        <Button
            android:id="@+id/stopServiceBtn"
            android:layout_width="match_parent"
            android:layout_height="56dp"
            android:layout_marginBottom="12dp"
            android:text="⏹️ Остановить службу"
            android:textSize="16sp"
            android:background="#f44336"
            android:textColor="#ffffff"
            android:elevation="4dp" />
        <Button
            android:id="@+id/requestPermissionBtn"
            android:layout_width="match_parent"
            android:layout_height="56dp"
            android:text="🔋 Отключить оптимизацию батареи"
            android:textSize="16sp"
            android:background="#FF9800"
            android:textColor="#ffffff"
            android:elevation="4dp" />
    </LinearLayout>
    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Приложение проверяет доступность серверов каждые 30 секунд и воспроизводит звук при успешном ответе."
        android:textSize="14sp"
        android:gravity="center"
        android:textColor="#666666"
        android:layout_marginTop="24dp"
        android:padding="16dp"
        android:background="#ffffff"
        android:elevation="1dp" />
</LinearLayout>
EOF
    debug "Создан activity_main.xml"

    # main_menu.xml
    cat > app/src/main/res/menu/main_menu.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:id="@+id/action_start_service"
        android:title="Запустить службу" />
    <item
        android:id="@+id/action_stop_service"
        android:title="Остановить службу" />
    <item
        android:id="@+id/action_request_permission"
        android:title="Отключить оптимизацию батареи" />
    <item
        android:id="@+id/action_change_url"
        android:title="Изменить URL сервера" />
</menu>
EOF
    debug "Создан main_menu.xml"

    # Создание тестового MP3
    create_test_mp3 "$project_dir/app/src/main/res/raw/sound.mp3"
    
    log "✅ Все файлы проекта ParsPost созданы."
}
EOF
