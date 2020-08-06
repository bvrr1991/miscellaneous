#!/bin/bash
# Start SQL Workbench/J in console mode

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

"$JAVACMD" -Djava.awt.headless=true \
           -Dvisualvm.display.name=SQLWorkbenchJ \
           -cp "$cp" workbench.console.SQLConsole "$@"

