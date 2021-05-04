# Define a Helm named template so that this BATS script can be included
# in a Helm test ConfigMap. This can be left commented out; Helm will
# still be able to find this template, and this file can be kept as
# valid BATS syntax.
#
#{{- define "kube-cluster-prep.helm-test.bats" }}
#!/usr/bin/env bats

# Run out of same directory in which this script resides
cd "/tests"
source "./utils.sh"

source "/bats/bats-support/load.bash"
source "/bats/bats-assert/load.bash"
source "/bats/bats-file/load.bash"

# Baseline BATS test result color
text_color "$MAGENTA"

@test "Conjur Appliance URL is a reachable address" {
  status=0
  cmd=(curl -k --connect-timeout 5 "$conjurApplianceUrl":443)
  display_info "Running ${cmd[@]}"
  "${cmd[@]}" || status="$?"
  if [ "$status" -ne 0 ]; then
    display_error "Please check configured Conjur Appliance URL.\n" \
                  "It is not reachable via 'curl -k'"
    # Test case failed
    assert false
  fi
}

#{{- end }}
