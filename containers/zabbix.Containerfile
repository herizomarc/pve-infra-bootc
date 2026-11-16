# ===============================================================
# RED HAT BOOTC IMMUTABLE SOVEREIGN ZABBIX APPLIANCE (IMAGE MODE)
# ===============================================================
FROM registry.redhat.io/rhel9/rhel-bootc:latest

# PHASE 1: PROXMOX CLOUD-INIT & GUEST AGENT INTEGRATION

RUN dnf install -y \
      cloud-init \
      cloud-utils-growpart \
      qemu-guest-agent && \
    systemctl enable \
      cloud-init.service \
      cloud-init-local.service \
      cloud-config.service \
      cloud-final.service \
      qemu-guest-agent.service && \
    dnf clean all


# PHASE 2: REPOSITORIES & METADATA INJECTION
RUN dnf install -y https://repo.zabbix.com/zabbix/7.0/rhel/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm && \
    dnf clean all

# PHASE 3: APPLICATION PACKAGING (ZABBIX ENGINE, POSTGRESQL & WEB LAYER)
RUN dnf install -y \
    zabbix-server-pgsql \
    zabbix-web-pgsql \
    zabbix-nginx-conf \
    zabbix-sql-scripts \
    zabbix-selinux-policy \
    postgresql-server \
    firewalld \
    && dnf clean all


# PHASE 4:SELINUX HARDENING FOR ZABBIX & NGINX ON RHEL 9
RUN setsebool -P zabbix_can_network on && \
    setsebool -P httpd_can_connect_zabbix on && \
    setsebool -P httpd_can_network_connect_db on && \
    dnf clean all


# PHASE 5: SYSTEMD LIFECYCLE MANAGEMENT & RUNTIME ACTIVATION
RUN systemctl enable firewalld && \
    systemctl enable postgresql && \
    systemctl enable zabbix-server && \
    systemctl enable nginx && \
    systemctl enable php-fpm

# PHASE 6: NETWORK SECURITY ISOLATION BOUNDARIES
EXPOSE 80 443 10051
