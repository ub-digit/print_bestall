#!/bin/bash - 
# ============================================================================ #
#
#          FILE: deploy.sh
# 
#         USAGE: ./deploy.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Torgny Rasmark (TR), Torgny.Rasmark@ub.gu.se
#  ORGANIZATION: UB
#       CREATED: 2018-03-26 11:04
#      REVISION:  ---
# ============================================================================ #


if [[ "${1}" == 'real' ]]
then
  echo "arg was real"
  exit
fi
TARGETMACHINE="${1}"
TARGETUSER=apps
TARGETREPO="/tmp/print_bestall_$$"
ssh ${TARGETUSER}@"${TARGETMACHINE}.ub.gu.se" mkdir -p ${TARGETREPO}
ssh ${TARGETUSER}@"${TARGETMACHINE}.ub.gu.se" git clone https://github.com/ub-digit/print_bestall.git ${TARGETREPO}
ssh ${TARGETUSER}@"${TARGETMACHINE}.ub.gu.se" "${TARGETREPO}/deploy.sh real"
echo " kopiera REPO:etc/cron.d till TARGET:/etc/cron.d/print_bestall # (644 root:root)"
#sudo cp etc/cron.d/print_bestall root@app-lab-1.ub.gu.se:/etc/cron.d
echo " kontrollera att DBI.pm är installerad                  # perl -e 'use DBI;' som root, skall gå rent"
echo " kontrollera att vhost-filen för bestall är uppdaterad från config-reposet: ex:"
echo "   CONFIG:servers/app-staging-1/etc/apache2/sites-available/bestall-staging.conf"
echo " installera "
echo "   från CONFIG:servers/app-staging-1/etc/htpasswd/print_bestall/.htpasswd"
echo "   till TARGET:/etc/htpasswd/print_bestall"
echo " kopiera i sin helhet katalogerna från REPO: till TARGET:/apps/bestall/print_bestall"
echo "   cgi-bin"
echo "   html"
echo "   scripts"
echo "   samt .htaccess-filen"
echo "kolla struktur, ägarskap och rättigheter"

