#!/bin/bash

export SERVER_HOME="/tomcat"

# ----------------------------------------------------------------------------------------------------------------------
# setenv.sh
echo "#!/bin/sh

# ---------------------------------------------------------------------------------
# export APR_HOME=\"${SERVER_HOME%/}/apr\"
# export OPENSSL_HOME=\"${SERVER_HOME%/}/openssl\"

# export CLASSPATH=\$CLASSPATH

# Library path setting
# if [[ -n \"\$LD_LIBRARY_PATH\" ]]; then
#     export LD_LIBRARY_PATH=\$APR_HOME/lib:\$OPENSSL_HOME/lib:\$CATALINA_HOME/lib:\$LD_LIBRARY_PATH
# else
#     export LD_LIBRARY_PATH=\$APR_HOME/lib:\$OPENSSL_HOME/lib:\$CATALINA_HOME/lib
# fi

# ---------------------------------------------------------------------------------
# Tomcat logs home directory (로그 기록 경로가 변경되는 경우 변경 아래 경로를 변경.)
export CATALINA_OPTS=\"\$CATALINA_OPTS -Dserver.logs.home=\$CATALINA_BASE/logs\"

# ---------------------------------------------------------------------------------
# discourage address map swapping by setting Xms and Xmx to the same value
# http://confluence.atlassian.com/display/DOC/Garbage+Collector+Performance+Issues
export CATALINA_OPTS=\"\$CATALINA_OPTS -Xms1024m\"
export CATALINA_OPTS=\"\$CATALINA_OPTS -Xmx2048m\"
# export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:NewSize=256mm\"
# export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:MaxNewSize=512m\"

# Java >= 8 : -XX:MetaspaceSize=<metaspace size>[g|m|k] -XX:MaxMetaspaceSize=<metaspace size>[g|m|k]
# export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:MetaspaceSize=512m\"
# export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:MaxMetaspaceSize=1024m\"

# Reserved code cache size
#export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:ReservedCodeCacheSize=256m\"

# Setting GC option
export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:+UseG1GC\"
export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:MaxGCPauseMillis=20\"
export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:InitiatingHeapOccupancyPercent=35\"
export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:+ExplicitGCInvokesConcurrent\"

# Disable remote (distributed) garbage collection by Java clients
# and remove ability for applications to call explicit GC collection
export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:+DisableExplicitGC\"

# Java 8 이하에서 GC 로그 기록, 서버에 많은 부하를 주지는 않음, 별도의 GC 모니터링이 필요 하다면 추가
export CATALINA_OPTS=\"\$CATALINA_OPTS -Xloggc:\$CATALINA_BASE/logs/gc.log\"

# Java 9 이상에서 GC 로그 기록, 서버에 많은 부하를 주지는 않음, 별도의 GC 모니터링이 필요 하다면 추가
# export CATALINA_OPTS=\"\$CATALINA_OPTS -Xlog:gc*:file=\$CATALINA_BASE/logs/gc.log::filecount=10,filesize=10M\"

export CATALINA_OPTS=\"\$CATALINA_OPTS -verbose:gc\"
export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:+PrintGCDetails\"
export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:+PrintGCDateStamps\"
export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:+PrintGCTimeStamps\"

# Rolling Java GC Logging
export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:+UseGCLogFileRotation\"
export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:NumberOfGCLogFiles=10\"
export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:GCLogFileSize=10M\"

# Save OutOfMemoryError to dump file
export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:+HeapDumpOnOutOfMemoryError\"
export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:HeapDumpPath=\$CATALINA_BASE/temp\"

# Error Log
export CATALINA_OPTS=\"\$CATALINA_OPTS -XX:ErrorFile=\$CATALINA_BASE/logs/hs_err_%p.log\"

# ----------------------------------------------------------------------------------------------------
# The hotspot server JVM has specific code-path optimizations
# which yield an approximate 10% gain over the client version.
export JAVA_OPTS=\"-server \$JAVA_OPTS\"

# Option to change random number generator to / dev / urandom instead of / dev / random
export JAVA_OPTS=\"\$JAVA_OPTS -Djava.security.egd=file:/dev/./urandom\"

# Globalization and Headless Environment
export JAVA_OPTS=\"\$JAVA_OPTS -Dfile.encoding=UTF8\"
export JAVA_OPTS=\"\$JAVA_OPTS -Dclient.encoding.override=UTF-8\"
export JAVA_OPTS=\"\$JAVA_OPTS -Duser.timezone=GMT+09:00\"
export JAVA_OPTS=\"\$JAVA_OPTS -Dsun.java2d.opengl=false\"
export JAVA_OPTS=\"\$JAVA_OPTS -Djava.awt.headless=true\"
export JAVA_OPTS=\"\$JAVA_OPTS -Djava.net.preferIPv4Stack=true\"

# Setting spring boot profiles
# export JAVA_OPTS=\"\$JAVA_OPTS -Dspring.profiles.active=dev\"
" > setenv-sample.sh
