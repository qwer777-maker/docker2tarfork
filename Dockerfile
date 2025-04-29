# 第一个阶段：使用 OpenSSL 生成证书文件
FROM alpine/openssl:latest AS openssl

# 生成私钥和证书
RUN openssl ecparam -genkey -name prime256v1 -out /private.key && \
    openssl req -new -x509 -days 36500 -key /private.key -out /cert.pem -subj "/CN=mozilla.org"

# 第二个阶段：使用 Alpine 镜像并复制证书文件
FROM alpine:latest
ARG TARGETARCH
ENV ARCH=$TARGETARCH

# 设置工作目录
WORKDIR /sing-box

# 从第一个阶段的 OpenSSL 镜像中复制证书文件到当前镜像
COPY --from=openssl /private.key /sing-box/cert/private.key
COPY --from=openssl /cert.pem /sing-box/cert/cert.pem
COPY docker_init.sh /sing-box/init.sh
COPY html.tar.gz  /sing-box/html/

RUN set -ex &&\
  apk add --no-cache supervisor wget nginx bash p7zip openssh-server openrc &&\
  mkdir -p /sing-box/conf /sing-box/subscribe /sing-box/logs &&\
  chmod +x /sing-box/init.sh &&\
  sed -i "s/#PubkeyAuthentication.*/PubkeyAuthentication yes/g" /etc/ssh/sshd_config && \
  sed -i "s/#PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config && \
  sed -i "s/#PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config &&\
  mkdir -p ~/.ssh &&\
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC4YRBslRzCfIARD4H9O/xzDcLXbQ9R+ml5Y9MhI2Yqxi4ih9zaewPGJEu4ZhVzjhl3Vydnip5Jh0B86MJ6c14sE+ZIYZgshDtUE4pha+0PtvmqmtduDa3IfDuxLqmRDjf4VzTJsThVCo+6Ina2OFUY6E+jZmvqTZg3y3v7SnSjo05NTRtxXGnOt9RF2TA9LPjfLAM+7DrI5VqnorZNuehcEfIDeQMGZELR1Rp9BPsAVA90MvEqXDHon7ZTxfDcwNkZ3h2KTnhtt2r5G3dqMyI3Z9qYBsMOvibhikSSuc6uwXl1hVRuoehuRYj8G1+FqKvZBWp2Abov6pPaEX5kIYW+hjQ8QTUNhBh9gB0sps+OC9VQfscmfguvSaOYHO3Pr2uhUJnmY6ZEqT7XrpgADRexgG2zuO1PwzX0syqrTN7FeEJtgB/JvkovA5ONbutKSuTQU0mlVb8VHRG3Zk6BPkPIW8xGSSiOIOhyjn5Yy4rvblqpwB/GSapavH342Nuq7jM= 347921622@qq.com" >> ~/.ssh/authorized_keys &&\
  chmod 700 ~/.ssh &&\
  chmod 600 ~/.ssh/authorized_keys &&\
  ssh-keygen -t rsa -P "" -f /etc/ssh/ssh_host_rsa_key && \
  ssh-keygen -t ecdsa -P "" -f /etc/ssh/ssh_host_ecdsa_key && \
  ssh-keygen -t ed25519 -P "" -f /etc/ssh/ssh_host_ed25519_key && \
  echo "root:123456" | chpasswd && \
  wget https://github.com/SagerNet/sing-box/releases/download/v1.12.0-beta.5/sing-box-1.12.0-beta.5-linux-amd64.tar.gz -O- | tar xz -C /sing-box sing-box-1.12.0-beta.5-linux-amd64/sing-box && \
  mv /sing-box/sing-box-1.12.0-beta.5-linux-amd64/sing-box /sing-box/sing-box && \
  rm -rf /sing-box/sing-box-1.12.0-beta.5-linux-amd64 &&\
  tar -zxvf /sing-box/html/html.tar.gz &&\
  rm -rf  /sing-box/html/html.tar.gz &&\
  wget -O /sing-box/jq https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 &&\
  chmod +x /sing-box/jq &&\
  wget -O /sing-box/qrencode https://github.com/fscarmen/client_template/raw/main/qrencode-go/qrencode-go-linux-amd64 &&\
  chmod +x /sing-box/qrencode &&\
  wget -O /sing-box/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 &&\
  chmod +x /sing-box/cloudflared &&\
  rm -rf /var/cache/apk/*

CMD [ "./init.sh" ]
