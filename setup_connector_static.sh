#!/bin/sh

# IBM Confidential
# 5900-AVW
# (c) Copyright IBM Corp. 2023

# Enforce a Linux host
OS=$(uname -s)
if [ "$OS" = "Linux" ]; then
  MACHINE=$(uname -m)
else
  echo "This connector can only be installed on a Linux OS"
  exit 1
fi


# Read the command line options using getopts.  Colon after the parameter
# means there should be a value after it (like -a myagentkey, not just -a).
while getopts "a:c:e:f:" opt; do
  case $opt in
    a)
      INSTANA_AGENT_KEY=$OPTARG
      ;;
    c)
      AGENT_CONF_BASE64=$OPTARG
      ;;
    e)
      ENDPOINT=$OPTARG
      ;;
    f)
      STATIC_AGENT_FILE=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Parse the endpoint
if [ -n "${ENDPOINT}" ]; then
  split=(${ENDPOINT//:/ })
  INSTANA_AGENT_HOST="${split[0]}"
  INSTANA_AGENT_PORT="${split[1]}"
else
  echo "The endpoint must be in the format host:port, but is " $ENDPOINT
  exit 1
fi

# Make sure the file exists
if [ -z $STATIC_AGENT_FILE ]; then
    echo "The static connector package was not specified."
    echo "Please obtain the static connector and specify its path using the -f flag."
    exit 1
fi


if [ ! -f $STATIC_AGENT_FILE ]; then
    echo "The static connector package $STATIC_AGENT_FILE does not exist."
    echo "Please obtain the static connector and specify its path using the -f flag."
    exit 1
fi


# Extract the static agent
tar -xzf $STATIC_AGENT_FILE
RC=$?
if [ $RC -ne 0 ]; then
   echo "There was a problem extracting the static connector ($RC)"
   exit 1
fi

# Write the agent backend sender configuration file
# Create a properties file from the kafka credentials, for use by the kafka
# client
cat <<EOF > instana-agent/etc/instana/com.instana.agent.main.sender.Backend.cfg
host=$INSTANA_AGENT_HOST
port=$INSTANA_AGENT_PORT
protocol=HTTP/2
key=$INSTANA_AGENT_KEY
EOF

# Write the connector configuration
echo $AGENT_CONF_BASE64 | base64 -d > instana-agent/etc/instana/configuration-connector.yaml

# Success
echo "The connector has been unpacked.  You must have a Java JDK installed"
echo "to use the connector.  To start the connector run:"
echo "  instana-agent/bin/start"
echo "To stop the connector run:"
echo "  instana-agent/bin/stop"
