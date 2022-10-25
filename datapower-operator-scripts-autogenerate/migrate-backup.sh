#!/bin/bash

###########
# Globals #
###########

# "5611" - updated flow port for v2

declare -a PORTARR=("9090" "8001")
BACKUP_ZIP=""
UNPACK_DIR=""
DOMAINS=()
DOMAIN=""
OUTPUT_DIR=""
CFG_SYNC_WAVE_COUNT=320
LOCAL_SYNC_WAVE_COUNT=335
ROUTE_SYNC_WAVE_COUNT=370

#############
# Functions #
#############

print_help() {
cat <<EOF
Usage:
  migrate-backup.sh [-h] <export.zip>

This tool will unpack an IBM DataPower Gateway configuration backup and generate
ConfigMap YAML templates containing domain configuration as well as files from
the local:/// file system for each domain.

By default the script will process the entire backup recursively, unpacking and
generating output files for each domain included in the backup. The --domain flag
can be used to only operate on a single domain at a time.

For each domain processed, the following files will be generated in the output
directory, where '\$domain' is the domain name:

  \$domain.cfg            extracted domain configuration
  \$domain-cfg.yaml       ConfigMap YAML containing \$domain.cfg
  \$domain-local.tar.gz   gzipped tarball of \$domain's local:/// file system
  \$domain-local.yaml     ConfigMap YAML containing \$domain-local.tar.gz

The \$domain-cfg.yaml and \$domain-local.yaml files are ConfigMap definitions that
can be directly applied to a Kubernetes or OpenShift cluster using either the
'kubectl' or 'oc' (for OpenShift) CLI tools, for example:

  kubectl apply -n \$namespace -f \$domain-cfg.yaml
  kubectl apply -n \$namespace -f \$domain-local.yaml

Flags:
  -d, --domain name             only process specified domain
  -u, --unpack dir              directory to unpack ZIP into
  -o, --output dir              directory to generate output files
  -h, --help                    print this help message
  --debug                       enable debug mode
EOF
}

error() {
    echo $1
    exit 1
}

initialize_defaults() {
    if [[ -z "$UNPACK_DIR" ]]; then
        UNPACK_DIR="./${BACKUP_ZIP%.*}/${BACKUP_ZIP%.*}-unpack"
    fi

    if [[ -z "$OUTPUT_DIR" ]]; then
        OUTPUT_DIR="./${BACKUP_ZIP%.*}/${BACKUP_ZIP%.*}-output"
    fi
}

validate_backup_fs() {
    if [[ ! -f "${UNPACK_DIR}/export.xml" ]]; then
        echo "expected to find ${UNPACK_DIR}/export.xml"
        error "${BACKUP_ZIP} does not appear to be a well-formed backup ZIP - aborting"
    fi

    if [[ ! $(find $UNPACK_DIR -name '*.zip' | wc -l) -gt 0 ]]; then
        echo "expected to find domain ZIP file(s) in ${UNPACK_DIR}"
        error "${BACKUP_ZIP} does not appear to be a well-formed backup ZIP - aborting"
    fi
}

normalize_domain_name() {
    local domain=$1

    domain=$(echo "${domain}" | tr '[:upper:]' '[:lower:]')
    domain=$(echo "${domain}" | tr '_' '-')

    echo "${domain}"
}

populate_domains_array() {
    local zipfile
    local domain
    local count

    echo "Searching for domains..."

    for zipfile in $(find $UNPACK_DIR -name '*.zip'); do
        domain=$(basename $zipfile)
        domain=${domain%.*}
        echo "Found domain backup: ${domain}"
        DOMAINS+=("$domain")
    done

    count="${#DOMAINS[@]}"
    echo "Found ${count} domains"
}

pretty_print_cfg() {
    local cfg=$1

    # cp $cfg $cfg.bak
    cat $cfg | sed -E 's/([[:space:]]|\r)+$//g' > $cfg.tmp
    mv $cfg.tmp $cfg
}

