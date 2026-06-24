
FROM ubuntu:latest

WORKDIR /


RUN apt-get update && apt-get install -y openssh-server
RUN useradd -m genericuser 
RUN echo "genericuser:prova" | chpasswd
RUN mkdir /home/genericuser/.ssh
RUN chmod 700 /home/genericuser/.ssh
RUN touch /home/genericuser/.ssh/authorized_keys
RUN chmod 600 /home/genericuser/.ssh/authorized_keys
COPY id_key_genericuser.pub /home/genericuser/.ssh/authorized_keys


RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication no/PasswordAuthentication no/' /etc/ssh/sshd_config 
RUN sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config 
RUN echo 'AllowUsers genericuser' >> /etc/ssh/sshd_config

EXPOSE 22 

CMD ["/usr/sbin/sshd","-D"] # -D : When this option is specified, sshd will not detach and does not become a  daemon.  
                            # This allows easy monitoring of sshd.
