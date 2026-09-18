FROM rockylinux:9


RUN dnf install -y openssh-server sudo && mkdir -p /var/run/sshd && useradd -m genericuser && \
    echo "genericuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/genericuser && chmod 440 /etc/sudoers.d/genericuser

RUN dnf install -y dnf-plugins-core && dnf config-manager --add-repo http://download.docker.com/linux/rhel/docker-ce.repo && \
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && dnf clean all 


RUN ssh-keygen -A


RUN sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    echo 'AllowUsers genericuser' >> /etc/ssh/sshd_config


EXPOSE 22


RUN mkdir -p /home/genericuser/.ssh && chmod 700 /home/genericuser/.ssh


COPY id-genericuser.pub /home/genericuser/.ssh/authorized_keys

COPY roles/step5/files/docker-entrypoint.sh /usr/local/bin/entrypoint.sh


RUN chmod 600 /home/genericuser/.ssh/authorized_keys && chmod 700 /usr/local/bin/entrypoint.sh && \
    chown -R genericuser:genericuser /home/genericuser/.ssh

CMD ["/usr/local/bin/entrypoint.sh"]
