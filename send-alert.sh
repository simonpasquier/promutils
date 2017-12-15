#!/bin/bash -e
# Fire/resolve a random alert to one or several AlertManager

name=$RANDOM
starts_at=$(date --iso-8601='seconds')
ends_at=null

function send_alert {
    local target="http://${1}/api/v1/alerts"
    local status="${2}"

    if [[ "${status}" == "resolved" ]]; then
        ends_at="\""$(date --iso-8601='second')"\""
    fi
    set +e
    curl -XPOST "${target}" -d "[{
        \"labels\": {
            \"alertname\": \"${name}\",
            \"service\": \"my-service\",
            \"severity\":\"warning\",
            \"instance\": \"${name}.example.net\"
        },
        \"annotations\": {
            \"summary\": \"High latency is high!\"
        },
        \"startsAt\": \"${starts_at}\",
        \"endsAt\": ${ends_at},
        \"generatorURL\": \"http://prometheus.int.example.net/<generating_expression>\"
    }]"
    set -e
    echo ""
}

if [ $# -eq 0 ]; then
    echo "Usage: $(basename ${0}) ADDRESS:PORT [...]"
    echo "Fire/resolve a random alert to several AlertManager endpoints."
    exit 0
fi

for host in "${@}"; do
    echo "firing alert $name to $host"
    send_alert "${host}" "firing"
done

echo ""

echo "press Enter to resolve the alert"
read

for host in "${@}"; do
    echo "resolving alert $name on $host"
    send_alert "${host}" "resolved"
done
