#!/bin/bash - 
# ============================================================================ #
#                                                                              #
#          FILE: deploy.sh                                                     #
#         USAGE: ./deploy#                                                     #
#                                                                              #
#   DESCRIPTION: script makes some preparations locally, includes copying      #
#              : certain files to TARGETMACHINE, and cloning git repositories  #
#              : remotely.                                                     #
#              : Then script calls itself remotely and the rest of the         #
#              : runs on TARGETMACHINE.                                        #
#                                                                              #
#  MACHINE-NAME: app-lab-1 | app-staging-1 | koha-app                          #
#  REQUIREMENTS: changes in .htpasswd must be recorded in config repos, as     #
#              : this script overwrites the installed version with the config  #
#              : version.                                                      #
#          BUGS: ---                                                           #
#         NOTES: ---                                                           #
#        AUTHOR: xrasto, xmagnn                                                #
#  ORGANIZATION: UB                                                            #
#       CREATED: 2018-03-26 11:04                                              #
#      REVISION:  ---                                                          #
# ============================================================================ #
TARGETUSER=apps
TMPREPO="/tmp/print_bestall"
INSTALLFOLDER="/apps/bestall"
configRepos='git@github.com:ub-digit/config.git'
tmpDir=/tmp
localTmpConfigDir="${tmpDir}/ubconfig"
if [[ "${1}" != 'remoteCall' ]]
  # -------------------------------------------------- #
  # local process                                      #
  # -------------------------------------------------- #
