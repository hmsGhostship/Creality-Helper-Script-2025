#!/bin/sh
cd $OCTOEVERYWHERE_FOLDER && PYTHONPATH=$OCTOEVERYWHERE_FOLDER $MOONRAKER_ENV_PYTHON -m moonraker_octoeverywhere --mconf $CONF_FILE --logpath /usr/data/printer_data/logs > /dev/null 2>&1 &