prune_app_domains() {
    local cfg=$1
    local inside_domain=false

    while IFS= read -r line
    do
        # drop the line if it's part of a domain declaration
        if [[ "$inside_domain" = true ]]; then

            # check for end of a domain declaration
            if echo "$line" | grep --quiet "exit"; then
                inside_domain=false
            fi

            continue
        fi

        # check for start of a domain declaration
        if echo "$line" | grep --quiet -e "^domain \""; then
            inside_domain=true
            continue
        fi

        # preserve everything that's not part of a domain declaration
        echo "${line}" >> $cfg.tmp

    done < $cfg

    cp $cfg $cfg.orig
    mv $cfg.tmp $cfg

    echo "Original default.cfg backed up: ${cfg}.orig"
}

process_domain() {
    local domain=$1
    local domain_zip="${UNPACK_DIR}/${domain}.zip"
    local domain_unpack="${UNPACK_DIR}/${domain}-unpack"
    local domain_config="${domain_unpack}/config"
    local domain_local="${domain_unpack}/local"
    local default=false
    local domain_norm=$(normalize_domain_name $domain)

    echo "Processing domain: $domain"

    if [[ "$domain" = "default" ]]; then
        default=true
    fi

    unzip -q $domain_zip -d $domain_unpack

    echo "Searching for cfg and local files"

    if [[ -d "${domain_config}" ]]; then
        if [[ $default = true ]]; then
            echo "Pulling auto-startup.cfg for default domain"
            cp $domain_config/auto-startup.cfg $OUTPUT_DIR/default.cfg
            pretty_print_cfg $OUTPUT_DIR/default.cfg
            echo "Pruning app domain definitions from default.cfg (this may take a while)"
            prune_app_domains $OUTPUT_DIR/default.cfg
            kubectl create configmap ${domain}-cfg \
                --from-file="${OUTPUT_DIR}/default.cfg" \
                --dry-run="client" \
                --output="yaml" > $OUTPUT_DIR/default-cfg.yaml
            echo -e "  annotations: \n    argocd.argoproj.io/sync-wave: \"${CFG_SYNC_WAVE_COUNT}\"" >> $OUTPUT_DIR/default-cfg.yaml
            echo "Generated: ${OUTPUT_DIR}/default-cfg.yaml"
            ((CFG_SYNC_WAVE_COUNT+=1))
        else
            echo "Iterating over domain config: ${domain_config}"
            for cfg in $(find ${domain_config} -type f); do
                echo "Pulling: ${cfg}"
                cp $cfg $OUTPUT_DIR
                pretty_print_cfg "${OUTPUT_DIR}/${domain}.cfg"
                echo "Generating configmap yaml..."
                kubectl create configmap ${domain}-cfg \
                    --from-file="${OUTPUT_DIR}/${domain}.cfg" \
                    --dry-run="client" \
                    --output="yaml" > $OUTPUT_DIR/$domain_norm-cfg.yaml
                echo -e "  annotations: \n    argocd.argoproj.io/sync-wave: \"${CFG_SYNC_WAVE_COUNT}\"" >> $OUTPUT_DIR/$domain_norm-cfg.yaml
                sed -i '' "s/name: ${domain}-cfg/name: ${domain_norm}-cfg/g" $OUTPUT_DIR/$domain_norm-cfg.yaml
                echo "Generated: ${OUTPUT_DIR}/${domain_norm}-cfg.yaml"
                ((CFG_SYNC_WAVE_COUNT+=1))
            done
        fi
    fi

    if [[ -d "${domain_local}" ]]; then
        echo "Found domain local: ${domain_local}"
        echo "Generating tarball..."
        tar --directory="${domain_local}" -cvzf $OUTPUT_DIR/$domain-local.tar.gz .
        echo "Generating configmap yaml..."
        kubectl create configmap ${domain}-local \
            --from-file="${OUTPUT_DIR}/${domain}-local.tar.gz" \
            --dry-run="client" \
            --output="yaml" > $OUTPUT_DIR/$domain_norm-local.yaml
        echo -e "  annotations: \n    argocd.argoproj.io/sync-wave: \"${LOCAL_SYNC_WAVE_COUNT}\"" >> $OUTPUT_DIR/$domain_norm-local.yaml
        sed -i '' "s/name: ${domain}-local/name: ${domain_norm}-local/g" $OUTPUT_DIR/$domain_norm-local.yaml
        echo "Generated: ${OUTPUT_DIR}/${domain_norm}-local.yaml"
        ((LOCAL_SYNC_WAVE_COUNT+=1))
    fi
}

