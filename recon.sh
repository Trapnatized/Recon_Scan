#!/bin/bash

# Colors
RED='\033[0;31m'
GRN='\033[0;32m'
BLU='\033[0;34m'
NC='\033[0m'

read_domains_interactive() {
    
    # Clear or create the domains file
    : > "$domain_file"

    echo -e "${GRN}========================${NC}" >&2
    echo -e "${GRN}=== Interactive Mode ===${NC}" >&2
    echo -e "${GRN}========================${NC}" >&2
    echo -e "${GRN}Enter domains (one per line, press Ctrl+D when finished):${NC}" >&2

    # Enable line editing with backspace support
    while IFS= read -e -p $'\033[0;31m> \033[0m' line; do
        if [[ -n "$line" ]]; then
            if [ ! -s "$domain_file" ]; then
                printf "%s" "$line" > "$domain_file"
            else
                printf "\n%s" "$line" >> "$domain_file"
            fi
            echo -e "${GRN}Added: $line${NC}" >&2
        fi
    done

    # Check if domains were entered
    if [ ! -s "$domain_file" ]; then
        echo -e "${RED}No domains were entered!${NC}" >&2
        exit 1
    fi

    echo -e "\n${GRN}Domains to process:${NC}" >&2
    echo -e "${GRN}-------------------${NC}" >&2
    cat "$domain_file"
    echo -e "\n${GRN}-------------------${NC}\n" >&2

}

subdomain_enum() {
    echo -e "${GRN}=============================${NC}" >&2
    echo -e "${GRN}=== Subdomain Enumeration ===${NC}" >&2
    echo -e "${GRN}=============================${NC}" >&2

    #subfinder
    echo -e  "${GRN}[+] Checking subfinder...${NC}"
    subfinder -d "$domain" -silent -o "${wd}/subfinder.txt" > /dev/null
    # subfinder -d "$domain" -v -o "${wd}/subfinder.txt" > /dev/null
    cat "${wd}/subfinder.txt" | anew "${wd}/domains.txt" > /dev/null
    rm "${wd}/subfinder.txt"
    echo -e "${GRN}[+] Done!${NC}"

    #assetfinder
    echo -e  "${GRN}[+] Searching assetfinder...${NC}"
    assetfinder --subs-only "$domain" >> "${wd}/assets.txt" > /dev/null
    cat "${wd}/assets.txt" | anew "${wd}/domains.txt" > /dev/null
    rm "${wd}/assets.txt"
    echo -e "${GRN}[+] Done!${NC}"

    #crt.sh
    echo -e  "${GRN}[+] Searching crt.sh...${NC}"
    curl "https://crt.sh/?q=$domain&output=json" -o "${wd}/crt.txt"
    jq -r ".[] | .name_value" "${wd}/crt.txt" >> "${wd}/crt-out.txt"
    sed -i 's/\*\.//' "${wd}/crt-out.txt"
    cat "${wd}/crt-out.txt" | anew "${wd}/domains.txt" > /dev/null
    rm "${wd}/crt.txt" "${wd}/crt-out.txt"
    echo -e "${GRN}[+] Done!${NC}"

}

filter_results() {
    echo -e "${GRN}=========================${NC}" >&2
    echo -e "${GRN}=== Filtering Results ===${NC}" >&2
    echo -e "${GRN}=========================${NC}" >&2

    #filter by status codes
    cat "${wd}/httpx-out.txt" | grep 200 >> "${wd}/200.txt"
    cat "${wd}/httpx-out.txt" | grep 301 >> "${wd}/300.txt"
    cat "${wd}/httpx-out.txt" | grep 302 >> "${wd}/300.txt"
    cat "${wd}/httpx-out.txt" | grep 401 >> "${wd}/400.txt"
    cat "${wd}/httpx-out.txt" | grep 403 >> "${wd}/400.txt"
    cat "${wd}/httpx-out.txt" | grep 404 >> "${wd}/404.txt"
    echo -e "${GRN}[+] Done!${NC}"

}

alive_hosts() {
    echo -e "${GRN}===================${NC}" >&2
    echo -e "${GRN}=== Alive Hosts ===${NC}" >&2
    echo -e "${GRN}===================${NC}" >&2

    #httprobe
    echo -e "${GRN}[+] Probing with HTTProbe...${NC}"
    cat "${wd}/domains.txt" | sort -u | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ':443' >> "${wd}/a.txt"
    sort -u "${wd}/a.txt" >> "${wd}/alive.txt"
    rm "${wd}/a.txt"
    echo -e "${GRN}[+] Done!${NC}"

    #httpx
    echo -e "${GRN}[+] Probing with HTTPX...${NC}"
    cat "${wd}/domains.txt" | sort -u | httpx -silent -sc -title -ip -td -o "${wd}/httpx-out.txt" > /dev/null
    echo -e "${GRN}[+] Double checking${NC}"
    cat "${wd}/alive.txt" | httpx -silent -sc -title -ip -td | anew "${wd}/httpx-out.txt" > /dev/null
    rm "${wd}/alive.txt"
    echo -e "${GRN}[+] Done!${NC}"

}

