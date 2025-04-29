
ARG PYTHON_VERSION="3.12"
# 3.14-rc-alpine与trac 1.6 会出现sqlite.version_info 的问题，所以这里使用3.12-rc-alpine
FROM python:${PYTHON_VERSION}-rc-alpine


ARG USER_UNAME="trac"
ARG USER_GNAME=${USER_UNAME}
ARG USER_UID="931"
ARG USER_GID=${USER_UID}
#ARG TRAC_BASE_DIR="/trac"

ENV TRAC_BASE_DIR="/trac"
ENV TRAC_PROJECT_NAME="default"

RUN addgroup -S -g ${USER_GID} ${USER_GNAME} \
    && adduser -S -u ${USER_UID} -g ${USER_GID} ${USER_UNAME}

  
COPY docker-entrypoint.sh /usr/local/bin/
COPY scripts/* /usr/local/bin/   
COPY requirements-container.txt .  

RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/manage.py  \
    && mkdir -p ${TRAC_BASE_DIR} \    
    && apk update && apk add git --no-cache \
    && pip install sqlite-utils  \
    && pip install babel==2.9.1  \
    && pip install Jinja2 \
    && pip install Trac==1.6  \
    && pip install TracAccountManager \
    && pip install -r requirements-container.txt \
    && rm -rf requirements-container.txt \
    && trac-admin ${TRAC_BASE_DIR}/${TRAC_PROJECT_NAME} initenv ${TRAC_PROJECT_NAME} sqlite:db/trac.db  \
    && chown -R ${USER_UNAME}:${USER_GNAME} ${TRAC_BASE_DIR} 

    
USER ${USER_UNAME} 

EXPOSE 8000  

# 执行命令
# CMD ["sh"]
ENTRYPOINT ["docker-entrypoint.sh"]
