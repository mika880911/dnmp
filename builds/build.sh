#!/bin/bash

# 構建 image 的腳本
bash /builds/utils/install.sh && \
bash /builds/nginx/install.sh && \
bash /builds/mysql/install.sh && \
bash /builds/php/install.sh 5.6 && \
bash /builds/php/install.sh 7.0 && \
bash /builds/php/install.sh 7.1 && \
bash /builds/php/install.sh 7.2 && \
bash /builds/php/install.sh 7.3 && \
bash /builds/php/install.sh 7.4 && \
bash /builds/php/install.sh 8.0 && \
bash /builds/php/install.sh 8.1 && \
bash /builds/composer/install.sh && \
bash /builds/redis/install.sh
