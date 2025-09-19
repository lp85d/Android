#!/bin/bash
# Получаем имя проекта из аргумента командной строки
PROJECT_NAME=$1
if [ -z "$PROJECT_NAME" ]; then
  echo "Ошибка: укажите имя проекта"
  exit 1
fi

echo "Создание файлов проекта в $(pwd)/$PROJECT_NAME..."

# Создание директорий проекта
mkdir -p "$PROJECT_NAME/app/src/main/java/com/example/mysoundapp"
mkdir -p "$PROJECT_NAME/app/src/main/res/layout"
mkdir -p "$PROJECT_NAME/app/src/main/res/menu"
mkdir -p "$PROJECT_NAME/app/src/main/res/raw"
mkdir -p "$PROJECT_NAME/app/src/main/res/values"
mkdir -p "$PROJECT_NAME/app/src/main/res/mipmap-hdpi"
mkdir -p "$PROJECT_NAME/app/src/main/res/mipmap-mdpi"
mkdir -p "$PROJECT_NAME/app/src/main/res/mipmap-xhdpi"
mkdir -p "$PROJECT_NAME/app/src/main/res/mipmap-xxhdpi"
mkdir -p "$PROJECT_NAME/app/src/main/res/mipmap-xxxhdpi"
mkdir -p "$PROJECT_NAME/gradle/wrapper"

# Создание settings.gradle
cat > "$PROJECT_NAME/settings.gradle" << 'EOF'
rootProject.name = 'ParsPost'
include ':app'
EOF
echo "[DEBUG] Создан settings.gradle"

# Создание корневого build.gradle с совместимой версией AGP
cat > "$PROJECT_NAME/build.gradle" << 'EOF'
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.4'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    configurations.all {
        resolutionStrategy {
            force 'org.jetbrains.kotlin:kotlin-stdlib:1.8.22'
            force 'org.jetbrains.kotlin:kotlin-stdlib-common:1.8.22'
        }
    }
}

tasks.register('clean', Delete) {
    delete rootProject.buildDir
}
EOF
echo "[DEBUG] Создан root build.gradle"

# Создание app/build.gradle
cat > "$PROJECT_NAME/app/build.gradle" << 'EOF'
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.example.mysoundapp'
    compileSdk 34

    defaultConfig {
        applicationId "com.example.mysoundapp"
        minSdk 26
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
    
    packagingOptions {
        pickFirst '**/kotlin-stdlib-*.jar'
        exclude 'META-INF/DEPENDENCIES'
        exclude 'META-INF/LICENSE'
        exclude 'META-INF/LICENSE.txt'
        exclude 'META-INF/NOTICE'
        exclude 'META-INF/NOTICE.txt'
    }
}

configurations {
    all {
        exclude group: 'org.jetbrains.kotlin', module: 'kotlin-stdlib-jdk7'
        exclude group: 'org.jetbrains.kotlin', module: 'kotlin-stdlib-jdk8'
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.core:core:1.9.0'
}
EOF
echo "[DEBUG] Создан app/build.gradle"

# Создание proguard-rules.pro
cat > "$PROJECT_NAME/app/proguard-rules.pro" << 'EOF'
# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
EOF
echo "[DEBUG] Создан proguard-rules.pro"

# Создание gradle.properties
cat > "$PROJECT_NAME/gradle.properties" << 'EOF'
org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m
org.gradle.daemon=false
android.useAndroidX=true
android.enableJetifier=true
kotlin.stdlib.default.dependency=false
EOF
echo "[DEBUG] Создан gradle.properties"

# Создание gradle-wrapper.properties
cat > "$PROJECT_NAME/gradle/wrapper/gradle-wrapper.properties" << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
echo "[DEBUG] Создан gradle-wrapper.properties"

# Создание strings.xml
cat > "$PROJECT_NAME/app/src/main/res/values/strings.xml" << 'EOF'
<resources>
    <string name="app_name">MySoundApp</string>
</resources>
EOF
echo "[DEBUG] Создан strings.xml"

# Создание простых иконок (используем стандартные Android иконки)
# Создаем ic_launcher.xml как vector drawable
cat > "$PROJECT_NAME/app/src/main/res/mipmap-hdpi/ic_launcher.png" << 'EOF'
EOF

# Простое решение - создаем AndroidManifest без ссылок на иконки
cat > "$PROJECT_NAME/app/src/main/AndroidManifest.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.mysoundapp">
    
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.INTERNET" />
    
    <application
        android:allowBackup="true"
        android:label="@string/app_name"
        android:supportsRtl="true"
        android:theme="@style/Theme.AppCompat.Light.DarkActionBar">
        
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        
        <service
            android:name=".SoundService"
            android:enabled="true"
            android:exported="false"
            android:foregroundServiceType="mediaPlayback" />
    </application>
</manifest>
EOF
echo "[DEBUG] Создан AndroidManifest.xml"

# Остальные Java файлы остаются такими же...
cat > "$PROJECT_NAME/app/src/main/java/com/example/mysoundapp/MainActivity.java" << 'EOF'
package com.example.mysoundapp;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.provider.Settings;
import android.util.Log;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import android.app.Notification;
import android.app.NotificationManager;

public class MainActivity extends AppCompatActivity {
    private TextView statusText;
    private LinearLayout buttonContainer;
    private String customUrl = "https://httpbin.org/status/200";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);

        Button startServiceBtn = findViewById(R.id.startServiceBtn);
        Button stopServiceBtn = findViewById(R.id.stopServiceBtn);
        Button requestPermissionBtn = findViewById(R.id.requestPermissionBtn);
        statusText = findViewById(R.id.statusText);
        buttonContainer = findViewById(R.id.buttonContainer);

        updateStatus();

        startServiceBtn.setOnClickListener(v -> {
            Intent serviceIntent = new Intent(this, SoundService.class);
            serviceIntent.putExtra("url", customUrl);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent);
            } else {
                startService(serviceIntent);
            }
            updateStatus();
        });

        stopServiceBtn.setOnClickListener(v -> {
            Intent serviceIntent = new Intent(this, SoundService.class);
            stopService(serviceIntent);
            updateStatus();
        });

        requestPermissionBtn.setOnClickListener(v -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                String packageName = getPackageName();
                PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
                if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                    Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
                    intent.setData(Uri.parse("package:" + packageName));
                    startActivity(intent);
                } else {
                    Toast.makeText(this, "Battery optimization already disabled", Toast.LENGTH_SHORT).show();
                }
            }
        });
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        Log.d("MainActivity", "Creating options menu");
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.main_menu, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == R.id.action_settings) {
            Toast.makeText(this, "Settings selected", Toast.LENGTH_SHORT).show();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    private void updateStatus() {
        PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
        String packageName = getPackageName();
        boolean isServiceRunning = isServiceRunning();
        boolean isIgnoringBatteryOptimizations = Build.VERSION.SDK_INT < Build.VERSION_CODES.M || pm.isIgnoringBatteryOptimizations(packageName);

        statusText.setText("Service running: " + isServiceRunning + "\nBattery optimization disabled: " + isIgnoringBatteryOptimizations);
        buttonContainer.setVisibility(isIgnoringBatteryOptimizations ? View.VISIBLE : View.GONE);
    }

    private boolean isServiceRunning() {
        return false; // Simplified for now
    }
}
EOF
echo "[DEBUG] Создан MainActivity.java"