then
  if [[ "$#" == 0 ]]
  then
    echo "Argument missing: this script craves one arg: allowed values:app-lab-1, app-staging-1, koha-app"
    exit
  fi
  TARGETMACHINE="${1}"

  SWITCH="${TARGETMACHINE}"
  case "$SWITCH" in
    "app-lab-1" ) 
      vhostConfFile="bestall-lab.conf"
      ;;
    "app-staging-1" )
      vhostConfFile="bestall-staging.conf"
      ;;
    "koha-app" )
      vhostConfFile="bestall.conf"
      ;;
    * )
      echo "Argument error: wrong target-machine, allowed values:app-lab-1, app-staging-1, koha-app"
      exit
      ;;
      # -------------------------------------------------- #
    esac 
    ssh ${TARGETUSER}@"${TARGETMACHINE}.ub.gu.se" which ssh-askpass > /dev/null  ; if [[ "${?}" != "0" ]]; then echo "ssh-askpass missing on ${TARGETMACHINE}";exit;fi
    rm -rf $localTmpConfigDir
    echo "# ------------------------------------------------ #"
    echo "# cloning config repo locally                      #"
    git clone -q $configRepos $localTmpConfigDir
    echo "# ------------------------------------------------ #"
    echo "# cloning app repo to app-server                   #"
    ssh ${TARGETUSER}@"${TARGETMACHINE}.ub.gu.se" rm -rf ${TMPREPO}
    ssh ${TARGETUSER}@"${TARGETMACHINE}.ub.gu.se" mkdir -p ${TMPREPO}
    ssh ${TARGETUSER}@"${TARGETMACHINE}.ub.gu.se" git clone -q https://github.com/ub-digit/print_bestall.git ${TMPREPO}
    echo "# ------------------------------------------------ #"
    echo "# copying configuration and authorization files    #"
    scp ${localTmpConfigDir}/servers/${TARGETMACHINE}/etc/apache2/sites-available/${vhostConfFile} ${TARGETUSER}@"${TARGETMACHINE}.ub.gu.se:${TMPREPO}"
    scp ${localTmpConfigDir}/servers/${TARGETMACHINE}/etc/htpasswd/print_bestall/.htpasswd ${TARGETUSER}@"${TARGETMACHINE}.ub.gu.se:${TMPREPO}"
    scp ${localTmpConfigDir}/servers/${TARGETMACHINE}/etc/htaccess/print_bestall/.htaccess ${TARGETUSER}@"${TARGETMACHINE}.ub.gu.se:${TMPREPO}"
    echo "# ------------------------------------------------ #"
    ssh -X ${TARGETUSER}@"${TARGETMACHINE}.ub.gu.se" "${TMPREPO}/deploy.sh remoteCall ${vhostConfFile}"
  else
  # -------------------------------------------------- #
  # remote process                                     #
  # -------------------------------------------------- #
    if [[ "${0}" != "/tmp/print_bestall/deploy.sh" ]]
    then
      echo "must be called from ./deploy.sh arg"
      exit
    fi
    vhostConfFile="${2}"
    # -------------------------------------------------- #
    echo "installing cron job REPO:etc/cron.d to TARGET:/etc/cron.d/print_bestall # (644 root:root)"
    SUDO_ASKPASS="/usr/bin/ssh-askpass" sudo -A cp "${TMPREPO}/etc/cron.d/print_bestall" /etc/cron.d/
    # -------------------------------------------------- #
    echo "checking perl installation"
    perl -e 'use DBI;'
    if [[ "$?" != "0" ]]; then
      echo "DBI is not installed: cpan: install DBI"
      exit
    fi
    echo "perl OK!"
    echo "# ------------------------------------------------ #"
    diff /etc/apache2/sites-enabled/${vhostConfFile} ${TMPREPO}/${vhostConfFile} > /dev/null 2>&1
    if [[ "$?" != "0" ]]; then
      echo "configuring vhost"
      echo "/etc/apache2/sites-available/${vhostConfFile}" 
      if [[ -f "/etc/apache2/sites-available/${vhostConfFile}" ]]; then
        echo "backing up /etc/apache2/sites-available/${vhostConfFile}" 
        SUDO_ASKPASS="/usr/bin/ssh-askpass" sudo -A cp /etc/apache2/sites-available/${vhostConfFile} /etc/apache2/sites-available/${vhostConfFile}.bak_$(date "+%s")
      fi
      SUDO_ASKPASS="/usr/bin/ssh-askpass" sudo -A cp ${TMPREPO}/${vhostConfFile} /etc/apache2/sites-available/${vhostConfFile}
      SUDO_ASKPASS="/usr/bin/ssh-askpass" sudo -A a2dissite -q ${vhostConfFile}
      SUDO_ASKPASS="/usr/bin/ssh-askpass" sudo -A a2ensite -q ${vhostConfFile}
      SUDO_ASKPASS="/usr/bin/ssh-askpass" sudo -A service apache2 reload
    fi
    echo "apache OK!"
    echo "# ------------------------------------------------ #"
    SUDO_ASKPASS="/usr/bin/ssh-askpass" sudo -A apache2ctl -M | grep cgid > /dev/null
    if [[ "$?" != "0" ]]; then
      echo "enabling cgid"
      SUDO_ASKPASS="/usr/bin/ssh-askpass" sudo -A a2enmod -q cgid
      SUDO_ASKPASS="/usr/bin/ssh-askpass" sudo -A service apache2 restart
    fi
    echo "apache modules OK!"
    echo "# ------------------------------------------------ #"
    # -------------------------------------------------- #
    echo "installing into:${INSTALLFOLDER}/print_bestall"
    SUDO_ASKPASS="/usr/bin/ssh-askpass" sudo -A rm -rf "${INSTALLFOLDER}/print_bestall/"
    mkdir -p "${INSTALLFOLDER}/print_bestall/"
    mkdir -p "${INSTALLFOLDER}/files/done"
    SUDO_ASKPASS="/usr/bin/ssh-askpass" sudo -A chmod 777 "${INSTALLFOLDER}/files/"
    SUDO_ASKPASS="/usr/bin/ssh-askpass" sudo -A chmod 777 "${INSTALLFOLDER}/files/done/"
    cp -r "${TMPREPO}/cgi-bin"   "${INSTALLFOLDER}/print_bestall/"
    cp -r "${TMPREPO}/html"      "${INSTALLFOLDER}/print_bestall/"
    cp -r "${TMPREPO}/scripts"   "${INSTALLFOLDER}/print_bestall/"
    cp    "${TMPREPO}/.htaccess" "${INSTALLFOLDER}/print_bestall/"
    cp    "${TMPREPO}/.htaccess" "${INSTALLFOLDER}/files/"
    SUDO_ASKPASS="/usr/bin/ssh-askpass" sudo -A chown www-data:www-data "${INSTALLFOLDER}/print_bestall/scripts/reprint.sh"
    SUDO_ASKPASS="/usr/bin/ssh-askpass" sudo -A chmod 6755 "${INSTALLFOLDER}/print_bestall/scripts/reprint.sh"
    echo "print_bestall installed"
    # -------------------------------------------------- #
    diff /etc/htpasswd/print_bestall/.htpasswd /apps/htpasswd/print_bestall/.htpasswd > /dev/null 2>&1
    if [[ "$?" != "0" ]]; then
      SUDO_ASKPASS="/usr/bin/ssh-askpass" sudo -A mkdir -p "/etc/htpasswd/print_bestall/"
      SUDO_ASKPASS="/usr/bin/ssh-askpass" sudo -A cp "${TMPREPO}/.htpasswd" "/etc/htpasswd/print_bestall/"
      echo "htpasswd installed"
    else
      echo "htpasswd already installed"
    fi
    # -------------------------------------------------- #
  fi
