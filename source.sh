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

[libraries]
appcompat = { group = "androidx.appcompat", name = "appcompat", version.ref = "appcompat" }
material = { group = "com.google.android.material", name = "material", version.ref = "material" }
constraintlayout = { group = "androidx.constraintlayout", name = "constraintlayout", version.ref = "constraintlayout" }
core-ktx = { group = "androidx.core", name = "core-ktx", version.ref = "coreKtx" }

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

# AndroidManifest.xml (ИЗМЕНЕНО)
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

    <Button
        android:id="@+id/saveButton"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_gravity="end"
        android:layout_marginTop="16dp"
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
        app:showAsAction="ifRoom" />
    <item
        android:id="@+id/action_stop_service"
        android:title="@string/stop_service"
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
    <string name="start_service">Старт</string>
    <string name="stop_service">Стоп</string>
    <string name="save">Сохранить</string>
    <string name="server_url_label">URL сервера:</string>
    <string name="enter_url_hint">Введите URL</string>
    <string name="url_saved">URL сохранен</string>
    <string name="service_running">Сервис запущен</string>
    <string name="service_stopped">Сервис остановлен</string>
    <string name="battery_optimization_enabled">Оптимизация батареи: ВКЛЮЧЕНА</string>
    <string name="battery_optimization_disabled">Оптимизация батареи: ВЫКЛЮЧЕНА (хорошо)</string>
    <string name="notification_permission_granted">Разрешение на уведомления: ЕСТЬ (хорошо)</string>
    <string name="notification_permission_denied">Разрешение на уведомления: НЕТ</string>
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
# MainActivity.java (ИЗМЕНЕНО)
cat > "$PROJECT_NAME/app/src/main/java/com/example/parspost/MainActivity.java" << 'EOF'
package com.example.parspost;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.provider.Settings;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;

import com.example.parspost.databinding.ActivityMainBinding;

public class MainActivity extends AppCompatActivity {

    private ActivityMainBinding binding;
    public static final String PREFS_NAME = "ParsPostPrefs";
    public static final String KEY_URL = "serverUrl";
    public static final String DEFAULT_URL = "https://httpbin.org/status/200"; // Сделано public static

    private final ActivityResultLauncher<String> requestPermissionLauncher =
            registerForActivityResult(new ActivityResultContracts.RequestPermission(), isGranted -> {
                if (isGranted) {
                    Toast.makeText(this, "Notification permission granted", Toast.LENGTH_SHORT).show();
                } else {
                    Toast.makeText(this, "Notification permission denied", Toast.LENGTH_SHORT).show();
                }
                updateStatus();
            });

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
        updateStatus();
        invalidateOptionsMenu();
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

        Intent serviceIntent = new Intent(this, SoundService.class);
        serviceIntent.putExtra("url", url);
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
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
                notificationStatus = getString(R.string.notification_permission_granted);
            } else {
                notificationStatus = getString(R.string.notification_permission_denied);
            }
        } else {
            notificationStatus = "Разрешение на уведомления: не требуется (Android < 13)";
        }
        binding.statusText.setText(String.format("%s\n%s\n%s", serviceStatus, batteryStatus, notificationStatus));
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
import android.os.IBinder;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

public class SoundService extends Service {
    private static final String CHANNEL_ID = "SoundServiceChannel";
    public static volatile boolean isRunning = false;

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        isRunning = true;
        String url = intent.getStringExtra("url");
        Intent notificationIntent = new Intent(this, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE);
        Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Sound Service")
                .setContentText("Service is running with URL: " + url)
                .setSmallIcon(android.R.drawable.ic_media_play)
                .setContentIntent(pendingIntent)
                .build();
        startForeground(1, notification);
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        isRunning = false;
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
            NotificationManager manager = getSystemService(NotificationManager.class);
            manager.createNotificationChannel(serviceChannel);
        }
    }
}
EOF

# SettingsActivity.java (ИЗМЕНЕНО)
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
        loadCurrentUrl();
        binding.saveButton.setOnClickListener(v -> saveUrl());
    }

    private void loadCurrentUrl() {
        // Теперь используем DEFAULT_URL из MainActivity, если URL еще не сохранен
        String currentUrl = prefs.getString(MainActivity.KEY_URL, MainActivity.DEFAULT_URL);
        binding.urlEditText.setText(currentUrl);
    }

    private void saveUrl() {
        String newUrl = binding.urlEditText.getText().toString().trim();
        if (!newUrl.isEmpty()) {
            SharedPreferences.Editor editor = prefs.edit();
            editor.putString(MainActivity.KEY_URL, newUrl);
            editor.apply();
            Toast.makeText(this, R.string.url_saved, Toast.LENGTH_SHORT).show();
            finish();
        } else {
            binding.urlEditText.setError("URL не может быть пустым");
        }
    }
}
EOF

