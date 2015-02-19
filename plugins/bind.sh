#!/bin/bash
#
# bind.sh
#
# Author: Matteo Cerutti <matteo.cerutti@hotmail.co.uk>
#

function showhelp() {
  echo -n "Usage: `basename $0` "
  case $1 in
    "zones")
      case $2 in
        "errors" | "warning")
          echo "$1 $2 <zone>"
          ;;

        *)
          echo "$1 <count|discovery|validate|errors|warnings>"
      esac
      ;;

    *)
      echo "<status|zones|xfers_running|xfers_deferred>"
  esac

  exit 1
}

which rndc &>/dev/null && RNDC_BIN=$(which rndc) || {
  test -e /usr/sbin/rndc && RNDC_BIN=/usr/sbin/rndc || { echo "Unable to locate rndc" >&2; exit 1; }
}
test ! -x $RNDC_BIN && { echo "Unable to execute $RNDC_BIN" >&2; exit 1; }

which named-checkzone &>/dev/null && NAMED_CHECKZONE=$(which named-checkzone) || {
  test -e /usr/sbin/named-checkzone && NAMED_CHECKZONE=/usr/sbin/named-checkzone || { echo "Unable to locate named-checkzone" >&2; exit 1; }
}
test ! -x $NAMED_CHECKZONE && { echo "Unable to execute $NAMED_CHECKZONE" >&2; exit 1; }

# bind zone files directory
BIND_ZONES_DIR=${BIND_ZONES_DIR:-/var/lib/named/master}

case $1 in
  "zones")
    case $2 in
      "count")
        $RNDC_BIN status | grep "number of zones" | cut -d ':' -f 2 | sed -e 's/^\s*//'
        ;;

      "validate")
        zone_file=$BIND_ZONES_DIR/$3
        if [ -e $zone_file ]; then
          $NAMED_CHECKZONE -k ignore "$3" $zone_file &>/dev/null
          [ $? -eq 0 ] && echo 0 || echo 1
        else
          # not existent
          echo -1
        fi
        ;;

      "errors" | "warnings")
        which sleuth &>/dev/null && SLEUTH_BIN=$(which sleuth) || {
          test -e /usr/bin/sleuth && SLEUTH_BIN=/usr/bin/sleuth || { echo "Unable to locate sleuth" >&2; exit 1; }
        }
        test ! -x $SLEUTH_BIN && { echo "Unable to execute $SLEUTH_BIN" >&2; exit 1; }

        test -z "$3" && showhelp $1 $2

        case $2 in
          "errors") pos=2 ;;
          "warnings") pos=4 ;;
        esac

        logline=$($SLEUTH_BIN $3 | tail -n 1)
        if [[ $logline =~ Fatal\ error ]]; then
          echo 0
        else
          echo "$logline" | cut -d " " -f $pos
        fi
        ;;

      "discovery")
        echo "{"
        echo "  \"data\": ["
          count=0
          cat /etc/named.conf | grep -v '^include' | grep zone | sed 's/[^"]*"//' | sed 's/".*//' | sort -n | uniq | grep -v '^.$' | while read zone; do
          [ $count -gt 0 ] && echo "    },"
          echo "    {"
          echo "      \"{#ZONE_NAME}\": \"$zone\""
          count=$((count+1))
        done
        [ $count -gt 0 ] && echo "    }"
        echo "  ]"
        echo "}"
        ;;

      *)
        showhelp $1
    esac
    ;;

  "status")
    $RNDC_BIN status | grep -c "server is up and running"
    ;;

  "xfers_running")
    $RNDC_BIN status | grep "xfers running" | cut -d ':' -f 2 | sed -e 's/^\s*//'
    ;;

  "xfers_deferred")
    $RNDC_BIN status | grep "xfers deferred" | cut -d ':' -f 2 | sed -e 's/^\s*//'
    ;;

  *)
    showhelp
esac

exit 0
