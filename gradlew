#!/usr/bin/env sh

#
# Copyright 2015 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Add default JVM options here. You can also use JAVA_OPTS and GRADLE_OPTS to pass any JVM options to Gradle separately.
DEFAULT_JVM_OPTS=""

APP_NAME="Gradle"
APP_BASE_NAME=`basename "$0"`

# Use the maximum available, or set MAX_FD != -1 to use that value.
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

# OS specific support (must be 'true' or 'false').
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

# Attempt to set APP_HOME
# Resolve links: $0 may be a link
PRG="$0"
# Need this for relative symlinks.
while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
        PRG="$link"
    else
        PRG=`dirname "$PRG"`"/$link"
    fi
done

APP_HOME=`dirname "$PRG"`

# For Cygwin, ensure paths are in UNIX format before anything is touched
if $cygwin ; then
    [ -n "$APP_HOME" ] && \
        APP_HOME=`cygpath --unix "$APP_HOME"`
    [ -n "$JAVA_HOME" ] && \
        JAVA_HOME=`cygpath --unix "$JAVA_HOME"`
fi

# Attempt to find JAVA_HOME if not already set.
if [ -z "$JAVA_HOME" ] ; then
    if $darwin ; then
        [ -x '/usr/libexec/java_home' ] && export JAVA_HOME=`/usr/libexec/java_home`
    elif $cygwin ; then
        [ -n "`which java`" ] && export JAVA_HOME=`readlink -f 
`which java
` | sed "s:/bin/java::"
    else
        java_exe=`which java 2>/dev/null`
        if [ -n "$java_exe" ] ; then
            java_exe=`readlink -f "$java_exe"`
            JAVA_HOME=`dirname "$java_exe"`
            JAVA_HOME=`dirname "$JAVA_HOME"`
        fi
    fi
fi

# Read relative path to Gradle Wrapper properties file
GRADLE_WRAPPER_PROPERTIES="$APP_HOME/gradle/wrapper/gradle-wrapper.properties"
if [ -f "$GRADLE_WRAPPER_PROPERTIES" ]; then
    . "$GRADLE_WRAPPER_PROPERTIES"
fi

# Set GRADLE_USER_HOME if not set
if [ -z "$GRADLE_USER_HOME" ] ; then
    GRADLE_USER_HOME="$HOME/.gradle"
fi

# Set distributionUrl if not set
if [ -z "$distributionUrl" ] ; then
    die "distributionUrl was not found in $GRADLE_WRAPPER_PROPERTIES"
fi

# Determine the name of the distribution directory
distributionUrl_basename=`basename $distributionUrl`
distribution_name=`echo $distributionUrl_basename | sed s/-[a-z]*.zip$//`

# Determine the location of the distribution directory
distribution_dir="$GRADLE_USER_HOME/wrapper/dists/$distribution_name"

# Determine the location of the distribution zip file
distribution_zip="$GRADLE_USER_HOME/wrapper/dists/$distributionUrl_basename"

# Determine the location of the gradle-wrapper.jar file
gradle_wrapper_jar="$distribution_dir/gradle-wrapper.jar"

# Download the distribution if not already present
if [ ! -f "$gradle_wrapper_jar" ]; then
    echo "Downloading $distributionUrl"
    if [ -f "$distribution_zip" ]; then
        rm "$distribution_zip"
    fi
    mkdir -p `dirname "$distribution_zip"`
    if [ -n "`which wget`" ]; then
        wget -q -O "$distribution_zip" "$distributionUrl"
    elif [ -n "`which curl`" ]; then
        curl -# -L -f -o "$distribution_zip" "$distributionUrl"
    else
        die "Could not find wget or curl to download Gradle distribution."
    fi
    echo "Unzipping $distribution_zip to $distribution_dir"
    unzip -q -d "$distribution_dir" "$distribution_zip"
fi

# Escape GRADLE_OPTS for bash
# Additionally preserve the single quotes if there are any
GRADLE_OPTS_ESCAPED=""
for arg in $GRADLE_OPTS; do
    if [[ "$arg" == *"'"* ]]; then
        GRADLE_OPTS_ESCAPED="$GRADLE_OPTS_ESCAPED \"$arg\""
    else
        GRADLE_OPTS_ESCAPED="$GRADLE_OPTS_ESCAPED '$arg'"
    fi
done

# Collect all arguments for the java command, following the shell quoting and substitution rules
eval set -- "$DEFAULT_JVM_OPTS" "$JAVA_OPTS" "$GRADLE_OPTS_ESCAPED" -Dorg.gradle.appname="$APP_BASE_NAME" -classpath "$gradle_wrapper_jar" org.gradle.wrapper.GradleWrapperMain "$@"

# Start the Gradle main class
exec "$JAVA_HOME/bin/java" "$@"
