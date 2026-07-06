 #!/bin/bash

ip2int() 
{ 
    local ip=$1; local IFS=.; set -- $ip
    echo "$(( ($1 << 24) + ($2 << 16) + ($3 << 8) + $4 ))"
}

int2ip() 
{
    local int=$1
    echo "$(( (int >> 24) & 255 )).$(( (int >> 16) & 255 )).$(( (int >> 8) & 255 )).$(( int & 255 ))"
}

output_file=""

log_output() 
{
	if [ -n "$output_file" ]; then
		echo "$1" >> "$output_file"
	else
		echo "$1"
	fi
}

while getopts "w:" opt; do
    case $opt in
        w) output_file="$OPTARG" ;;
        *) exit 1 ;;
    esac
done

shift $((OPTIND - 1))

if [ -z "$1" ]; then
    echo "Error!"
    exit 1
fi 

ip=$(echo "$1" | cut -d "/" -f1)
cidr=$(echo "$1" | cut -d "/" -f2)

ip_num=$(ip2int "$ip")
mask_num=$(( (0xFFFFFFFF << (32 - cidr)) & 0xFFFFFFFF ))
wildcard_num=$(( mask_num ^ 0xFFFFFFFF ))

first_usable_num=$(( (ip_num & mask_num) + 1 ))
last_usable_num=$(( (ip_num & mask_num) + wildcard_num - 1 ))

if [ -n "$output_file" ]; then
    > "$output_file"
fi

log_output "IP and CIDR IP: $ip/$cidr" 
log_output "Fist Usable IP: $(int2ip $first_usable_num)" 
log_output "Lost Usable IP: $(int2ip $last_usable_num)" 
log_output "---------------------------------------"

max_jobs=100

for current_num in $(seq $first_usable_num $last_usable_num); do
    (
        current_ip=$(int2ip $current_num)

		ping_res=$(ping -c 1 -W 1 "$current_ip" 2> /dev/null)

		if echo "$ping_res" | grep -iq "ttl="; then
			ttl=$(echo "$ping_res" | grep -io "ttl=[0-9]*" | cut -d= -f2)

			if [ "$ttl" -gt 0 ] && [ "$ttl" -le 64 ]; then
                os_type="Linux / Android / macOS / iOS"
            elif [ "$ttl" -gt 64 ] && [ "$ttl" -le 128 ]; then
                os_type="Windows"
            elif [ "$ttl" -gt 128 ] && [ "$ttl" -le 255 ]; then
                os_type="Router / Network Device"
            else
                os_type="Unknown OS"
            fi

			hostname=$(getent hosts "$current_ip" | awk '{print $2}')

            if [ -z "$hostname" ]; then 
				hostname="NoName"; 
			fi

			log_output "$current_ip is up | hostname: $hostname | ttl: $ttl | os: $os_type"
		fi
    ) &

    if [ $(jobs -r | wc -l) -ge $max_jobs ]; then
        sleep 0.05
    fi

done

wait 
