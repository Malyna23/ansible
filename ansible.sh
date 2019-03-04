#!/bin/bash
sudo yum -y update

sudo yum -y install epel-release

sudo yum -y install ansible

mkdir templates

sudo chmod 500 /home/vagrant/machines/web/virtualbox/private_key
sudo chmod 500 /home/vagrant/machines/web1/virtualbox/private_key
sudo chmod 500 /home/vagrant/machines/web2/virtualbox/private_key

sudo cat <<EOF | sudo tee -a /home/vagrant/hosts.txt
[lb]
load_balancer ansible_host=192.168.56.2 ansible_user=vagrant ansible_ssh_private_key_file=/home/vagrant/machines/web/virtualbox/private_key
[web]
web1 ansible_host=192.168.56.3 ansible_user=vagrant ansible_ssh_private_key_file=/home/vagrant/machines/web1/virtualbox/private_key
web2 ansible_host=192.168.56.4 ansible_user=vagrant ansible_ssh_private_key_file=/home/vagrant/machines/web2/virtualbox/private_key
EOF

sudo cat <<EOF | sudo tee -a /home/vagrant/ansible.cfg
[defaults]
host_key_checking = false
inventory = /home/vagrant/hosts.txt
EOF

sudo cat <<EOF | sudo tee -a /home/vagrant/templates/haproxy.cfg.j2
global
    
    log         127.0.0.1 local2

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats


defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000


frontend  main 192.168.56.2:80
    acl url_static       path_beg       -i /static /images /javascript /stylesheets
    acl url_static       path_end       -i .jpg .gif .png .css .js

    use_backend static          if url_static
    default_backend             app


backend static
    balance     roundrobin
    server      static 127.0.0.1:4331 check


backend app
    balance     roundrobin
    server  app1 192.168.56.3:80 check
    server  app2 192.168.56.4:80 check
EOF

sudo cat <<EOF | sudo tee -a /home/vagrant/playbook.yml
- name: Install web-server Apache
  hosts: web
  become: yes

  tasks:
  - name: Install Apahce web-server
    yum: name=httpd state=latest
  - name: Start Apache and Enable it on the server
    service: name=httpd state=started enabled=yes



- name: Install web-server Apache
  hosts: lb
  become: yes
  tasks:
  - name: Download and install haproxy
    yum: name=haproxy state=present
  - name: Configure the haproxy cnf file with hosts
    template: src=haproxy.cfg.j2 dest=/etc/haproxy/haproxy.cfg
    notify: restart haproxy
  - name: Start the haproxy service
    service: name=haproxy state=started enabled=yes
  handlers:
  - name: restart haproxy
    service: name=haproxy state=restarted
EOF

sudo ansible-playbook playbook.yml
