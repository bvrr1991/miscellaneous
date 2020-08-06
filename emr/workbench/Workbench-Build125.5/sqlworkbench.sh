#!/bin/bash
# Start SQL Workbench/J in GUI mode

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"

JAVACMD="java"

if [ -x "$SCRIPT_PATH/jre/bin/java" ]
then
  JAVACMD="$SCRIPT_PATH/jre/bin/java"
elif [ -x "$SCRIPT_PATH/jre/Contents/Home/bin/java" ]
then
  # MacOS
  JAVACMD="$SCRIPT_PATH/jre/Contents/Home/bin/java"
elif [ -x "$WORKBENCH_JDK/bin/java" ]
then
  JAVACMD="$WORKBENCH_JDK/bin/java"
elif [ -x "$JAVA_HOME/jre/bin/java" ]
then
  JAVACMD="$JAVA_HOME/jre/bin/java"
elif [ -x "$JAVA_HOME/bin/java" ]
then
  JAVACMD="$JAVA_HOME/bin/java"
fi

cp=$SCRIPT_PATH/sqlworkbench.jar
cp=$cp:$SCRIPT_PATH/ext/*

# When running in batch mode on a system with no X11 installed, the option
#   -Djava.awt.headless=true
# might be needed for some combinations of OS and JDK
# For Java 9 and above the following option might be needed:
# --add-opens java.desktop/com.sun.java.swing.plaf.windows=ALL-UNNAMED

exec "$JAVACMD" -Dvisualvm.display.name=SQLWorkbenchJ -Dawt.useSystemAAFontSettings=on -cp "$cp" workbench.WbStarter "$@"
