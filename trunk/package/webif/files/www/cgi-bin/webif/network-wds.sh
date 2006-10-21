#!/usr/bin/webif-page
<? 
. "/usr/lib/webif/webif.sh"

load_settings wds
load_settings wireless

lan_wds_mac=${wl0_wds:-$(nvram get wl0_wds)}

interface_num=49153
for mac in $(nvram get wl0_wds); do
wds_list=" $wds_list
          wds0.$interface_num=$mac"
let "interface_num+=1"
done

equal "$FORM_interface" "lan" && 
{
	wds_macs=$(echo $lan_wds_mac |sed s/$FORM_macremove//)
	#save_setting wireless wl0_wds "$wds_macs"
	save_setting_ex wds macaddress bridge bridgename(wan/wifi/p2p) 
	save_setting_ex wds macaddress ipaddr ipaddress(192.168.3.4)
	save_setting_ex wds macaddress proto  static
}

if empty "$FORM_submit"; then 
	FORM_lazywds=${wl0_lazywds:-$(nvram get wl0_lazywds)}
	case "$FORM_lazywds" in
		1|on|enabled) FORM_lazywds=1;;
		*) FORM_lazywds=0;;
	esac
	FORM_wds_mac=${FORM_wds_mac:-00:00:00:00:00:00}
else 
	SAVED=1
	validate <<EOF
mac|FORM_wds_mac|@TR<<IP Address>>||$FORM_wds_mac
EOF
	equal "$?" 0 && {
		case "$FORM_wdsbridge" in
			lan) save_setting wireless wl0_wds "$lan_wds_mac $FORM_wds_mac";;
			wan) ;;
			wifi) ;;
		esac
		save_setting wireless wl0_lazywds "$FORM_lazywds"

	}
fi

for mac in $lan_wds_mac; do
	stuff="string|<tr><td $style>$mac</td><td $style>LAN</td><td $style><a href=\"network-wds.sh?action=remove&amp;interface=lan&amp;macremove=$mac\">@TR<<Remove>></a></td></tr><br />
		$stuff"
done

header "Network" "WDS" "@TR<<WDS Configuration>>" ' onLoad="modechange()" ' "$SCRIPT_NAME"

display_form <<EOF

start_form|@TR<<Active WDS>>
string|<table style=\\"width: 70%\\">
string|<tr><th> MAC Addresses &nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp</th><th> Interface &nbsp&nbsp</th><th> Action </th></tr>
string|<tr><td colspan=\\"3\\"><hr class=\\"separator\\" /></td></tr>
$stuff
string|</table><br />
end_form

start_form|@TR<<WDS Configuration>>
field|@TR<<WDS>>
text|wds_mac|$FORM_wds_mac

select|wdsmode|$FORM_wdsmode
option|bridged|@TR<<Bridged>>
option|p2p|@TR<<Point To Point>>

helpitem|WDS
helptext|Helptext WDS#This page does not work yet!!!!!!

field|@TR<<WDS Bridge>>
select|wdsbridge|$FORM_wdsbridge
option|lan|@TR<<LAN>>
option|wan|@TR<<WAN>>
option|wifi|@TR<<WIFI>>
end_form

start_form|@TR<<WDS P2P Configuration>>|wdsp2pform|hidden
field|@TR<<WDS P2P>>
end_form

start_form|@TR<<Automatic WDS>>
field|@TR<<Automatic WDS>>

select|lazywds|$FORM_lazywds
option|1|@TR<<Enabled>>
option|0|@TR<<Disabled>>
end_form
EOF

footer ?>
<!--
##WEBIF:name:Network:415:WDS
-->