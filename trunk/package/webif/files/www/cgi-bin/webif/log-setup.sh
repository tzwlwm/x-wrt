#!/usr/bin/webif-page
<?
. /usr/lib/webif/webif.sh

config_cb() {
	[ -n "$1" ] && eval "$1_cfg=\"$2\""
}

uci_load syslog

if empty "$FORM_submit"; then
	eval FORM_ipaddr="\$CONFIG_${syslogd_cfg}_ipaddr"
	eval FORM_port="\$CONFIG_${syslogd_cfg}_port"
	eval FORM_mark="\$CONFIG_${syslogd_cfg}_mark"
	eval FORM_type="\$CONFIG_${syslogd_cfg}_type"
	eval FORM_file="\$CONFIG_${syslogd_cfg}_file"
	FORM_file="${FORM_file:-/var/log/messages}"
	eval FORM_size="\$CONFIG_${syslogd_cfg}_size"
	FORM_size="${FORM_size:-16}"
	eval FORM_conloglevel="\$CONFIG_${klogd_cfg}_conloglevel"
	eval FORM_buffersize="\$CONFIG_${dmesg_cfg}_buffersize"
	config_get_bool FORM_enabled "$dmesgbackup_cfg" enabled 0
	eval FORM_kfile="\$CONFIG_${dmesgbackup_cfg}_file"
	FORM_kfile="${FORM_kfile:-/var/log/dmesg}"
	config_get_bool FORM_gzip "$dmesgbackup_cfg" gzip 0
else
	SAVED=1
	[ "$FORM_type" = "file" ] && file_required="required"
	[ 1 -eq "$FORM_enabled" ] && kfile_required="required"
	validate <<EOF
ip|FORM_ipaddr|@TR<<Remote host>>||$FORM_ipaddr
int|FORM_port|@TR<<Remote Port>>|min=0 max=65535|$FORM_port
int|FORM_mark|@TR<<Minutes Between Marks>>||$FORM_mark
string|file|@TR<<Log File>>|$file_required|$FORM_file
int|FORM_size|@TR<<Log Size>>|min=1 max=9999 required|$FORM_size
int|FORM__conloglevel|@TR<<Default Log Level>>|min=0 max=9|$FORM__conloglevel
int|FORM_buffersize|@TR<<Ring Buffer Size>>|min=1 max=9999|$FORM_buffersize
string|kfile|@TR<<Backup File>>|$kfile_required|$FORM_kfile
EOF
	equal "$?" 0 && {
		reload_config=0
		[ -z "$syslogd_cfg" ] && { uci_add syslog syslogd; reload_config=1; }
		[ -z "$klogd_cfg" ] && { uci_add syslog klogd; reload_config=1; }
		[ -z "$dmesg_cfg" ] && { uci_add syslog dmesg; reload_config=1; }
		[ -z "$dmesgbackup_cfg" ] && { uci_add syslog dmesgbackup; reload_config=1; }
		[ 1 -eq "$reload_config" ] && uci_load syslog
		uci_set syslog "$syslogd_cfg" ipaddr "$FORM_ipaddr"
		uci_set syslog "$syslogd_cfg" port "$FORM_port"
		uci_set syslog "$syslogd_cfg" mark "$FORM_mark"
		uci_set syslog "$syslogd_cfg" type "$FORM_type"
		uci_set syslog "$syslogd_cfg" file "$FORM_file"
		uci_set syslog "$syslogd_cfg" size "$FORM_size"
		uci_set syslog "$klogd_cfg" conloglevel "$FORM_conloglevel"
		uci_set syslog "$dmesg_cfg" buffersize "$FORM_buffersize"
		uci_set syslog "$dmesgbackup_cfg" enabled "$FORM_enabled"
		uci_set syslog "$dmesgbackup_cfg" file "$FORM_kfile"
		uci_set syslog "$dmesgbackup_cfg" gzip "$FORM_gzip"
	}
fi

header "Log" "Log Settings" "@TR<<Log Settings>>" '' "$SCRIPT_NAME"

#####################################################################
# modechange script
#
cat <<EOF
<script type="text/javascript" src="/webif.js"></script>
<script type="text/javascript">
<!--
function modechange()
{
	var v;
	v = isset('type', 'file');
	set_visible('logname', v);
}
//-->
</script>

EOF

display_form <<EOF
start_form|@TR<<Remote Syslog>>
field|@TR<<Server IP Address>>
text|ipaddr|$FORM_ipaddr
field|@TR<<Server Port>>
text|port|$FORM_port
helpitem|Remote Syslog
helptext|HelpText Remote Syslog#IP address and port of the remote logging host. Leave this address blank for no remote logging.
end_form

start_form|@TR<<Syslog Marks>>
field|@TR<<Minutes Between Marks>>
text|mark|$FORM_mark
helpitem|Syslog Marks
helptext|HelpText Syslog Marks#Periodic marks in your log. This parameter sets the time in minutes between the marks. A value of 0 means no mark.
end_form

start_form|@TR<<Local Log>>
onchange|modechange
field|@TR<<Log type>>
select|type|$FORM_type
option|circular|@TR<<Circular>>
option|file|@TR<<File>>
field|@TR<<Log File>>|logname|hidden
text|file|$FORM_file
field|@TR<<Log Size>>
text|size|$FORM_size|&nbsp;@TR<<KiB>>
helpitem|Log type
helptext|HelpText Log Type#Whether your log will be stored in a memory circular buffer or in a file. Beware that files are stored in a memory filesystem which will be lost if you reboot your router.
helpitem|Log File
helptext|HelpText Log File#The path and name of your log file. It can be set on any writable filesystem. CAUTION: DO NOT USE A JFFS filesystem because syslog will write A LOT to it. You can use /tmp or any filesystem on an external storage unit.
helpitem|Log Size
helptext|HelpText Log Size#The size of your log in kibibytes. Be carefull with the size of the circular buffer as it is taken from your main memory.
end_form

start_form|@TR<<Kernel Log>>
field|@TR<<Messages Priority>>
text|conloglevel|$FORM_conloglevel
field|@TR<<Ring Buffer Size>>
text|buffersize|$FORM_buffersize|&nbsp;@TR<<KiB>>
helpitem|Messages Priority
helptext|Messages Priority_helptext#Log messages up to the defined priority, the default priority level is 7 (debug).
helpitem|Ring Buffer Size
helptext|Ring Buffer Size_helptext#How much space will kernel reserve for messages in memory. The default size is 16 KiB.
end_form

start_form|@TR<<Boot Time Log>>
field|@TR<<Backup Boot Time Messages>>
checkbox|enabled|$FORM_enabled|1
field|@TR<<Backup File>>
text|kfile|$FORM_kfile
field|@TR<<Compress Backup>>
checkbox|gzip|$FORM_gzip|1
helpitem|Backup Boot Time Messages
helptext|Backup Boot Time Messages_helptext#The boot time messages will get overwritten by other events. You can save them for the later reference.
end_form
EOF

footer ?>
<!--
##WEBIF:name:Log:001:Log Settings
-->