# Упрощенный SoundService без использования R.raw
cat > "$PROJECT_NAME/app/src/main/java/com/example/mysoundapp/SoundService.java" << 'EOF'
package com.example.mysoundapp;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import androidx.core.app.NotificationCompat;

public class SoundService extends Service {
    private static final String CHANNEL_ID = "SoundServiceChannel";

    @Override
    public void onCreate() {
        super.onCreate();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(CHANNEL_ID, "Sound Service", NotificationManager.IMPORTANCE_LOW);
            NotificationManager manager = getSystemService(NotificationManager.class);
            manager.createNotificationChannel(channel);
        }
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Intent notificationIntent = new Intent(this, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE);

        Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Sound Service")
                .setContentText("Service is running")
                .setSmallIcon(android.R.drawable.ic_media_play)
                .setContentIntent(pendingIntent)
                .build();

        startForeground(1, notification);
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
EOF
echo "[DEBUG] Создан SoundService.java"

# Создание layout файлов
cat > "$PROJECT_NAME/app/src/main/res/layout/activity_main.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <androidx.appcompat.widget.Toolbar
        android:id="@+id/toolbar"
        android:layout_width="match_parent"
        android:layout_height="?attr/actionBarSize"
        android:background="?attr/colorPrimary"
        android:theme="@style/Theme.AppCompat.Light.DarkActionBar"
        app:layout_constraintTop_toTopOf="parent" />

    <TextView
        android:id="@+id/statusText"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Status"
        app:layout_constraintTop_toBottomOf="@id/toolbar"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        android:layout_marginTop="16dp" />

    <LinearLayout
        android:id="@+id/buttonContainer"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        app:layout_constraintTop_toBottomOf="@id/statusText"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        android:layout_marginTop="16dp">

        <Button
            android:id="@+id/startServiceBtn"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Start Service" />

        <Button
            android:id="@+id/stopServiceBtn"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Stop Service" />

        <Button
            android:id="@+id/requestPermissionBtn"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Request Permission" />
    </LinearLayout>
</androidx.constraintlayout.widget.ConstraintLayout>
EOF
echo "[DEBUG] Создан activity_main.xml"

# Создание menu файла
cat > "$PROJECT_NAME/app/src/main/res/menu/main_menu.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto">
    <item
        android:id="@+id/action_settings"
        android:title="Settings"
        app:showAsAction="never" />
</menu>
EOF
echo "[DEBUG] Создан main_menu.xml"

# Создание тестового звукового файла (без ffmpeg пока что)
echo "Создание тестового звукового файла..."
touch "$PROJECT_NAME/app/src/main/res/raw/sound.mp3"
echo "[DEBUG] Создан пустой sound.mp3 файл"

echo "[$(date +%Y-%m-%d\ %H:%M:%S)] ✅ Все файлы проекта $PROJECT_NAME созданы."
