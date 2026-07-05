 #!/bin/bash

ip2int() { 
    local ip=$1; local IFS=.; set -- $ip
    echo "$(( ($1 << 24) + ($2 << 16) + ($3 << 8) + $4 ))"
}

int2ip() {
    local int=$1
    echo "$(( (int >> 24) & 255 )).$(( (int >> 16) & 255 )).$(( (int >> 8) & 255 )).$(( int & 255 ))"
}

output_file=""

while getopts "w:" opt; do
    case $opt in
        w) output_file="$OPTARG" ;;
        *) exit 1 ;;
    esac
done

shift $((OPTIND - 1))

if [ -z "$1" ]; then
    echo "Error"
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
    echo "Исходный IP:    $ip/$cidr" > "$output_file"
    echo "Первый хост IP: $(int2ip $first_usable_num)" >> "$output_file"
    echo "Последний хост: $(int2ip $last_usable_num)" >> "$output_file"
else
    echo "Исходный IP:    $ip/$cidr"
    echo "Первый хост IP: $(int2ip $first_usable_num)"
    echo "Последний хост: $(int2ip $last_usable_num)"
fi 

max_jobs=100

for current_num in $(seq $first_usable_num $last_usable_num); do
    (
        current_ip=$(int2ip $current_num)
        ping -c 1 -W 1 "$current_ip" &> /dev/null
        if [ $? -eq 0 ]; then
            if [ -n "$output_file" ]; then
                echo "$current_ip is up" >> "$output_file"
            else
                echo "$current_ip is up"
            fi
        fi
    ) &

    if [ $(jobs -r | wc -l) -ge $max_jobs ]; then
        sleep 0.05
    fi

done

wait 