change_domains_case() {
    local domain_norm

    echo "Changing domain cases for yamls"

    for i in "${!DOMAINS[@]}"; do
        domain_norm=$(normalize_domain_name ${DOMAINS[i]})
        echo "Changed name to: ${domain_norm}"
        DOMAINS[i]=$domain_norm
    done
}

create_yamls() {
    ./migrate-backup-dps.sh ${BACKUP_ZIP%.*} "${DOMAINS[@]}" > ./${BACKUP_ZIP%.*}/${BACKUP_ZIP%.*}-output/${BACKUP_ZIP%.*}-dps.yaml
    echo "./${BACKUP_ZIP%.*}/${BACKUP_ZIP%.*}-output/${BACKUP_ZIP%.*}-dps.yaml created"
    ./migrate-backup-service.sh ${BACKUP_ZIP%.*} "${PORTARR[@]}" > ./${BACKUP_ZIP%.*}/${BACKUP_ZIP%.*}-output/${BACKUP_ZIP%.*}-service.yaml
    echo "./${BACKUP_ZIP%.*}/${BACKUP_ZIP%.*}-output/${BACKUP_ZIP%.*}-service.yaml created"
    for port in "${PORTARR[@]}"; do
        ./migrate-backup-route.sh ${BACKUP_ZIP%.*} "$port" > ./${BACKUP_ZIP%.*}/${BACKUP_ZIP%.*}-output/${BACKUP_ZIP%.*}-"$port"-route.yaml
        echo "./${BACKUP_ZIP%.*}/${BACKUP_ZIP%.*}-output/${BACKUP_ZIP%.*}-"$port"-route.yaml created"
        sed -i '' "s/370/${ROUTE_SYNC_WAVE_COUNT}/g" $OUTPUT_DIR/${BACKUP_ZIP%.*}-"$port"-route.yaml
        ((ROUTE_SYNC_WAVE_COUNT+=1))
    done;
}

########
# Main #
########

# Parse flags
while [ $# -gt 0 ]; do
    case $1 in
        -h | --help)
            print_help
            exit 0
            ;;
        --debug)
            set -x
            shift
            ;;
        -d | --domain)
            DOMAIN=$2
            shift 2
            ;;
        -o | --output)
            OUTPUT_DIR=$2
            shift 2
            ;;
        -u | --unpack)
            UNPACK_DIR=$2
            shift 2
            ;;
        -*)
            error "unrecongized flag: $1"
            ;;
        *.zip)
            BACKUP_ZIP=$1
            shift
            ;;
    esac
done

# Fail early if no zip was provided
if [[ -z "$BACKUP_ZIP" ]]; then
    error "no backup ZIP provided - aborting"
fi

# Initialize variables not set by user flags
initialize_defaults

if [[ ! -d "$OUTPUT_DIR" ]]; then
    mkdir -p -v $OUTPUT_DIR
else
    if [[ "$(ls -A $OUTPUT_DIR)" ]]; then
        error "output directory is non-empty: ${OUTPUT_DIR} - aborting"
    fi
fi

echo "Processing backup archive: ${BACKUP_ZIP}"
echo "ZIP will be unpacked into: ${UNPACK_DIR}"
echo "YAML will be generated in: ${OUTPUT_DIR}"

# abort if unpack directory already exists
if [[ -d "${UNPACK_DIR}" ]]; then
    error "directory already exists: ${UNPACK_DIR} - aborting"
fi

# unpack the backup archive into the backup directory
unzip -q $BACKUP_ZIP -d $UNPACK_DIR

# sniff test to make sure this looks like a backup
validate_backup_fs

populate_domains_array

if [[ ! -z "$DOMAIN" ]]; then
    echo "Processing single domain"
    process_domain $DOMAIN
else
    echo "Processing domain archives..."
    for domain in ${DOMAINS[@]}; do
        process_domain $domain
    done
fi

change_domains_case

create_yamls $DOMAINS[@]