# --- 5. Создание исполняемых файлов Gradle Wrapper ---
# gradlew (Linux/macOS)
cat > "$PROJECT_NAME/gradlew" << 'EOF'
#!/usr/bin/env sh
#
# Copyright 2015 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
DEFAULT_JVM_OPTS=""
APP_NAME="Gradle"
APP_BASE_NAME=`basename "$0"`
MAX_FD="maximum"
warn () {
    echo "$*"
}
die () {
    echo
    echo "ERROR: $*"
    echo
    exit 1
}
cygwin=false
msys=false
darwin=false
nonstop=false
case "`uname`" in
  CYGWIN* )
    cygwin=true
    ;;
  Darwin* )
    darwin=true
    ;;
  MINGW* )
    msys=true
    ;;
  NONSTOP* )
    nonstop=true
    ;;
esac
PRG="$0"
while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
        PRG="$link"
    else
        PRG=`dirname "$PRG"`"/$link"
    fi
done
SAVED="`pwd`"
cd "`dirname \"$PRG\"`/" >/dev/null
APP_HOME="`pwd -P`"
cd "$SAVED" >/dev/null
if [ -z "$JAVA_HOME" ]; then
    if $darwin; then
        [ -x '/usr/libexec/java_home' ] && JAVA_HOME=`/usr/libexec/java_home`
    fi
    if [ -z "$JAVA_HOME" ]; then
        if [ -d "$APP_HOME/jre" ]; then
            JAVA_HOME="$APP_HOME/jre"
        fi
    fi
    if [ -z "$JAVA_HOME" ]; then
        if $darwin; then
            if [ -d "/Library/Java/JavaVirtualMachines/jdk1.8.0.jdk/Contents/Home/jre" ]; then
                JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk1.8.0.jdk/Contents/Home/jre"
            fi
        else
            if [ -d "/opt/jdk1.8.0" ]; then
                JAVA_HOME="/opt/jdk1.8.0/jre"
            fi
        fi
    fi
fi
if [ -z "$JAVA_HOME" ]; then
    JAVACMD="java"
else
    JAVACMD="$JAVA_HOME/bin/java"
fi
if [ ! -x "$JAVACMD" ] ; then
    die "The JAVA_HOME environment variable is not defined correctly, or java is not on your PATH."
fi
if [ -z "$GRADLE_OPTS" ]; then
    GRADLE_OPTS="-Dorg.gradle.appname=$APP_BASE_NAME"
else
    GRADLE_OPTS="$GRADLE_OPTS -Dorg.gradle.appname=$APP_BASE_NAME"
fi
CLASSPATH="$APP_HOME/gradle/wrapper/gradle-wrapper.jar"
if [ -z "$JAVA_OPTS" ]; then
    JVM_OPTS_ARRAY=()
    for arg in $DEFAULT_JVM_OPTS; do
        JVM_OPTS_ARRAY[${#JVM_OPTS_ARRAY[*]}]="$arg"
    done
else
    JVM_OPTS_ARRAY=("$JAVA_OPTS")
fi
exec "$JAVACMD" "${JVM_OPTS_ARRAY[@]}" -classpath "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"
EOF

# gradlew.bat (Windows)
cat > "$PROJECT_NAME/gradlew.bat" << 'EOF'
@if "%DEBUG%" == "" @echo off
@rem ##########################################################################
@rem
@rem  Gradle startup script for Windows
@rem
@rem ##########################################################################
@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal
set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%
@rem Add default JVM options here. You can also use JAVA_OPTS and GRADLE_OPTS to pass JVM options to this script.
set DEFAULT_JVM_OPTS=
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
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %GRADLE_OPTS% "-Dorg.gradle.appname=%APP_BASE_NAME%" -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*
:end
@rem End local scope for the variables with windows NT shell
if "%ERRORLEVEL%"=="0" goto mainEnd
:fail
rem Set variable GRADLE_EXIT_CONSOLE if you need the _script_ return code instead of
rem the _cmd.exe /c_ return code.
if not defined GRADLE_EXIT_CONSOLE (
  exit /b 1
)
exit 1
:mainEnd
if "%OS%"=="Windows_NT" endlocal
:omega
EOF

# --- 6. Установка прав ---
chmod +x "$PROJECT_NAME/gradlew"

echo "Project '$PROJECT_NAME' created successfully."
