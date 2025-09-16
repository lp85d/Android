#!/bin/bash

# ЧАСТЬ 1: ИСХОДНЫЙ КОД ПРИЛОЖЕНИЯ
# Этот скрипт содержит все необходимые функции для создания файлов проекта MySoundApp.
# Он должен вызываться из основного сборочного скрипта build.sh.

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
rootProject.name = "MySoundApp"
include ':app'
EOF
    debug "Создан settings.gradle"

    # root build.gradle
    cat > build.gradle << 'EOF'
plugins {
    id 'com.android.application' version '8.4.0' apply false
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
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}
dependencies {
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
}
EOF
    debug "Создан app/build.gradle"

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
        android:label="MySoundApp"
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
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

public class MainActivity extends Activity {
    private TextView statusText;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        Button startServiceBtn = findViewById(R.id.startServiceBtn);
        Button stopServiceBtn = findViewById(R.id.stopServiceBtn);
        Button requestPermissionBtn = findViewById(R.id.requestPermissionBtn);
        statusText = findViewById(R.id.statusText);
        updateStatus();
        startServiceBtn.setOnClickListener(v -> {
            Intent serviceIntent = new Intent(this, SoundService.class);
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
                }
            }
            updateStatus();
        });
    }
    @Override
    protected void onResume() {
        super.onResume();
        updateStatus();
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
        status.append("Оптимизация батареи: ").append(isBatteryOptimized ? "Включена ⚠️" : "Отключена ✅");
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
        if (!isRunning) {
            startForeground(NOTIFICATION_ID, createNotification("Запуск мониторинга..."));
            startServerChecking();
            isRunning = true;
        }
        return START_STICKY;
    }
    private void acquireWakeLock() {
        PowerManager powerManager = (PowerManager) getSystemService(POWER_SERVICE);
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "MySoundApp:WakeLock");
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
        return builder.setContentTitle("MySoundApp работает").setContentText(text)
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
                String[] testUrls = {"https://httpbin.org/status/200", "https://www.google.com"};
                boolean serverResponded = false;
                for (String testUrl : testUrls) {
                    try {
                        URL url = new URL(testUrl);
                        HttpURLConnection c = (HttpURLConnection) url.openConnection();
                        c.setRequestMethod("GET");
                        c.setConnectTimeout(5000);
                        c.setReadTimeout(5000);
                        int responseCode = c.getResponseCode();
                        if (responseCode >= 200 && responseCode < 400) {
                            serverResponded = true;
                            handler.post(() -> {
                                playSound();
                                updateNotification("Сервер отвечает ✅ (код: " + responseCode + ")");
                            });
                            break;
                        }
                        c.disconnect();
                    } catch (Exception e) {
                        Log.w(TAG, "Ошибка при проверке " + testUrl + ": " + e.getMessage());
                    }
                }
                if (!serverResponded) handler.post(() -> updateNotification("Серверы не отвечают ❌"));
            } catch (Exception e) {
                handler.post(() -> updateNotification("Ошибка проверки ⚠️"));
            }}
        ).start();
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
        android:text="MySoundApp"
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

    # Создание тестового MP3
    create_test_mp3 "$project_dir/app/src/main/res/raw/sound.mp3"
    
    log "✅ Все файлы проекта MySoundApp созданы."
}