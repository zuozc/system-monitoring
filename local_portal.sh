#!/bin/bash

# portal for disk usage test
# this script actaully call disk_usage.sh

PLUGIN_HOME=/usr/local/collectd/plugins/
PLUGIN_DB_HOME=/usr/share/collectd/
COLLECTD_CONF=/opt/collectd/etc/collectd.conf

#1. Add the plugin shell to plugin folder
mkdir -p $PLUGIN_HOME 
mkdir -p $PLUGIN_DB_HOME

SCRIPT_NAME=disk_usage.sh # actual plugin script used to check disk usage

cp $SCRIPT_NAME $PLUGIN_HOME

#2. Add the collector defnition db to collectd.conf
[[ `grep blu_type.db $COLLECTD_CONF` ]] || [[ `sed -i 's/^TypesDB/TypesDB  \"\/usr\/share\/collectd\/blu_type.db\"/g' $COLLECTD_CONF` ]]
cp blu_type.db.txt /usr/share/collectd/blu_type.db

#3. Add plugin conf to collectd.conf
sed -i 's/^#BaseDir/BaseDir/' $COLLECTD_CONF

sed -i 's/^#TypesDB/TypesDB/' $COLLECTD_CONF

sed -i 's/^#LoadPlugin exec/LoadPlugin exec/g' $COLLECTD_CONF
cat << EOF > /tmp/temp_collectd_cfg

#TypesDB "/usr/share/collectd/blu_type.db"
<Plugin exec>
  #     userid    plugin executable            plugin        args
  #Interval 60 
  Exec "zuozc" "/usr/local/collectd/plugins/${SCRIPT_NAME}" "10" 
</Plugin>
EOF

[[ `grep ${SCRIPT_NAME} $COLLECTD_CONF` ]] || [[ `cat /tmp/temp_collectd_cfg >> $COLLECTD_CONF` ]]

#restart collectd
pid=$(ps -aux | grep '^root.*collectd' | awk '{print $2}')
echo $pid
kill $pid

cd /opt/collectd/sbin
./collectd

