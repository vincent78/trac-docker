
ARG PYTHON_VERSION="3.12"
# 3.14-rc-alpine与trac 1.6 会出现sqlite.version_info 的问题，所以这里使用3.12-rc-alpine
FROM python:${PYTHON_VERSION}-rc-alpine



# COPY requirements-container.txt .    
RUN apk add git \    
    && apk add sudo \
    && pip install sqlite-utils --root-user-action=ignore \
    && pip install babel==2.9.1 --root-user-action=ignore \
    && pip install Jinja2 --root-user-action=ignore \
    && pip install Trac==1.6 --root-user-action=ignore

#    && pip install -r requirements-container.txt \
#    && rm requirements-container.txt



ENV TRAC_BASE_DIR="/trac"
ENV TRAC_PROJECT_NAME="default"


RUN mkdir ${TRAC_BASE_DIR} \
    && trac-admin \
        ${TRAC_BASE_DIR}/${TRAC_PROJECT_NAME} \
        initenv \
        ${TRAC_PROJECT_NAME} \
        sqlite:db/trac.db    


ARG USER_UNAME="trac"
ARG USER_GNAME=${USER_UNAME}
ARG USER_UID="931"
ARG USER_GID=${USER_UID}

RUN addgroup -S -g ${USER_GID} ${USER_GNAME} \
    && adduser -S -u ${USER_UID} -g ${USER_GID} ${USER_UNAME} sudo \
    && echo "${USER_UNAME}:1" | chpasswd \
    && echo "trac ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/trac \
    && chown -R ${USER_UNAME}:${USER_GNAME} ${TRAC_BASE_DIR}
    
   
EXPOSE 8000  

COPY docker-entrypoint.sh /usr/local/bin/
COPY scripts/* /usr/local/bin/   

RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/manage.py  \
    && chown ${USER_UNAME}:${USER_GNAME} /usr/local/bin/docker-entrypoint.sh 


USER ${USER_UNAME} 

# 执行命令
CMD ["sh"]
# ENTRYPOINT ["docker-entrypoint.sh"]