subdomain_takeover() {
    echo -e "${GRN}==========================${NC}" >&2
    echo -e "${GRN}=== Subdomain Takeover ===${NC}" >&2
    echo -e "${GRN}==========================${NC}" >&2
    
    subjack -w "${wd}/domains.txt" -t 100 -timeout 30 -ssl -c /go/pkg/mod/github.com/haccer/subjack@v0.0.0-20201112041112-49c51e57deab/fingerprints.json -v 3 >> "${wd}/subjack-out.txt"
    cat "${wd}/subjack-out.txt" | grep -v "Not" >> "${wd}/takeovers.txt"
    rm "${wd}/subjack-out.txt"
    echo -e "${GRN}[+] Done!${NC}"

}

403_bypass() {
    echo -e "${GRN}==================${NC}" >&2
    echo -e "${GRN}=== 403 Bypass ===${NC}" >&2
    echo -e "${GRN}==================${NC}" >&2

    cat "${wd}/400.txt" | cut -d " " -f 1 >> "${wd}/400-stripped.txt"
    if [ -f "${wd}/400-stripped.txt" ]; then
        while IFS= read -r url; do
            /opt/tools/bypass-403/bypass-403.sh "$url" >> "${wd}/403-bypass-out.txt"
        done < "${wd}/400-stripped.txt"
    fi

    cat "${wd}/403-bypass-out.txt" | grep 200 >> "${wd}/bypass.txt"
    rm "${wd}/400-stripped.txt" "${wd}/403-bypass-out.txt"
    echo -e "${GRN}[+] Done!${NC}"
    
}

master_report() {
    echo -e "${GRN}=====================${NC}" >&2
    echo -e "${GRN}=== Master Report ===${NC}" >&2
    echo -e "${GRN}=====================${NC}" >&2
    
    cat ${bd}/*/200.txt | anew "${bd}/${mrn}-domains.txt"
    cat ${bd}/*/300.txt | anew "${bd}/${mrn}-domains.txt"
    cat ${bd}/*/400.txt | anew "${bd}/${mrn}-domains.txt"
    cat ${bd}/*/404.txt | anew "${bd}/${mrn}-domains.txt"
    cat ${bd}/*/takeovers.txt | anew "${bd}/${mrn}-takeovers.txt"
    cat ${bd}/*/bypass.txt | anew "${bd}/${mrn}-bypass.txt"
    cat ${bd}/*/httpx-out.txt | anew "${bd}/${mrn}-httpx.txt"
    # cat "${bd}/*/nuclei.txt" | anew "${bd}/${mrn}-nuclei.txt"
    echo -e "${GRN}[+] Done!${NC}"

}

clean_up() {
    echo -e "${GRN}================${NC}" >&2
    echo -e "${GRN}=== Clean Up ===${NC}" >&2
    echo -e "${GRN}================${NC}" >&2
    # rm -rf "${bd}"/*/
    echo -e "${GRN}[+] Done!${NC}"

}

nuceli_scan () {
    echo -e "${GRN}===================${NC}" >&2
    echo -e "${GRN}=== Nuclei Scan ===${NC}" >&2
    echo -e "${GRN}===================${NC}" >&2
    # TEST
    # for getting all ip's and ports then running nuclei
    # cat "${wd}/domains.txt" | dnsx -resp-only | uncover | httpx | nuclei | anew "${wd}/nuclei.txt"

    # for finding assets a company owns by ssl cert
    # uncover -shodan “ssl_subject_organization:dell” | httpx | nuclei
    echo -e "${GRN}[+] Done!${NC}"

}

modes() {
# Main script logic
if [ -z "$1" ]; then
    # Interactive mode
    domain_file="/data/domains.txt"
    read_domains_interactive
    if [ ! -f "$domain_file" ] || [ ! -s "$domain_file" ]; then
        echo -e "${RED}Error: No domains were entered or file creation failed${NC}"
        exit 1
    fi
else
    # File mode
    domain_file="$1"
    if [ ! -f "$domain_file" ]; then
        echo -e "${RED}Error: File '$domain_file' not found${NC}"
        exit 1
    fi
    echo -e "\n${GRN}Domains to process:${NC}" >&2
    echo -e "${GRN}-------------------${NC}" >&2
    cat "$domain_file"
    echo -e "\n${GRN}-------------------${NC}\n" >&2
fi
}

# ---------------- 
# Main 
# ---------------

modes "$1"

echo -e "${GRN}Enter Master Report Name:${NC}" >&2
read -e -p $'\033[0;31m> \033[0m' mrn;

# Create output directory
mkdir -p /data/output
bd="/data/output"

# Process domains
while IFS= read -r domain || [ -n "$domain" ]; do
    if [[ -n "$domain" ]]; then
        # Process the domain
        echo -e "\n${GRN}Processing domain: ${BLU}$domain${NC}"
    fi
    
    mkdir -p "/data/output/$domain"
    wd="/data/output/$domain"
    
    #----------------------------------------
    
    subdomain_enum
    
    #-------------------------------------------

    alive_hosts

    #----------------------------------------------

    filter_results

    #----------------------------------------------

    subdomain_takeover

    403_bypass

    # nuceli_scan

    #----------------------------------------------

done < "$domain_file"

master_report

clean_up

echo -e "${GRN}Reconnaissance complete. Results are in ${bd}/${NC}"
